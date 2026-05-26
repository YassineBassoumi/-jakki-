/// The two players in a Jakki game.
///
/// Mahbousseh layout used by this engine ("white right / black left"):
///
/// * White starts on absolute point **24** (top-right of the board).
///   White's checkers travel **counter-clockwise** along the absolute
///   axis, i.e. `24 → 23 → … → 1`, and bear off below point 1.
///   White's home board is points **1–6** (bottom-right quadrant).
///
/// * Black starts on absolute point **12** (bottom-left of the board).
///   Black's checkers travel **clockwise**, i.e. `12 → 13 → … → 24 → 1
///   → 2 → … → 11`, wrapping around the 1↔24 corner, and bear off
///   when they would step past point 12 on the way back.
///   Black's home board is points **7–12** (bottom-left quadrant).
///
/// Both players therefore make a half-loop of 23 pips before bearing
/// off their first checker, keeping the game symmetric. See
/// `docs/RULES.md` §2 for the full coordinate convention.
enum Player {
  white,
  black;

  Player get opposite => this == Player.white ? Player.black : Player.white;

  /// The direction this player moves along the absolute 1..24 axis.
  /// -1 for white (24 → 1), +1 for black (12 → 13 → … with wrap).
  int get direction => this == Player.white ? -1 : 1;

  /// The starting point for all 15 checkers (absolute index).
  /// White starts on 24, black on 12.
  int get startingPoint => this == Player.white ? 24 : 12;

  /// True if `point` is in this player's home board (the last 6
  /// points before bearing off).
  ///
  /// White: 1..6 (bottom-right quadrant).
  /// Black: 7..12 (bottom-left quadrant, ending at the start point).
  bool isInHome(int point) {
    if (this == Player.white) return point >= 1 && point <= 6;
    return point >= 7 && point <= 12;
  }
}
