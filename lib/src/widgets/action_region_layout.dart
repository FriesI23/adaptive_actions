import 'package:flutter/widgets.dart';

import '../../core.dart';

/// The built-in horizontal distribution used by one action region.
enum ActionRegionMainAxisDistribution {
  /// Keeps every slot at its minimum extent and shrink-wraps the region.
  compact,

  /// Shares finite remaining space between rendered slots.
  spaceBetween,

  /// Shares finite remaining space around rendered slots.
  spaceAround,

  /// Shares finite remaining space evenly around rendered slots.
  spaceEvenly,
}

/// Whether a flexible action slot must consume its allocated share.
enum ActionRegionFlexFit {
  /// The slot consumes its complete weighted share.
  tight,

  /// The slot keeps its minimum extent and leaves its share unconsumed.
  loose,
}

/// Identifies one package-owned slot in an action-region layout plan.
extension type const ActionRegionLayoutSlotId._(ActionId? _actionId) {
  /// Identifies the slot for [actionId].
  const ActionRegionLayoutSlotId.action(ActionId actionId) : this._(actionId);

  /// Identifies the region's unique global-overflow trigger.
  const ActionRegionLayoutSlotId.overflow() : this._(null);

  /// The action represented by this ID, or `null` for overflow.
  ActionId? get actionId => _actionId;

  /// Whether this ID represents the global-overflow trigger.
  bool get isOverflow => _actionId == null;
}

/// A read-only description of one resolved package-owned slot.
final class ActionRegionLayoutSlot {
  /// Creates a slot description.
  factory ActionRegionLayoutSlot({
    required ActionRegionLayoutSlotId id,
    required double minimumExtent,
  }) {
    _ActionRegionLayoutValidation.extent(minimumExtent, 'minimumExtent');
    return ActionRegionLayoutSlot._(id: id, minimumExtent: minimumExtent);
  }

  const ActionRegionLayoutSlot._({
    required this.id,
    required this.minimumExtent,
  });

  /// The stable slot identity used by layout plans.
  final ActionRegionLayoutSlotId id;

  /// The finite, non-negative width required by placement resolution.
  final double minimumExtent;
}

/// Describes whether one action slot is fixed or flexible.
sealed class ActionRegionExtent {
  const ActionRegionExtent._();

  /// Keeps the slot at its minimum extent.
  const factory ActionRegionExtent.fixed() = ActionRegionFixedExtent;

  /// Lets the slot participate in weighted remainder allocation.
  factory ActionRegionExtent.flex({int flex, ActionRegionFlexFit fit}) =
      ActionRegionFlexibleExtent;
}

/// A fixed action-slot extent.
final class ActionRegionFixedExtent extends ActionRegionExtent {
  /// Creates a fixed extent.
  const ActionRegionFixedExtent() : super._();
}

/// A weighted flexible action-slot extent.
final class ActionRegionFlexibleExtent extends ActionRegionExtent {
  /// Creates a validated flexible extent.
  factory ActionRegionFlexibleExtent({
    int flex = 1,
    ActionRegionFlexFit fit = ActionRegionFlexFit.tight,
  }) {
    if (flex <= 0) {
      throw RangeError.value(flex, 'flex', 'must be positive');
    }
    return ActionRegionFlexibleExtent._(flex: flex, fit: fit);
  }

  const ActionRegionFlexibleExtent._({required this.flex, required this.fit})
    : super._();

  /// The positive remainder-allocation weight.
  final int flex;

  /// Whether the slot must consume its complete share.
  final ActionRegionFlexFit fit;
}

/// One validated entry in an action-region layout plan.
sealed class ActionRegionLayoutEntry {
  const ActionRegionLayoutEntry._();

  /// Places one package-owned slot.
  const factory ActionRegionLayoutEntry.slot(
    ActionRegionLayoutSlotId id, {
    ActionRegionExtent extent,
  }) = ActionRegionSlotLayoutEntry;

  /// Inserts a structural gap with an exact width, like a horizontal SizedBox.
  factory ActionRegionLayoutEntry.fixedGap(double extent) =
      ActionRegionFixedGapLayoutEntry;

  /// Inserts an Expanded-like gap that shares finite remaining width.
  factory ActionRegionLayoutEntry.flexGap({int flex}) =
      ActionRegionFlexGapLayoutEntry;
}

/// A package-owned slot entry in a layout plan.
final class ActionRegionSlotLayoutEntry extends ActionRegionLayoutEntry {
  /// Creates a slot entry.
  const ActionRegionSlotLayoutEntry(
    this.id, {
    this.extent = const ActionRegionExtent.fixed(),
  }) : super._();

  /// The slot placed by this entry.
  final ActionRegionLayoutSlotId id;

  /// The slot's fixed or flexible allocation behavior.
  final ActionRegionExtent extent;
}

/// A structural fixed-gap entry in a layout plan.
final class ActionRegionFixedGapLayoutEntry extends ActionRegionLayoutEntry {
  /// Creates a validated fixed gap.
  factory ActionRegionFixedGapLayoutEntry(double extent) {
    if (!extent.isFinite) {
      throw ArgumentError.value(extent, 'extent', 'must be finite');
    }
    if (extent < 0) {
      throw RangeError.value(extent, 'extent', 'must not be negative');
    }
    return ActionRegionFixedGapLayoutEntry._(extent);
  }

