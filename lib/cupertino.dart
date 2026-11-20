/// Cupertino widgets for rendering adaptive actions.
///
/// This entrypoint re-exports the platform-neutral core contract and adds
/// [CupertinoAdaptiveActions], a width-aware Cupertino primary and overflow
/// action region. It also exposes the shared action-region layout contract.
/// Import `package:cupertino_ui/cupertino_ui.dart` for the host app, themes,
/// and custom UI builders; this entrypoint does not re-export that library.
library;

export 'core.dart';
export 'src/cupertino/adaptive_cupertino_tooltip.dart';
export 'src/cupertino/cupertino_adaptive_actions.dart';
export 'src/widgets/action_region_layout.dart';
