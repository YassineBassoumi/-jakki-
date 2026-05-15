# Jakki Tunisie — Development Plan

This document is the development plan for **Jakki Tunisie**, a Flutter
implementation of the Tunisian *Mahbousseh* variant of tavla /
backgammon. It complements [`RULES.md`](RULES.md) (rules / engine
spec) and [`ARCHITECTURE.md`](ARCHITECTURE.md) (technical design).

## 1. Goals

- A polished, mobile-first Flutter app that plays Jakki Tunisie
  correctly according to [`RULES.md`](RULES.md).
- A pure-Dart game engine that is independent of the UI and fully
  unit-tested.
- Three play modes:
  1. **Pass-and-play** local two-player on one device (Milestone 2).
  2. **AI opponent** (Milestone 4): start with random/heuristic, end
     with a search-based agent.
  3. **Online play** (Milestone 6, optional): friend room over
     Firebase Realtime Database or a small custom WebSocket backend.
- Tunisian look and feel: French + Arabic localization, Tunisian
  dialect (Derja) terms for dice and moves, optional Arabic
  numerals.

## 2. Non-goals (for v1)

- Tournament-grade AI (no neural-net rollout engine).
- Cross-device sync of stats / cloud accounts.
- Custom skins, monetization, ads.
- Tutorials beyond a short interactive walk-through.

## 3. Milestones

Each milestone is a short, shippable slice. Items inside a milestone
are roughly ordered.

### Milestone 0 — Repo bootstrap & plan *(this PR)*

- [x] Empty `main` branch created on GitHub.
- [x] `README.md` introducing the project.
- [x] `docs/RULES.md` — researched and locked-down rules.
- [x] `docs/PLAN.md` — this file.
- [x] `docs/ARCHITECTURE.md` — technical design.
- [x] `.gitignore` for Flutter / Dart / IDE files.

**Definition of done:** PR merged into `main`. No code yet.

### Milestone 1 — Flutter project skeleton

- [ ] Install Flutter SDK (stable channel) locally; document in
      `docs/DEV_SETUP.md`.
- [ ] `flutter create --org tn.jakki --project-name jakki .` at repo
      root.
- [ ] Add `pubspec.yaml` dependencies:
      `flutter_riverpod`, `flutter_animate`, `just_audio`,
      `hive_flutter`, `intl`, `flutter_localizations`.
- [ ] Add dev dependencies: `flutter_lints`, `mocktail`,
      `golden_toolkit`.
- [ ] Configure `analysis_options.yaml` with `flutter_lints` and
      additional rules (`prefer_const_constructors`,
      `always_declare_return_types`, `avoid_dynamic_calls`).
- [ ] CI on GitHub Actions: `flutter analyze`, `flutter test`,
      build APK in release mode.
- [ ] Basic `lib/main.dart` with a placeholder home screen.

**Definition of done:** `flutter run` shows a placeholder screen on
Android emulator; CI green.

### Milestone 2 — Game engine (pure Dart) + pass-and-play UI

- [ ] Engine: data model (`Board`, `Point`, `Checker`, `Move`,
      `GameState`, `Player`). See `ARCHITECTURE.md` § Engine model.
- [ ] Engine: move generator for a `(dice, gameState)` returning
      all legal move sequences.
- [ ] Engine: rule enforcement per [`RULES.md`](RULES.md) §§ 3–8.
- [ ] Engine: pinning logic and stacked-checker representation.
- [ ] Engine: bear-off logic with the "cannot bear off a pinning
      checker" restriction.
- [ ] Engine: serialization (JSON) for saved games.
- [ ] Tests: ≥ 95% line coverage for `lib/engine/**`, including the
      11-point acceptance checklist in `RULES.md` § 11.
- [ ] UI: board widget that renders 24 points, a centre bar (unused
      but kept for visual symmetry), and two bear-off trays.
- [ ] UI: dice widget with animated roll.
- [ ] UI: tap-to-select-checker, tap-to-move flow; highlight legal
      destinations.
- [ ] UI: turn indicator, "must roll", "pass turn", "undo last
      sub-move within current turn".
- [ ] UI: pass-and-play mode (no AI).
- [ ] Local persistence: auto-save the current game with Hive;
      "continue game" on launch.

**Definition of done:** Two humans can play a full game on one
device, following all the rules, with no crashes; engine tests pass.

### Milestone 3 — Polish, localization, sound, settings

