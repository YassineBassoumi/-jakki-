import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_storage.dart';
import '../engine/game_state.dart';
import 'game_controller.dart';

/// Initialised at app startup; null when storage is unavailable
/// (e.g. in unit tests that don't initialise Hive).
final Provider<GameStorage?> gameStorageProvider = Provider<GameStorage?>(
  (Ref ref) => null,
);

/// Watches [gameControllerProvider] and writes every state change
/// back to [GameStorage]. Disposed automatically when the
/// [ProviderScope] is torn down.
class GameAutoSaver {
  GameAutoSaver(this._ref);

  final Ref _ref;
  ProviderSubscription<GameState>? _sub;

  void start() {
    final GameStorage? storage = _ref.read(gameStorageProvider);
    if (storage == null) return;
    _sub = _ref.listen<GameState>(gameControllerProvider, (
      GameState? previous,
      GameState next,
    ) {
      unawaited(storage.saveCurrent(next));
    }, fireImmediately: true);
  }

  void stop() {
    _sub?.close();
    _sub = null;
  }
}

final Provider<GameAutoSaver> gameAutoSaverProvider = Provider<GameAutoSaver>((
  Ref ref,
) {
  final GameAutoSaver saver = GameAutoSaver(ref);
  ref.onDispose(saver.stop);
  return saver;
});
