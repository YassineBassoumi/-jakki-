import 'package:flutter/material.dart';

import '../../engine/board.dart';
import '../../engine/player.dart';
import '../theme/jakki_theme.dart';
import 'checker_pill.dart';
import 'point_view.dart';

/// The 24-point Jakki board, rendered from the moving player's
/// perspective with their home in the bottom-right quadrant.
///
/// Top row (left → right): 13, 14, 15, 16, 17, 18 | 19, 20, 21, 22, 23, 24
/// Bottom row (left → right): 12, 11, 10, 9, 8, 7 | 6, 5, 4, 3, 2, 1
///
/// Bear-off zones appear on the right side of each row (the moving
/// player's bottom row; the opponent's top row).
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.board,
    required this.viewer,
    this.selectedFrom,
    this.legalTargets = const <int>{},
    this.canBearOff = false,
    this.onPointTapped,
    this.onBearOffTapped,
  });

  final Board board;
  final Player viewer;

  /// Currently-selected point index, if any (used for highlight).
  final int? selectedFrom;

  /// Destination points that are currently legal landings; rendered
  /// with a legal-target highlight.
  final Set<int> legalTargets;

  final bool canBearOff;
  final ValueChanged<int>? onPointTapped;
  final VoidCallback? onBearOffTapped;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return AspectRatio(
          aspectRatio: 16 / 11,
          child: Container(
            decoration: BoxDecoration(
              color: JakkiTheme.parchment,
              border: Border.all(color: JakkiTheme.charcoal, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                Expanded(child: _half(context, isRightHalf: false)),
                _MiddleBar(),
                Expanded(child: _half(context, isRightHalf: true)),
                const SizedBox(width: 8),
                _bearOffColumn(context),
              ],
            ),
          ),
        );
      },
    );
  }

  /// One half of the board (6 columns × 2 rows).
  Widget _half(BuildContext context, {required bool isRightHalf}) {
    final List<int> topIndices;
    final List<int> bottomIndices;
    if (isRightHalf) {
      topIndices = <int>[19, 20, 21, 22, 23, 24];
      bottomIndices = <int>[6, 5, 4, 3, 2, 1];
    } else {
      topIndices = <int>[13, 14, 15, 16, 17, 18];
      bottomIndices = <int>[12, 11, 10, 9, 8, 7];
    }
    return Column(
      children: <Widget>[
        Expanded(child: _row(topIndices, isTopHalf: true)),
        const SizedBox(height: 4),
        Expanded(child: _row(bottomIndices, isTopHalf: false)),
      ],
    );
  }

  Widget _row(List<int> indices, {required bool isTopHalf}) {
    return Row(
      children: <Widget>[
        for (final int index in indices)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: PointView(
                index: index,
                point: board.pointAt(index),
                isTopHalf: isTopHalf,
                isSelected: selectedFrom == index,
                isLegalTarget: legalTargets.contains(index),
                onTap: onPointTapped == null
                    ? null
                    : () => onPointTapped!(index),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bearOffColumn(BuildContext context) {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: JakkiTheme.charcoal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: canBearOff ? JakkiTheme.olive : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: canBearOff ? onBearOffTapped : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _bearOffSide(
              player: viewer.opposite,
              count: board.bornOffFor(viewer.opposite),
            ),
            _bearOffSide(player: viewer, count: board.bornOffFor(viewer)),
          ],
        ),
      ),
    );
  }

  Widget _bearOffSide({required Player player, required int count}) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CheckerPill(owner: player, diameter: 18),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _MiddleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: JakkiTheme.charcoal,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