- [ ] FR + AR localization (via `intl` / `.arb` files).
- [ ] Optional Tunisian Derja terminology toggle for dice
      announcements (e.g. *chèche-bech* instead of "6-5").
- [ ] Sounds: dice roll, checker move, pin, bear-off, win. Mute
      toggle in settings.
- [ ] Haptics on dice roll and pin.
- [ ] Settings screen: theme (light / dark / sepia-wood), language,
      sound, haptics, house-rules flags from `RULES.md` § 9.
- [ ] Onboarding: 3-screen quick tutorial explaining the pinning
      rule (the main difference from backgammon).
- [ ] Accessibility pass: semantic labels, large-text scaling,
      colour-blind friendly checker palette.

**Definition of done:** App is ready to share with friends and
family for playtesting.

### Milestone 4 — AI opponent

- [ ] Difficulty: *Easy* (random legal move), *Medium* (heuristic
      evaluation: pip count + pinning value + safety), *Hard*
      (1-ply expectimax search over dice rolls).
- [ ] Engine refactor: separate `MoveGenerator`, `Evaluator`, and
      `Search` so future engines (e.g. NN-based) can plug in.
- [ ] Move generation must be fast enough for *Hard* on mobile:
      target < 200 ms per move on a 2020-class Android.
- [ ] UI: difficulty picker; "thinking" indicator with a real
      progress estimate.
- [ ] Stats: track wins / losses / gammons per difficulty in Hive.

**Definition of done:** A user can complete a full game vs each
difficulty, AI does not produce illegal moves under fuzz testing
(10 000 random games).

### Milestone 5 — Match play, doubling cube (optional), stats

- [ ] Match to N points (configurable, default 5) using the scoring
      from `RULES.md` § 8.
- [ ] Optional doubling cube (off by default) with double / take /
      drop UI.
- [ ] End-of-match summary screen with pip-count chart over time
      (uses `fl_chart`).
- [ ] Replay last game move-by-move.

### Milestone 6 — Online play (optional, post-v1)

- [ ] Choose backend: **Firebase Realtime Database** (simplest) or
      **custom Dart/Go WebSocket service** (more control).
- [ ] Friend-room flow with a 6-character room code.
- [ ] Authoritative server-side validation using the same Dart
      engine (compiled to JS or run in a Cloud Function via the
      Dart `aot-snapshot`).
- [ ] Reconnect / resume on disconnect.

### Milestone 7 — Release

- [ ] App icon + splash screen with a Tunisian visual identity
      (e.g. *Sejnane* pottery motifs or *zellige* tiling, used
      respectfully and credited).
- [ ] Privacy policy + terms of use.
- [ ] Play Store / App Store / Web deployment via GitHub Actions.
- [ ] Tag `v1.0.0`.

## 4. Cross-cutting concerns

- **Testing strategy:** unit tests for engine; widget tests for
  every screen; golden tests for the board widget in light + dark
  + RTL layouts; integration test that plays a scripted game
  end-to-end on an emulator.
- **CI/CD:** GitHub Actions matrix for Android + Web + Linux,
  running `flutter analyze && flutter test && flutter build`. A
  separate workflow that builds and signs release artifacts on
  tag push.
- **Code quality:** mandatory `flutter format` + `flutter analyze`
  via a pre-commit hook (set up in Milestone 1) and CI.
- **Branching:** trunk-based; feature branches named
  `devin/<timestamp>-<slug>`; PRs require green CI before merge.
- **Risk register:**
  - *Rule ambiguity for Tunisian house rules* — mitigated by the
    flag-based engine config (`RULES.md` § 9) and by playtesting
    with native players in Milestone 3.
  - *Performance of AI on mobile* — mitigated by pure-Dart engine
    and benchmarking gate in CI.
  - *Online play scope creep* — explicitly post-v1; v1 ships
    without it if needed.

## 5. Timeline (indicative, weeks)

| Milestone | Calendar weeks |
| --------- | -------------- |
| M0 — Plan |  done           |
| M1 — Skeleton | 1           |
| M2 — Engine + pass-and-play | 3 |
| M3 — Polish & i18n | 2     |
| M4 — AI | 2                |
| M5 — Match play | 1        |
| M6 — Online (optional) | 3 |
| M7 — Release | 1           |

Total to a shippable v1 (without online play): ~10 calendar weeks
at part-time pace.

## 6. Out-of-scope explicit list

- Real-money play, leaderboards, social features.
- Spectator mode.
- Custom-rule editor exposed to end users (the flags exist
  internally but are not user-tunable in v1).
