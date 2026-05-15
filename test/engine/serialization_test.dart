import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jakki/engine/board.dart';
import 'package:jakki/engine/dice.dart';
import 'package:jakki/engine/game_state.dart';
import 'package:jakki/engine/house_rules.dart';
import 'package:jakki/engine/move.dart';
import 'package:jakki/engine/move_generator.dart';
import 'package:jakki/engine/player.dart';
import 'package:jakki/engine/rule_engine.dart';

void main() {
  test('GameState round-trips through JSON', () {
    GameState state = GameState.newGame();
    state = RuleEngine.rollDice(state, const Dice(5, 3));
    final List<List<Move>> seqs = MoveGenerator.legalSequences(state);
    state = RuleEngine.applyMoves(state, seqs.first);

    final String encoded = jsonEncode(state.toJson());
    final GameState decoded = GameState.fromJson(
      (jsonDecode(encoded) as Map<String, Object?>),
    );
    expect(decoded.board, equals(state.board));
    expect(decoded.toMove, state.toMove);
    expect(decoded.dice, state.dice);
    expect(decoded.remainingPips, state.remainingPips);
    expect(decoded.rules.toJson(), state.rules.toJson());
    expect(decoded.winner, state.winner);
  });

  test('Dice equality is unordered', () {
    expect(const Dice(5, 3), const Dice(3, 5));
    expect(const Dice(5, 3).hashCode, const Dice(3, 5).hashCode);
  });

  test('Player.opposite is involutive', () {
    expect(Player.white.opposite, Player.black);
    expect(Player.black.opposite, Player.white);
    expect(Player.white.opposite.opposite, Player.white);
  });

  test('HouseRules JSON round-trip preserves all flags', () {
    const HouseRules rules = HouseRules(
      doublesPlayedFourTimes: false,
      mustPlayBothDice: false,
      mustPlayLargerDieWhenOnlyOne: false,
      enableBackgammonScoring: true,
      enableDoublingCube: true,
      canBearOffWhilePinning: true,
    );
    final HouseRules decoded = HouseRules.fromJson(rules.toJson());
    expect(decoded.toJson(), rules.toJson());
  });

  test('Board round-trips through JSON', () {
    final Board board = Board.startingPosition();
    final Board decoded = Board.fromJson(board.toJson());
    expect(decoded, equals(board));
  });
}
