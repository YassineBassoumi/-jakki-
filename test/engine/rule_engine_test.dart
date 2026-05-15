import 'package:flutter_test/flutter_test.dart';
import 'package:jakki/engine/board.dart';
import 'package:jakki/engine/dice.dart';
import 'package:jakki/engine/game_state.dart';
import 'package:jakki/engine/house_rules.dart';
import 'package:jakki/engine/move.dart';
import 'package:jakki/engine/move_generator.dart';
import 'package:jakki/engine/player.dart';
import 'package:jakki/engine/point.dart';
import 'package:jakki/engine/rule_engine.dart';

import 'test_helpers.dart';

void main() {
  group('Bear-off semantics', () {
    test('Exact bear-off: white at point 5 with a 5 → off the board', () {
      final Board board = boardFrom(<int, Point>{
        5: ownStack(Player.white, 15),
        24: ownStack(Player.black, 15),
      });
      final GameState s = stateWith(
        board: board,
        toMove: Player.white,
        dice: const Dice(5, 1),
      );
      const Move m = Move(from: 5, pips: 5, bearsOff: true);
      expect(RuleEngine.canApply(s, m), isTrue);
      final GameState after = RuleEngine.applyMove(s, m);
      expect(after.board.bornOffWhite, 1);
      expect(after.board.pointAt(5).topCount, 14);
    });

    test('Over-roll bear-off: white with 1 checker on 4 and roll 6 → off', () {
      final Board board = boardFrom(<int, Point>{
        4: ownStack(Player.white, 15),
        24: ownStack(Player.black, 15),
      });
      final GameState s = stateWith(
        board: board,
        toMove: Player.white,
        dice: const Dice(6, 1),
      );
      const Move m = Move(from: 4, pips: 6, bearsOff: true);
      expect(RuleEngine.canApply(s, m), isTrue);
    });

    test('Over-roll bear-off rejected when a further-from-bear-off point '
        'is occupied', () {
      // White at 4 (1) AND at 5 (14). Highest occupied is 5; rolling
      // a 6 from point 4 is not a legal bear-off (must use the 6 on
      // the checker at point 5 instead).
      final Board board = boardFrom(<int, Point>{
        4: ownStack(Player.white, 1),
        5: ownStack(Player.white, 14),
        24: ownStack(Player.black, 15),
      });
      final GameState s = stateWith(
        board: board,
        toMove: Player.white,
        dice: const Dice(6, 1),
      );
      expect(
        RuleEngine.canApply(s, const Move(from: 4, pips: 6, bearsOff: true)),
        isFalse,
      );
      // From 5 with a 6 is a legal over-roll bear-off.
      expect(
        RuleEngine.canApply(s, const Move(from: 5, pips: 6, bearsOff: true)),
        isTrue,
      );
    });

    test('Winner is set when all 15 own checkers have borne off', () {
      final Board board = boardFrom(<int, Point>{
        1: ownStack(Player.white, 1),
        24: ownStack(Player.black, 15),
      }, bornOffWhite: 14);
      final GameState s = stateWith(
        board: board,
        toMove: Player.white,
        dice: const Dice(1, 2),
      );
      final GameState after = RuleEngine.applyMove(
        s,
        const Move(from: 1, pips: 1, bearsOff: true),
      );
      expect(after.isGameOver, isTrue);
      expect(after.winner, Player.white);
      expect(after.board.bornOffWhite, 15);
    });
  });

  group('Turn lifecycle', () {
    test('rollDice → applyMoves → endTurn switches the player', () {
      GameState s = GameState.newGame();
      s = RuleEngine.rollDice(s, const Dice(6, 5));
      expect(s.dice, const Dice(6, 5));
      expect(s.remainingPips, <int>[6, 5]);

      final List<List<Move>> seqs = MoveGenerator.legalSequences(s);
      expect(seqs, isNotEmpty);
      s = RuleEngine.applyMoves(s, seqs.first);
      expect(s.remainingPips, isEmpty);

      s = RuleEngine.endTurn(s);
      expect(s.toMove, Player.black);
      expect(s.dice, isNull);
    });

    test('rollDice throws if dice were already rolled', () {
      GameState s = GameState.newGame();
      s = RuleEngine.rollDice(s, const Dice(3, 4));
      expect(() => RuleEngine.rollDice(s, const Dice(1, 2)), throwsStateError);
    });

    test('Doubles produce four equal pips by default', () {
      GameState s = GameState.newGame();
      s = RuleEngine.rollDice(s, const Dice(6, 6));
      expect(s.remainingPips, <int>[6, 6, 6, 6]);
    });

    test('Cannot move when no legal sub-move exists (returns empty list)', () {
      // Construct a state where white has zero legal moves: white
      // has a single checker on 24, black has heavy blocks at 23, 22,
      // 21, 20, 19, 18.
      final Board board = boardFrom(<int, Point>{
        24: ownStack(Player.white, 15),
        23: ownStack(Player.black, 3),
        22: ownStack(Player.black, 3),
        21: ownStack(Player.black, 3),
        20: ownStack(Player.black, 2),
        19: ownStack(Player.black, 2),
        18: ownStack(Player.black, 2),
      });
      final GameState s = stateWith(
        board: board,
        toMove: Player.white,
        dice: const Dice(1, 6),
      );
      final List<List<Move>> seqs = MoveGenerator.legalSequences(s);
      expect(
        seqs,
        isEmpty,
        reason: 'white is completely shut out for this roll',
      );
    });
  });

  group('Move generator', () {
    test('Legal sequences for opening roll (3, 1) are bounded and valid', () {
      final GameState s = RuleEngine.rollDice(
        GameState.newGame(),
        const Dice(3, 1),
      );
      final List<List<Move>> seqs = MoveGenerator.legalSequences(s);
      expect(seqs, isNotEmpty);
      // Each maximal sequence should consume both pips.
      for (final List<Move> seq in seqs) {
        final List<int> pips = seq.map((Move m) => m.pips).toList()..sort();
        expect(pips, <int>[1, 3]);
      }
    });

    test('canBearOffWhilePinning flag inverts the pinning bear-off rule', () {
      final Board board = boardFrom(<int, Point>{
        1: ownStack(Player.white, 14),
        5: ownStack(Player.white, 1, pinned: true),
        24: ownStack(Player.black, 14),
      });
      // Default rules: cannot bear off from 5 (pinning).
      final GameState s1 = stateWith(
        board: board,
        toMove: Player.white,
        dice: const Dice(5, 1),
      );
      expect(
        RuleEngine.canApply(s1, const Move(from: 5, pips: 5, bearsOff: true)),
        isFalse,
      );
      // Enabled flag: now allowed.
      final GameState s2 = stateWith(
        board: board,
        toMove: Player.white,
        dice: const Dice(5, 1),
        rules: const HouseRules(canBearOffWhilePinning: true),
      );
      expect(
        RuleEngine.canApply(s2, const Move(from: 5, pips: 5, bearsOff: true)),
        isTrue,
      );
    });
  });
}
