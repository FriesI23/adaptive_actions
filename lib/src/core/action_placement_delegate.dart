import 'action_id.dart';
import 'action_layout.dart';
import 'action_layout_constraints.dart';
import 'action_placement_constraints.dart';
import 'action_placement_policy.dart';
import 'action_resolver/action_placement_input_normalization.dart';
import 'action_resolver/action_resolver_diagnostics.dart';
import 'adaptive_action.dart';

typedef _AutomaticPlacementPass<T extends Object> = ({
  List<_AutomaticLayoutUnit<T>> primary,
  List<_AutomaticLayoutUnit<T>> secondary,
});

/// Assigns action roots to primary, overflow, or hidden regions.
abstract interface class ActionPlacementDelegate {
  /// The placement for [request] without modifying any input collection.
  ActionPlacementResult<T> resolve<T extends Object>(
    ActionLayoutRequest<T> request,
  );
}

/// The standard deterministic implementation of [ActionPlacementDelegate].
///
/// `ActionLayoutResolver` uses this delegate by default, then applies region
/// order overrides before a renderer receives its final result. Call this class
/// directly only when a custom pipeline needs the intermediate placement.
final class DefaultActionPlacementDelegate implements ActionPlacementDelegate {
  /// Creates a stateless delegate that can be safely reused.
  const DefaultActionPlacementDelegate();

  @override
  ActionPlacementResult<T> resolve<T extends Object>(
    ActionLayoutRequest<T> request,
  ) {
    final units = _LayoutUnitBuilder(request.normalizedPlacementInput).build();
    final placement = _ActionPlacementAllocator<T>(
      request.constraints,
    ).allocate(units);
    final selectedPrimary = _selectPrimaryOptions(
      placement: placement,
      constraints: request.constraints,
    );

    return _buildPlacementResult(
      roots: request.actions.roots,
      constraints: request.constraints,
      placement: placement,
      selectedPrimary: selectedPrimary,
    );
  }
}

/// Converts normalized action placement input into placement units.
final class _LayoutUnitBuilder<T extends Object> {
  _LayoutUnitBuilder(this.input);

  final NormalizedActionPlacementInput<T> input;

  List<_LayoutUnit<T>> build() {
    final units = <_LayoutUnit<T>>[];
    final builtConstraintIds = <ActionPlacementConstraintId>{};
    final constraintsByActionId = {
      for (final placementConstraints in input.placementConstraints)
        for (final member in placementConstraints.members)
          member.action.id: placementConstraints,
    };

    for (final root in input.roots) {
      final placementConstraints = constraintsByActionId[root.action.id];
      if (placementConstraints != null &&
          placementConstraints.constraints.splitPolicy ==
              ActionPlacementSplitPolicy.indivisible) {
        if (builtConstraintIds.add(placementConstraints.constraints.id)) {
          units.add(_buildIndivisibleConstraints(placementConstraints));
        }
      } else {
        units.add(_buildRoot(root));
      }
    }

    return units;
  }

  _LayoutUnit<T> _buildRoot(NormalizedActionRoot<T> root) {
    final policy = root.policy;
    return _LayoutUnit(
      members: [_buildMember(root)],
      policy: policy,
      allowsHiding: policy.allowsHiding,
      rootIndex: root.rootIndex,
    );
  }

  _LayoutUnit<T> _buildIndivisibleConstraints(
    NormalizedPlacementConstraints<T> placementConstraints,
  ) {
    final members = placementConstraints.members
        .map(_buildMember)
        .toList(growable: false);
    final policy = placementConstraints.members.first.policy;

    return _LayoutUnit(
      members: members,
      policy: policy,
      allowsHiding:
          policy.placement == ActionPlacement.automatic &&
          placementConstraints.members.every(
            (member) => member.policy.allowsHiding,
          ),
      rootIndex: placementConstraints.members
          .map((member) => member.rootIndex)
          .reduce((first, next) => first < next ? first : next),
    );
  }

  _LayoutUnitMember<T> _buildMember(NormalizedActionRoot<T> root) =>
      switch (root) {
        final NormalizedPrimaryActionRoot<T> primary =>
          _PrimaryLayoutUnitMember(
            action: primary.action,
            rootIndex: primary.rootIndex,
            profile: primary.profile,
          ),
        final NormalizedSecondaryActionRoot<T> secondary =>
          _SecondaryLayoutUnitMember(
            action: secondary.action,
            rootIndex: secondary.rootIndex,
          ),
      };
}

/// One root within an atomic placement unit.
sealed class _LayoutUnitMember<T extends Object> {
  const _LayoutUnitMember({required this.action, required this.rootIndex});

  final AdaptiveAction<T> action;
  final int rootIndex;
}

