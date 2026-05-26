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
  group('Mahbousseh starting layout & player axis', () {
    test('white starts on point 24, black starts on point 12', () {
      final Board board = Board.startingPosition();
      expect(board.pointAt(24).topOwner, Player.white);
      expect(board.pointAt(24).topCount, 15);
      expect(board.pointAt(12).topOwner, Player.black);
      expect(board.pointAt(12).topCount, 15);
      for (int i = 1; i <= 24; i++) {
        if (i == 12 || i == 24) continue;
        expect(board.pointAt(i).isEmpty, isTrue, reason: 'point $i empty');
      }
    });

    test('Player.startingPoint and Player.isInHome reflect the new layout', () {
      expect(Player.white.startingPoint, 24);
      expect(Player.black.startingPoint, 12);
      // White home = 1..6 (right-hand quadrant on screen).
      for (int i = 1; i <= 24; i++) {
        expect(Player.white.isInHome(i), i >= 1 && i <= 6);
        // Black home = 7..12 (left-hand quadrant on screen).
        expect(Player.black.isInHome(i), i >= 7 && i <= 12);
      }
    });
  });

  group('Black wrap-around movement', () {
    test('black at 22 with pips=4 wraps to point 2', () {
      expect(RuleEngine.destinationFor(Player.black, 22, 4), 2);
    });

    test('black at 24 with pips=1 wraps to point 1', () {
      expect(RuleEngine.destinationFor(Player.black, 24, 1), 1);
    });

    test('black at 12 with pips=1 advances to point 13 (away journey)', () {
      expect(RuleEngine.destinationFor(Player.black, 12, 1), 13);
    });

    test('white at 1 with pips=1 returns off-board sentinel 0', () {
      expect(RuleEngine.destinationFor(Player.white, 1, 1), 0);
      expect(RuleEngine.isOffBoardDestination(Player.white, 0), isTrue);
    });

    test('distanceToBearOff handles full loop for black', () {
      // 12 pips to walk the right half + 1 pip to step past 12.
      expect(Board.distanceToBearOff(Player.black, 12), 1);
      expect(Board.distanceToBearOff(Player.black, 7), 6);
      expect(Board.distanceToBearOff(Player.black, 6), 7);
      expect(Board.distanceToBearOff(Player.black, 24), 13);
      expect(Board.distanceToBearOff(Player.black, 13), 24);
    });

    test('white distanceToBearOff is unchanged by the new layout', () {
      expect(Board.distanceToBearOff(Player.white, 1), 1);
      expect(Board.distanceToBearOff(Player.white, 6), 6);
      expect(Board.distanceToBearOff(Player.white, 24), 24);
    });
  });

  group('Second-half gating', () {
    test(
      'black cannot enter own home (point 7..12) until gate has flipped',
      () {
        // 14 black still on the starting point 12, 1 black already at
        // point 6 (right half) — gate has NOT flipped, so 6 -> 7 with
        // pips=1 must be illegal.
        final GameState state = stateWith(
          board: boardFrom(<int, Point>{
            12: ownStack(Player.black, 14),
            6: ownStack(Player.black, 1),
          }),
          toMove: Player.black,
          dice: const Dice(1, 2),
        );
        expect(state.board.canEnterHomeFor(Player.black), isFalse);
        expect(
          RuleEngine.canApply(state, const Move(from: 6, pips: 1)),
          isFalse,
          reason: 'gate is closed, cannot land on 7',
        );
      },
    );

    test(
      'once all 15 black checkers reach the right half, the gate latches',
      () {
        final Board board = boardFrom(<int, Point>{
          // 15 black checkers spread across right half (1..6 ∪ 19..24).
          1: ownStack(Player.black, 5),
          4: ownStack(Player.black, 5),
          24: ownStack(Player.black, 5),
        });
        expect(board.computeCanReturnHomeFor(Player.black), isTrue);
        // canEnterHomeFor auto-detects from board state.
        expect(board.canEnterHomeFor(Player.black), isTrue);
      },
    );

    test('after gate flips, black moving 6 → 7 is legal', () {
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{
          6: ownStack(Player.black, 14),
          5: ownStack(Player.black, 1),
        }, blackCanReturnHome: true),
        toMove: Player.black,
        dice: const Dice(1, 2),
      );
      expect(state.board.canEnterHomeFor(Player.black), isTrue);
      expect(RuleEngine.canApply(state, const Move(from: 6, pips: 1)), isTrue);
    });

    test('white cannot bear off until canEnterHome AND all 15 are in home', () {
      // 14 white in home, 1 still on point 24 — bear-off must fail.
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{
          24: ownStack(Player.white, 1),
          5: ownStack(Player.white, 14),
        }),
        toMove: Player.white,
        dice: const Dice(5, 4),
      );
      expect(state.board.allCheckersInHome(Player.white), isFalse);
      expect(
        RuleEngine.canApply(
          state,
          const Move(from: 5, pips: 5, bearsOff: true),
        ),
        isFalse,
      );
    });
  });

  group('One checker per turn rule', () {
    test('move generator prefers sequences with two distinct origins', () {
      // White has one checker at 24 (alone) and one further along
      // at 20. Dice 3,1.
      //
      // Possible 2-move sequences (length 2, distinct origins) include:
      //   * 24 (3) -> 21, 20 (1) -> 19
      //   * 24 (1) -> 23, 20 (3) -> 17
      // The chained sequence (24 -> 21 -> 20 collision is illegal anyway,
      // but 20 -> 19 -> 16 chains the same checker).
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{
          24: ownStack(Player.white, 1),
          20: ownStack(Player.white, 1),
        }),
        toMove: Player.white,
        dice: const Dice(3, 1),
      );
      final List<List<Move>> seqs = MoveGenerator.legalSequences(state);
      expect(seqs, isNotEmpty);
      for (final List<Move> seq in seqs) {
        // Each pair of sub-moves must have distinct `from` indices.
        final Set<int> origins = seq.map((Move m) => m.from).toSet();
        expect(
          origins.length,
          seq.length,
          reason: 'origins should be distinct, got $seq',
        );
      }
    });

    test('falls back to chaining when only one checker can move', () {
      // White has a single checker at 20 (one piece total). With dice
      // (3, 1) the only legal plays use this single checker twice —
      // and `oneCheckerPerTurn=true` must still allow the chain
      // because there is no alternative play.
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{
          20: ownStack(Player.white, 1),
        }, bornOffWhite: 14),
        toMove: Player.white,
        dice: const Dice(3, 1),
      );
      final List<List<Move>> seqs = MoveGenerator.legalSequences(state);
      expect(seqs, isNotEmpty);
      // Each maximal sequence chains the same checker because it is
      // the only one on the board.
      for (final List<Move> seq in seqs) {
        if (seq.length < 2) continue;
        final int firstDest = RuleEngine.destinationFor(
          Player.white,
          seq[0].from,
          seq[0].pips,
        );
        expect(seq[1].from, firstDest, reason: 'must chain the lone checker');
      }
    });

    test('rule disabled lets the bot chain freely (regression hook)', () {
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{24: ownStack(Player.white, 2)}),
        toMove: Player.white,
        dice: const Dice(3, 1),
        rules: const HouseRules(oneCheckerPerTurn: false),
      );
      final List<List<Move>> seqs = MoveGenerator.legalSequences(state);
      // With the rule disabled, chaining 24 -> 21 -> 20 should be
      // permitted alongside 24 -> 23 / 24 -> 21 sequences.
      final bool anyChained = seqs.any((List<Move> s) {
        final Move first = s[0];
        final Move second = s[1];
        return RuleEngine.destinationFor(
              Player.white,
              first.from,
              first.pips,
            ) ==
            second.from;
      });
      expect(anyChained, isTrue);
    });
  });

  group('Optional no-self-stacking rule', () {
    test('default rules allow stacking on own outside home', () {
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{
          24: ownStack(Player.white, 14),
          20: ownStack(Player.white, 1),
        }),
        toMove: Player.white,
        dice: const Dice(4, 1),
      );
      // 24 -> 20 stacks on own (outside white home). Default = allowed.
      expect(RuleEngine.canApply(state, const Move(from: 24, pips: 4)), isTrue);
    });

    test('forbidSelfStackingOutsideHome blocks stacking when opponent has '
        'a legal move', () {
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{
          24: ownStack(Player.white, 14),
          20: ownStack(Player.white, 1),
          12: ownStack(Player.black, 15),
        }),
        toMove: Player.white,
        dice: const Dice(4, 1),
        rules: const HouseRules(forbidSelfStackingOutsideHome: true),
      );
      expect(
        RuleEngine.canApply(state, const Move(from: 24, pips: 4)),
        isFalse,
      );
    });

    test('forbidSelfStackingOutsideHome still allows stacking inside home', () {
      // White already in home (1..6), gate effectively true via the
      // auto-detect. Stacking on a home point is allowed.
      final GameState state = stateWith(
        board: boardFrom(<int, Point>{
          5: ownStack(Player.white, 10),
          4: ownStack(Player.white, 5),
        }),
        toMove: Player.white,
        dice: const Dice(1, 2),
        rules: const HouseRules(forbidSelfStackingOutsideHome: true),
      );
      // 5 -> 4 stacks inside home (legal even with the flag on).
      expect(RuleEngine.canApply(state, const Move(from: 5, pips: 1)), isTrue);
    });
  });
}
