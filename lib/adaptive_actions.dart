/// The default platform-neutral adaptive actions API.
///
/// Import `package:adaptive_actions/core.dart` when only the platform-neutral
/// models and resolver are needed, especially from a renderer implementation.
/// Applications can instead import `package:adaptive_actions/material.dart` or
/// `package:adaptive_actions/cupertino.dart`; each renderer entrypoint
/// re-exports the same core contract alongside its platform Widget API.
///
/// Code must not import `package:adaptive_actions/src/...`; those files are
/// implementation details rather than supported entrypoints.
library;

export 'core.dart';
