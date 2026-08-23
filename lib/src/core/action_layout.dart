import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'action_collection.dart';
import 'action_id.dart';
import 'action_layout_constraints.dart';
import 'action_resolver/action_placement_input_normalization.dart';
import 'adaptive_action.dart';
import 'renderer_capabilities.dart';

/// A validated snapshot of everything needed for one layout decision.
///
/// Construction validates cross-model rules before a placement delegate runs,
/// so a delegate never returns a partial result for invalid input. Renderers
/// create this request from measured capacity, opaque layout options, and
/// supported interactions; no UI object is stored here.
final class ActionLayoutRequest<T extends Object> {
  /// Creates and validates one layout request.
  ///
  /// Throws an [ArgumentError] for invalid placement constraints, missing or
  /// unknown layout profiles, and duplicate order-override IDs.
  factory ActionLayoutRequest({
    required ActionCollection<T> actions,
    required ActionLayoutConstraints constraints,
    required RendererCapabilities capabilities,
    Iterable<ActionId> primaryOrderOverride = const [],
    Iterable<ActionId> overflowOrderOverride = const [],
  }) {
    final copiedPrimaryOverride = _copyUniqueOverride(
      primaryOrderOverride,
      'primaryOrderOverride',
    );
    final copiedOverflowOverride = _copyUniqueOverride(
      overflowOrderOverride,
      'overflowOrderOverride',
    );
    final normalizedPlacementInput = actions.normalizeForPlacement(constraints);

    return ActionLayoutRequest._(
      actions: actions,
      constraints: constraints,
      capabilities: capabilities,
      primaryOrderOverride: copiedPrimaryOverride,
      overflowOrderOverride: copiedOverflowOverride,
      normalizedPlacementInput: normalizedPlacementInput,
    );
  }

  ActionLayoutRequest._({
    required this.actions,
    required this.constraints,
    required this.capabilities,
    required this.primaryOrderOverride,
    required this.overflowOrderOverride,
    required NormalizedActionPlacementInput<T> normalizedPlacementInput,
  }) : _normalizedPlacementInput = normalizedPlacementInput;

  /// The validated action tree and its placement constraints.
  final ActionCollection<T> actions;

  /// Available primary space and the renderer's layout costs.
  final ActionLayoutConstraints constraints;

  /// Interaction features available from the renderer.
  final RendererCapabilities capabilities;

  /// Requested primary order for the later ordering stage.
  final List<ActionId> primaryOrderOverride;

  /// Requested overflow order for the later ordering stage.
  final List<ActionId> overflowOrderOverride;

  final NormalizedActionPlacementInput<T> _normalizedPlacementInput;

  /// The placement data normalized when this request was created.
  ///
  /// This member supports package-internal placement implementations and is not
  /// part of the supported public API.
  @internal
  NormalizedActionPlacementInput<T> get normalizedPlacementInput =>
      _normalizedPlacementInput;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionLayoutRequest<T> &&
          actions == other.actions &&
          constraints == other.constraints &&
          capabilities == other.capabilities &&
          const ListEquality<ActionId>().equals(
            primaryOrderOverride,
            other.primaryOrderOverride,
          ) &&
          const ListEquality<ActionId>().equals(
            overflowOrderOverride,
            other.overflowOrderOverride,
          );

  @override
  int get hashCode => Object.hash(
    actions,
    constraints,
    capabilities,
    const ListEquality<ActionId>().hash(primaryOrderOverride),
    const ListEquality<ActionId>().hash(overflowOrderOverride),
  );

  @override
  String toString() =>
      'ActionLayoutRequest(actions: $actions, '
      'constraints: $constraints, '
      'capabilities: $capabilities, primaryOrderOverride: '
      '$primaryOrderOverride, overflowOrderOverride: '
      '$overflowOrderOverride)';
}

List<ActionId> _copyUniqueOverride(Iterable<ActionId> ids, String name) {
  final copy = List<ActionId>.unmodifiable(ids);
  final seen = <ActionId>{};
  for (final id in copy) {
    if (!seen.add(id)) {
      throw ArgumentError.value(ids, name, 'must not contain duplicate IDs');
    }
  }
  return copy;
}

/// A primary root and the renderer layout selected for it.
final class ResolvedPrimaryAction<T extends Object> {
  /// Associates [action] with the renderer option chosen for this pass.
  const ResolvedPrimaryAction({required this.action, required this.optionId});

  /// The original action, including its complete subtree.
  final AdaptiveAction<T> action;

  /// The key used to select the renderer's matching widget layout.
  final ActionLayoutOptionId optionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedPrimaryAction<T> &&
          action == other.action &&
          optionId == other.optionId;

