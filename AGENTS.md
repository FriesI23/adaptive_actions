# Repository Guidelines

## Project Structure & Module Organization

`lib/core.dart` exports the platform-neutral placement model and resolver. Platform entrypoints live in `lib/material.dart` and `lib/cupertino.dart`; implementations are under `lib/src/core`, `lib/src/material`, `lib/src/cupertino`, and `lib/src/widgets`. Keep Flutter UI dependencies out of Core. The runnable showcase is in `example/`, architecture notes are in `docs/`, and publication images are in `screenshots/`. Tests mirror the source boundaries under `test/core`, `test/material`, `test/cupertino`, `test/renderer`, `test/widgets`, and `test/architecture`.

## Build, Test, and Development Commands

- `make check`: canonical local gate; verifies formatting, analyzes the package and example, and runs both test suites.
- `make test` / `make test-example`: run package or example tests only.
- `make analyze`: run Flutter static analysis with the repository's strict rules.
- `make format`: format package and example Dart sources.
- `make aio`: apply Dart fixes and formatting, then analyze and test everything.
- `make publish-dry-run`: validate pub.dev packaging before release work.

FVM is used when available; CI currently runs Flutter 3.44.9.

## Coding Style & Naming Conventions

Use two-space Dart formatting and let `dart format` decide line wrapping. Follow `flutter_lints` plus the strict casts, inference, raw-types, directive-ordering, and public-doc rules in `analysis_options.yaml`. Public APIs require concise dartdoc.

Use `_Name` for implementation details confined to one Dart library. For complete package-internal contracts shared across files, use a public name with `@internal`, place it under `lib/src`, and do not export it from a barrel. Do not treat underscored filenames or directories as language-level privacy.

## Testing Guidelines

Use `flutter_test`; name files `*_test.dart` and prefer behavior-focused `test` or `testWidgets` descriptions. Add regression coverage for observable changes, including placement, ordering, animation, semantics, focus, RTL, and menu timing where relevant. Test an internal class directly only when it is a complete reusable contract rather than a replaceable implementation detail. Run focused tests while iterating, then `make check` before handoff.

## Commit & Pull Request Guidelines

Follow the repository's Conventional Commit style: `feat:`, `fix:`, `refactor(core):`, `chore:`, and `feat!:` for breaking changes. Keep commits scoped and independently testable. Pull requests should briefly describe behavior and API impact, list verification performed, link relevant issues, and include screenshots for visible Material or Cupertino changes. Do not combine feature, release, tag, or push operations without explicit authorization.

## Working Tree Safety

Inspect the current branch and staged/unstaged changes before editing. Preserve unrelated work, generated outputs, and public API boundaries; never discard user changes to obtain a clean tree.
