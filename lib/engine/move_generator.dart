import 'board.dart';
import 'game_state.dart';
import 'move.dart';
import 'player.dart';
import 'point.dart';
import 'rule_engine.dart';

/// Computes the full set of legal turn sequences from a [GameState].
///
/// A "turn sequence" is a list of [Move] sub-moves to play in order,
/// using as many of [GameState.remainingPips] as the rules require
/// (must-play-both-dice, must-play-larger-die-when-only-one).
abstract class MoveGenerator {
  MoveGenerator._();

  /// All maximal legal sequences from `state`. Each sequence uses
  /// the same multiset of pips and is non-empty unless no legal
  /// sub-move exists at all (in which case the result is empty).
  ///
  /// Sequences are returned with no duplicates (canonical comparison
  /// on `(from, pips, bearsOff)` order). The list may be empty,
  /// meaning the player has no legal play and must pass.
  static List<List<Move>> legalSequences(GameState state) {
    if (state.isGameOver) return const <List<Move>>[];
    if (state.dice == null || state.remainingPips.isEmpty) {
      return const <List<Move>>[];
    }

    final List<List<Move>> raw = <List<Move>>[];
    final Set<String> seen = <String>{};

    void recurse(GameState current, List<Move> path) {
      bool extended = false;
      final List<Move> nextMoves = _singleMoves(current);
      for (final Move move in nextMoves) {
        extended = true;
        final GameState after = RuleEngine.applyMove(current, move);
        path.add(move);
        recurse(after, path);
        path.removeLast();
        if (after.isGameOver) break;
      }
      if (!extended && path.isNotEmpty) {
        final String key = path.map(_moveKey).join('|');
        if (seen.add(key)) {
          raw.add(List<Move>.unmodifiable(path));
        }
      }
    }

    recurse(state, <Move>[]);

    if (raw.isEmpty) return const <List<Move>>[];

    // Filter to maximal-length sequences. The "must play both dice"
    // rule means we must use as many pips as possible; for doubles
    // this is up to 4 sub-moves.
    int maxLen = 0;
    for (final List<Move> seq in raw) {
      if (seq.length > maxLen) maxLen = seq.length;
    }
    List<List<Move>> filtered = raw
        .where((List<Move> s) => s.length == maxLen)
        .toList();

    // If after that we still have one-move sequences (i.e. the
    // player could only play one die), the rule requires choosing
    // the larger die when both are individually playable.
    if (state.rules.mustPlayLargerDieWhenOnlyOne &&
        maxLen == 1 &&
        state.dice != null &&
        !state.dice!.isDoubles) {
      final int larger = state.dice!.a > state.dice!.b
          ? state.dice!.a
          : state.dice!.b;
      final List<List<Move>> withLarger = filtered
          .where((List<Move> s) => s.first.pips == larger)
          .toList();
      if (withLarger.isNotEmpty) {
        filtered = withLarger;
      }
    }

    return filtered;
  }

  /// All single sub-moves currently legal for the player to move
  /// (no consideration of how many pips remain after).
  static List<Move> _singleMoves(GameState state) {
    final List<Move> result = <Move>[];
    final Player player = state.toMove;
    final Set<int> uniquePips = state.remainingPips.toSet();

    for (int from = 1; from <= 24; from++) {
      final Point point = state.board.pointAt(from);
      if (point.topOwner != player || point.topCount == 0) continue;
      for (final int pips in uniquePips) {
        final Move attempt = Move(from: from, pips: pips);
        if (RuleEngine.canApply(state, attempt)) {
          result.add(attempt);
        }
        if (state.board.allCheckersInHome(player)) {
          final int distance = Board.distanceToBearOff(player, from);
          if (pips >= distance) {
            final Move bearOff = Move(from: from, pips: pips, bearsOff: true);
            if (RuleEngine.canApply(state, bearOff)) {
              result.add(bearOff);
            }
          }
        }
      }
    }
    return result;
  }

  static String _moveKey(Move m) =>
      '${m.from}:${m.pips}${m.bearsOff ? '!' : ''}';
}
