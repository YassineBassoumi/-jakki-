import 'dart:math';

import '../engine/dice.dart';
import '../engine/game_state.dart';
import '../engine/move.dart';
import '../engine/move_generator.dart';
import '../engine/player.dart';
import '../engine/rule_engine.dart';
import 'evaluator.dart';

/// A 1-ply heuristic bot for Jakki.
///
/// "1-ply" here means: enumerate every legal turn sequence,
/// simulate the board after each sequence, score the resulting
/// position with [Evaluator], and pick the highest-scoring sequence.
///
/// Optionally averages over the opponent's next roll using a
/// shallow expectimax pass (`expectimax: true`) — the bot then
/// considers the worst-case opponent response weighted by roll
/// probability. This is much slower but plays measurably stronger.
///
/// The bot is deterministic given the same RNG seed; ties are
/// broken at random (so it doesn't always pick the same sequence
/// when multiple are equally rated).
class OnePlyBot {
  OnePlyBot({Random? rng, this.expectimax = false}) : _rng = rng ?? Random();

  final Random _rng;

  /// When true, runs a depth-1 expectimax search: for each candidate
  /// sequence, average the opponent's best-reply score over the 21
  /// possible (a,b) dice pairs (doubles + non-doubles), then choose
  /// the sequence that maximises `eval(self) - eval(opponent)`.
  final bool expectimax;

  /// Pick the best legal turn sequence for the player to move.
  ///
  /// Returns an empty list when there is no legal move at all
  /// (forced pass) or when the game is over.
  List<Move> chooseTurn(GameState state) {
    if (state.isGameOver) return const <Move>[];
    final List<List<Move>> sequences = MoveGenerator.legalSequences(state);
    if (sequences.isEmpty) return const <Move>[];

    final Player me = state.toMove;
    final List<MapEntry<int, double>> scored = <MapEntry<int, double>>[];

    for (int i = 0; i < sequences.length; i++) {
      final GameState after = RuleEngine.applyMoves(state, sequences[i]);
      double score;
      if (expectimax && !after.isGameOver) {
        // The opponent rolls next, so simulate ending our turn first
        // (clears dice + flips toMove) before sampling their rolls.
        final GameState opponentTurn = RuleEngine.endTurn(after);
        score = _expectimax(opponentTurn, me);
      } else {
        score = Evaluator.evaluate(after, perspective: me);
      }
      scored.add(MapEntry<int, double>(i, score));
    }

    scored.sort(
      (MapEntry<int, double> a, MapEntry<int, double> b) =>
          b.value.compareTo(a.value),
    );
    // Choose randomly among sequences within EPS of the best score.
    const double eps = 1e-6;
    final double best = scored.first.value;
    final List<int> tied = <int>[
      for (final MapEntry<int, double> e in scored)
        if ((e.value - best).abs() <= eps) e.key,
    ];
    return sequences[tied[_rng.nextInt(tied.length)]];
  }

  /// Average value of `state` (which is the opponent's turn now)
  /// over all 21 distinct dice rolls, from `me`'s perspective.
  double _expectimax(GameState state, Player me) {
    // Iterate over the 21 ordered-without-repetition pairs:
    //   doubles (6 pairs, prob 1/36 each)
    //   non-doubles (15 pairs, prob 2/36 each)
    double sum = 0;
    for (int a = 1; a <= 6; a++) {
      for (int b = a; b <= 6; b++) {
        final double prob = a == b ? 1 / 36 : 2 / 36;
        final GameState rolled = RuleEngine.rollDice(state, Dice(a, b));
        final List<List<Move>> oppSequences = MoveGenerator.legalSequences(
          rolled,
        );
        double bestForOpp;
        if (oppSequences.isEmpty) {
          // Opponent must pass — evaluate the state as-is from
          // our perspective.
          bestForOpp = Evaluator.evaluate(rolled, perspective: me);
        } else {
          bestForOpp = -double.infinity;
          for (final List<Move> oppSeq in oppSequences) {
            final GameState oppAfter = RuleEngine.applyMoves(rolled, oppSeq);
            final double v = -Evaluator.evaluate(
              oppAfter,
              perspective: me.opposite,
            );
            if (v > bestForOpp) bestForOpp = v;
          }
        }
        sum += prob * bestForOpp;
      }
    }
    return sum;
  }
}
