// Package-internal pipeline types are intentionally not part of the public API.
// ignore_for_file: public_member_api_docs

import '../action_collection.dart';
import '../action_layout_constraints.dart';
import '../action_placement_constraints.dart';
import '../action_placement_policy.dart';
import '../adaptive_action.dart';

/// One placement constraint paired with its normalized roots.
typedef NormalizedPlacementConstraints<T extends Object> = ({
  ActionPlacementConstraints constraints,
  List<NormalizedActionRoot<T>> members,
});

/// Package-internal placement data normalized at the request boundary.
typedef NormalizedActionPlacementInput<T extends Object> = ({
  List<NormalizedActionRoot<T>> roots,
  List<NormalizedPlacementConstraints<T>> placementConstraints,
});

/// Package-internal policy after applying shared placement constraints.
sealed class EffectiveActionPolicy {
  const EffectiveActionPolicy();

  ActionPlacement get placement;
  bool get allowsHiding;

  EffectiveFixedActionPolicy withPlacementOverride(ActionPlacement placement) =>
      EffectiveFixedActionPolicy(placement);
}

final class EffectiveAutomaticActionPolicy extends EffectiveActionPolicy {
  const EffectiveAutomaticActionPolicy({
    required this.retentionPriority,
    required this.allowsHiding,
  });

  @override
  ActionPlacement get placement => ActionPlacement.automatic;

  final PrimaryRetentionPriority retentionPriority;

  @override
  final bool allowsHiding;

  EffectiveAutomaticActionPolicy withRetentionPriority(
    PrimaryRetentionPriority retentionPriority,
  ) => EffectiveAutomaticActionPolicy(
    retentionPriority: retentionPriority,
    allowsHiding: allowsHiding,
  );
}

final class EffectiveFixedActionPolicy extends EffectiveActionPolicy {
  const EffectiveFixedActionPolicy(this.placement);

  @override
  final ActionPlacement placement;

  @override
  bool get allowsHiding => false;
}

/// One root paired with its normalized policy and stable declaration order.
sealed class NormalizedActionRoot<T extends Object> {
  const NormalizedActionRoot({
    required this.action,
    required this.policy,
    required this.rootIndex,
  });

  final AdaptiveAction<T> action;
  final EffectiveActionPolicy policy;
  final int rootIndex;
}

final class NormalizedPrimaryActionRoot<T extends Object>
    extends NormalizedActionRoot<T> {
  const NormalizedPrimaryActionRoot({
    required super.action,
    required super.policy,
    required super.rootIndex,
    required this.profile,
  });

  final ActionLayoutProfile profile;
}

final class NormalizedSecondaryActionRoot<T extends Object>
    extends NormalizedActionRoot<T> {
  const NormalizedSecondaryActionRoot({
    required super.action,
    required super.policy,
    required super.rootIndex,
  });
}

final class _MutableActionRoot<T extends Object> {
  _MutableActionRoot({
    required this.action,
    required this.policy,
    required this.rootIndex,
  });

  final AdaptiveAction<T> action;
  EffectiveActionPolicy policy;
  final int rootIndex;
}

/// Normalizes an action collection for one placement decision.
extension ActionCollectionPlacementNormalization<T extends Object>
    on ActionCollection<T> {
  /// Applies renderer constraints and returns placement-ready action data.
  NormalizedActionPlacementInput<T> normalizeForPlacement(
    ActionLayoutConstraints constraints,
  ) => _ActionPlacementInputNormalizer(
    actions: this,
    constraints: constraints,
  ).normalize();
}

final class _ActionPlacementInputNormalizer<T extends Object> {
  _ActionPlacementInputNormalizer({
    required this.actions,
    required this.constraints,
  });

  final ActionCollection<T> actions;
  final ActionLayoutConstraints constraints;

  NormalizedActionPlacementInput<T> normalize() {
    _validateLayoutProfileReferences();
    final mutableRoots = _resolveEffectivePolicies();
    final roots = _freezeNormalizedRoots(mutableRoots);

    return (
      roots: roots,
      placementConstraints: _normalizePlacementConstraints(roots),
    );
  }

  void _validateLayoutProfileReferences() {
    final rootIds = actions.roots.map((action) => action.id).toSet();
    final unknownProfileId = constraints.profiles.keys
        .where((actionId) => !rootIds.contains(actionId))
        .firstOrNull;
    if (unknownProfileId != null) {
      throw ArgumentError.value(
        unknownProfileId,
        'constraints.profiles',
        'must reference a root action',
      );
    }
  }

  List<_MutableActionRoot<T>> _resolveEffectivePolicies() {
    final roots = [
      for (final (rootIndex, root) in actions.roots.indexed)
        _MutableActionRoot(
          action: root,
          rootIndex: rootIndex,
          policy: switch (root.placementPolicy.automaticPreference) {
            final preference? => EffectiveAutomaticActionPolicy(
              retentionPriority: preference.retentionPriority,
              allowsHiding: preference.allowsHiding,
            ),
            null => EffectiveFixedActionPolicy(root.placementPolicy.placement),
          },
        ),
    ];

    for (final placementConstraints in actions.placementConstraints) {
      _applyPlacementConstraints(placementConstraints, roots);
    }
    return roots;
  }

