import '../engine/board.dart';
import '../engine/game_state.dart';
import '../engine/player.dart';
import '../engine/point.dart';

/// Heuristic state evaluator for the Jakki AI.
///
/// Returns a numeric score from `perspective`'s point of view. Higher
/// is better for `perspective`; negate when used as a min-player.
///
/// The heuristics reward:
///   * Pip progress (how close my checkers are to bearing off)
///   * Borne-off checkers (very large bonus per off-the-board checker)
///   * Pinning opponent checkers (the deeper into our territory, the
///     longer they stay trapped)
///   * Built points in our home board (anchors and prime structures)
///
/// And penalise:
///   * Own pinned checkers (locked, can't be moved)
///   * Blots (lone checkers that the opponent can pin next roll)
///
/// Coefficients were hand-tuned to play credibly against beginners
/// without needing search beyond 1 ply.
abstract class Evaluator {
  Evaluator._();

  // Weight constants (tuned by playtesting).
  static const double _bornOffBonus = 50;
  static const double _pipCost = -1;
  static const double _pinOpponentBonus = 18;
  static const double _ownPinnedPenalty = -22;
  static const double _blotPenalty = -3;
  static const double _anchorBonus = 4;
  static const double _homePointBonus = 6;
  static const double _winBonus = 1000;

  /// Score the state from `perspective`'s point of view.
  static double evaluate(GameState state, {required Player perspective}) {
    if (state.isGameOver) {
      return state.winner == perspective ? _winBonus : -_winBonus;
    }
    final Board board = state.board;
    final Player opp = perspective.opposite;

    final double own = _sideScore(board, perspective);
    final double other = _sideScore(board, opp);
    return own - other;
  }

  /// One side's standalone score. Caller subtracts the opponent's
  /// side-score to get the relative evaluation.
  static double _sideScore(Board board, Player player) {
    double score = 0;
    score += _bornOffBonus * board.bornOffFor(player);

    for (int i = 1; i <= 24; i++) {
      final Point p = board.pointAt(i);

      // Pip progress for top-of-stack checkers we own.
      if (p.topOwner == player && p.topCount > 0) {
        final int dist = Board.distanceToBearOff(player, i);
        score += _pipCost * dist * p.topCount;

        // Built point (anchor or prime piece).
        if (p.topCount >= 2) {
          score += _anchorBonus;
          if (player.isInHome(i)) {
            score += _homePointBonus;
          }
        } else {
          // Blot — exposed to being pinned next turn.
          if (!p.hasPinned) {
            score += _blotPenalty;
          }
        }

        // We're sitting on top of a pinned opponent checker.
        if (p.hasPinned) {
          // Deeper pins are more valuable to us — the opponent has
          // farther to walk back. distanceFromOppHome is large when
          // the pin is deep in our territory.
          final int distFromOppHome = Board.distanceToBearOff(
            player.opposite,
            i,
          );
          score += _pinOpponentBonus + 0.5 * distFromOppHome;
        }
      }

      // Pinned own checker — pip cost + flat penalty.
      if (p.pinnedOwner == player) {
        final int dist = Board.distanceToBearOff(player, i);
        score += _pipCost * dist;
        score += _ownPinnedPenalty;
      }
    }
    return score;
  }
}
