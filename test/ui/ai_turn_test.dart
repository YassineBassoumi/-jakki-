// Regression coverage for the widget-side AI auto-play loop in
// vs-computer mode (M4). The pure-Dart bot tests cover the AI's
// move selection, but they do not exercise the GameScreen's
// post-frame callback that drives `_runAiTurn`. This test pumps
// the full app, navigates via the home screen, plays a deterministic
// human turn, ends the turn, and asserts that the AI auto-rolls
// and plays its sub-moves back to white.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakki/app.dart';
import 'package:jakki/engine/dice.dart';
import 'package:jakki/engine/game_state.dart';
import 'package:jakki/engine/move.dart';
import 'package:jakki/engine/player.dart';
import 'package:jakki/state/game_controller.dart';
import 'package:jakki/state/game_mode_controller.dart';

Future<void> _playHumanTurn(
  WidgetTester tester,
  GameController controller,
  Dice forcedRoll,
  List<int> destinations,
) async {
  controller.setDice(forcedRoll);
  await tester.pumpAndSettle();

  for (final int to in destinations) {
    final List<Move> legal = controller.legalNextMovesFrom(24);
    final Move move = legal.firstWhere(
      (Move m) =>
          !m.bearsOff && (m.from + Player.white.direction * m.pips) == to,
    );
    controller.applyMove(move);
    await tester.pumpAndSettle();
  }

  await tester.tap(find.text('End turn'));
}

void main() {
  testWidgets(
    'vs-computer: AI auto-rolls and plays after human ends a non-doubles turn',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: JakkiApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play vs computer'));
      await tester.pumpAndSettle();
      expect(find.text("White's turn"), findsOneWidget);

      final BuildContext context = tester.element(find.byType(Scaffold).first);
      final ProviderContainer container = ProviderScope.containerOf(context);
      expect(
        container.read(gameModeControllerProvider).mode,
        GameMode.vsComputer,
      );

      final GameController controller = container.read(
        gameControllerProvider.notifier,
      );

      // Human plays 24→21 (3 pips) and 24→22 (2 pips), then ends turn.
      await _playHumanTurn(tester, controller, const Dice(3, 2), <int>[21, 22]);

      // Pump enough wall-clock to cover the AI roll delay, between-move
      // delays and the end-turn delay defined in _GameScreenState.
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final GameState afterAi = container.read(gameControllerProvider);
      expect(
        afterAi.board.pointAt(1).topCount,
        lessThan(15),
        reason:
            'AI did not move any black checkers — auto-play never kicked off.',
      );
      expect(
        afterAi.toMove,
        Player.white,
        reason: 'After the AI plays, control should be back with white.',
      );
    },
  );

  testWidgets(
    'vs-computer: AI auto-rolls and plays after human ends a doubles turn',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: JakkiApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play vs computer'));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(Scaffold).first);
      final ProviderContainer container = ProviderScope.containerOf(context);
      final GameController controller = container.read(
        gameControllerProvider.notifier,
      );

      // Human rolls doubles 6-6 and plays four 24→18 sub-moves, then ends turn.
      await _playHumanTurn(tester, controller, const Dice(6, 6), <int>[
        18,
        18,
        18,
        18,
      ]);

      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final GameState afterAi = container.read(gameControllerProvider);
      expect(
        afterAi.board.pointAt(1).topCount,
        lessThan(15),
        reason:
            'AI did not move any black checkers — auto-play never kicked off '
            'after a doubles turn.',
      );
      expect(afterAi.toMove, Player.white);
    },
  );
}
