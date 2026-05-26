import 'player.dart';
import 'point.dart';

/// A 24-point board plus the two bear-off counts.
///
/// `points` is a List of length 25 with index 0 unused so that the
/// natural absolute coordinates 1..24 map to indices 1..24.
class Board {
  Board({
    required List<Point> points,
    this.bornOffWhite = 0,
    this.bornOffBlack = 0,
    this.whiteCanReturnHome = false,
    this.blackCanReturnHome = false,
  }) : assert(points.length == 25, 'points must be length 25 (index 0 unused)'),
       _points = List<Point>.unmodifiable(points);

  final List<Point> _points;

  /// Number of borne-off checkers for each side.
  final int bornOffWhite;
  final int bornOffBlack;

  /// True once all 15 of the player's checkers have simultaneously
  /// reached the half of the board opposite to their starting half.
  /// Until this flag is set, the player may not LAND a checker on
  /// any point inside their own home board (and therefore cannot
  /// bear off). Once set, the flag stays set for the rest of the
  /// game — see `docs/RULES.md` §7.
  ///
  /// * White starts in the right half (1–6 ∪ 19–24); the flag flips
  ///   to `true` when all 15 white checkers are in the left half
  ///   (7–18).
  /// * Black starts in the left half (7–18); the flag flips to
  ///   `true` when all 15 black checkers are in the right half
  ///   (1–6 ∪ 19–24).
  final bool whiteCanReturnHome;
  final bool blackCanReturnHome;

  bool canReturnHomeFor(Player player) =>
      player == Player.white ? whiteCanReturnHome : blackCanReturnHome;

  /// The point at absolute index 1..24.
  Point pointAt(int index) {
    assert(index >= 1 && index <= 24, 'index must be 1..24');
    return _points[index];
  }

  /// Immutable view of all points (length 25; index 0 is sentinel
  /// `Point.empty`).
  List<Point> get points => _points;

  int bornOffFor(Player player) =>
      player == Player.white ? bornOffWhite : bornOffBlack;

  /// Set the bear-off counts (and optionally the gating flags). Used
  /// by [RuleEngine] when applying moves.
  Board withBornOff({
    int? bornOffWhite,
    int? bornOffBlack,
    bool? whiteCanReturnHome,
    bool? blackCanReturnHome,
  }) {
    return Board(
      points: _points,
      bornOffWhite: bornOffWhite ?? this.bornOffWhite,
      bornOffBlack: bornOffBlack ?? this.bornOffBlack,
      whiteCanReturnHome: whiteCanReturnHome ?? this.whiteCanReturnHome,
      blackCanReturnHome: blackCanReturnHome ?? this.blackCanReturnHome,
    );
  }

  /// All 15 checkers (own + pinned opponent) belonging to `player`,
  /// summed across the 24 points (does NOT count borne-off checkers).
  int checkersOnBoard(Player player) {
    int total = 0;
    for (int i = 1; i <= 24; i++) {
      final Point p = _points[i];
      if (p.topOwner == player) total += p.topCount;
      if (p.pinnedOwner == player) total += 1;
    }
    return total;
  }

  /// True if all 15 of `player`'s checkers are in their home board
  /// (a precondition for bearing off). Pinned checkers in their home
  /// also count (they cannot move but they are in-home for the
  /// purpose of this check).
  bool allCheckersInHome(Player player) {
    int inHome = 0;
    for (int i = 1; i <= 24; i++) {
      if (!player.isInHome(i)) {
        final Point p = _points[i];
        if (p.topOwner == player && p.topCount > 0) return false;
        if (p.pinnedOwner == player) return false;
      } else {
        final Point p = _points[i];
        if (p.topOwner == player) inHome += p.topCount;
        if (p.pinnedOwner == player) inHome += 1;
      }
    }
    return inHome + bornOffFor(player) == 15;
  }

