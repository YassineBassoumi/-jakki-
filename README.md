# Jakki Tunisie

A Flutter implementation of **Jakki** (جاكي), the traditional Tunisian
board game played on a backgammon-style board. Locally also called
*chiche-biche*, the standard variant played in Tunisia is **Mahbousseh**
(محبوسة, "the imprisoned one"). It uses the same board and dice as
Western backgammon, but instead of hitting a lone opponent checker, you
**pin** it (place your checker on top of it), trapping the opponent until
you decide to free it. This changes strategy significantly and makes the
game distinct from Western backgammon.

> Status: **planning / bootstrapping**. No game code yet. See
> [`docs/PLAN.md`](docs/PLAN.md) for the development roadmap, and
> [`docs/RULES.md`](docs/RULES.md) for the rules that the engine will
> implement.

## Documentation

- [`docs/RULES.md`](docs/RULES.md) — Rules of Jakki Tunisie (Mahbousseh
  variant) as the source of truth for the game engine.
- [`docs/PLAN.md`](docs/PLAN.md) — Development plan, milestones, and
  deliverables.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — Technical architecture
  (Flutter project layout, state management, game engine design).

## Tech stack (planned)

- **Flutter** (stable channel) — cross-platform UI (Android, iOS, Web,
  desktop).
- **Dart** — game engine (pure Dart, no Flutter dependencies, so it is
  fully unit-testable and reusable).
- **Riverpod** — state management.
- **flutter_animate** — smooth checker animations.
- **just_audio** — dice-roll and pin sound effects.
- **shared_preferences** / **hive** — local persistence (saved games,
  settings, statistics).

The full rationale and alternative choices are documented in
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Quick start (once the Flutter project is initialized)

```bash
# 1. Install the Flutter SDK (stable channel)
#    https://docs.flutter.dev/get-started/install
flutter --version

# 2. Initialize the Flutter project in this directory (only once, see
#    Milestone 1 in docs/PLAN.md)
flutter create --org tn.jakki --project-name jakki .

# 3. Fetch dependencies
flutter pub get

# 4. Run on a connected device / emulator
flutter run
```

## License

To be decided by the repository owner. Suggested: MIT or Apache-2.0.
