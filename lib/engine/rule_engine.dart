import 'board.dart';
import 'dice.dart';
import 'game_state.dart';
import 'move.dart';
import 'player.dart';
import 'point.dart';

/// Applies moves and turn transitions to a [GameState].
///
/// All methods are pure: they return a new state and never mutate
/// the input. Illegal moves throw [StateError]; use
/// [MoveGenerator.legalSequences] to filter to legal turns first.
abstract class RuleEngine {
  RuleEngine._();

  /// Set the dice for the current player's turn.
  static GameState rollDice(GameState state, Dice dice) {
    if (state.isGameOver) {
      throw StateError('Cannot roll dice: game is over.');
    }
    if (state.dice != null) {
      throw StateError('Dice already rolled; end turn before rolling again.');
    }
    final List<int> pips = dice.pipsFor(
      doublesAreFour: state.rules.doublesPlayedFourTimes,
    );
    return state.copyWith(dice: dice, remainingPips: pips);
  }

  /// End the current turn (must have used all required pips). Hands
  /// control to the opponent and clears the dice.
  static GameState endTurn(GameState state) {
    if (state.isGameOver) return state;
    return state.copyWith(
      toMove: state.toMove.opposite,
      clearDice: true,
      remainingPips: const <int>[],
    );
  }

  /// Compute the on-board destination point for `player` moving
  /// from `from` by `pips` along the absolute axis.
  ///
  /// White moves with direction -1 (24 → 1). A return value of `0`
  /// (or negative) means the checker has stepped past point 1 — i.e.
  /// an off-board move (bear-off if legal, otherwise illegal).
  ///
  /// Black moves with direction +1 and **wraps around the 24→1
  /// corner**: from 22 with 4 pips, the destination is 2. This
  /// method NEVER returns an off-board sentinel for black; bear-off
  /// is signalled exclusively via [Move.bearsOff] and validated by
  /// [_isLegalBearOff] using [Board.distanceToBearOff].
  static int destinationFor(Player player, int from, int pips) {
    if (player == Player.white) {
      return from - pips;
    }
    int dest = from + pips;
    if (dest > 24) dest -= 24;
    return dest;
  }

  /// True iff the destination [dest] returned by [destinationFor]
  /// represents an off-board (bear-off) position for `player`.
  ///
  /// For black this is always false — black bear-off is signalled
  /// by [Move.bearsOff] and not by an out-of-range destination.
  static bool isOffBoardDestination(Player player, int dest) {
    return player == Player.white && dest <= 0;
  }

