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

  static const HouseRules standard = HouseRules();

  HouseRules copyWith({
    bool? doublesPlayedFourTimes,
    bool? mustPlayBothDice,
    bool? mustPlayLargerDieWhenOnlyOne,
    bool? enableBackgammonScoring,
    bool? enableDoublingCube,
    bool? canBearOffWhilePinning,
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
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'doublesPlayedFourTimes': doublesPlayedFourTimes,
    'mustPlayBothDice': mustPlayBothDice,
    'mustPlayLargerDieWhenOnlyOne': mustPlayLargerDieWhenOnlyOne,
    'enableBackgammonScoring': enableBackgammonScoring,
    'enableDoublingCube': enableDoublingCube,
    'canBearOffWhilePinning': canBearOffWhilePinning,
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
    );
  }
}
