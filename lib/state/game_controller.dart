import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/dice.dart';
import '../engine/game_state.dart';
import '../engine/house_rules.dart';
import '../engine/move.dart';
import '../engine/move_generator.dart';
import '../engine/player.dart';
import '../engine/rule_engine.dart';

/// Riverpod-backed controller around an immutable [GameState].
class GameController extends Notifier<GameState> {
  GameController({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  @override
  GameState build() => GameState.newGame();

  /// Reset to a fresh starting position.
  void newGame({Player firstToMove = Player.white, HouseRules? rules}) {
    state = GameState.newGame(
      firstToMove: firstToMove,
      rules: rules ?? state.rules,
    );
  }

  /// Replace the current state outright (used by storage / save load).
  void load(GameState newState) {
    state = newState;
  }

  /// Roll the dice for the current player.
  Dice rollDice() {
    final Dice roll = Dice(_rng.nextInt(6) + 1, _rng.nextInt(6) + 1);
    state = RuleEngine.rollDice(state, roll);
    return roll;
  }

  /// Override the roll (for testing or replay).
  void setDice(Dice dice) {
    state = RuleEngine.rollDice(state, dice);
  }

  /// Apply a single legal sub-move.
  void applyMove(Move move) {
    state = RuleEngine.applyMove(state, move);
  }

  /// Apply a list of legal sub-moves.
  void applyMoves(List<Move> moves) {
    state = RuleEngine.applyMoves(state, moves);
  }

  /// Switch to the opposite player and clear the dice.
  void endTurn() {
    state = RuleEngine.endTurn(state);
  }

  /// All legal sequences from the current state.
  List<List<Move>> legalSequences() => MoveGenerator.legalSequences(state);

  /// All legal next sub-moves starting from `from`. Computed from
  /// the current state's full sequence list.
  List<Move> legalNextMovesFrom(int from) {
    final List<List<Move>> seqs = MoveGenerator.legalSequences(state);
    final Set<String> seen = <String>{};
    final List<Move> result = <Move>[];
    for (final List<Move> seq in seqs) {
      if (seq.isEmpty) continue;
      final Move first = seq.first;
      if (first.from != from) continue;
      final String key = '${first.from}:${first.pips}:${first.bearsOff}';
      if (seen.add(key)) {
        result.add(first);
      }
    }
    return result;
  }

  /// Whether the current player has any legal move at all.
  bool get hasLegalMove => MoveGenerator.legalSequences(state).isNotEmpty;
}

final NotifierProvider<GameController, GameState> gameControllerProvider =
    NotifierProvider<GameController, GameState>(GameController.new);
