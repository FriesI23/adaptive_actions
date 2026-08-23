/// Platform-neutral models and layout decisions for adaptive actions.
///
/// Every public symbol exported by this library is part of the supported core
/// contract. This library has no experimental renderer API: renderers integrate
/// by exchanging immutable data with core instead of implementing a base class.
///
/// A renderer describes each root action, the space it has available, and the
/// layout options it can draw. [ActionLayoutResolver] assigns every root to one
/// region and applies the request's region-local order overrides without
/// importing Flutter, measuring UI, or interpreting widgets.
///
/// The usual data flow is:
///
/// ```text
/// action tree + renderer costs + available capacity
///                         |
///                         v
///                ActionLayoutResolver
///                         |
///                         v
///       ordered primary | overflow | hidden
/// ```
///
/// The renderer owns the meaning of option IDs and their numeric costs. Core
/// only compares those costs, returns the selected IDs, and never invokes an
/// action payload:
///
/// ```dart
/// import 'package:adaptive_actions/core.dart';
///
/// final save = AdaptiveAction<String>.action(
///   id: ActionId('save'),
///   metadata: const ActionMetadata(label: 'Save'),
///   payload: 'save-document',
/// );
///
/// final request = ActionLayoutRequest(
///   actions: ActionCollection(roots: [save]),
///   constraints: ActionLayoutConstraints(
///     primaryCapacity: 48,
///     profiles: [
///       ActionLayoutProfile(
///         actionId: save.id,
///         options: [
///           ActionLayoutOption(
///             id: ActionLayoutOptionId('icon'),
///             cost: 48,
///           ),
///         ],
///       ),
///     ],
///   ),
///   capabilities: const RendererCapabilities(),
/// );
///
/// final layout = const ActionLayoutResolver().resolve(request);
/// final optionId = layout.primary.single.optionId;
/// // Draw `save` using the renderer widget registered as `optionId`.
///
/// void handlePayload(String payload) {
///   // Dispatch the caller-owned command outside core.
/// }
///
/// final action = layout.primary.single.action;
/// if (action.isEnabled) {
///   final payload = action.payload;
///   if (payload != null) {
///     handlePayload(payload);
///   }
/// }
/// ```
library;

export 'src/core/action_collection.dart';
export 'src/core/action_collection_entry.dart';
export 'src/core/action_id.dart';
export 'src/core/action_layout.dart';
export 'src/core/action_layout_constraints.dart';
export 'src/core/action_layout_resolver.dart';
export 'src/core/action_metadata.dart';
export 'src/core/action_placement_constraints.dart';
export 'src/core/action_placement_delegate.dart';
export 'src/core/action_placement_policy.dart';
export 'src/core/adaptive_action.dart';
export 'src/core/renderer_capabilities.dart';
