import 'package:flutter/services.dart';

/// Sound effects manager.
///
/// Plays short system-level UI sounds (no bundled audio assets, so
/// the SFX work on Web and degrade gracefully when no audio hardware
/// is available).
///
/// Intentionally tolerant: any [MissingPluginException] thrown by
/// `SystemSound.play` (common in unit tests and on platforms with no
/// audio) is swallowed so callers don't have to handle it.
class SoundManager {
  const SoundManager();

  Future<void> playRoll() => _safePlay(SystemSoundType.click);
  Future<void> playMove() => _safePlay(SystemSoundType.click);
  Future<void> playBearOff() => _safePlay(SystemSoundType.alert);
  Future<void> playWin() => _safePlay(SystemSoundType.alert);

  Future<void> _safePlay(SystemSoundType type) async {
    try {
      await SystemSound.play(type);
    } catch (_) {
      // SFX are best-effort; ignore failures (tests, no audio, etc.).
    }
  }
}

/// Convenience singleton.
const SoundManager soundManager = SoundManager();
