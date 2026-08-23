/// Material widgets for rendering adaptive actions.
///
/// This entrypoint re-exports the platform-neutral core contract and adds
/// [MaterialAdaptiveActions], a width-aware primary and overflow action region.
/// It does not change the core API or make the default package entrypoint
/// depend on Material.
library;

export 'core.dart';
export 'src/material/material_adaptive_actions.dart';
