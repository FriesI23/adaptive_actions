import 'package:collection/collection.dart';

import 'action_id.dart';

/// A renderer-owned way to draw an action in the primary region.
///
/// The [id] associates a resolver decision with renderer code, while [cost]
/// participates in capacity calculations. Core assigns no visual meaning to
/// either value.
final class ActionLayoutOption {
  /// Creates a layout option with an opaque [id] and non-negative [cost].
  ///
  /// Throws an [ArgumentError] when [cost] is not finite and a [RangeError]
  /// when it is negative.
  ActionLayoutOption({required this.id, required this.cost}) {
    _requireValidCost(cost, 'cost');
  }

  /// The key a renderer uses to find the matching widget builder.
  final ActionLayoutOptionId id;

  /// Space consumed in the renderer-defined capacity unit.
  final double cost;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionLayoutOption && id == other.id && cost == other.cost;

  @override
  int get hashCode => Object.hash(id, cost);

  @override
  String toString() => 'ActionLayoutOption(id: $id, cost: $cost)';
}

/// The primary-region layouts available for one root action.
///
/// Options are declared most-preferred first, but placement initially uses the
/// cheapest option. After primary actions are known, remaining capacity is
/// used to move back toward the preferred end:
///
/// ```text
/// preferred                                      fallback
/// [label + icon, cost 96] -> [icon, cost 48] -> [dot, cost 24]
///          ^ upgrade when space remains              ^ placement baseline
/// ```
final class ActionLayoutProfile {
  /// Creates the ordered layout choices for [actionId].
  ///
  /// Throws an [ArgumentError] when [options] is empty or repeats an option
  /// ID. The iterable is copied and cannot be changed through this profile.
  ActionLayoutProfile({
    required this.actionId,
    required Iterable<ActionLayoutOption> options,
  }) : options = List<ActionLayoutOption>.unmodifiable(options) {
    if (this.options.isEmpty) {
      throw ArgumentError.value(this.options, 'options', 'must not be empty');
    }
    final optionIds = <ActionLayoutOptionId>{};
    for (final option in this.options) {
      if (!optionIds.add(option.id)) {
        throw ArgumentError.value(
          option.id,
          'options',
          'must not contain duplicate option IDs',
        );
      }
    }
  }

  /// The root action these options can render.
  final ActionId actionId;

  /// Layout choices in preferred-to-fallback order.
  final List<ActionLayoutOption> options;

  /// Returns the option identified by [id], or `null` when absent.
  ActionLayoutOption? optionFor(ActionLayoutOptionId id) =>
      options.where((option) => option.id == id).firstOrNull;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionLayoutProfile &&
          actionId == other.actionId &&
          const ListEquality<ActionLayoutOption>().equals(
            options,
            other.options,
          );

  @override
  int get hashCode => Object.hash(
    actionId,
    const ListEquality<ActionLayoutOption>().hash(options),
  );

  @override
  String toString() =>
      'ActionLayoutProfile(actionId: $actionId, options: $options)';
}

/// Available primary space and renderer costs for one resolution pass.
final class ActionLayoutConstraints {
  /// Creates a snapshot of primary-region limits and [profiles].
  ///
  /// All costs use one renderer-defined unit and must be finite and
  /// non-negative. Duplicate action profiles throw an [ArgumentError]. A
  /// negative [maxPrimaryActions] throws a [RangeError].
  factory ActionLayoutConstraints({
    required double primaryCapacity,
    int? maxPrimaryActions,
    double overflowTriggerCost = 0,
    Iterable<ActionLayoutProfile> profiles = const [],
  }) {
    _requireValidCost(primaryCapacity, 'primaryCapacity');
    _requireValidCost(overflowTriggerCost, 'overflowTriggerCost');
    if (maxPrimaryActions case final value? when value < 0) {
      throw RangeError.range(value, 0, null, 'maxPrimaryActions');
    }

    final copiedProfiles = List<ActionLayoutProfile>.of(profiles);
    final profilesById = {
      for (final profile in copiedProfiles) profile.actionId: profile,
    };
    if (profilesById.length != copiedProfiles.length) {
      throw ArgumentError.value(
        copiedProfiles,
        'profiles',
        'must not contain duplicate action IDs',
      );
    }

    return ActionLayoutConstraints._(
      primaryCapacity: primaryCapacity,
      maxPrimaryActions: maxPrimaryActions,
      overflowTriggerCost: overflowTriggerCost,
      profiles: profilesById,
    );
  }

  ActionLayoutConstraints._({
    required this.primaryCapacity,
    required this.maxPrimaryActions,
    required this.overflowTriggerCost,
    required Map<ActionId, ActionLayoutProfile> profiles,
  }) : profiles = Map.unmodifiable(profiles);

  /// Total space available in the same unit as [ActionLayoutOption.cost].
  final double primaryCapacity;

  /// Optional upper bound on the number of primary root actions.
  final int? maxPrimaryActions;

  /// Space reserved for the control that opens a non-empty overflow region.
  final double overflowTriggerCost;

  /// Layout profiles keyed by root action ID.
  final Map<ActionId, ActionLayoutProfile> profiles;

  /// Returns the measured costs for [actionId], or `null` when absent.
  ActionLayoutProfile? profileFor(ActionId actionId) => profiles[actionId];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionLayoutConstraints &&
          primaryCapacity == other.primaryCapacity &&
          maxPrimaryActions == other.maxPrimaryActions &&
          overflowTriggerCost == other.overflowTriggerCost &&
          const MapEquality<ActionId, ActionLayoutProfile>().equals(
            profiles,
            other.profiles,
          );

  @override
  int get hashCode => Object.hash(
    primaryCapacity,
    maxPrimaryActions,
    overflowTriggerCost,
    const MapEquality<ActionId, ActionLayoutProfile>().hash(profiles),
  );

  @override
  String toString() =>
      'ActionLayoutConstraints(primaryCapacity: $primaryCapacity, '
      'maxPrimaryActions: $maxPrimaryActions, '
      'overflowTriggerCost: $overflowTriggerCost, '
      'profiles: $profiles)';
}

void _requireValidCost(double value, String name) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, name, 'must be finite');
  }
  if (value < 0) {
    throw RangeError.value(value, name, 'must not be negative');
  }
}
