import 'package:collection/collection.dart';

import 'action_collection_entry.dart';
import 'action_id.dart';
import 'action_placement_constraints.dart';
import 'adaptive_action.dart';

/// The complete action tree and its root-level placement relationships.
final class ActionCollection<T extends Object> {
  /// Creates a snapshot of [roots] and [placementConstraints].
  ///
  /// IDs must be unique across the complete tree. Placement constraints may
  /// reference roots only, and each root may be governed by at most one
  /// constraint set. Invalid input throws an [ArgumentError].
  factory ActionCollection({
    required Iterable<AdaptiveAction<T>> roots,
    Iterable<ActionPlacementConstraints> placementConstraints = const [],
  }) {
    final immutableRoots = List<AdaptiveAction<T>>.unmodifiable(roots);
    final immutableConstraints = List<ActionPlacementConstraints>.unmodifiable(
      placementConstraints,
    );
    _ActionCollectionValidator(immutableRoots, immutableConstraints).validate();
    return ActionCollection._(
      entries: List<AdaptiveMenuEntry<T>>.unmodifiable(immutableRoots),
      roots: immutableRoots,
      placementConstraints: immutableConstraints,
    );
  }

  /// Creates a collection whose top-level declaration may contain dividers.
  ///
  /// Only [AdaptiveAction] entries become [roots] and participate in layout
  /// placement. [AdaptiveMenuDivider] entries retain group boundaries for the
  /// final primary and overflow renderings. Divider-only declarations resolve
  /// like an empty action collection.
  factory ActionCollection.withEntries({
    required Iterable<AdaptiveMenuEntry<T>> entries,
    Iterable<ActionPlacementConstraints> placementConstraints = const [],
  }) {
    final immutableEntries = List<AdaptiveMenuEntry<T>>.unmodifiable(entries);
    final immutableRoots = List<AdaptiveAction<T>>.unmodifiable(
      immutableEntries.whereType<AdaptiveAction<T>>(),
    );
    final immutableConstraints = List<ActionPlacementConstraints>.unmodifiable(
      placementConstraints,
    );
    _ActionCollectionValidator(immutableRoots, immutableConstraints).validate();
    return ActionCollection._(
      entries: immutableEntries,
      roots: immutableRoots,
      placementConstraints: immutableConstraints,
    );
  }

  /// Creates a collection from normalized declaration entries.
  ///
  /// Built-in entries are created with [ActionCollectionEntry.action] and
  /// [ActionCollectionEntry.constrainedActions]. Custom implementations can
  /// contribute the same flat roots and ID-based placement relationships.
  factory ActionCollection.fromEntries(
    Iterable<ActionCollectionEntry<T>> entries,
  ) {
    final roots = <AdaptiveAction<T>>[];
    final placementConstraints = <ActionPlacementConstraints>[];
    for (final entry in entries) {
      roots.addAll(entry.roots);
      placementConstraints.addAll(entry.placementConstraints);
    }
    return ActionCollection(
      roots: roots,
      placementConstraints: placementConstraints,
    );
  }

  ActionCollection._({
    required this.entries,
    required this.roots,
    required this.placementConstraints,
  });

  /// Top-level actions and divider boundaries in declaration order.
  final List<AdaptiveMenuEntry<T>> entries;

  /// Top-level actions in stable display order.
  final List<AdaptiveAction<T>> roots;

  /// Placement relationships between roots.
  final List<ActionPlacementConstraints> placementConstraints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionCollection<T> &&
          const ListEquality<Object?>().equals(entries, other.entries) &&
          const ListEquality<Object?>().equals(
            placementConstraints,
            other.placementConstraints,
          );

  @override
  int get hashCode => Object.hash(
    const ListEquality<Object?>().hash(entries),
    const ListEquality<Object?>().hash(placementConstraints),
  );

  @override
  String toString() =>
      'ActionCollection(entries: ${entries.length}, roots: ${roots.length}, '
      'placementConstraints: ${placementConstraints.length})';
}

final class _ActionCollectionValidator<T extends Object> {
  _ActionCollectionValidator(this.roots, this.placementConstraints);

  final List<AdaptiveAction<T>> roots;
  final List<ActionPlacementConstraints> placementConstraints;
  final Set<ActionId> _actionIds = {};

  void validate() {
    _collectAndValidateActions();
    _validatePlacementConstraints();
  }

  void _collectAndValidateActions() {
    final visiting = Set<AdaptiveAction<T>>.identity();

    void visit(AdaptiveAction<T> action) {
      if (visiting.contains(action)) {
        throw ArgumentError.value(
          action.id,
          'roots',
          'action tree must not contain a cycle',
        );
      }
      if (!_actionIds.add(action.id)) {
        throw ArgumentError.value(
          action.id,
          'roots',
          'action IDs must be globally unique',
        );
      }

      visiting.add(action);
      for (final child in action.children) {
        if (child case final AdaptiveAction<T> childAction) {
          visit(childAction);
        }
      }
      visiting.remove(action);
    }

    for (final root in roots) {
      visit(root);
    }
  }

  void _validatePlacementConstraints() {
    final rootIds = roots.map((root) => root.id).toSet();

    final constraintIds = <ActionPlacementConstraintId>{};
    final constrainedActionIds = <ActionId>{};
    for (final constraints in placementConstraints) {
      if (!constraintIds.add(constraints.id)) {
        throw ArgumentError.value(
          constraints.id,
          'placementConstraints',
          'placement constraint IDs must be unique',
        );
      }

      for (final actionId in constraints.actionIds) {
        if (!_actionIds.contains(actionId)) {
          throw ArgumentError.value(
            actionId,
            'placementConstraints',
            'constrained action must reference an existing action',
          );
        }
        if (!rootIds.contains(actionId)) {
          throw ArgumentError.value(
            actionId,
            'placementConstraints',
            'constrained action must reference a root action',
          );
        }
        if (!constrainedActionIds.add(actionId)) {
          throw ArgumentError.value(
            actionId,
            'placementConstraints',
            'an action may have at most one placement constraint set',
          );
        }
      }
    }
  }
}
