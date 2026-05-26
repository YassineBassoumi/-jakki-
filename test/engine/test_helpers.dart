import 'package:jakki/engine/board.dart';
import 'package:jakki/engine/dice.dart';
import 'package:jakki/engine/game_state.dart';
import 'package:jakki/engine/house_rules.dart';
import 'package:jakki/engine/player.dart';
import 'package:jakki/engine/point.dart';

/// Build a Board from a sparse map of `{absolute index: Point}`.
/// Indices not present are empty.
Board boardFrom(
  Map<int, Point> entries, {
  int bornOffWhite = 0,
  int bornOffBlack = 0,
  bool whiteCanReturnHome = false,
  bool blackCanReturnHome = false,
}) {
  final List<Point> points = List<Point>.filled(25, Point.empty);
  entries.forEach((int index, Point point) {
    points[index] = point;
  });
  return Board(
    points: points,
    bornOffWhite: bornOffWhite,
    bornOffBlack: bornOffBlack,
    whiteCanReturnHome: whiteCanReturnHome,
    blackCanReturnHome: blackCanReturnHome,
  );
}

/// Build a GameState with the given board and dice already rolled.
GameState stateWith({
  required Board board,
  required Player toMove,
  required Dice dice,
  HouseRules rules = HouseRules.standard,
}) {
  final List<int> pips = dice.pipsFor(
    doublesAreFour: rules.doublesPlayedFourTimes,
  );
  return GameState(
    board: board,
    toMove: toMove,
    rules: rules,
    dice: dice,
    remainingPips: pips,
  );
}

Point ownStack(Player owner, int count, {bool pinned = false}) =>
    Point(topCount: count, topOwner: owner, hasPinned: pinned);
