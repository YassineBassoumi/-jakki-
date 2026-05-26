import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../engine/player.dart';
import '../theme/jakki_theme.dart';

/// A single checker rendered as a small disc with a 1-px border.
class CheckerPill extends StatelessWidget {
  const CheckerPill({
    super.key,
    required this.owner,
    required this.diameter,
    this.isPinned = false,
    this.faded = false,
  });

  final Player owner;
  final double diameter;
  final bool isPinned;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final bool isCream = owner == Player.white;
    final Color highlight = isCream
        ? JakkiTheme.woodCheckerCream
        : const Color(0xFF6A4628);
    final Color shadow = isCream
        ? JakkiTheme.woodCheckerCreamRim
        : JakkiTheme.woodCheckerDarkRim;
    final Color rim = isCream
        ? JakkiTheme.woodCheckerCreamRim
        : JakkiTheme.woodCheckerDarkRim;
    final Color pinIconColor = isCream
        ? JakkiTheme.woodCheckerDarkRim
        : JakkiTheme.woodCheckerCream;
    return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.45),
              radius: 0.95,
              colors: <Color>[
                highlight.withValues(alpha: faded ? 0.55 : 1.0),
                shadow.withValues(alpha: faded ? 0.55 : 1.0),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: rim, width: 1.2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _WoodRingPainter(rim: rim, isCream: isCream),
            child: isPinned
                ? Center(
                    child: Icon(
                      Icons.lock,
                      size: diameter * 0.5,
                      color: pinIconColor,
                    ),
                  )
                : null,
          ),
        )
        .animate()
        .fadeIn(duration: 180.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: 220.ms,
          curve: Curves.easeOutBack,
        );
  }
}

/// Paints a thin inner lathe ring on the wooden checker to suggest
/// the chamfered edge of a turned wood piece.
class _WoodRingPainter extends CustomPainter {
  _WoodRingPainter({required this.rim, required this.isCream});

  final Color rim;
  final bool isCream;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Offset centre = Offset(r, r);
    final Paint ring = Paint()
      ..color = rim.withValues(alpha: isCream ? 0.55 : 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(centre, r * 0.78, ring);
  }

  @override
  bool shouldRepaint(covariant _WoodRingPainter old) =>
      old.rim != rim || old.isCream != isCream;
}