  void _applyPlacementConstraints(
    ActionPlacementConstraints placementConstraints,
    List<_MutableActionRoot<T>> roots,
  ) {
    if (placementConstraints.placementOverride case final placementOverride?) {
      _replaceConstrainedPolicies(
        placementConstraints,
        roots,
        (policy) => policy.withPlacementOverride(placementOverride),
      );
      return;
    }

    if (placementConstraints.splitPolicy ==
        ActionPlacementSplitPolicy.splittable) {
      _applySplittableRetentionPriority(placementConstraints, roots);
      return;
    }

    _applyIndivisiblePolicy(placementConstraints, roots);
  }

  void _applySplittableRetentionPriority(
    ActionPlacementConstraints placementConstraints,
    List<_MutableActionRoot<T>> roots,
  ) {
    if (placementConstraints.retentionPriority case final retentionPriority?) {
      _replaceConstrainedPolicies(
        placementConstraints,
        roots,
        (policy) => switch (policy) {
          final EffectiveAutomaticActionPolicy automatic =>
            automatic.withRetentionPriority(retentionPriority),
          final EffectiveFixedActionPolicy fixed => fixed,
        },
      );
    }
  }

  void _applyIndivisiblePolicy(
    ActionPlacementConstraints placementConstraints,
    List<_MutableActionRoot<T>> roots,
  ) {
    final constrainedActionIds = placementConstraints.actionIds.toSet();
    final constrainedPolicies = roots
        .where((root) => constrainedActionIds.contains(root.action.id))
        .map((root) => root.policy);
    final fixedPlacements = constrainedPolicies
        .whereType<EffectiveFixedActionPolicy>()
        .map((policy) => policy.placement)
        .toSet();

    if (fixedPlacements.length > 1) {
      throw ArgumentError.value(
        placementConstraints.id,
        'actions.placementConstraints',
        'indivisible constraints have conflicting placement overrides',
      );
    }

    if (fixedPlacements.firstOrNull case final placementOverride?) {
      _replaceConstrainedPolicies(
        placementConstraints,
        roots,
        (policy) => policy.withPlacementOverride(placementOverride),
      );
      return;
    }

    final retentionPriority = placementConstraints.retentionPriority;
    if (retentionPriority == null) {
      throw ArgumentError.value(
        placementConstraints.id,
        'actions.placementConstraints',
        'indivisible automatic constraints require a retention priority',
      );
    }
    _replaceConstrainedPolicies(
      placementConstraints,
      roots,
      (policy) => switch (policy) {
        final EffectiveAutomaticActionPolicy automatic =>
          automatic.withRetentionPriority(retentionPriority),
        final EffectiveFixedActionPolicy fixed => fixed,
      },
    );
  }

  void _replaceConstrainedPolicies(
    ActionPlacementConstraints placementConstraints,
    List<_MutableActionRoot<T>> roots,
    EffectiveActionPolicy Function(EffectiveActionPolicy policy) replace,
  ) {
    final constrainedActionIds = placementConstraints.actionIds.toSet();
    for (final root in roots) {
      if (constrainedActionIds.contains(root.action.id)) {
        root.policy = replace(root.policy);
      }
    }
  }

  List<NormalizedActionRoot<T>> _freezeNormalizedRoots(
    List<_MutableActionRoot<T>> roots,
  ) {
    final normalizedRoots = <NormalizedActionRoot<T>>[];
    for (final root in roots) {
      if (root.policy.placement._mayEnterPrimary) {
        final profile = constraints.profileFor(root.action.id);
        if (profile == null) {
          throw ArgumentError.value(
            root.action.id,
            'constraints.profiles',
            'must provide options for every action that may enter primary',
          );
        }
        normalizedRoots.add(
          NormalizedPrimaryActionRoot(
            action: root.action,
            policy: root.policy,
            rootIndex: root.rootIndex,
            profile: profile,
          ),
        );
      } else {
        normalizedRoots.add(
          NormalizedSecondaryActionRoot(
            action: root.action,
            policy: root.policy,
            rootIndex: root.rootIndex,
          ),
        );
      }
    }
    return normalizedRoots;
  }

  List<NormalizedPlacementConstraints<T>> _normalizePlacementConstraints(
    List<NormalizedActionRoot<T>> roots,
  ) => [
    for (final placementConstraints in actions.placementConstraints)
      (
        constraints: placementConstraints,
        members: [
          for (final actionId in placementConstraints.actionIds)
            for (final root in roots)
              if (root.action.id == actionId) root,
        ],
      ),
  ];
}

extension on ActionPlacement {
  bool get _mayEnterPrimary =>
      this == ActionPlacement.pinned || this == ActionPlacement.automatic;
}
