import 'player.dart';

/// The state of a single point on the board.
///
/// Mahbousseh stacks at most: one pinned opponent checker at the
/// bottom, then any number of own (`topOwner`) checkers on top.
/// `topCount == 0` indicates an empty point.
class Point {
  const Point({
    required this.topCount,
    required this.topOwner,
    required this.hasPinned,
  }) : assert(
         (topCount == 0 && topOwner == null && !hasPinned) ||
             (topCount >= 1 && topOwner != null),
         'invalid Point state',
       );

  /// Number of `topOwner` checkers stacked on top.
  final int topCount;

  /// Owner of the top stack; null only when the point is empty.
  final Player? topOwner;

  /// Whether there is exactly one opponent checker pinned at the
  /// bottom (under the [topOwner]'s stack).
  final bool hasPinned;

  static const Point empty = Point(
    topCount: 0,
    topOwner: null,
    hasPinned: false,
  );

  bool get isEmpty => topCount == 0;

  /// Owner of the pinned checker, if any.
  Player? get pinnedOwner =>
      hasPinned && topOwner != null ? topOwner!.opposite : null;

  /// Total checkers on this point (including the pinned one).
  int get totalCount => topCount + (hasPinned ? 1 : 0);

  /// True if `player` cannot land here: i.e. an opponent owns the
  /// top stack with 2+ checkers, or with 1+ checker pinning one of
  /// our own.
  bool isBlockedFor(Player player) {
    if (topOwner == null) return false;
    if (topOwner == player) return false;
    return topCount >= 2 || hasPinned;
  }

  /// True if landing here would pin a single opponent checker.
  bool wouldPin(Player player) =>
      topOwner != null && topOwner != player && topCount == 1 && !hasPinned;

  /// State after `player` lands one checker here. Returns null if the
  /// landing is illegal.
  Point? landed(Player player) {
    if (isEmpty) {
      return Point(topCount: 1, topOwner: player, hasPinned: false);
    }
    if (topOwner == player) {
      return Point(
        topCount: topCount + 1,
        topOwner: player,
        hasPinned: hasPinned,
      );
    }
    // Opponent on top.
    if (wouldPin(player)) {
      return Point(topCount: 1, topOwner: player, hasPinned: true);
    }
    return null;
  }

  /// State after `player` removes one of their top checkers from
  /// here. Returns null if `player` does not own the top stack.
  Point? lifted(Player player) {
    if (topOwner != player || topCount == 0) {
      return null;
    }
    final int nextTop = topCount - 1;
    if (nextTop > 0) {
      return Point(topCount: nextTop, topOwner: player, hasPinned: hasPinned);
    }
    if (hasPinned) {
      // Freeing the pinned opponent checker.
      return Point(topCount: 1, topOwner: player.opposite, hasPinned: false);
    }
    return Point.empty;
  }

  @override
  bool operator ==(Object other) =>
      other is Point &&
      topCount == other.topCount &&
      topOwner == other.topOwner &&
      hasPinned == other.hasPinned;

  @override
  int get hashCode => Object.hash(topCount, topOwner, hasPinned);

  @override
  String toString() {
    if (isEmpty) return 'Point.empty';
    final String pinSuffix = hasPinned ? ', pinned' : '';
    return 'Point($topCount $topOwner$pinSuffix)';
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'topCount': topCount,
    'topOwner': topOwner?.name,
    'hasPinned': hasPinned,
  };

  factory Point.fromJson(Map<String, Object?> json) {
    final Object? topCount = json['topCount'];
    final Object? topOwnerName = json['topOwner'];
    final Object? hasPinned = json['hasPinned'];
    if (topCount is! int) {
      throw const FormatException('Point.fromJson expects int "topCount".');
    }
    Player? topOwner;
    if (topOwnerName is String) {
      topOwner = Player.values.firstWhere(
        (Player p) => p.name == topOwnerName,
        orElse: () => throw FormatException('Unknown player "$topOwnerName".'),
      );
    }
    return Point(
      topCount: topCount,
      topOwner: topOwner,
      hasPinned: hasPinned is bool ? hasPinned : false,
    );
  }
}
