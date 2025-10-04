# Repository Guidelines

## Project Structure & Module Organization
The Flutter entry point lives in `lib/main.dart`; add feature code under `lib/` grouped by domain (e.g., `lib/features/pots` with widgets, models, state). Reusable UI assets or themes belong in `lib/shared/`. Tests mirror sources in `test/`, while platform-specific runners stay under `android/`, `ios/`, `macos/`, `windows/`, `linux/`, and `web/`; avoid editing generated platform files unless the change is platform-specific.

## Build, Test, and Development Commands
Run `flutter pub get` after updating dependencies. Use `flutter run -d <device>` for local development, or `flutter run -d chrome` for web smoke tests. `flutter analyze` surfaces lint issues; fix them before committing. Build artifacts via `flutter build apk` or `flutter build macos` depending on the target platform.

## Coding Style & Naming Conventions
This project adopts the rules from `flutter_lints`; run `dart format lib test` to enforce two-space indentation and trailing commas in collection literals. Use `UpperCamelCase` for Dart classes, `lowerCamelCase` for methods and variables, and prefix widgets that render full screens with `Pots`. Keep files focused; split UI into smaller widgets when they surpass ~200 lines.

## Testing Guidelines
Write unit and widget tests in `test/`, naming files `<feature>_test.dart`. Use `group` blocks to mirror widget or service names, and prefer `pumpWidget` helpers for widget setups. Required smoke tests: `flutter test`. For coverage checks, run `flutter test --coverage` and inspect `coverage/lcov.info`.

## Commit & Pull Request Guidelines
Conventional Commits keep history readable: `feat: add pot detail screen`, `fix: resolve layout overflow`. Rebase onto the latest `main` before opening a PR. Each PR should describe the change, list test commands run, and attach screenshots or screen recordings for UI updates. Link Jira or GitHub issues when available and request review from at least one other agent.