/// One root with the renderer candidates required for primary placement.
final class _PrimaryLayoutUnitMember<T extends Object>
    extends _LayoutUnitMember<T> {
  _PrimaryLayoutUnitMember({
    required super.action,
    required super.rootIndex,
    required this.profile,
  }) : minimumOption = profile._minimumOption;

  final ActionLayoutProfile profile;
  final ActionLayoutOption minimumOption;
  late ActionLayoutOption selectedOption = minimumOption;
}

/// One root whose effective policy cannot enter primary.
final class _SecondaryLayoutUnitMember<T extends Object>
    extends _LayoutUnitMember<T> {
  const _SecondaryLayoutUnitMember({
    required super.action,
    required super.rootIndex,
  });
}

/// One atomic placement unit after shared placement constraints are applied.
sealed class _LayoutUnit<T extends Object> {
  factory _LayoutUnit({
    required List<_LayoutUnitMember<T>> members,
    required EffectiveActionPolicy policy,
    required bool allowsHiding,
    required int rootIndex,
  }) {
    final primaryMembers = members
        .whereType<_PrimaryLayoutUnitMember<T>>()
        .toList(growable: false);
    final minimumCost = primaryMembers.fold<double>(
      0,
      (total, member) => total + member.minimumOption.cost,
    );
    return switch (policy) {
      final EffectiveAutomaticActionPolicy automatic => _AutomaticLayoutUnit._(
        members: members,
        primaryMembers: primaryMembers,
        retentionPriority: automatic.retentionPriority,
        allowsHiding: allowsHiding,
        rootIndex: rootIndex,
        minimumCost: minimumCost,
      ),
      final EffectiveFixedActionPolicy fixed => _FixedLayoutUnit._(
        members: members,
        primaryMembers: primaryMembers,
        placement: fixed.placement,
        rootIndex: rootIndex,
        minimumCost: minimumCost,
      ),
    };
  }

  _LayoutUnit._({
    required this.members,
    required this.primaryMembers,
    required this.placement,
    required this.allowsHiding,
    required this.rootIndex,
    required this.minimumCost,
  }) : rootCount = members.length;

  final List<_LayoutUnitMember<T>> members;
  final List<_PrimaryLayoutUnitMember<T>> primaryMembers;
  final ActionPlacement placement;
  final bool allowsHiding;
  final int rootIndex;
  final int rootCount;
  final double minimumCost;

  Iterable<ActionId> get actionIds => members.map((member) => member.action.id);
}

final class _AutomaticLayoutUnit<T extends Object> extends _LayoutUnit<T> {
  _AutomaticLayoutUnit._({
    required super.members,
    required super.primaryMembers,
    required this.retentionPriority,
    required super.allowsHiding,
    required super.rootIndex,
    required super.minimumCost,
  }) : super._(placement: ActionPlacement.automatic);

  final PrimaryRetentionPriority retentionPriority;
}

final class _FixedLayoutUnit<T extends Object> extends _LayoutUnit<T> {
  _FixedLayoutUnit._({
    required super.members,
    required super.primaryMembers,
    required super.placement,
    required super.rootIndex,
    required super.minimumCost,
  }) : super._(allowsHiding: false);
}

/// Applies fixed placement, capacity, overflow-trigger, and hiding rules.
final class _ActionPlacementAllocator<T extends Object> {
  const _ActionPlacementAllocator(this.constraints);

  final ActionLayoutConstraints constraints;

  _PlacementAllocation<T> allocate(List<_LayoutUnit<T>> units) {
    final pinned = units._withPlacement(ActionPlacement.pinned);
    final forcedOverflow = units._withPlacement(ActionPlacement.overflowOnly);
    final forcedHidden = units._withPlacement(ActionPlacement.hidden);
    final automatic = units.whereType<_AutomaticLayoutUnit<T>>().toList()
      ..sort(_compareAutomaticUnits);

    final pinnedCost = pinned._totalMinimumCost;
    final pinnedCount = pinned._totalRootCount;
    final firstPass = _placeAutomaticWithinCapacity(
      automatic,
      pinnedCost: pinnedCost,
      pinnedCount: pinnedCount,
      reserveOverflowTrigger: forcedOverflow.isNotEmpty,
    );

    if (forcedOverflow.isNotEmpty) {
      return _createAllocation(
        pinned: pinned,
        forcedOverflow: forcedOverflow,
        forcedHidden: forcedHidden,
        pass: firstPass,
        hasOverflow: true,
      );
    }
    if (firstPass.secondary.isEmpty) {
      return _createAllocation(
        pinned: pinned,
        forcedOverflow: forcedOverflow,
        forcedHidden: forcedHidden,
        pass: firstPass,
        hasOverflow: false,
      );
    }
    if (_canHideInsteadOfExposeOverflow(
      firstPass.secondary,
      pinnedCost: pinnedCost,
    )) {
      return _createAllocation(
        pinned: pinned,
        forcedOverflow: forcedOverflow,
        forcedHidden: forcedHidden,
        pass: firstPass,
        capacityHidden: firstPass.secondary,
        hasOverflow: false,
      );
    }

    final secondPass = _placeAutomaticWithinCapacity(
      automatic,
      pinnedCost: pinnedCost,
      pinnedCount: pinnedCount,
      reserveOverflowTrigger: true,
    );
    return _createAllocation(
      pinned: pinned,
      forcedOverflow: forcedOverflow,
      forcedHidden: forcedHidden,
      pass: secondPass,
      hasOverflow: true,
    );
  }

