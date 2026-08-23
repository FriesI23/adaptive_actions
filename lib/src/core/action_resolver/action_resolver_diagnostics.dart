// Package-internal diagnostics are intentionally not part of the public API.
// ignore_for_file: public_member_api_docs

import '../action_id.dart';
import '../action_layout.dart';
import '../action_layout_constraints.dart';
import '../adaptive_action.dart';

/// Creates stable diagnostics without participating in placement decisions.
List<ResolutionDiagnostic> buildResolutionDiagnostics<T extends Object>({
  required List<AdaptiveAction<T>> roots,
  required ActionLayoutConstraints constraints,
  required Iterable<ActionId> forcedHiddenIds,
  required Iterable<ActionId> insufficientCapacityIds,
  required Iterable<ActionId> pinnedIds,
  required bool hasOverflow,
  required double selectedPinnedCost,
}) {
  final forcedHidden = forcedHiddenIds.toSet();
  final insufficientCapacity = insufficientCapacityIds.toSet();
  final pinned = pinnedIds.toSet();
  final diagnostics = <ResolutionDiagnostic>[
    if (forcedHidden.isNotEmpty)
      _diagnosticInRootOrder(
        roots,
        ResolutionDiagnosticCode.forcedHidden,
        forcedHidden,
      ),
    if (insufficientCapacity.isNotEmpty)
      _diagnosticInRootOrder(
        roots,
        ResolutionDiagnosticCode.insufficientCapacity,
        insufficientCapacity,
      ),
  ];

  if (_pinnedConstraintsAreUnsatisfied(
    constraints: constraints,
    pinnedIds: pinned,
    hasOverflow: hasOverflow,
    selectedPinnedCost: selectedPinnedCost,
  )) {
    diagnostics.add(
      _diagnosticInRootOrder(
        roots,
        ResolutionDiagnosticCode.unsatisfiedPinnedConstraint,
        pinned,
      ),
    );
  }
  return diagnostics;
}

bool _pinnedConstraintsAreUnsatisfied({
  required ActionLayoutConstraints constraints,
  required Set<ActionId> pinnedIds,
  required bool hasOverflow,
  required double selectedPinnedCost,
}) {
  final pinnedCost =
      selectedPinnedCost + (hasOverflow ? constraints.overflowTriggerCost : 0);
  final maxPrimaryActions = constraints.maxPrimaryActions;
  final exceedsCount =
      maxPrimaryActions != null && pinnedIds.length > maxPrimaryActions;
  return pinnedCost > constraints.primaryCapacity || exceedsCount;
}

ResolutionDiagnostic _diagnosticInRootOrder<T extends Object>(
  List<AdaptiveAction<T>> roots,
  ResolutionDiagnosticCode code,
  Set<ActionId> actionIds,
) => ResolutionDiagnostic(
  code: code,
  actionIds: roots
      .where((root) => actionIds.contains(root.id))
      .map((root) => root.id),
);
