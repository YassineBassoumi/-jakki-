import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/bot.dart';

/// Single shared [OnePlyBot] instance used by [GameScreen] when
/// the active [GameMode] is `vsComputer`.
final Provider<OnePlyBot> aiBotProvider = Provider<OnePlyBot>(
  (Ref ref) => OnePlyBot(),
);
