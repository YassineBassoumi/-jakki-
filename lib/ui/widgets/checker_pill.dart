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
    final Color color = owner == Player.white
        ? JakkiTheme.parchment
        : JakkiTheme.charcoal;
    final Color border = owner == Player.white
        ? JakkiTheme.charcoal
        : JakkiTheme.parchment;
    return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              radius: 0.9,
              colors: <Color>[
                color.withValues(alpha: faded ? 0.5 : 1.0),
                owner == Player.white
                    ? const Color(
                        0xFFD9CDAE,
                      ).withValues(alpha: faded ? 0.5 : 1.0)
                    : const Color(
                        0xFF1A1916,
                      ).withValues(alpha: faded ? 0.5 : 1.0),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: isPinned
              ? Center(
                  child: Icon(Icons.lock, size: diameter * 0.5, color: border),
                )
              : null,
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
