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

    return ActionLayoutResult(
      primary: _applySlotPreservingOrderOverride<ResolvedPrimaryAction<T>>(
        entries: placement.primary,
        orderOverride: request.primaryOrderOverride,
        actionIdOf: (entry) => entry.action.id,
      ),
      overflow: _applySlotPreservingOrderOverride<AdaptiveAction<T>>(
        entries: placement.overflow,
        orderOverride: request.overflowOrderOverride,
        actionIdOf: (action) => action.id,
      ),
      hidden: placement.hidden,
      diagnostics: placement.diagnostics,
    );
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
