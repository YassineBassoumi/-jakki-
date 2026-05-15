import 'package:flutter/material.dart';

import '../../engine/point.dart';
import '../theme/jakki_theme.dart';
import 'checker_pill.dart';

/// A single board point. Renders a column of stacked checkers (or
/// shows an N-marker if more than [maxVisible] checkers are stacked)
/// plus a pinned-opponent indicator at the base.
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
  /// (checkers stack downward from the top edge). False for the
  /// lower half (checkers stack upward from the bottom edge).
  final bool isTopHalf;
  final bool isSelected;
  final bool isLegalTarget;
  final VoidCallback? onTap;

  static const int maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final bool isOddColumn = index.isOdd;
    final Color base = isOddColumn
        ? JakkiTheme.terracotta.withValues(alpha: 0.18)
        : JakkiTheme.olive.withValues(alpha: 0.18);
    final Color border = isSelected
        ? JakkiTheme.terracotta
        : isLegalTarget
        ? JakkiTheme.olive
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: base,
          border: Border.all(color: border, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: LayoutBuilder(
          builder: (BuildContext _, BoxConstraints constraints) {
            final double diameter = constraints.maxWidth.clamp(12, 26);
            return Column(
              mainAxisAlignment: isTopHalf
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _stack(diameter),
            );
          },
        ),
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
      // Top points: the visible base of the column is at the top of
      // the screen; the pinned checker sits beneath the stack
      // visually (= lower on screen, further down the column).
      children.addAll(topCheckers);
      if (point.topCount > maxVisible) children.add(overflowBadge);
      if (pinnedWidget != null) children.add(pinnedWidget);
    } else {
      // Bottom points: visible base of the column is at the bottom;
      // pinned checker sits underneath, so visually it is the
      // bottom-most checker (= higher on screen).
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
