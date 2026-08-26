/// Material widgets for rendering adaptive actions.
///
/// This entrypoint re-exports the platform-neutral core contract and adds
/// [MaterialAdaptiveActions], a width-aware primary and overflow action region.
/// It also exposes the shared action-region layout contract.
library;

export 'core.dart';
export 'src/material/material_adaptive_actions.dart';
export 'src/widgets/action_region_layout.dart';
