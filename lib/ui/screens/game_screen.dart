import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/bot.dart';
import '../../audio/sound_manager.dart';
import '../../engine/game_state.dart';
import '../../engine/move.dart';
import '../../engine/player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/ai_provider.dart';
import '../../state/game_controller.dart';
import '../../state/game_mode_controller.dart';
import '../theme/jakki_theme.dart';
import '../widgets/board_view.dart';
import '../widgets/dice_view.dart';
import '../widgets/turn_banner.dart';

/// Main game screen.
///
/// In pass-and-play mode both players tap. In vs-computer mode the
/// human controls one colour (white by default) and the AI auto-
/// plays the opposite colour: it rolls, applies its best legal turn
/// sequence with a short delay between sub-moves, then ends its
/// turn.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int? _selectedFrom;
  bool _aiRunning = false;

  /// Pacing for the AI animation. Tuned to feel "thinking" without
  /// dragging out the turn — total ~1.5–2s for a normal roll.
  static const Duration _aiRollDelay = Duration(milliseconds: 700);
  static const Duration _aiBetweenMoves = Duration(milliseconds: 380);
  static const Duration _aiEndTurnDelay = Duration(milliseconds: 550);

  @override
  Widget build(BuildContext context) {
    final GameState state = ref.watch(gameControllerProvider);
    final GameController controller = ref.read(gameControllerProvider.notifier);
    final GameModeSettings mode = ref.watch(gameModeControllerProvider);
    final bool isAiTurn = mode.isAi(state.toMove) && !state.isGameOver;

    // Kick off the AI turn as soon as the build that introduced an
    // AI-to-move state has finished. The guard prevents re-entry
    // while an AI animation is already in flight.
    if (isAiTurn && !_aiRunning) {
      _aiRunning = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runAiTurn();
      });
    }

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
    final bool interactionLocked = isAiTurn;

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
                    onPointTapped:
                        state.dice == null ||
                            state.isGameOver ||
                            interactionLocked
                        ? null
                        : (int index) => _onPointTapped(index, nextMoves),
                    onBearOffTapped: canBearOff && !interactionLocked
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
                aiThinking: isAiTurn,
                l: l,
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

  Future<void> _runAiTurn() async {
    final GameController controller = ref.read(gameControllerProvider.notifier);
    final OnePlyBot bot = ref.read(aiBotProvider);

    try {
      // 1. Roll the dice for the AI.
      GameState state = ref.read(gameControllerProvider);
      if (state.dice == null && !state.isGameOver) {
        controller.rollDice();
        unawaited(soundManager.playRoll());
        await Future<void>.delayed(_aiRollDelay);
        if (!mounted) return;
      }

      // 2. Compute and play the chosen legal sequence one move at a time.
      state = ref.read(gameControllerProvider);
      if (!state.isGameOver && state.dice != null) {
        final List<Move> sequence = bot.chooseTurn(state);
        for (final Move move in sequence) {
          controller.applyMove(move);
          if (move.bearsOff) {
            unawaited(soundManager.playBearOff());
          } else {
            unawaited(soundManager.playMove());
          }
          final GameState afterMove = ref.read(gameControllerProvider);
          if (afterMove.isGameOver) {
            unawaited(soundManager.playWin());
            return;
          }
          await Future<void>.delayed(_aiBetweenMoves);
          if (!mounted) return;
        }
      }

      // 3. Settle, then end the AI's turn (unless the game just ended).
      await Future<void>.delayed(_aiEndTurnDelay);
      if (!mounted) return;
      final GameState finalState = ref.read(gameControllerProvider);
      if (!finalState.isGameOver) {
        controller.endTurn();
      }
    } finally {
      if (mounted) {
        setState(() {
          _aiRunning = false;
          _selectedFrom = null;
        });
      } else {
        _aiRunning = false;
      }
    }
  }

  Widget _bottomBar(
    GameState state,
    GameController controller, {
    required bool dicePending,
    required bool turnExhausted,
    required bool stuck,
    required bool aiThinking,
    required AppLocalizations l,
  }) {
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
    if (aiThinking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(l.computerThinking),
        ],
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
