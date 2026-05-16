import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/jakki_theme.dart';

/// A square die rendered with pip-art (dot patterns) via a
/// [CustomPainter]. Standard western die layout:
///
/// ```
/// 1: ·         2: ·         3: ·         4: · ·       5: · ·       6: · ·
///    [c]            [tl]         [tl]         [tl br]      [tl br]      [tl ml]
///                    [br]         [c]                       [c]         [bl mr]
///                                 [br]         [tr bl]      [tr bl]      [br]
/// ```
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
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: JakkiTheme.charcoal, width: 1.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
      child: CustomPaint(
        painter: _PipPainter(
          value: value,
          pipColor: consumed
              ? JakkiTheme.charcoal.withValues(alpha: 0.35)
              : JakkiTheme.charcoal,
        ),
      ),
    );
  }
}

class _PipPainter extends CustomPainter {
  _PipPainter({required this.value, required this.pipColor});

  final int value;
  final Color pipColor;

  /// Standard die layout in unit coordinates (0..1).
  /// Each slot: (x, y) within the die face. The 9-grid uses positions
  /// at 0.25 / 0.50 / 0.75 of width and height.
  static const Offset _tl = Offset(0.25, 0.25);
  static const Offset _tr = Offset(0.75, 0.25);
  static const Offset _ml = Offset(0.25, 0.50);
  static const Offset _mr = Offset(0.75, 0.50);
  static const Offset _c = Offset(0.50, 0.50);
  static const Offset _bl = Offset(0.25, 0.75);
  static const Offset _br = Offset(0.75, 0.75);

  static const Map<int, List<Offset>> _layout = <int, List<Offset>>{
    1: <Offset>[_c],
    2: <Offset>[_tl, _br],
    3: <Offset>[_tl, _c, _br],
    4: <Offset>[_tl, _tr, _bl, _br],
    5: <Offset>[_tl, _tr, _c, _bl, _br],
    6: <Offset>[_tl, _tr, _ml, _mr, _bl, _br],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = pipColor
      ..style = PaintingStyle.fill;
    final double r = size.shortestSide * 0.09;
    final List<Offset> pips = _layout[value] ?? const <Offset>[];
    for (final Offset rel in pips) {
      canvas.drawCircle(
        Offset(rel.dx * size.width, rel.dy * size.height),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PipPainter old) =>
      old.value != value || old.pipColor != pipColor;
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
      return const SizedBox(height: 44);
    }
    final List<int> values = remainingPips.length > 2
        ? remainingPips
        : <int>[dice!.a, dice!.b];
    final List<bool> consumed = <bool>[
      for (final int v in values) !remainingPips.contains(v),
    ];
    final List<int> dynamicConsumed = List<int>.from(remainingPips);
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < values.length; i++) {
      final int v = values[i];
      final bool isConsumed = !dynamicConsumed.remove(v);
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: DieFace(value: v, consumed: isConsumed || consumed[i]),
        ),
      );
    }
    final Row row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    // Re-run the entrance animation whenever the underlying roll changes.
    final String rollKey = '${dice!.a}-${dice!.b}-${remainingPips.join(',')}';
    return row
        .animate(key: ValueKey<String>(rollKey))
        .fadeIn(duration: 250.ms)
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
          duration: 320.ms,
          curve: Curves.easeOutBack,
        );
  }
}
