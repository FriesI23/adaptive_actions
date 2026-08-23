import 'dart:collection';

import 'action_id.dart';
import 'action_layout.dart';
import 'action_placement_delegate.dart';
import 'adaptive_action.dart';

/// Produces the final, renderer-ready layout for one [ActionLayoutRequest].
///
/// The injected [placementDelegate] owns placement only. This resolver then
/// applies the request's independent primary and overflow order overrides so
/// renderers can consume [ActionLayoutResult] without repeating core decisions.
final class ActionLayoutResolver {
  /// Creates a layout resolver backed by [placementDelegate].
  const ActionLayoutResolver({
    this.placementDelegate = const DefaultActionPlacementDelegate(),
  });

  /// The placement strategy used before region ordering.
  final ActionPlacementDelegate placementDelegate;

  /// Resolves placement and region ordering without modifying [request].
  ActionLayoutResult<T> resolve<T extends Object>(
    ActionLayoutRequest<T> request,
  ) {
    final placement = placementDelegate.resolve(request);
    final primary = _applySlotPreservingOrderOverride<ResolvedPrimaryAction<T>>(
      entries: placement.primary,
      orderOverride: request.primaryOrderOverride,
      actionIdOf: (entry) => entry.action.id,
    );
    final overflow = _applySlotPreservingOrderOverride<AdaptiveAction<T>>(
      entries: placement.overflow,
      orderOverride: request.overflowOrderOverride,
      actionIdOf: (action) => action.id,
    );

    return ActionLayoutResult(
      primary: primary,
      overflow: overflow,
      primaryDividerBeforeActionIds: _dividerBoundaries(
        declarations: request.actions.entries,
        orderedActionIds: primary.map((entry) => entry.action.id),
        menu: false,
      ),
      overflowDividerBeforeActionIds: _dividerBoundaries(
        declarations: request.actions.entries,
        orderedActionIds: overflow.map((action) => action.id),
        menu: true,
      ),
      hidden: placement.hidden,
      diagnostics: placement.diagnostics,
    );
  }

  List<ActionId> _dividerBoundaries<T extends Object>({
    required List<AdaptiveMenuEntry<T>> declarations,
    required Iterable<ActionId> orderedActionIds,
    required bool menu,
  }) {
    final groupByActionId = <ActionId, int>{};
    final boundaries =
        <
          ({
            AdaptiveMenuDivider<T> divider,
            ActionId? previousActionId,
            ActionId? nextActionId,
          })
        >[];
    final pendingBoundaryIndexes = <int>[];
    ActionId? previousActionId;
    var group = 0;
    for (final declaration in declarations) {
      switch (declaration) {
        case final AdaptiveAction<T> action:
          groupByActionId[action.id] = group;
          for (final index in pendingBoundaryIndexes) {
            final boundary = boundaries[index];
            boundaries[index] = (
              divider: boundary.divider,
              previousActionId: boundary.previousActionId,
              nextActionId: action.id,
            );
          }
          pendingBoundaryIndexes.clear();
          previousActionId = action.id;
        case final AdaptiveMenuDivider<T> divider:
          boundaries.add((
            divider: divider,
            previousActionId: previousActionId,
            nextActionId: null,
          ));
          pendingBoundaryIndexes.add(boundaries.length - 1);
          group += 1;
      }
    }

    final actionIds = orderedActionIds.toList(growable: false);
    final visibleActionIds = actionIds.toSet();
    final result = <ActionId>[];
    for (var index = 1; index < actionIds.length; index += 1) {
      final previousGroup = groupByActionId[actionIds[index - 1]];
      final currentGroup = groupByActionId[actionIds[index]];
      if (previousGroup == null ||
          currentGroup == null ||
          previousGroup == currentGroup) {
        continue;
      }
      final firstBoundary = previousGroup < currentGroup
          ? previousGroup
          : currentGroup;
      final lastBoundary = previousGroup < currentGroup
          ? currentGroup
          : previousGroup;
      final hasVisibleDivider = boundaries
          .getRange(firstBoundary, lastBoundary)
          .any(
            (boundary) =>
                boundary.previousActionId != null &&
                boundary.nextActionId != null &&
                visibleActionIds.contains(boundary.previousActionId) &&
                visibleActionIds.contains(boundary.nextActionId) &&
                (menu
                    ? boundary.divider.showInMenu
                    : boundary.divider.showInPrimary),
          );
      if (hasVisibleDivider) result.add(actionIds[index]);
    }
    return List.unmodifiable(result);
  }
}

/// Reorders only entries named by [orderOverride] within their original slots.
List<T> _applySlotPreservingOrderOverride<T extends Object>({
  required List<T> entries,
  required List<ActionId> orderOverride,
  required ActionId Function(T entry) actionIdOf,
}) {
  final entriesById = <ActionId, T>{
    for (final entry in entries) actionIdOf(entry): entry,
  };
  final replacements = ListQueue<T>();
  final participatingIds = <ActionId>{};

  for (final id in orderOverride) {
    final entry = entriesById[id];
    if (entry != null) {
      replacements.addLast(entry);
      participatingIds.add(id);
    }
  }

  final result = <T>[];

  for (final entry in entries) {
    if (participatingIds.contains(actionIdOf(entry))) {
      result.add(replacements.removeFirst());
    } else {
      result.add(entry);
    }
  }

  return result;
}
