import 'package:flutter/material.dart';

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
        color: faded ? color.withValues(alpha: 0.6) : color,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isPinned
          ? Center(
              child: Icon(Icons.lock, size: diameter * 0.5, color: border),
            )
          : null,
    );
  }
}
