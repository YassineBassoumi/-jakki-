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
          // Outer light-wood bezel that frames the felt cloth.
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  JakkiTheme.woodLight,
                  JakkiTheme.woodMid,
                  JakkiTheme.woodDark,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: CustomPaint(
              painter: const _WoodGrainPainter(),
              child: Padding(
                padding: const EdgeInsets.all(14),
                // Inner dark-green felt surface.
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      center: Alignment.center,
                      radius: 0.95,
                      colors: <Color>[
                        JakkiTheme.feltGreen,
                        JakkiTheme.feltGreenDeep,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: JakkiTheme.woodGrain, width: 1),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: const _FeltTexturePainter(),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: <Widget>[
                          // Black bears off into the left tray
                          // (black's home is points 7..12 on the
                          // bottom-left).
                          _bearOffColumn(context, player: Player.black),
                          const SizedBox(width: 6),
                          Expanded(child: _half(context, isRightHalf: false)),
                          const _MiddleBar(),
                          Expanded(child: _half(context, isRightHalf: true)),
                          const SizedBox(width: 6),
                          // White bears off into the right tray
                          // (white's home is points 1..6 on the
                          // bottom-right).
                          _bearOffColumn(context, player: Player.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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

  Widget _bearOffColumn(BuildContext context, {required Player player}) {
    // The tray on the viewer's bear-off side is interactive when the
    // viewer can bear off; the opposing tray is purely informational.
    final bool isMyTray = player == viewer;
    final bool active = canBearOff && isMyTray;
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: JakkiTheme.charcoal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? JakkiTheme.olive : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: active ? onBearOffTapped : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _bearOffSide(player: player, count: board.bornOffFor(player)),
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

/// Wooden centre column that mirrors the hinge of a folded backgammon
/// box. Two metal plates (top and bottom thirds) suggest the brass
/// hinges visible on a real Jakki board.
class _MiddleBar extends StatelessWidget {
  const _MiddleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            JakkiTheme.woodDark,
            JakkiTheme.woodMid,
            JakkiTheme.woodLight,
            JakkiTheme.woodMid,
            JakkiTheme.woodDark,
          ],
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: const CustomPaint(painter: _HingePlatesPainter()),
    );
  }
}

/// Paints subtle wood-grain stripes on the bezel rails.
class _WoodGrainPainter extends CustomPainter {
  const _WoodGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint grain = Paint()
      ..color = JakkiTheme.woodGrain.withValues(alpha: 0.18)
      ..strokeWidth = 0.6;
    const int lines = 7;
    for (int i = 0; i < lines; i++) {
      final double y = 2 + (i * 1.4);
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), grain);
      final double yb = size.height - 2 - (i * 1.4);
      canvas.drawLine(Offset(8, yb), Offset(size.width - 8, yb), grain);
      final double x = 2 + (i * 1.4);
      canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), grain);
      final double xr = size.width - 2 - (i * 1.4);
      canvas.drawLine(Offset(xr, 8), Offset(xr, size.height - 8), grain);
    }
  }

  @override
  bool shouldRepaint(covariant _WoodGrainPainter old) => false;
}

/// Subtle horizontal-thread noise on the felt surface.
class _FeltTexturePainter extends CustomPainter {
  const _FeltTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint thread = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 0.4;
    final int rows = (size.height / 3).floor();
    for (int i = 0; i < rows; i++) {
      final double y = i * 3.0 + ((i.isEven) ? 0 : 1.2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thread);
    }
  }

  @override
  bool shouldRepaint(covariant _FeltTexturePainter old) => false;
}

/// Two small brass hinge plates inside the middle bar.
class _HingePlatesPainter extends CustomPainter {
  const _HingePlatesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double plateW = w * 0.85;
    final double plateH = (h * 0.07).clamp(8.0, 18.0);
    final double leftX = (w - plateW) / 2;

    void drawPlate(double topY) {
      final Rect rect = Rect.fromLTWH(leftX, topY, plateW, plateH);
      final RRect rr = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      final Paint fill = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[JakkiTheme.hingeMetalLight, JakkiTheme.hingeMetal],
        ).createShader(rect);
      canvas.drawRRect(rr, fill);
      final Paint screw = Paint()..color = Colors.black.withValues(alpha: 0.55);
      final double r = (plateH * 0.18).clamp(1.0, 2.5);
      canvas.drawCircle(
        Offset(rect.left + plateW * 0.18, rect.center.dy),
        r,
        screw,
      );
      canvas.drawCircle(
        Offset(rect.right - plateW * 0.18, rect.center.dy),
        r,
        screw,
      );
    }

    drawPlate(h * 0.18);
    drawPlate(h * 0.75 - plateH);
  }

  @override
  bool shouldRepaint(covariant _HingePlatesPainter old) => false;
}
