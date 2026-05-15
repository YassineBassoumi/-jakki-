# Jakki Tunisie — Architecture

This document describes the technical architecture for the Flutter
implementation. Companion to [`RULES.md`](RULES.md) and
[`PLAN.md`](PLAN.md).

## 1. Layers

```
+-----------------------------------------------------------+
|  Presentation (Flutter widgets, screens, animations)      |
+------------------------------+----------------------------+
|  Application (Riverpod state notifiers, controllers)      |
+------------------------------+----------------------------+
|  Domain / Engine (pure Dart, no Flutter imports)          |
|     - Board, Point, Checker, Move, GameState              |
|     - MoveGenerator, RuleEngine, Evaluator, AIPlayer      |
+------------------------------+----------------------------+
|  Infrastructure (Hive persistence, audio, platform)       |
+-----------------------------------------------------------+
```

The **Engine** has zero Flutter dependencies. It can be unit-tested
in isolation, compiled to JS for a future web replay viewer, or
re-used server-side for authoritative online play.

## 2. Project layout

```
.
├── README.md
├── pubspec.yaml
├── analysis_options.yaml
├── docs/
│   ├── RULES.md
│   ├── PLAN.md
│   ├── ARCHITECTURE.md
│   └── DEV_SETUP.md          # added in Milestone 1
├── assets/
│   ├── images/
│   ├── sounds/
│   └── fonts/
├── lib/
│   ├── main.dart
│   ├── app.dart              # MaterialApp + routes + theming
│   ├── engine/               # pure Dart, no Flutter imports
│   │   ├── board.dart
│   │   ├── point.dart
│   │   ├── checker.dart
│   │   ├── dice.dart
│   │   ├── move.dart
│   │   ├── game_state.dart
│   │   ├── rule_engine.dart
│   │   ├── move_generator.dart
│   │   ├── evaluator.dart    # heuristic eval for AI
│   │   ├── ai_player.dart
│   │   └── house_rules.dart  # feature flags from RULES.md §9
│   ├── state/                # Riverpod providers / notifiers
│   │   ├── game_controller.dart
│   │   ├── settings_controller.dart
│   │   └── stats_controller.dart
│   ├── ui/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── game_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   ├── tutorial_screen.dart
│   │   │   └── stats_screen.dart
│   │   ├── widgets/
│   │   │   ├── board_view.dart
│   │   │   ├── point_view.dart
│   │   │   ├── checker_view.dart
│   │   │   ├── dice_view.dart
│   │   │   └── bear_off_tray.dart
│   │   └── theme/
│   │       └── jakki_theme.dart
│   ├── data/
│   │   ├── persistence.dart   # Hive boxes for game / settings / stats
│   │   └── audio_service.dart
│   └── l10n/
│       ├── intl_en.arb
│       ├── intl_fr.arb
│       └── intl_ar.arb
└── test/
    ├── engine/                # mirrors lib/engine
    ├── state/
    └── ui/                    # widget + golden tests
```

## 3. Engine model

```dart
enum Player { white, black }

class Checker {
  final Player owner;
}

/// A point on the board (1..24). Implements stacking and pinning.
class Point {
  final int index;          // 1..24, from the *current* player's POV
  final List<Checker> stack;// bottom-to-top; pinned checker is at bottom

  bool get isEmpty => stack.isEmpty;
  int get count => stack.length;
  Player? get topOwner => stack.isEmpty ? null : stack.last.owner;
  Checker? get pinned =>
      // a checker is pinned when there is exactly one opponent checker
      // at the bottom and at least one of the top owner's checkers above
      stack.length >= 2 && stack.first.owner != stack.last.owner
          ? stack.first
          : null;
}

class Board {
  final List<Point> points;     // length 24
  final List<Checker> bornOffWhite;
  final List<Checker> bornOffBlack;
}

class Dice {
  final int a, b;
  bool get isDoubles => a == b;
  /// 4 pips when doubles, else 2.
  List<int> get pips => isDoubles ? [a, a, a, a] : [a, b];
}

/// A single sub-move: move one checker from `from` by `pips` points.
class Move {
  final int from;
  final int pips;
  final bool bearsOff;
}

class GameState {
  final Board board;
  final Player toMove;
  final Dice? dice;        // null until rolled
  final List<int> remainingPips;
  final int whiteScore;
  final int blackScore;
  final HouseRules rules;
}
```

