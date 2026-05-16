import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jakki/ai/bot.dart';
import 'package:jakki/ai/evaluator.dart';
import 'package:jakki/engine/dice.dart';
import 'package:jakki/engine/game_state.dart';
import 'package:jakki/engine/move.dart';
import 'package:jakki/engine/move_generator.dart';
import 'package:jakki/engine/player.dart';
import 'package:jakki/engine/point.dart';
import 'package:jakki/engine/rule_engine.dart';

import '../engine/test_helpers.dart';

void main() {
  group('Evaluator', () {
    test('borne-off checkers strongly favour their owner', () {
      // White is one bear-off closer to finishing → should evaluate
      // strictly higher from white's perspective than a state with
      // an extra checker still on the board.
      final GameState baseline = GameState.newGame();
      final GameState ahead = baseline.copyWith(
        board: baseline.board.copyWith(bornOffWhite: 1),
      );
      final double baseScore = Evaluator.evaluate(
        baseline,
        perspective: Player.white,
      );
      final double aheadScore = Evaluator.evaluate(
        ahead,
        perspective: Player.white,
      );
      expect(aheadScore, greaterThan(baseScore));
    });

    test('pinning an opponent yields a positive contribution', () {
      // Mid-board point with a single black checker; white sitting
      // on top is a textbook pin.
      final GameState pinning = GameState(
        board: boardFrom(<int, Point>{
          12: ownStack(Player.white, 1, pinned: true),
          24: ownStack(Player.white, 14),
          1: ownStack(Player.black, 14),
        }),
        toMove: Player.white,
        rules: GameState.newGame().rules,
      );
      final GameState noPin = GameState(
        board: boardFrom(<int, Point>{
          12: ownStack(Player.white, 1),
          24: ownStack(Player.white, 14),
          1: ownStack(Player.black, 14),
          // Black's pinned checker has been "moved" back to its home
          // stack instead.
        }, bornOffBlack: 0),
        toMove: Player.white,
        rules: GameState.newGame().rules,
      );
      final double pinScore = Evaluator.evaluate(
        pinning,
        perspective: Player.white,
      );
      final double noPinScore = Evaluator.evaluate(
        noPin,
        perspective: Player.white,
      );
      expect(pinScore, greaterThan(noPinScore));
    });

    test('evaluate is anti-symmetric across perspectives', () {
      final GameState state = GameState.newGame();
      final double white = Evaluator.evaluate(state, perspective: Player.white);
      final double black = Evaluator.evaluate(state, perspective: Player.black);
      // Starting position is exactly symmetric so the two values
      // should be opposites (up to floating-point error).
      expect(white + black, closeTo(0, 1e-9));
    });
  });

  group('OnePlyBot', () {
    test('returns an empty sequence when there is no legal play', () {
      // White must move from point 24, but black has a 2-stack on every
      // reachable destination, blocking the roll.
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{
          24: ownStack(Player.white, 15),
          23: ownStack(Player.black, 2),
          22: ownStack(Player.black, 2),
        }),
        toMove: Player.white,
        dice: const Dice(1, 2),
      );
      expect(MoveGenerator.legalSequences(state), isEmpty);
      final OnePlyBot bot = OnePlyBot(rng: Random(42));
      expect(bot.chooseTurn(state), isEmpty);
    });

    test('chooses a legal sequence on the opening roll', () {
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{
          24: ownStack(Player.white, 15),
          1: ownStack(Player.black, 15),
        }),
        toMove: Player.white,
        dice: const Dice(5, 3),
      );
      final OnePlyBot bot = OnePlyBot(rng: Random(1));
      final List<Move> sequence = bot.chooseTurn(state);
      expect(sequence, isNotEmpty);
      // Whatever was chosen must apply cleanly to the engine.
      final GameState after = RuleEngine.applyMoves(state, sequence);
      expect(after.remainingPips, isEmpty);
      // White should have moved checkers off of 24 (the only place
      // it can move from on the opening roll).
      expect(after.board.pointAt(24).topCount, lessThan(15));
    });

    test('prefers bearing off over a non-bearing move', () {
      // White has every checker home; the only sensible play with a
      // 5 is to bear off the checker on point 5.
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{
          5: ownStack(Player.white, 1),
          1: ownStack(Player.white, 14),
          24: ownStack(Player.black, 15),
        }),
        toMove: Player.white,
        dice: const Dice(5, 1),
      );
      final OnePlyBot bot = OnePlyBot(rng: Random(0));
      final List<Move> sequence = bot.chooseTurn(state);
      expect(
        sequence.any((Move m) => m.bearsOff),
        isTrue,
        reason: 'Bot should pick the bear-off line when one is available.',
      );
    });

    test('expectimax mode also returns a legal sequence', () {
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{
          24: ownStack(Player.white, 15),
          1: ownStack(Player.black, 15),
        }),
        toMove: Player.white,
        dice: const Dice(6, 1),
      );
      final OnePlyBot bot = OnePlyBot(rng: Random(7), expectimax: true);
      final List<Move> sequence = bot.chooseTurn(state);
      expect(sequence, isNotEmpty);
      // Smoke test: applying the move never throws.
      RuleEngine.applyMoves(state, sequence);
    });

    test('plays a full white-vs-bot game without crashing', () {
      // Two bots play each other — the game must terminate (winner
      // set) within a reasonable number of turns and produce a
      // legal final state.
      final OnePlyBot bot = OnePlyBot(rng: Random(123));
      final Random diceRng = Random(456);

      GameState state = GameState.newGame();
      int turnsTaken = 0;
      const int maxTurns = 300; // safety cap

      while (!state.isGameOver && turnsTaken < maxTurns) {
        // Roll dice.
        state = RuleEngine.rollDice(
          state,
          Dice(diceRng.nextInt(6) + 1, diceRng.nextInt(6) + 1),
        );
        // Pick & apply a legal sequence (possibly empty: stuck).
        final List<Move> seq = bot.chooseTurn(state);
        if (seq.isNotEmpty) {
          state = RuleEngine.applyMoves(state, seq);
        }
        if (state.isGameOver) break;
        state = RuleEngine.endTurn(state);
        turnsTaken++;
      }

      expect(state.isGameOver, isTrue);
      expect(turnsTaken, lessThan(maxTurns));
    });
  });
}
