# Dev setup

Local development setup for the Jakki Tunisie app.

## Prerequisites

- **Flutter SDK** — stable channel, Dart `^3.11.5` (see `pubspec.yaml`
  `environment` block). Install via the official guide:
  <https://docs.flutter.dev/get-started/install>.
- **Android Studio / Xcode** — only if you plan to build native
  Android / iOS. Web and Linux desktop builds work without them.
- **A device or emulator** — Android emulator, iOS simulator, or
  Chrome for the web build.

Verify your toolchain:

```bash
flutter --version
flutter doctor
```

## Common commands

```bash
# 1. Install/refresh dependencies
flutter pub get

# 2. Run the app on the first available device (or pick one with -d)
flutter run

# 3. Run the app on the web (Chrome)
flutter run -d chrome

# 4. Static analysis (must pass before push; CI enforces this)
flutter analyze

# 5. Auto-format (CI enforces formatted code)
dart format .

# 6. Run all tests
flutter test

# 7. Build a release APK
flutter build apk --release

# 8. Build a release web bundle
flutter build web --release
```

## Project structure

See [`ARCHITECTURE.md`](ARCHITECTURE.md) §2. In short:

- `lib/main.dart` — entry point, wraps the app in a Riverpod
  `ProviderScope`.
- `lib/app.dart` — `MaterialApp` + theming + routing.
- `lib/engine/` — pure Dart game engine (no Flutter imports). Will
  be filled in Milestone 2.
- `lib/ui/` — screens, widgets, theme.
- `lib/state/` — Riverpod controllers.
- `lib/data/` — Hive boxes + audio service.
- `lib/l10n/` — `.arb` localization files.
- `test/` — unit + widget tests; mirrors `lib/` structure.

## CI

GitHub Actions workflow at `.github/workflows/ci.yml` runs on every
push and PR:

1. `flutter pub get`
2. `dart format --output=none --set-exit-if-changed .`
3. `flutter analyze`
4. `flutter test --coverage`
5. `flutter build apk --debug`
6. `flutter build web --release`

PRs cannot merge until all of the above pass. Run them locally
before pushing to avoid CI churn.

## Pre-commit hook (optional, recommended)

The repo does not bundle a pre-commit framework yet. A simple
shell hook is enough for now — drop this into
`.git/hooks/pre-commit` and `chmod +x` it:

```bash
#!/usr/bin/env bash
set -e
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

A proper `pre-commit` / `husky` integration will be added in a
later PR once team conventions are set.
