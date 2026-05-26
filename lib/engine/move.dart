/// A single sub-move within a turn: move one checker from absolute
/// point `from` using `pips` pips.
///
/// If `bearsOff` is true, the checker leaves the board (this only
/// applies inside the moving player's home board).
class Move {
  const Move({required this.from, required this.pips, this.bearsOff = false})
    : assert(from >= 1 && from <= 24, 'from must be 1..24'),
      assert(pips >= 1 && pips <= 6, 'pips must be 1..6');

  final int from;
  final int pips;
  final bool bearsOff;

  @override
  bool operator ==(Object other) =>
      other is Move &&
      from == other.from &&
      pips == other.pips &&
      bearsOff == other.bearsOff;

  @override
  int get hashCode => Object.hash(from, pips, bearsOff);

  @override
  String toString() => bearsOff
      ? 'Move($from off, pips=$pips)'
      : 'Move($from -> ${_to()}, pips=$pips)';

  int _to() => from; // placeholder; the absolute destination depends on player.

  Map<String, Object?> toJson() => <String, Object?>{
    'from': from,
    'pips': pips,
    'bearsOff': bearsOff,
  };

  factory Move.fromJson(Map<String, Object?> json) {
    final Object? from = json['from'];
    final Object? pips = json['pips'];
    final Object? bearsOff = json['bearsOff'];
    if (from is! int || pips is! int) {
      throw const FormatException(
        'Move.fromJson expects int "from" and "pips".',
      );
    }
    return Move(
      from: from,
      pips: pips,
      bearsOff: bearsOff is bool ? bearsOff : false,
    );
  }
}
