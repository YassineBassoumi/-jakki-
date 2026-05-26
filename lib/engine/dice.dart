/// An ordered pair of dice values. Equality is unordered so that
/// `Dice(5, 3) == Dice(3, 5)`.
class Dice {
  const Dice(this.a, this.b)
    : assert(a >= 1 && a <= 6, 'die a must be 1..6'),
      assert(b >= 1 && b <= 6, 'die b must be 1..6');

  final int a;
  final int b;

  bool get isDoubles => a == b;

  /// The pip values to be played this turn. Doubles are played four
  /// times when `HouseRules.doublesPlayedFourTimes` is enabled (the
  /// default). When disabled, doubles still produce two pips.
  List<int> pipsFor({bool doublesAreFour = true}) {
    if (isDoubles && doublesAreFour) {
      return <int>[a, a, a, a];
    }
    return <int>[a, b];
  }

  @override
  bool operator ==(Object other) {
    if (other is! Dice) return false;
    return (a == other.a && b == other.b) || (a == other.b && b == other.a);
  }

  @override
  int get hashCode {
    final int low = a <= b ? a : b;
    final int high = a <= b ? b : a;
    return Object.hash(low, high);
  }

  @override
  String toString() => 'Dice($a, $b)';

  Map<String, int> toJson() => <String, int>{'a': a, 'b': b};

  factory Dice.fromJson(Map<String, Object?> json) {
    final Object? rawA = json['a'];
    final Object? rawB = json['b'];
    if (rawA is! int || rawB is! int) {
      throw const FormatException('Dice.fromJson expects int "a" and "b".');
    }
    return Dice(rawA, rawB);
  }
}
