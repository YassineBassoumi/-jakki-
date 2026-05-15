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

  /// Compute the destination point for `player` moving from `from`
  /// by `pips`. Returns 0 (white) or 25 (black) for off-the-board.
  static int destinationFor(Player player, int from, int pips) {
    return from + player.direction * pips;
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

    final int dest = destinationFor(player, move.from, move.pips);
    final bool onBoard = dest >= 1 && dest <= 24;

    if (move.bearsOff) {
      if (onBoard) return false; // bearsOff requires going off-board
      return _isLegalBearOff(state, move);
    }

    if (!onBoard) return false;
    final Point destPoint = state.board.pointAt(dest);
    if (destPoint.isBlockedFor(player)) return false;

    if (!state.rules.canBearOffWhilePinning && from.hasPinned) {
      // Moving the pinning checker is fine (it frees the opponent),
      // but bearing it off is not. Regular moves are allowed.
    }
    return true;
  }

  static bool _isLegalBearOff(GameState state, Move move) {
    final Player player = state.toMove;
    if (!state.board.allCheckersInHome(player)) return false;

    final Point from = state.board.pointAt(move.from);
    if (from.topOwner != player) return false;

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
