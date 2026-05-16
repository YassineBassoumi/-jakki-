import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/game_storage.dart';
import 'engine/game_state.dart';
import 'state/game_controller.dart';
import 'state/storage_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final GameStorage storage = await GameStorage.open();
  final GameState? saved = storage.loadCurrent();

  runApp(
    ProviderScope(
      overrides: [
        gameStorageProvider.overrideWithValue(storage),
        if (saved != null)
          gameControllerProvider.overrideWith(
            () => _PreloadedGameController(saved),
          ),
      ],
      child: const _AppRoot(),
    ),
  );
}

class _PreloadedGameController extends GameController {
  _PreloadedGameController(this._initial);

  final GameState _initial;

  @override
  GameState build() => _initial;
}

class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  @override
  void initState() {
    super.initState();
    ref.read(gameAutoSaverProvider).start();
  }

  @override
  Widget build(BuildContext context) => const JakkiApp();
}