  @override
  int get hashCode => Object.hash(action, optionId);

  @override
  String toString() =>
      'ResolvedPrimaryAction(action: ${action.id}, '
      'optionId: $optionId)';
}

/// The reason a root is unavailable in a resolved layout.
enum HiddenActionReason {
  /// The action has a hard hidden placement policy.
  ///
  /// ```text
  /// ActionPlacement.hidden
  ///           |
  ///           v
  /// hidden:  [A]
  /// ```
  forcedHidden,

  /// Capacity was insufficient and the action permits hiding.
  ///
  /// ```text
  /// primary:  [full]  +  A cannot fit
  ///                          |
  ///                          v
  /// hidden:                 [A]
  /// ```
  insufficientCapacity,
}

/// A root excluded from both visible layout regions.
final class HiddenAction<T extends Object> {
  /// Associates an unavailable [action] with its [reason].
  const HiddenAction({required this.action, required this.reason});

  /// The original action, including its complete subtree.
  final AdaptiveAction<T> action;

  /// Why the action is unavailable.
  final HiddenActionReason reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiddenAction<T> &&
          action == other.action &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(action, reason);

  @override
  String toString() => 'HiddenAction(action: ${action.id}, reason: $reason)';
}

/// Stable machine-readable categories emitted during resolution.
///
/// Diagnostics describe the resolved state for developer tooling. They do not
/// require a renderer to draw warning UI.
enum ResolutionDiagnosticCode {
  /// An action was hidden by its hard placement policy.
  ///
  /// ```text
  /// policy:   hidden
  /// result:   hidden [A]
  /// report:   forcedHidden(A)
  /// ```
  forcedHidden,

  /// Available capacity could not expose one or more automatic actions.
  ///
  /// ```text
  /// primary:  [full]
  /// result:   overflow [A]  or  hidden [A]
  /// report:   insufficientCapacity(A)
  /// ```
  insufficientCapacity,

  /// Pinned actions exceed a primary constraint but remain pinned.
  ///
  /// ```text
  /// capacity: |----------|
  /// pinned:   |---A---B------>
  /// result:   primary [A] [B]
  /// report:   unsatisfiedPinnedConstraint(A, B)
  /// ```
  unsatisfiedPinnedConstraint,

  /// A resolver received input it could not safely interpret.
  ///
  /// ```text
  /// invalid request  --X-->  placement result
  ///        |
  ///        v
  /// report: invalidRequest
  /// ```
  invalidRequest,
}

/// Developer-facing information about a placement constraint.
final class ResolutionDiagnostic {
  /// Creates a diagnostic related to [actionIds].
  ResolutionDiagnostic({
    required this.code,
    Iterable<ActionId> actionIds = const [],
    this.message,
  }) : actionIds = List.unmodifiable(actionIds);

  /// The stable machine-readable diagnostic category.
  final ResolutionDiagnosticCode code;

  /// Root actions related to this diagnostic, in stable order.
  final List<ActionId> actionIds;

  /// Optional detail intended for logs and developer tooling.
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolutionDiagnostic &&
          code == other.code &&
          message == other.message &&
          const ListEquality<ActionId>().equals(actionIds, other.actionIds);

  @override
  int get hashCode => Object.hash(
    code,
    const ListEquality<ActionId>().hash(actionIds),
    message,
  );

  @override
  String toString() =>
      'ResolutionDiagnostic(code: $code, actionIds: $actionIds, '
      'message: $message)';
}

/// The mutually exclusive regions produced by `ActionPlacementDelegate`.
///
/// Every collection root appears exactly once across [primary], [overflow], and
/// [hidden]. Children remain attached to their root and do not appear as
/// independent entries.
///
/// This intermediate result supports custom [ActionPlacementDelegate]
/// implementations. Normal renderers should consume [ActionLayoutResult]
/// after region order overrides have been applied.
///
/// ```text
/// roots:       A  B  C  D
///                resolve
///                 v
/// primary:    A     C
/// overflow:      B
/// hidden:             D
/// ```
final class ActionPlacementResult<T extends Object> {
  /// Creates an immutable placement result from region entries.
  ActionPlacementResult({
    Iterable<ResolvedPrimaryAction<T>> primary = const [],
    Iterable<AdaptiveAction<T>> overflow = const [],
    Iterable<HiddenAction<T>> hidden = const [],
    Iterable<ResolutionDiagnostic> diagnostics = const [],
  }) : primary = List.unmodifiable(primary),
       overflow = List.unmodifiable(overflow),
       hidden = List.unmodifiable(hidden),
       diagnostics = List.unmodifiable(diagnostics);

