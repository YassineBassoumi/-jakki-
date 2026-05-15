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
  }) : assert(points.length == 25, 'points must be length 25 (index 0 unused)'),
       _points = List<Point>.unmodifiable(points);

  final List<Point> _points;

  /// Number of borne-off checkers for each side.
  final int bornOffWhite;
  final int bornOffBlack;

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

  /// The point indices in [start, 24] (or [1, start]) holding any of
  /// `player`'s own checkers, **highest to lowest distance from
  /// bear-off**. Used to compute "highest occupied point" for
  /// over-rolling bear-off legality.
  int? highestOccupiedHomePoint(Player player) {
    // For white, home is 1..6, "highest" = furthest from bear-off = 6.
    // For black, home is 19..24, "highest" = 19.
    if (player == Player.white) {
      for (int i = 6; i >= 1; i--) {
        if (_points[i].topOwner == Player.white && _points[i].topCount > 0) {
          return i;
        }
      }
      return null;
    }
    for (int i = 19; i <= 24; i++) {
      if (_points[i].topOwner == Player.black && _points[i].topCount > 0) {
        return i;
      }
    }
    return null;
  }

  /// The distance-from-bear-off for a point in the moving player's
  /// home. White's point 6 has distance 6, point 1 has distance 1.
  /// Black's point 19 has distance 6, point 24 has distance 1.
  static int distanceToBearOff(Player player, int point) {
    if (player == Player.white) return point;
    return 25 - point;
  }

  Board copyWithPoint(int index, Point next) {
    assert(index >= 1 && index <= 24);
    final List<Point> next$ = List<Point>.from(_points);
    next$[index] = next;
    return Board(
      points: next$,
      bornOffWhite: bornOffWhite,
      bornOffBlack: bornOffBlack,
    );
  }

  Board copyWith({int? bornOffWhite, int? bornOffBlack}) {
    return Board(
      points: _points,
      bornOffWhite: bornOffWhite ?? this.bornOffWhite,
      bornOffBlack: bornOffBlack ?? this.bornOffBlack,
    );
  }

  /// Starting position for a new Mahbousseh game: all 15 of each
  /// player's checkers stacked on their own point 24 (white on
  /// absolute 24, black on absolute 1).
  static Board startingPosition() {
    final List<Point> points = List<Point>.filled(25, Point.empty);
    points[24] = const Point(
      topCount: 15,
      topOwner: Player.white,
      hasPinned: false,
    );
    points[1] = const Point(
      topCount: 15,
      topOwner: Player.black,
      hasPinned: false,
    );
    return Board(points: points);
  }

  @override
  bool operator ==(Object other) {
    if (other is! Board) return false;
    if (bornOffWhite != other.bornOffWhite ||
        bornOffBlack != other.bornOffBlack) {
      return false;
    }
    for (int i = 1; i <= 24; i++) {
      if (_points[i] != other._points[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int h = Object.hash(bornOffWhite, bornOffBlack);
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
    return Board(
      points: points,
      bornOffWhite: bornOffWhite is int ? bornOffWhite : 0,
      bornOffBlack: bornOffBlack is int ? bornOffBlack : 0,
    );
  }
}
