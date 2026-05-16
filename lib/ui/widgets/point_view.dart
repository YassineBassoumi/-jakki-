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
    final bool isOddColumn = index.isOdd;
    final Color spikeColor = isOddColumn
        ? JakkiTheme.terracotta.withValues(alpha: 0.55)
        : JakkiTheme.olive.withValues(alpha: 0.55);
    final Color? highlight = isSelected
        ? JakkiTheme.terracotta
        : isLegalTarget
        ? JakkiTheme.olive
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
                    color: spikeColor,
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

class _SpikePainter extends CustomPainter {
  _SpikePainter({
    required this.color,
    required this.highlight,
    required this.apexDown,
  });

  final Color color;
  final Color? highlight;
  final bool apexDown;

  @override
  void paint(Canvas canvas, Size size) {
    final Path triangle = Path();
    if (apexDown) {
      // Base at the top of the cell, apex pointing down toward the centre.
      triangle
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    } else {
      // Base at the bottom of the cell, apex pointing up toward the centre.
      triangle
        ..moveTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width / 2, 0)
        ..close();
    }

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(triangle, fill);

    final Paint outline = Paint()
      ..color = JakkiTheme.charcoal.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    canvas.drawPath(triangle, outline);

    if (highlight != null) {
      final Paint glow = Paint()
        ..color = highlight!.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawPath(triangle, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _SpikePainter old) =>
      old.color != color ||
      old.highlight != highlight ||
      old.apexDown != apexDown;
}
