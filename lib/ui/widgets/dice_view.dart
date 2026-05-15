import 'package:flutter/material.dart';

import '../theme/jakki_theme.dart';

/// A simple square die rendered with the numeric value. Used as a
/// placeholder; real pip-art comes in Milestone 3.
class DieFace extends StatelessWidget {
  const DieFace({
    super.key,
    required this.value,
    this.size = 36,
    this.consumed = false,
  });

  final int value;
  final double size;
  final bool consumed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: consumed
            ? JakkiTheme.parchment.withValues(alpha: 0.5)
            : JakkiTheme.parchment,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: JakkiTheme.charcoal, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.bold,
          color: consumed
              ? JakkiTheme.charcoal.withValues(alpha: 0.4)
              : JakkiTheme.charcoal,
        ),
      ),
    );
  }
}

class DiceRow extends StatelessWidget {
  const DiceRow({super.key, required this.dice, required this.remainingPips});

  /// The pair of values rolled this turn. May be null before the
  /// roll.
  final ({int a, int b})? dice;

  /// The pips still left to play (may be empty when the turn is
  /// almost done).
  final List<int> remainingPips;

  @override
  Widget build(BuildContext context) {
    if (dice == null) {
      return const SizedBox(height: 36);
    }
    final List<int> values = remainingPips.length > 2
        ? remainingPips
        : <int>[dice!.a, dice!.b];
    final List<bool> consumed = <bool>[
      for (final int v in values) !remainingPips.contains(v),
    ];
    // Mark only as many "consumed" as needed (for doubles).
    final List<int> dynamicConsumed = List<int>.from(remainingPips);
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < values.length; i++) {
      final int v = values[i];
      final bool isConsumed = !dynamicConsumed.remove(v);
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DieFace(value: v, consumed: isConsumed || consumed[i]),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
