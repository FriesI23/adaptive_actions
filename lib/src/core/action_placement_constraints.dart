import 'package:collection/collection.dart';

import 'action_id.dart';
import 'action_placement_policy.dart';
import 'adaptive_action.dart';

/// Whether actions governed by [ActionPlacementConstraints] may be placed
/// separately.
///
/// The diagrams show resolved regions, not a visual container drawn by a
/// renderer.
enum ActionPlacementSplitPolicy {
  /// The constrained actions must move between layout regions as one unit.
  ///
  /// ```text
  /// constraint:  [A-----C]
  ///
  /// primary:      A     C       or       B
  /// overflow:        B                 A   C
  ///
  /// never:       primary [A]  |  overflow [C]
  /// ```
  indivisible,

  /// Constrained actions may be placed separately in stable root order.
  ///
  /// ```text
  /// constraint:  [A-----C]
  ///
  /// primary:      A
  /// overflow:           C
  ///
  /// A and C keep root order but may occupy different regions.
  /// ```
  splittable,
}

/// Shared placement rules for a set of root actions.
///
/// These constraints affect placement only. They do not draw a border, create
/// a menu, or require [actionIds] to be adjacent in the collection's root list.
///
/// For example, indivisible constraints over `A` and `C` move both roots
/// together while preserving the original `A, B, C` display order:
///
/// ```text
/// declaration:  A  B  C
/// constraint:   [A-----C]
///
/// primary:      A     C       or       B
/// overflow:        B                 A   C
/// ```
final class ActionPlacementConstraints {
  /// Creates shared placement rules for [actionIds].
  ///
  /// Throws an [ArgumentError] when [actionIds] is empty, contains duplicate
  /// IDs, or [placementOverride] is [ActionPlacement.automatic].
  ActionPlacementConstraints({
    required this.id,
    required Iterable<ActionId> actionIds,
    this.splitPolicy = ActionPlacementSplitPolicy.splittable,
    this.placementOverride,
    this.retentionPriority,
  }) : actionIds = List<ActionId>.unmodifiable(actionIds) {
    if (this.actionIds.isEmpty) {
      throw ArgumentError.value(
        this.actionIds,
        'actionIds',
        'must not be empty',
      );
    }

    final uniqueActionIds = <ActionId>{};
    for (final actionId in this.actionIds) {
      if (!uniqueActionIds.add(actionId)) {
        throw ArgumentError.value(
          actionId,
          'actionIds',
          'must not contain duplicate action IDs',
        );
      }
    }
    if (placementOverride == ActionPlacement.automatic) {
      throw ArgumentError.value(
        placementOverride,
        'placementOverride',
        'must be pinned, overflowOnly, hidden, or null',
      );
    }
  }

  /// Creates a placement relationship from action instances.
  ///
  /// This is an authoring convenience for [ActionPlacementConstraints.new]. The
  /// resulting object stores only stable action IDs and does not own, reorder,
  /// or render the supplied actions.
  factory ActionPlacementConstraints.fromActions({
    required ActionPlacementConstraintId id,
    required Iterable<AdaptiveAction> actions,
    ActionPlacementSplitPolicy splitPolicy =
        ActionPlacementSplitPolicy.splittable,
    ActionPlacement? placementOverride,
    PrimaryRetentionPriority? retentionPriority,
  }) => ActionPlacementConstraints(
    id: id,
    actionIds: actions.map((action) => action.id),
    splitPolicy: splitPolicy,
    placementOverride: placementOverride,
    retentionPriority: retentionPriority,
  );

  /// The constraint set's stable identity.
  final ActionPlacementConstraintId id;

  /// Root action IDs governed by this relationship.
  ///
  /// Their order here controls option upgrades for indivisible constraints;
  /// final display order still comes from the collection's root list.
  final List<ActionId> actionIds;

  /// Whether the constrained actions may be placed separately.
  final ActionPlacementSplitPolicy splitPolicy;

  /// The region forced upon every action, or `null` to inherit action policy.
  final ActionPlacement? placementOverride;

  /// The primary-retention priority shared by automatic actions, if any.
  ///
  /// For splittable constraints, this is applied to each automatic action. For
  /// indivisible automatic constraints, it is the priority of the whole unit.
  final PrimaryRetentionPriority? retentionPriority;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionPlacementConstraints &&
          id == other.id &&
          splitPolicy == other.splitPolicy &&
          placementOverride == other.placementOverride &&
          retentionPriority == other.retentionPriority &&
          const ListEquality<Object?>().equals(actionIds, other.actionIds);

  @override
  int get hashCode => Object.hash(
    id,
    splitPolicy,
    placementOverride,
    retentionPriority,
    const ListEquality<Object?>().hash(actionIds),
  );

  @override
  String toString() =>
      'ActionPlacementConstraints(id: $id, actionIds: $actionIds, '
      'splitPolicy: $splitPolicy, '
      'placementOverride: $placementOverride, '
      'retentionPriority: $retentionPriority)';
}
