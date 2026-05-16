import 'package:flutter/material.dart';

import '../../engine/player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/jakki_theme.dart';
import 'checker_pill.dart';

/// Top banner showing whose turn it is and the current match score.
class TurnBanner extends StatelessWidget {
  const TurnBanner({
    super.key,
    required this.toMove,
    required this.whiteScore,
    required this.blackScore,
    this.winner,
  });

  final Player toMove;
  final int whiteScore;
  final int blackScore;
  final Player? winner;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: JakkiTheme.parchment,
        border: Border.all(color: JakkiTheme.charcoal),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          _scoreChip(Player.white, whiteScore),
          const Spacer(),
          if (winner != null)
            Text(
              winner == Player.white ? l.whiteWins : l.blackWins,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: JakkiTheme.terracotta,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CheckerPill(owner: toMove, diameter: 20),
                const SizedBox(width: 8),
                Text(
                  toMove == Player.white ? l.whitesTurn : l.blacksTurn,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          const Spacer(),
          _scoreChip(Player.black, blackScore),
        ],
      ),
    );
  }

  Widget _scoreChip(Player player, int score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CheckerPill(owner: player, diameter: 18),
        const SizedBox(width: 6),
        Text(
          '$score',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