### Move generation

`MoveGenerator.legalSequences(state)` returns the list of *full
turns* (sequences of `Move`) playable from the current state. The
generator enforces:

- "must play both dice if possible" (RULES § 5),
- "must play the larger die when only one is playable" (RULES § 5),
- pinning legality and the "cannot bear off a pinning checker"
  rule (RULES §§ 6, 7).

Returning full sequences (not individual sub-moves) avoids the
classic backgammon UX bug of trapping the player into an illegal
half-move.

### House rules

The `HouseRules` value object holds the flags from `RULES.md` § 9.
It is part of `GameState` so saved games keep the rules they were
created with.

## 4. State management

We use **Riverpod** (`flutter_riverpod`).

- `gameControllerProvider` — `StateNotifier<GameState>` exposing
  intents: `rollDice()`, `selectChecker(point)`, `applyMove(move)`,
  `undoSubMove()`, `endTurn()`, `newGame(rules, mode)`.
- `settingsControllerProvider` — persisted via Hive.
- `statsControllerProvider` — read-only view over the stats Hive
  box.

UI widgets watch the providers; they never mutate `GameState`
directly.

## 5. UI / board rendering

- The board widget is a `LayoutBuilder` that computes point
  geometry from the available size; checkers are positioned with
  `Positioned` inside a `Stack`.
- Animations use `flutter_animate` for dice roll, checker slide,
  and pin "snap" feedback.
- The board supports **right-to-left** layout for the Arabic
  locale: the player's home board moves to the opposite side.
- Golden tests cover the board in light / dark / RTL.

## 6. AI

The AI lives in `lib/engine/ai_player.dart`:

- *Easy*: pick uniformly at random from `legalSequences`.
- *Medium*: evaluate each sequence with `Evaluator`:

  ```
  score =  pipCountAdvantage
         + 2.0 * numberOfOpponentCheckersPinned
         - 1.5 * numberOfOwnCheckersPinned
         + 0.4 * numberOfOwnAnchorsInOpponentHome
         - 0.2 * numberOfOwnBlots
  ```

  Coefficients are tunable and stored as constants for now;
  Milestone 4 may add self-play calibration.

- *Hard*: 1-ply expectimax over the 21 distinct dice outcomes,
  using `Evaluator` as the static eval. Caps total search time
  per move at 200 ms.

The AI never sees Flutter types and is fully unit-testable.

## 7. Persistence

`hive_flutter` boxes:

- `gameBox` — the *current* in-progress `GameState` (single key).
- `settingsBox` — `Settings` (theme, locale, sound, haptics,
  house-rules).
- `statsBox` — list of `MatchResult` records.

`GameState` serialization is hand-written `toJson`/`fromJson` (no
generated code) to keep the engine free of build_runner.

## 8. Localization

- `flutter_localizations` + `intl` with `.arb` files for English,
  French, and Arabic.
- Arabic uses RTL layout; the board flips accordingly.
- A *Derja terms* toggle replaces dice-roll announcements with
  their Tunisian/Persian names from `RULES.md` § 10.

## 9. Testing

| Layer       | Tooling                  | Coverage target |
| ----------- | ------------------------ | --------------- |
| Engine      | `package:test`           | ≥ 95% lines     |
| State       | `flutter_test` + mocktail| ≥ 80%           |
| Widgets     | `flutter_test` + `golden_toolkit` | smoke + key flows |
| Integration | `integration_test`       | one happy path + one AI game |

Fuzz test: 10 000 random self-play games on every PR (executed in
CI in `--release` mode) verifying no exception, no illegal state.

## 10. CI

GitHub Actions workflow `ci.yml`:

```yaml
on: [push, pull_request]
jobs:
  analyze_and_test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze
      - run: flutter test --coverage
      - run: flutter build apk --debug
```

A release workflow on tag push builds + signs Android, builds web,
and uploads artifacts.
