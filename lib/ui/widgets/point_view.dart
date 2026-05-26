import 'package:flutter/material.dart';

import '../../engine/point.dart';
import '../theme/jakki_theme.dart';
import 'checker_pill.dart';

/// A single board point. Renders a triangular spike pointing toward
/// the centre of the board, then stacks the checkers on top of it.
///
/// `onTap` fires regardless of contents; selection / highlighting is
/// done via [isSelected] and [isLegalTarget].
class PointView extends StatelessWidget {
  const PointView({
    super.key,
    required this.index,
    required this.point,
    required this.isTopHalf,
    this.isSelected = false,
    this.isLegalTarget = false,
    this.onTap,
  });

  final int index;
  final Point point;

  /// True when this point is rendered in the upper half of the board
  /// (the triangle's apex points down toward the centre of the board).
  /// False for the lower half (apex points up toward the centre).
  final bool isTopHalf;
  final bool isSelected;
  final bool isLegalTarget;
  final VoidCallback? onTap;

  static const int maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    // Alternate the two engraved styles every column to match the
    // rhythm of a real Tunisian board (white-outline vs oxblood-outline).
    final bool isOxblood = index.isOdd;
    final Color outline = isOxblood
        ? JakkiTheme.motifOxblood
        : JakkiTheme.motifWhite;
    final Color? highlight = isSelected
        ? JakkiTheme.terracotta
        : isLegalTarget
        ? JakkiTheme.motifWhite
        : null;

    return InkWell(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (BuildContext _, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final double diameter = width.clamp(12, 26);
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _SpikePainter(
                    outline: outline,
                    highlight: highlight,
                    apexDown: isTopHalf,
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Column(
                    mainAxisAlignment: isTopHalf
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: _stack(diameter),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _stack(double diameter) {
    final List<Widget> children = <Widget>[];

    final int visible = point.topCount > maxVisible
        ? maxVisible
        : point.topCount;
    final Widget overflowBadge = point.topCount > maxVisible
        ? _overflowBadge(diameter)
        : const SizedBox.shrink();

    final List<Widget> topCheckers = <Widget>[
      for (int i = 0; i < visible; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: CheckerPill(owner: point.topOwner!, diameter: diameter),
        ),
    ];

    final Widget? pinnedWidget = point.hasPinned
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: CheckerPill(
              owner: point.pinnedOwner!,
              diameter: diameter,
              isPinned: true,
            ),
          )
        : null;

    if (isTopHalf) {
      children.addAll(topCheckers);
      if (point.topCount > maxVisible) children.add(overflowBadge);
      if (pinnedWidget != null) children.add(pinnedWidget);
    } else {
      if (pinnedWidget != null) children.add(pinnedWidget);
      if (point.topCount > maxVisible) children.add(overflowBadge);
      children.addAll(topCheckers);
    }

    return children;
  }

  Widget _overflowBadge(double diameter) {
    return Container(
      height: diameter * 0.55,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: JakkiTheme.charcoal,
        borderRadius: BorderRadius.circular(diameter),
      ),
      child: Text(
        '${point.topCount}',
        style: TextStyle(
          color: JakkiTheme.parchment,
          fontSize: diameter * 0.42,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Paints one spike (an engraved triangle on the dark-green felt) with
/// a thin outline and a vertical chain of decorative motifs running
/// down the central axis, in the style of a hand-painted Tunisian
/// Jakki board.
class _SpikePainter extends CustomPainter {
  _SpikePainter({
    required this.outline,
    required this.highlight,
    required this.apexDown,
  });

  /// Stroke colour used for the triangle outline and the motif lines.
  final Color outline;
  final Color? highlight;
  final bool apexDown;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Path triangle = Path();
    if (apexDown) {
      // Base at the top of the cell, apex pointing down toward the centre.
      triangle
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w / 2, h)
        ..close();
    } else {
      // Base at the bottom of the cell, apex pointing up toward the centre.
      triangle
        ..moveTo(0, h)
        ..lineTo(w, h)
        ..lineTo(w / 2, 0)
        ..close();
    }

    // A very subtle fill so the spike reads against the felt even
    // before the motifs are drawn.
    final Paint fill = Paint()
      ..color = outline.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawPath(triangle, fill);

    final Paint stroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(triangle, stroke);

    _drawMotifs(canvas, w, h);

    if (highlight != null) {
      final Paint glow = Paint()
        ..color = highlight!.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawPath(triangle, glow);
    }
  }

  /// Engraves a chain of small floral / leaf motifs along the central
  /// vertical axis of the spike. The motif near the *base* is fancier
  /// (a 3-petal fleur) and successive ones become smaller leaves /
  /// diamonds as the spike narrows toward the apex.
  void _drawMotifs(Canvas canvas, double w, double h) {
    final Paint stroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final Paint fill = Paint()
      ..color = outline
      ..style = PaintingStyle.fill;

    final double cx = w / 2;
    // Local coordinate: t goes 0 (base) → 1 (apex) regardless of
    // orientation, so the same drawing code works in both halves.
    double yAt(double t) => apexDown ? t * h : (1 - t) * h;

    // Triangle half-width at distance t from base.
    double halfAt(double t) => (1 - t) * (w / 2);

    // ---- Fleur near the base (largest motif) -----------------------
    // The wide end of the spike carries a bolder "fleur" motif similar
    // to the painted flower at the top of each spike on the reference
    // photo: a centre petal flanked by two larger side petals and a
    // small base bar.
    const double tFleur = 0.14;
    final double fy = yAt(tFleur);
    final double fHalf = halfAt(tFleur);
    final double petal = (fHalf * 0.72).clamp(3.0, 11.0);
    final Paint bolderStroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    // Centre petal (small oval pointing along the axis).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, fy),
        width: petal * 0.5,
        height: petal * 1.5,
      ),
      bolderStroke,
    );
    // Two larger side petals tilted outward.
    for (final double sign in <double>[-1, 1]) {
      canvas.save();
      canvas.translate(cx, fy);
      canvas.rotate(sign * 0.85);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -petal * 0.05),
          width: petal * 0.55,
          height: petal * 1.45,
        ),
        bolderStroke,
      );
      canvas.restore();
    }
    // Tiny base bar / calyx just below the fleur.
    final double stemY = yAt(0.03);
    canvas.drawLine(
      Offset(cx - petal * 0.55, stemY),
      Offset(cx + petal * 0.55, stemY),
      bolderStroke,
    );
    canvas.drawCircle(Offset(cx, fy), 0.9, fill);

    // ---- A chain of small leaf / diamond motifs down the axis ------
    const List<double> leafStops = <double>[0.32, 0.50, 0.66, 0.80];
    for (final double t in leafStops) {
      final double y = yAt(t);
      final double half = halfAt(t);
      if (half < 1.5) continue;
      final double s = (half * 0.55).clamp(2.0, 6.5);
      // Diamond / leaf shape.
      final Path leaf = Path()
        ..moveTo(cx, y - s * 0.8)
        ..lineTo(cx + s * 0.45, y)
        ..lineTo(cx, y + s * 0.8)
        ..lineTo(cx - s * 0.45, y)
        ..close();
      canvas.drawPath(leaf, stroke);
      // Tiny centre dot.
      canvas.drawCircle(Offset(cx, y), 0.6, fill);
    }

    // ---- Apex dot --------------------------------------------------
    canvas.drawCircle(Offset(cx, yAt(0.93)), 0.9, fill);
  }

  @override
  bool shouldRepaint(covariant _SpikePainter old) =>
      old.outline != outline ||
      old.highlight != highlight ||
      old.apexDown != apexDown;
}
