import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/player.dart';

/// Modes in which a game can be played.
enum GameMode {
  /// Two humans sharing the device. Both colours are controlled by
  /// taps. (Default.)
  passAndPlay,

  /// Single-player: the human plays one colour, the AI plays the
  /// other. The AI auto-rolls and auto-plays on its turn.
  vsComputer,
}

/// Settings around the active game mode.
///
/// We only persist this in-memory for now — it gets reset to the
/// default whenever the app is restarted. The user's choice between
/// pass-and-play and vs-computer is implicit in which "Play" button
/// they tap on the home screen.
class GameModeSettings {
  const GameModeSettings({
    this.mode = GameMode.passAndPlay,
    this.humanPlayer = Player.white,
  });

  final GameMode mode;

  /// In [GameMode.vsComputer], the colour the human controls. The AI
  /// controls the opposite. Ignored in [GameMode.passAndPlay].
  final Player humanPlayer;

  Player get aiPlayer => humanPlayer.opposite;

  /// True if `player` is currently the AI in this mode.
  bool isAi(Player player) => mode == GameMode.vsComputer && player == aiPlayer;

  GameModeSettings copyWith({GameMode? mode, Player? humanPlayer}) {
    return GameModeSettings(
      mode: mode ?? this.mode,
      humanPlayer: humanPlayer ?? this.humanPlayer,
    );
  }
}

/// Controller for [GameModeSettings].
class GameModeController extends Notifier<GameModeSettings> {
  @override
  GameModeSettings build() => const GameModeSettings();

  void setMode(GameMode mode, {Player humanPlayer = Player.white}) {
    state = GameModeSettings(mode: mode, humanPlayer: humanPlayer);
  }

  void reset() {
    state = const GameModeSettings();
  }
}

final NotifierProvider<GameModeController, GameModeSettings>
gameModeControllerProvider =
    NotifierProvider<GameModeController, GameModeSettings>(
      GameModeController.new,
    );