  _AutomaticPlacementPass<T> _placeAutomaticWithinCapacity(
    List<_AutomaticLayoutUnit<T>> automatic, {
    required double pinnedCost,
    required int pinnedCount,
    required bool reserveOverflowTrigger,
  }) {
    var usedCost =
        pinnedCost +
        (reserveOverflowTrigger ? constraints.overflowTriggerCost : 0);
    var usedCount = pinnedCount;
    final primary = <_AutomaticLayoutUnit<T>>[];
    final secondary = <_AutomaticLayoutUnit<T>>[];

    for (final unit in automatic) {
      final nextCost = usedCost + unit.minimumCost;
      final nextCount = usedCount + unit.rootCount;
      if (_fitsPrimaryCapacity(cost: nextCost, count: nextCount)) {
        primary.add(unit);
        usedCost = nextCost;
        usedCount = nextCount;
      } else {
        secondary.add(unit);
      }
    }

    return (primary: primary, secondary: secondary);
  }

  bool _fitsPrimaryCapacity({required double cost, required int count}) {
    final maxPrimaryActions = constraints.maxPrimaryActions;
    return cost <= constraints.primaryCapacity &&
        (maxPrimaryActions == null || count <= maxPrimaryActions);
  }

  bool _canHideInsteadOfExposeOverflow(
    List<_AutomaticLayoutUnit<T>> secondary, {
    required double pinnedCost,
  }) =>
      pinnedCost <= constraints.primaryCapacity &&
      pinnedCost + constraints.overflowTriggerCost >
          constraints.primaryCapacity &&
      secondary.every((unit) => unit.allowsHiding);

  _PlacementAllocation<T> _createAllocation({
    required List<_LayoutUnit<T>> pinned,
    required List<_LayoutUnit<T>> forcedOverflow,
    required List<_LayoutUnit<T>> forcedHidden,
    required _AutomaticPlacementPass<T> pass,
    required bool hasOverflow,
    List<_AutomaticLayoutUnit<T>> capacityHidden = const [],
  }) => _PlacementAllocation(
    pinned: pinned,
    forcedOverflow: forcedOverflow,
    forcedHidden: forcedHidden,
    primaryAutomatic: pass.primary,
    secondaryAutomatic: pass.secondary,
    capacityHidden: capacityHidden,
    hasOverflow: hasOverflow,
  );
}

/// The categorized units produced by primary-capacity allocation.
final class _PlacementAllocation<T extends Object> {
  _PlacementAllocation({
    required this.pinned,
    required this.forcedOverflow,
    required this.forcedHidden,
    required this.primaryAutomatic,
    required this.secondaryAutomatic,
    required this.capacityHidden,
    required this.hasOverflow,
  });

  final List<_LayoutUnit<T>> pinned;
  final List<_LayoutUnit<T>> forcedOverflow;
  final List<_LayoutUnit<T>> forcedHidden;
  final List<_AutomaticLayoutUnit<T>> primaryAutomatic;
  final List<_AutomaticLayoutUnit<T>> secondaryAutomatic;
  final List<_AutomaticLayoutUnit<T>> capacityHidden;
  final bool hasOverflow;

  Iterable<_LayoutUnit<T>> get primaryUnits => [...pinned, ...primaryAutomatic];

  Iterable<_LayoutUnit<T>> get overflowUnits => [
    ...forcedOverflow,
    if (hasOverflow) ...secondaryAutomatic,
  ];
}

/// Selects renderer-preferred options after primary placement is fixed.
List<_PrimaryLayoutUnitMember<T>> _selectPrimaryOptions<T extends Object>({
  required _PlacementAllocation<T> placement,
  required ActionLayoutConstraints constraints,
}) {
  final selected = <_PrimaryLayoutUnitMember<T>>[
    for (final unit in placement.primaryUnits) ...unit.primaryMembers,
  ];
  var usedCost = selected.fold<double>(
    placement.hasOverflow ? constraints.overflowTriggerCost : 0,
    (total, member) => total + member.selectedOption.cost,
  );

  for (final unit in _primaryOptionUpgradeOrder(placement)) {
    for (final member in unit.primaryMembers) {
      final current = member.selectedOption;
      final upgraded = member.profile.options.firstWhere(
        (option) =>
            usedCost - current.cost + option.cost <=
            constraints.primaryCapacity,
        orElse: () => current,
      );
      member.selectedOption = upgraded;
      usedCost += upgraded.cost - current.cost;
    }
  }

  return selected;
}