  /// Roots rendered directly in the primary region.
  final List<ResolvedPrimaryAction<T>> primary;

  /// Roots exposed through the renderer's overflow affordance.
  final List<AdaptiveAction<T>> overflow;

  /// Roots intentionally unavailable in this layout.
  final List<HiddenAction<T>> hidden;

  /// Constraint and resolution diagnostics in stable order.
  final List<ResolutionDiagnostic> diagnostics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionPlacementResult<T> &&
          const ListEquality<Object?>().equals(primary, other.primary) &&
          const ListEquality<Object?>().equals(overflow, other.overflow) &&
          const ListEquality<Object?>().equals(hidden, other.hidden) &&
          const ListEquality<Object?>().equals(diagnostics, other.diagnostics);

  @override
  int get hashCode => Object.hash(
    const ListEquality<Object?>().hash(primary),
    const ListEquality<Object?>().hash(overflow),
    const ListEquality<Object?>().hash(hidden),
    const ListEquality<Object?>().hash(diagnostics),
  );

  @override
  String toString() =>
      'ActionPlacementResult(primary: $primary, overflow: $overflow, '
      'hidden: $hidden, diagnostics: $diagnostics)';
}

/// The final renderer input after optional region ordering is applied.
///
/// A renderer must preserve [primary] and [overflow] order, use each primary
/// entry's selected layout option ID, keep every action subtree intact, and
/// leave [hidden] unavailable to users. Divider boundary lists identify the
/// actions that should receive a leading separator in each visible region.
/// Rendering and payload dispatch remain outside core.
final class ActionLayoutResult<T extends Object> {
  /// Creates an immutable renderer-ready layout.
  ActionLayoutResult({
    Iterable<ResolvedPrimaryAction<T>> primary = const [],
    Iterable<AdaptiveAction<T>> overflow = const [],
    Iterable<ActionId> primaryDividerBeforeActionIds = const [],
    Iterable<ActionId> overflowDividerBeforeActionIds = const [],
    Iterable<HiddenAction<T>> hidden = const [],
    Iterable<ResolutionDiagnostic> diagnostics = const [],
  }) : primary = List.unmodifiable(primary),
       overflow = List.unmodifiable(overflow),
       primaryDividerBeforeActionIds = List.unmodifiable(
         primaryDividerBeforeActionIds,
       ),
       overflowDividerBeforeActionIds = List.unmodifiable(
         overflowDividerBeforeActionIds,
       ),
       hidden = List.unmodifiable(hidden),
       diagnostics = List.unmodifiable(diagnostics);

  /// Primary roots in final display order.
  final List<ResolvedPrimaryAction<T>> primary;

  /// Overflow roots in final display order.
  final List<AdaptiveAction<T>> overflow;

  /// Primary action IDs that have a visible divider immediately before them.
  ///
  /// Divider boundaries do not consume placement capacity or become actions.
  final List<ActionId> primaryDividerBeforeActionIds;

  /// Overflow action IDs that have a visible menu divider before them.
  final List<ActionId> overflowDividerBeforeActionIds;

  /// Roots unavailable to the user.
  final List<HiddenAction<T>> hidden;

  /// Constraint and resolution diagnostics in stable order.
  final List<ResolutionDiagnostic> diagnostics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionLayoutResult<T> &&
          const ListEquality<Object?>().equals(primary, other.primary) &&
          const ListEquality<Object?>().equals(overflow, other.overflow) &&
          const ListEquality<ActionId>().equals(
            primaryDividerBeforeActionIds,
            other.primaryDividerBeforeActionIds,
          ) &&
          const ListEquality<ActionId>().equals(
            overflowDividerBeforeActionIds,
            other.overflowDividerBeforeActionIds,
          ) &&
          const ListEquality<Object?>().equals(hidden, other.hidden) &&
          const ListEquality<Object?>().equals(diagnostics, other.diagnostics);

  @override
  int get hashCode => Object.hash(
    const ListEquality<Object?>().hash(primary),
    const ListEquality<Object?>().hash(overflow),
    const ListEquality<ActionId>().hash(primaryDividerBeforeActionIds),
    const ListEquality<ActionId>().hash(overflowDividerBeforeActionIds),
    const ListEquality<Object?>().hash(hidden),
    const ListEquality<Object?>().hash(diagnostics),
  );

  @override
  String toString() =>
      'ActionLayoutResult(primary: $primary, overflow: $overflow, '
      'primaryDividerBeforeActionIds: $primaryDividerBeforeActionIds, '
      'overflowDividerBeforeActionIds: $overflowDividerBeforeActionIds, '
      'hidden: $hidden, diagnostics: $diagnostics)';
}
