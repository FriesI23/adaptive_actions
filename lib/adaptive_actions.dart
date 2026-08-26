/// The complete adaptive actions API.
///
/// Import `package:adaptive_actions/core.dart` when only the platform-neutral
/// models and resolver are needed, especially from a renderer implementation.
/// Applications can import this aggregate entrypoint, or select
/// `package:adaptive_actions/material.dart` or
/// `package:adaptive_actions/cupertino.dart`; each renderer entrypoint
/// re-exports the core and shared Widget contracts alongside its platform API.
///
/// Code must not import `package:adaptive_actions/src/...`; those files are
/// implementation details rather than supported entrypoints.
library;

export 'core.dart';
export 'cupertino.dart';
export 'material.dart';