  const ActionRegionFixedGapLayoutEntry._(this.extent) : super._();

  /// The exact structural width reserved before resolution.
  final double extent;
}

/// A weighted, zero-minimum flex-gap entry in a layout plan.
final class ActionRegionFlexGapLayoutEntry extends ActionRegionLayoutEntry {
  /// Creates a validated flexible gap.
  factory ActionRegionFlexGapLayoutEntry({int flex = 1}) {
    if (flex <= 0) {
      throw RangeError.value(flex, 'flex', 'must be positive');
    }
    return ActionRegionFlexGapLayoutEntry._(flex);
  }

  const ActionRegionFlexGapLayoutEntry._(this.flex) : super._();

  /// The positive remainder-allocation weight.
  final int flex;
}

/// Input available before the single Core resolution for a layout pass.
final class ActionRegionLayoutReservationInput {
  /// Creates immutable reservation input.
  factory ActionRegionLayoutReservationInput({
    required BoxConstraints constraints,
    required TextDirection textDirection,
    required double primaryCapacity,
    required Iterable<ActionId> actionIds,
  }) {
    _ActionRegionLayoutValidation.extent(primaryCapacity, 'primaryCapacity');
    return ActionRegionLayoutReservationInput._(
      constraints: constraints,
      textDirection: textDirection,
      primaryCapacity: primaryCapacity,
      actionIds: List<ActionId>.unmodifiable(actionIds),
    );
  }

  const ActionRegionLayoutReservationInput._({
    required this.constraints,
    required this.textDirection,
    required this.primaryCapacity,
    required this.actionIds,
  });

  /// The outer Flutter constraints for the region.
  final BoxConstraints constraints;

  /// The ambient text direction.
  final TextDirection textDirection;

  /// The caller-provided placement capacity before fixed reservations.
  final double primaryCapacity;

  /// All root action IDs available before placement.
  final List<ActionId> actionIds;
}

/// A structural width reservation made before Core resolution.
final class ActionRegionLayoutReservation {
  /// Creates a validated reservation.
  factory ActionRegionLayoutReservation({double fixedExtent = 0}) {
    if (!fixedExtent.isFinite) {
      throw ArgumentError.value(fixedExtent, 'fixedExtent', 'must be finite');
    }
    if (fixedExtent < 0) {
      throw RangeError.value(
        fixedExtent,
        'fixedExtent',
        'must not be negative',
      );
    }
    return ActionRegionLayoutReservation._(fixedExtent);
  }

  const ActionRegionLayoutReservation._(this.fixedExtent);

  /// The fixed width subtracted from placement capacity.
  final double fixedExtent;
}

/// Input available after the single Core resolution for a layout pass.
final class ActionRegionLayoutInput {
  /// Creates immutable post-resolution layout input.
  factory ActionRegionLayoutInput({
    required BoxConstraints constraints,
    required TextDirection textDirection,
    required double primaryCapacity,
    required double? targetExtent,
    required ActionRegionLayoutReservation reservation,
    required Iterable<ActionRegionLayoutSlot> slots,
  }) {
    _ActionRegionLayoutValidation.extent(primaryCapacity, 'primaryCapacity');
    if (targetExtent != null) {
      _ActionRegionLayoutValidation.extent(targetExtent, 'targetExtent');
    }
    return ActionRegionLayoutInput._(
      constraints: constraints,
      textDirection: textDirection,
      primaryCapacity: primaryCapacity,
      targetExtent: targetExtent,
      reservation: reservation,
      slots: List<ActionRegionLayoutSlot>.unmodifiable(slots),
    );
  }

  const ActionRegionLayoutInput._({
    required this.constraints,
    required this.textDirection,
    required this.primaryCapacity,
    required this.targetExtent,
    required this.reservation,
    required this.slots,
  });

  /// The outer Flutter constraints for the region.
  final BoxConstraints constraints;

  /// The ambient text direction.
  final TextDirection textDirection;

  /// The effective placement capacity after fixed reservations.
  final double primaryCapacity;

  /// The finite allocation target for flex entries, or `null` if unbounded.
  final double? targetExtent;

  /// The reservation used for the completed resolution.
  final ActionRegionLayoutReservation reservation;

  /// The resolved slots in renderer order, including the optional More slot.
  final List<ActionRegionLayoutSlot> slots;
}

/// An immutable requested ordering and allocation plan for one region.
final class ActionRegionLayoutPlan {
  /// Creates a layout plan from [entries].
  ActionRegionLayoutPlan({required Iterable<ActionRegionLayoutEntry> entries})
    : entries = List<ActionRegionLayoutEntry>.unmodifiable(entries);

  /// The ordered slot and gap entries.
  final List<ActionRegionLayoutEntry> entries;
}

/// Provides the two-stage layout policy around one Core resolution.
abstract interface class ActionRegionLayoutDelegate {
  /// Declares fixed structural width before placement resolution.
  ActionRegionLayoutReservation reserve(
    ActionRegionLayoutReservationInput input,
  );

  /// Builds the final plan from the immutable resolved slot snapshot.
  ActionRegionLayoutPlan layout(ActionRegionLayoutInput input);
}

final class _ActionRegionLayoutValidation {
  const _ActionRegionLayoutValidation._();

  static void extent(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
    if (value < 0) {
      throw RangeError.value(value, name, 'must not be negative');
    }
  }
}