List<_LayoutUnit<T>> _primaryOptionUpgradeOrder<T extends Object>(
  _PlacementAllocation<T> placement,
) {
  final automatic = placement.primaryAutomatic.toList()
    ..sort(_compareAutomaticUnits);
  return [...placement.pinned, ...automatic];
}

/// Restores root order and creates the immutable public result.
ActionPlacementResult<T> _buildPlacementResult<T extends Object>({
  required List<AdaptiveAction<T>> roots,
  required ActionLayoutConstraints constraints,
  required _PlacementAllocation<T> placement,
  required List<_PrimaryLayoutUnitMember<T>> selectedPrimary,
}) {
  final decisions = <_RootDecision<T>>[
    for (final member in selectedPrimary)
      _PrimaryDecision(
        rootIndex: member.rootIndex,
        resolved: ResolvedPrimaryAction(
          action: member.action,
          optionId: member.selectedOption.id,
        ),
      ),
    for (final unit in placement.overflowUnits)
      for (final member in unit.members)
        _OverflowDecision(rootIndex: member.rootIndex, action: member.action),
    for (final unit in placement.forcedHidden)
      for (final member in unit.members)
        _HiddenDecision(
          rootIndex: member.rootIndex,
          hidden: HiddenAction(
            action: member.action,
            reason: HiddenActionReason.forcedHidden,
          ),
        ),
    for (final unit in placement.capacityHidden)
      for (final member in unit.members)
        _HiddenDecision(
          rootIndex: member.rootIndex,
          hidden: HiddenAction(
            action: member.action,
            reason: HiddenActionReason.insufficientCapacity,
          ),
        ),
  ]..sort((first, second) => first.rootIndex.compareTo(second.rootIndex));
  final diagnostics = buildResolutionDiagnostics(
    roots: roots,
    constraints: constraints,
    forcedHiddenIds: placement.forcedHidden._actionIds,
    insufficientCapacityIds: placement.secondaryAutomatic._actionIds,
    pinnedIds: placement.pinned._actionIds,
    hasOverflow: placement.hasOverflow,
    selectedPinnedCost: placement.pinned.fold(
      0,
      (total, unit) =>
          total +
          unit.primaryMembers.fold(
            0,
            (unitTotal, member) => unitTotal + member.selectedOption.cost,
          ),
    ),
  );

  return ActionPlacementResult(
    primary: decisions.whereType<_PrimaryDecision<T>>().map(
      (decision) => decision.resolved,
    ),
    overflow: decisions.whereType<_OverflowDecision<T>>().map(
      (decision) => decision.action,
    ),
    hidden: decisions.whereType<_HiddenDecision<T>>().map(
      (decision) => decision.hidden,
    ),
    diagnostics: diagnostics,
  );
}

sealed class _RootDecision<T extends Object> {
  const _RootDecision({required this.rootIndex});

  final int rootIndex;
}

final class _PrimaryDecision<T extends Object> extends _RootDecision<T> {
  const _PrimaryDecision({required super.rootIndex, required this.resolved});

  final ResolvedPrimaryAction<T> resolved;
}

final class _OverflowDecision<T extends Object> extends _RootDecision<T> {
  const _OverflowDecision({required super.rootIndex, required this.action});

  final AdaptiveAction<T> action;
}

final class _HiddenDecision<T extends Object> extends _RootDecision<T> {
  const _HiddenDecision({required super.rootIndex, required this.hidden});

  final HiddenAction<T> hidden;
}

int _compareAutomaticUnits<T extends Object>(
  _AutomaticLayoutUnit<T> first,
  _AutomaticLayoutUnit<T> second,
) {
  final retentionOrder = second.retentionPriority.compareTo(
    first.retentionPriority,
  );
  return retentionOrder != 0
      ? retentionOrder
      : first.rootIndex.compareTo(second.rootIndex);
}

extension<T extends Object> on Iterable<_LayoutUnit<T>> {
  List<_LayoutUnit<T>> _withPlacement(ActionPlacement placement) =>
      where((unit) => unit.placement == placement).toList(growable: false);

  double get _totalMinimumCost =>
      fold(0, (total, unit) => total + unit.minimumCost);

  int get _totalRootCount => fold(0, (total, unit) => total + unit.rootCount);

  Set<ActionId> get _actionIds => {for (final unit in this) ...unit.actionIds};
}

extension on ActionLayoutProfile {
  ActionLayoutOption get _minimumOption =>
      options.reduce((best, option) => option.cost < best.cost ? option : best);
}
