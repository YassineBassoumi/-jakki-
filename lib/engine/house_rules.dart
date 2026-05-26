/// Configurable rule flags. See `docs/RULES.md` §9 for the rationale
/// behind each flag and its default. Defaults match the most common
/// Tunisian Mahbousseh ruleset.
class HouseRules {
  const HouseRules({
    this.doublesPlayedFourTimes = true,
    this.mustPlayBothDice = true,
    this.mustPlayLargerDieWhenOnlyOne = true,
    this.enableBackgammonScoring = false,
    this.enableDoublingCube = false,
    this.canBearOffWhilePinning = false,
    this.oneCheckerPerTurn = true,
    this.forbidSelfStackingOutsideHome = false,
  });

  /// If true, a roll of doubles is played four times (the standard
  /// Mahbousseh rule).
  final bool doublesPlayedFourTimes;

  /// If true, the player must play both dice if any legal sequence
  /// exists.
  final bool mustPlayBothDice;

  /// If only one of the two dice can be played, the larger one must
  /// be chosen when both are individually playable but cannot be
  /// played together.
  final bool mustPlayLargerDieWhenOnlyOne;

  /// If true, awards 3 points for a backgammon (opponent still has a
  /// checker in our home board or in a pinned state).
  final bool enableBackgammonScoring;

  /// If true, expose the optional doubling cube. Casual Tunisian
  /// play omits it.
  final bool enableDoublingCube;

  /// If true, a checker that is currently pinning an opponent checker
  /// may be borne off (freeing the opponent in the process). The
  /// canonical Mahbousseh rule forbids this; defaults to false.
  final bool canBearOffWhilePinning;

  /// If true (default), the two dice of a turn must move two
  /// different checkers — i.e. the second sub-move cannot start
  /// from the destination of the first. For doubles, no sub-move
  /// may start from a destination of any prior sub-move.
  ///
  /// The rule falls back automatically: if no legal play exists
  /// that respects it, the player may chain sub-moves on the same
  /// checker. See `docs/RULES.md` §3.
  final bool oneCheckerPerTurn;

  /// If true, a checker may not land on a point already occupied by
  /// one or more of the moving player's own checkers when that
  /// destination is OUTSIDE the player's home board, unless the
  /// opponent currently has no legal single-die move ("opponent
  /// locked" exception). Inside the home board, stacking is always
  /// allowed (the player must collect all 15 checkers into 6 home
  /// points before bearing off).
  ///
  /// Defaults to false: most casual Tunisian Mahbousseh tables
  /// allow free stacking outside home as long as you do not pin
  /// your own checker.
  final bool forbidSelfStackingOutsideHome;

  static const HouseRules standard = HouseRules();

  HouseRules copyWith({
    bool? doublesPlayedFourTimes,
    bool? mustPlayBothDice,
    bool? mustPlayLargerDieWhenOnlyOne,
    bool? enableBackgammonScoring,
    bool? enableDoublingCube,
    bool? canBearOffWhilePinning,
    bool? oneCheckerPerTurn,
    bool? forbidSelfStackingOutsideHome,
  }) {
    return HouseRules(
      doublesPlayedFourTimes:
          doublesPlayedFourTimes ?? this.doublesPlayedFourTimes,
      mustPlayBothDice: mustPlayBothDice ?? this.mustPlayBothDice,
      mustPlayLargerDieWhenOnlyOne:
          mustPlayLargerDieWhenOnlyOne ?? this.mustPlayLargerDieWhenOnlyOne,
      enableBackgammonScoring:
          enableBackgammonScoring ?? this.enableBackgammonScoring,
      enableDoublingCube: enableDoublingCube ?? this.enableDoublingCube,
      canBearOffWhilePinning:
          canBearOffWhilePinning ?? this.canBearOffWhilePinning,
      oneCheckerPerTurn: oneCheckerPerTurn ?? this.oneCheckerPerTurn,
      forbidSelfStackingOutsideHome:
          forbidSelfStackingOutsideHome ?? this.forbidSelfStackingOutsideHome,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'doublesPlayedFourTimes': doublesPlayedFourTimes,
    'mustPlayBothDice': mustPlayBothDice,
    'mustPlayLargerDieWhenOnlyOne': mustPlayLargerDieWhenOnlyOne,
    'enableBackgammonScoring': enableBackgammonScoring,
    'enableDoublingCube': enableDoublingCube,
    'canBearOffWhilePinning': canBearOffWhilePinning,
    'oneCheckerPerTurn': oneCheckerPerTurn,
    'forbidSelfStackingOutsideHome': forbidSelfStackingOutsideHome,
  };

  factory HouseRules.fromJson(Map<String, Object?> json) {
    bool readBool(String key, bool fallback) {
      final Object? value = json[key];
      return value is bool ? value : fallback;
    }

    return HouseRules(
      doublesPlayedFourTimes: readBool('doublesPlayedFourTimes', true),
      mustPlayBothDice: readBool('mustPlayBothDice', true),
      mustPlayLargerDieWhenOnlyOne: readBool(
        'mustPlayLargerDieWhenOnlyOne',
        true,
      ),
      enableBackgammonScoring: readBool('enableBackgammonScoring', false),
      enableDoublingCube: readBool('enableDoublingCube', false),
      canBearOffWhilePinning: readBool('canBearOffWhilePinning', false),
      oneCheckerPerTurn: readBool('oneCheckerPerTurn', true),
      forbidSelfStackingOutsideHome: readBool(
        'forbidSelfStackingOutsideHome',
        false,
      ),
    );
  }
}
