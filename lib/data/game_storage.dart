import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../engine/game_state.dart';

/// Hive-backed persistence for a single in-progress game.
///
/// The game state is serialised as a JSON string and stored in the
/// `games` box under the key `current`. This avoids the need to
/// register custom TypeAdapters for every engine class; the engine
/// already exposes `toJson` / `fromJson`.
class GameStorage {
  GameStorage._(this._box);

  static const String _boxName = 'games';
  static const String _currentKey = 'current';

  final Box<String> _box;

  static Future<GameStorage> open() async {
    await Hive.initFlutter('jakki');
    final Box<String> box = await Hive.openBox<String>(_boxName);
    return GameStorage._(box);
  }

  /// Returns the most recently persisted game state, or null if none.
  GameState? loadCurrent() {
    final String? raw = _box.get(_currentKey);
    if (raw == null) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return GameState.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCurrent(GameState state) async {
    final String encoded = jsonEncode(state.toJson());
    await _box.put(_currentKey, encoded);
  }

  Future<void> clearCurrent() async {
    await _box.delete(_currentKey);
  }
}
