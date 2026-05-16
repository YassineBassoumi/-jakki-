import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/sound_manager.dart';
import '../../engine/game_state.dart';
import '../../engine/move.dart';
import '../../engine/player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_controller.dart';
import '../theme/jakki_theme.dart';
import '../widgets/board_view.dart';
import '../widgets/dice_view.dart';
import '../widgets/turn_banner.dart';

/// Main pass-and-play screen. Tap a checker, then tap a legal
/// destination (or the bear-off zone) to move.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int? _selectedFrom;

  @override
  Widget build(BuildContext context) {
    final GameState state = ref.watch(gameControllerProvider);
    final GameController controller = ref.read(gameControllerProvider.notifier);

    final List<Move> nextMoves = _selectedFrom == null
        ? <Move>[]
        : controller.legalNextMovesFrom(_selectedFrom!);
    final Set<int> legalTargets = <int>{
      for (final Move m in nextMoves)
        if (!m.bearsOff) m.from + state.toMove.direction * m.pips,
    };
    final bool canBearOff = nextMoves.any((Move m) => m.bearsOff);

    final bool dicePending = state.dice == null && !state.isGameOver;
    final bool turnExhausted =
        state.dice != null && state.remainingPips.isEmpty && !state.isGameOver;
    final bool stuck =
        state.dice != null &&
        state.remainingPips.isNotEmpty &&
        !controller.hasLegalMove;

    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l.newGame,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _selectedFrom = null;
                controller.newGame(firstToMove: state.toMove);
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: <Widget>[
              TurnBanner(
                toMove: state.toMove,
                whiteScore: state.whiteScore,
                blackScore: state.blackScore,
                winner: state.winner,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: BoardView(
                    board: state.board,
                    viewer: state.toMove,
                    selectedFrom: _selectedFrom,
                    legalTargets: legalTargets,
                    canBearOff: canBearOff,
                    onPointTapped: state.dice == null || state.isGameOver
                        ? null
                        : (int index) => _onPointTapped(index, nextMoves),
                    onBearOffTapped: canBearOff
                        ? () => _onBearOffTapped(nextMoves)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DiceRow(
                dice: state.dice == null
                    ? null
                    : (a: state.dice!.a, b: state.dice!.b),
                remainingPips: state.remainingPips,
              ),
              const SizedBox(height: 8),
              _bottomBar(
                state,
                controller,
                dicePending: dicePending,
                turnExhausted: turnExhausted,
                stuck: stuck,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _onPointTapped(int index, List<Move> currentNextMoves) {
    final GameController controller = ref.read(gameControllerProvider.notifier);
    final GameState state = ref.read(gameControllerProvider);

    // If a point is already selected and the tapped index is a legal
    // destination, apply that move.
    if (_selectedFrom != null) {
      for (final Move m in currentNextMoves) {
        if (m.bearsOff) continue;
        final int dest = m.from + state.toMove.direction * m.pips;
        if (dest == index) {
          controller.applyMove(m);
          soundManager.playMove();
          setState(() => _selectedFrom = null);
          return;
        }
      }
    }
    // Otherwise, select this point if it's a valid origin.
    final List<Move> originMoves = controller.legalNextMovesFrom(index);
    if (originMoves.isNotEmpty) {
      setState(() => _selectedFrom = index);
    } else {
      setState(() => _selectedFrom = null);
    }
  }

  void _onBearOffTapped(List<Move> currentNextMoves) {
    final GameController controller = ref.read(gameControllerProvider.notifier);
    for (final Move m in currentNextMoves) {
      if (m.bearsOff) {
        controller.applyMove(m);
        soundManager.playBearOff();
        final GameState s = ref.read(gameControllerProvider);
        if (s.isGameOver) {
          soundManager.playWin();
        }
        setState(() => _selectedFrom = null);
        return;
      }
    }
  }

  Widget _bottomBar(
    GameState state,
    GameController controller, {
    required bool dicePending,
    required bool turnExhausted,
    required bool stuck,
  }) {
    final AppLocalizations l = AppLocalizations.of(context);
    if (state.isGameOver) {
      return FilledButton.icon(
        icon: const Icon(Icons.refresh),
        label: Text(l.newGame),
        onPressed: () {
          setState(() {
            _selectedFrom = null;
            controller.newGame(
              firstToMove: state.winner == null
                  ? Player.white
                  : state.winner!.opposite,
            );
          });
        },
      );
    }
    if (dicePending) {
      return FilledButton.icon(
        icon: const Icon(Icons.casino),
        label: Text(l.rollDice),
        onPressed: () {
          controller.rollDice();
          soundManager.playRoll();
          setState(() => _selectedFrom = null);
        },
      );
    }
    if (turnExhausted || stuck) {
      final String label = stuck ? l.noLegalMoveEndTurn : l.endTurn;
      return FilledButton.icon(
        icon: const Icon(Icons.arrow_forward),
        label: Text(label),
        style: FilledButton.styleFrom(backgroundColor: JakkiTheme.olive),
        onPressed: () {
          controller.endTurn();
          setState(() => _selectedFrom = null);
        },
      );
    }
    return const SizedBox.shrink();
  }
}