  /// The point indices in the player's home board holding any of
  /// `player`'s own checkers, **highest to lowest distance from
  /// bear-off**. Used to compute "highest occupied point" for
  /// over-rolling bear-off legality.
  int? highestOccupiedHomePoint(Player player) {
    // For white, home is 1..6, "highest" = furthest from bear-off = 6.
    // For black, home is 7..12, "highest" = furthest from bear-off = 7.
    if (player == Player.white) {
      for (int i = 6; i >= 1; i--) {
        if (_points[i].topOwner == Player.white && _points[i].topCount > 0) {
          return i;
        }
      }
      return null;
    }
    for (int i = 7; i <= 12; i++) {
      if (_points[i].topOwner == Player.black && _points[i].topCount > 0) {
        return i;
      }
    }
    return null;
  }

  /// The distance-from-bear-off for any point on the board (1..24).
  /// Inside the player's home this matches the minimum pips needed
  /// to bear off that checker; outside the home it is the minimum
  /// pips needed to walk the rest of the half-loop and bear off.
  ///
  /// White (moves -1, no wrap): distance == point.
  /// Black (moves +1 with wrap at 24→1, home is 7..12):
  ///   * points 1..12 → 13 - point (1..12 pips).
  ///   * points 13..24 → 37 - point (24..13 pips).
  static int distanceToBearOff(Player player, int point) {
    if (player == Player.white) return point;
    if (point <= 12) return 13 - point;
    return 37 - point;
  }

  Board copyWithPoint(int index, Point next) {
    assert(index >= 1 && index <= 24);
    final List<Point> next$ = List<Point>.from(_points);
    next$[index] = next;
    return Board(
      points: next$,
      bornOffWhite: bornOffWhite,
      bornOffBlack: bornOffBlack,
      whiteCanReturnHome: whiteCanReturnHome,
      blackCanReturnHome: blackCanReturnHome,
    );
  }

  Board copyWith({
    int? bornOffWhite,
    int? bornOffBlack,
    bool? whiteCanReturnHome,
    bool? blackCanReturnHome,
  }) {
    return Board(
      points: _points,
      bornOffWhite: bornOffWhite ?? this.bornOffWhite,
      bornOffBlack: bornOffBlack ?? this.bornOffBlack,
      whiteCanReturnHome: whiteCanReturnHome ?? this.whiteCanReturnHome,
      blackCanReturnHome: blackCanReturnHome ?? this.blackCanReturnHome,
    );
  }

  /// Starting position for a new Mahbousseh game: all 15 of each
  /// player's checkers stacked on their starting point. White starts
  /// on absolute point 24 (top-right), black on absolute point 12
  /// (bottom-left).
  static Board startingPosition() {
    final List<Point> points = List<Point>.filled(25, Point.empty);
    points[24] = const Point(
      topCount: 15,
      topOwner: Player.white,
      hasPinned: false,
    );
    points[12] = const Point(
      topCount: 15,
      topOwner: Player.black,
      hasPinned: false,
    );
    return Board(points: points);
  }

  /// True if `player` is currently allowed to land a checker inside
  /// their own home board. False at game start (the player has not
  /// yet completed the half-lap that fills the opposite half of the
  /// board).
  ///
  /// This is independent of [allCheckersInHome], which gates bearing
  /// off proper; this method gates **entering** the home points in
  /// the first place.
  ///
  /// The latched [whiteCanReturnHome] / [blackCanReturnHome] flags
  /// are the authoritative answer during regular play, but we also
  /// auto-detect the post-lap state from the board so that boards
  /// constructed directly in tests — with pieces already at
  /// home-minus-start positions — behave correctly without having
  /// to wire the flag through every helper.
  bool canEnterHomeFor(Player player) {
    if (canReturnHomeFor(player)) return true;
    // The "all 15 in opposite half" condition would have flipped the
    // latched flag in regular play; recompute it here for test boards
    // constructed directly.
    if (computeCanReturnHomeFor(player)) return true;
    if (bornOffFor(player) > 0) return true;
    for (int i = 1; i <= 24; i++) {
      if (!player.isInHome(i)) continue;
      if (i == player.startingPoint) continue;
      final Point p = _points[i];
      if (p.topOwner == player && p.topCount > 0) return true;
      if (p.pinnedOwner == player) return true;
    }
    return false;
  }

