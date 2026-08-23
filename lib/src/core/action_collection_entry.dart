import 'action_id.dart';
import 'action_placement_constraints.dart';
import 'action_placement_policy.dart';
import 'adaptive_action.dart';

/// One normalized declaration fragment for `ActionCollection.fromEntries`.
///
/// Implementations contribute flat [roots] and optional
/// [placementConstraints]. The collection snapshots all contributions and
/// applies the same global ID, root-membership, and overlap validation as its
/// standard constructor.
abstract interface class ActionCollectionEntry<T extends Object> {
  /// Creates an entry containing one unconstrained [action].
  factory ActionCollectionEntry.action(AdaptiveAction<T> action) =
      _ActionEntry<T>;

  /// Creates an entry containing roots with shared placement constraints.
  ///
  /// The entry is an authoring container only. It does not create an
  /// action-tree node or a renderer-visible container.
  factory ActionCollectionEntry.constrainedActions({
    required ActionPlacementConstraintId id,
    required Iterable<AdaptiveAction<T>> actions,
    ActionPlacementSplitPolicy splitPolicy,
    ActionPlacement? placementOverride,
    PrimaryRetentionPriority? retentionPriority,
  }) = _ConstrainedActionsEntry<T>;

  /// Root actions contributed in display order.
  ///
  /// Implementations should return a finite, side-effect-free iterable.
  Iterable<AdaptiveAction<T>> get roots;

  /// ID-based placement relationships contributed by this entry.
  ///
  /// Implementations should return a finite, side-effect-free iterable whose
  /// action IDs reference roots contributed by this or another entry.
  Iterable<ActionPlacementConstraints> get placementConstraints;
}

final class _ActionEntry<T extends Object> implements ActionCollectionEntry<T> {
  _ActionEntry(AdaptiveAction<T> action) : roots = List.unmodifiable([action]);

  @override
  final List<AdaptiveAction<T>> roots;

  @override
  Iterable<ActionPlacementConstraints> get placementConstraints => const [];
}

final class _ConstrainedActionsEntry<T extends Object>
    implements ActionCollectionEntry<T> {
  factory _ConstrainedActionsEntry({
    required ActionPlacementConstraintId id,
    required Iterable<AdaptiveAction<T>> actions,
    ActionPlacementSplitPolicy splitPolicy =
        ActionPlacementSplitPolicy.splittable,
    ActionPlacement? placementOverride,
    PrimaryRetentionPriority? retentionPriority,
  }) {
    final immutableActions = List<AdaptiveAction<T>>.unmodifiable(actions);
    final constraints = ActionPlacementConstraints.fromActions(
      id: id,
      actions: immutableActions,
      splitPolicy: splitPolicy,
      placementOverride: placementOverride,
      retentionPriority: retentionPriority,
    );
    return _ConstrainedActionsEntry._(
      actions: immutableActions,
      constraints: constraints,
    );
  }

  _ConstrainedActionsEntry._({
    required List<AdaptiveAction<T>> actions,
    required ActionPlacementConstraints constraints,
  }) : roots = actions,
       placementConstraints = List.unmodifiable([constraints]);

  @override
  final List<AdaptiveAction<T>> roots;

  @override
  final List<ActionPlacementConstraints> placementConstraints;
}