  /// Whether `player` may move a checker from `from` using `pips`,
  /// assuming the pip is available in [GameState.remainingPips].
  static bool canApply(GameState state, Move move) {
    if (state.isGameOver) return false;
    if (state.dice == null) return false;
    if (!state.remainingPips.contains(move.pips)) return false;
    final Player player = state.toMove;
    final Point from = state.board.pointAt(move.from);
    if (from.topOwner != player || from.topCount == 0) return false;

    if (move.bearsOff) {
      return _isLegalBearOff(state, move);
    }

    final int dest = destinationFor(player, move.from, move.pips);
    if (isOffBoardDestination(player, dest)) return false;

    final Point destPoint = state.board.pointAt(dest);
    if (destPoint.isBlockedFor(player)) return false;

    // Mahbousseh second-half gating: a checker that is OUTSIDE your
    // home cannot LAND inside your home until you have completed the
    // half-lap that brings all 15 of your checkers into the opposite
    // half of the board. Pieces already in home (e.g. on the starting
    // stack for black at point 12) are free to LEAVE home to begin
    // the away journey.
    if (player.isInHome(dest) &&
        !player.isInHome(move.from) &&
        !state.board.canEnterHomeFor(player)) {
      return false;
    }

    // During the bear-off phase, a checker already in home may not
    // be played to a non-bear-off destination outside home. (For
    // black this is the only way the wrap-around could otherwise
    // produce a nonsense "leaves home, continues the loop" move.)
    if (state.board.canEnterHomeFor(player) &&
        player.isInHome(move.from) &&
        !player.isInHome(dest)) {
      return false;
    }

    // Mahbousseh no-self-stacking rule (house-rule flag): outside
    // the player's own home, a checker may not land on a point
    // already occupied by their own checkers, UNLESS the opponent
    // has no legal move at all (the "opponent locked" exception).
    // Inside the player's home, stacking is always allowed because
    // the player must collect all 15 checkers into 6 home points
    // before bearing off.
    if (state.rules.forbidSelfStackingOutsideHome) {
      final bool wouldStackOnOwn =
          destPoint.topOwner == player && destPoint.topCount > 0;
      if (wouldStackOnOwn && !player.isInHome(dest)) {
        if (_opponentHasAnyLegalMove(state)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Strict legality probe used by the no-self-stacking exception:
  /// returns true if the opponent of `state.toMove` has at least one
  /// legal sub-move with any single die value 1..6 from the current
  /// board. This intentionally does NOT recurse into the no-stack
  /// rule (it uses a flat, no-exception form of legality) to avoid
  /// infinite recursion, and ignores bear-off (a player who can only
  /// bear off is treated as already "escaped" in spirit — they are
  /// running out of pieces, not trapped).
  static bool _opponentHasAnyLegalMove(GameState state) {
    final Player opp = state.toMove.opposite;
    for (int from = 1; from <= 24; from++) {
      final Point p = state.board.pointAt(from);
      if (p.topOwner != opp || p.topCount == 0) continue;
      for (int pips = 1; pips <= 6; pips++) {
        final int dest = destinationFor(opp, from, pips);
        if (isOffBoardDestination(opp, dest)) continue;
        if (dest < 1 || dest > 24) continue;
        final Point destP = state.board.pointAt(dest);
        if (destP.isBlockedFor(opp)) continue;
        // Second-half gating (same rule as canApply).
        if (opp.isInHome(dest) &&
            !opp.isInHome(from) &&
            !state.board.canEnterHomeFor(opp)) {
          continue;
        }
        if (state.board.canEnterHomeFor(opp) &&
            opp.isInHome(from) &&
            !opp.isInHome(dest)) {
          continue;
        }
        // Strict no-self-stack for the probe (no nested exception).
        if (destP.topOwner == opp &&
            destP.topCount > 0 &&
            !opp.isInHome(dest)) {
          continue;
        }
        return true;
      }
    }
    return false;
  }

  static bool _isLegalBearOff(GameState state, Move move) {
    final Player player = state.toMove;
    // Must have completed the half-lap that fills the opposite half.
    if (!state.board.canEnterHomeFor(player)) return false;
    if (!state.board.allCheckersInHome(player)) return false;

    final Point from = state.board.pointAt(move.from);
    if (from.topOwner != player) return false;
    if (!player.isInHome(move.from)) return false;

    if (!state.rules.canBearOffWhilePinning && from.hasPinned) {
      // Cannot bear off a checker that is pinning an opponent.
      return false;
    }

    final int distance = Board.distanceToBearOff(player, move.from);
    if (move.pips == distance) return true;
    if (move.pips < distance) return false;
    // Over-roll: legal only if no own checker on a point further
    // from the bear-off than `move.from`.
    final int? highest = state.board.highestOccupiedHomePoint(player);
    if (highest == null) return false;
    return Board.distanceToBearOff(player, highest) <= distance;
  }

  /// Apply a single legal sub-move and return the resulting state.
  static GameState applyMove(GameState state, Move move) {
    if (!canApply(state, move)) {
      throw StateError('Illegal move: $move from ${state.toMove}.');
    }
    final Player player = state.toMove;

    // Remove the moving checker from its origin.
    final Point originBefore = state.board.pointAt(move.from);
    final Point? originAfter = originBefore.lifted(player);
    if (originAfter == null) {
      throw StateError('Inconsistent state lifting from ${move.from}.');
    }
    Board board = state.board.copyWithPoint(move.from, originAfter);

    if (move.bearsOff) {
      board = board.copyWith(
        bornOffWhite: player == Player.white
            ? board.bornOffWhite + 1
            : board.bornOffWhite,
        bornOffBlack: player == Player.black
            ? board.bornOffBlack + 1
            : board.bornOffBlack,
      );
    } else {
      final int dest = destinationFor(player, move.from, move.pips);
      final Point destBefore = board.pointAt(dest);
      final Point? destAfter = destBefore.landed(player);
      if (destAfter == null) {
        throw StateError('Inconsistent state landing on $dest.');
      }
      board = board.copyWithPoint(dest, destAfter);
    }

    // Re-evaluate the "can return home" gating flag for the moving
    // player. The flag latches: once flipped to true it stays true.
    if (!board.canReturnHomeFor(player)) {
      if (board.computeCanReturnHomeFor(player)) {
        board = board.copyWith(
          whiteCanReturnHome: player == Player.white
              ? true
              : board.whiteCanReturnHome,
          blackCanReturnHome: player == Player.black
              ? true
              : board.blackCanReturnHome,
        );
      }
    }

    // Consume the pip.
    final List<int> remaining = List<int>.from(state.remainingPips);
    remaining.remove(move.pips);

    GameState next = state.copyWith(
      board: board,
      remainingPips: List<int>.unmodifiable(remaining),
    );

    // Did this move complete the game?
    if (board.bornOffFor(player) == 15) {
      next = next.copyWith(winner: player);
    }

    return next;
  }

  /// Apply a full sequence of legal moves.
  static GameState applyMoves(GameState state, List<Move> moves) {
    GameState current = state;
    for (final Move move in moves) {
      current = applyMove(current, move);
      if (current.isGameOver) break;
    }
    return current;
  }

  /// Compute the score of a finished game.
  ///
  /// * 1 — single (loser has borne off at least one checker).
  /// * 2 — mars / gammon (loser has not borne off any checker).
  /// * 3 — backgammon (loser still has a checker in winner's home
  ///   or is pinned somewhere; only enabled when
  ///   `HouseRules.enableBackgammonScoring` is true).
  static int scoreFinishedGame(GameState state) {
    final Player? winner = state.winner;
    if (winner == null) {
      throw StateError('scoreFinishedGame called on unfinished state.');
    }
    final Player loser = winner.opposite;
    final int loserOff = state.board.bornOffFor(loser);

    if (loserOff > 0) return 1; // single

    if (state.rules.enableBackgammonScoring) {
      bool loserInWinnerHome = false;
      for (int i = 1; i <= 24; i++) {
        final Point p = state.board.pointAt(i);
        if (winner.isInHome(i) &&
            (p.topOwner == loser || p.pinnedOwner == loser)) {
          loserInWinnerHome = true;
          break;
        }
      }
      bool loserHasPinned = false;
      for (int i = 1; i <= 24; i++) {
        if (state.board.pointAt(i).pinnedOwner == loser) {
          loserHasPinned = true;
          break;
        }
      }
      if (loserInWinnerHome || loserHasPinned) return 3;
    }
    return 2; // mars / gammon
  }
}
