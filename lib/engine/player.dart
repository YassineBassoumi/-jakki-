/// The two players in a Jakki game.
///
/// White starts on absolute point 24 and moves toward point 1, bearing
/// off below point 1. Black starts on absolute point 1 and moves toward
/// point 24, bearing off above point 24. (See `docs/RULES.md` §2.)
enum Player {
  white,
  black;

  Player get opposite => this == Player.white ? Player.black : Player.white;

  /// The direction this player moves along the absolute 1..24 axis.
  /// -1 for white (24 → 1), +1 for black (1 → 24).
  int get direction => this == Player.white ? -1 : 1;

  /// The starting point for all 15 checkers (absolute index).
  int get startingPoint => this == Player.white ? 24 : 1;

  /// True if `point` is in this player's home board (the last 6 points
  /// before bearing off).
  bool isInHome(int point) {
    if (this == Player.white) return point >= 1 && point <= 6;
    return point >= 19 && point <= 24;
  }
}