  /// Compute the "can return home" flag for `player` based on the
  /// current arrangement. Returns true once all 15 of the player's
  /// checkers are simultaneously in the half of the board opposite
  /// to their starting half.
  bool computeCanReturnHomeFor(Player player) {
    int count = 0;
    for (int i = 1; i <= 24; i++) {
      final bool inOppositeHalf = _isInOppositeStartingHalf(player, i);
      if (!inOppositeHalf) continue;
      final Point p = _points[i];
      if (p.topOwner == player) count += p.topCount;
      if (p.pinnedOwner == player) count += 1;
    }
    // Already borne-off checkers count toward the threshold too: once
    // a piece has been borne off it has definitively cleared the
    // half-lap, so it should not block the flag from flipping.
    count += bornOffFor(player);
    return count >= 15;
  }

  /// True iff `index` is in the half of the board opposite to
  /// `player`'s starting half.
  static bool _isInOppositeStartingHalf(Player player, int index) {
    // White starts in the right half (1–6 ∪ 19–24); its opposite is
    // the left half (7–18).
    // Black starts in the left half (7–18); its opposite is the
    // right half (1–6 ∪ 19–24).
    final bool inRightHalf =
        (index >= 1 && index <= 6) || (index >= 19 && index <= 24);
    return player == Player.white ? !inRightHalf : inRightHalf;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Board) return false;
    if (bornOffWhite != other.bornOffWhite ||
        bornOffBlack != other.bornOffBlack ||
        whiteCanReturnHome != other.whiteCanReturnHome ||
        blackCanReturnHome != other.blackCanReturnHome) {
      return false;
    }
    for (int i = 1; i <= 24; i++) {
      if (_points[i] != other._points[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int h = Object.hash(
      bornOffWhite,
      bornOffBlack,
      whiteCanReturnHome,
      blackCanReturnHome,
    );
    for (int i = 1; i <= 24; i++) {
      h = Object.hash(h, _points[i]);
    }
    return h;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'points': <Map<String, Object?>>[
      for (int i = 1; i <= 24; i++) _points[i].toJson(),
    ],
    'bornOffWhite': bornOffWhite,
    'bornOffBlack': bornOffBlack,
    'whiteCanReturnHome': whiteCanReturnHome,
    'blackCanReturnHome': blackCanReturnHome,
  };

  factory Board.fromJson(Map<String, Object?> json) {
    final Object? rawPoints = json['points'];
    if (rawPoints is! List) {
      throw const FormatException('Board.fromJson expects "points" list.');
    }
    if (rawPoints.length != 24) {
      throw FormatException(
        'Board.fromJson expects 24 points, got ${rawPoints.length}.',
      );
    }
    final List<Point> points = List<Point>.filled(25, Point.empty);
    for (int i = 0; i < 24; i++) {
      final Object? raw = rawPoints[i];
      if (raw is! Map) {
        throw const FormatException('Each point entry must be an object.');
      }
      points[i + 1] = Point.fromJson(raw.cast<String, Object?>());
    }
    final Object? bornOffWhite = json['bornOffWhite'];
    final Object? bornOffBlack = json['bornOffBlack'];
    final Object? whiteCanReturnHome = json['whiteCanReturnHome'];
    final Object? blackCanReturnHome = json['blackCanReturnHome'];
    return Board(
      points: points,
      bornOffWhite: bornOffWhite is int ? bornOffWhite : 0,
      bornOffBlack: bornOffBlack is int ? bornOffBlack : 0,
      whiteCanReturnHome: whiteCanReturnHome is bool
          ? whiteCanReturnHome
          : false,
      blackCanReturnHome: blackCanReturnHome is bool
          ? blackCanReturnHome
          : false,
    );
  }
}
