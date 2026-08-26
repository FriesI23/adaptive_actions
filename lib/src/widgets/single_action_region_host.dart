import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../../core.dart';
import 'action_region_layout.dart';
import 'action_region_slot.dart';
import 'animated_action_region.dart';

/// Builds one immutable single-region snapshot from current constraints.
@internal
typedef SingleActionRegionSnapshotBuilder<T extends Object> =
    SingleActionRegionSnapshot<T> Function(
      BuildContext context,
      BoxConstraints constraints,
      double primaryCapacity,
    );

/// The resolved slots shared by composition and animation for one pass.
@internal
@immutable
final class SingleActionRegionSnapshot<T extends Object> {
  SingleActionRegionSnapshot({required Iterable<ActionRegionSlot<T>> slots})
    : slots = List<ActionRegionSlot<T>>.unmodifiable(slots) {
    final ids = <Object>{};
    final layoutIds = <ActionRegionLayoutSlotId>{};
    var overflowCount = 0;
    for (final (index, slot) in this.slots.indexed) {
      if (!ids.add(slot.id)) {
        throw ArgumentError.value(slots, 'slots', 'must have unique IDs');
      }
      if (!layoutIds.add(slot.layoutId)) {
        throw ArgumentError.value(
          slots,
          'slots',
          'must have unique layout IDs',
        );
      }
      if (slot.role == ActionRegionSlotRole.overflow) {
        overflowCount += 1;
        if (!slot.layoutId.isOverflow) {
          throw ArgumentError.value(
            slots,
            'slots',
            'overflow role must use the overflow layout ID',
          );
        }
        if (index != this.slots.length - 1) {
          throw ArgumentError.value(
            slots,
            'slots',
            'overflow must be the final slot',
          );
        }
      } else if (slot.layoutId.isOverflow) {
        throw ArgumentError.value(
          slots,
          'slots',
          'action role must use an action layout ID',
        );
      }
    }
    if (overflowCount > 1) {
      throw ArgumentError.value(
        slots,
        'slots',
        'must contain at most one overflow slot',
      );
    }
  }

  final List<ActionRegionSlot<T>> slots;
}

/// Resolves and composes one action region from parent constraints.
@internal
final class SingleActionRegionHost<T extends Object> extends StatelessWidget {
  const SingleActionRegionHost({
    super.key,
    required this.snapshotBuilder,
    required this.primaryCapacity,
    required this.actionIds,
    required this.height,
    required this.fadeDuration,
    required this.resizeDuration,
    required this.switchInCurve,
    required this.switchOutCurve,
    this.distribution = ActionRegionMainAxisDistribution.compact,
    this.layoutDelegate,
    this.variantBuilder,
  }) : assert(height > 0 && height < double.infinity),
       assert(primaryCapacity >= 0 && primaryCapacity < double.infinity),
       assert(
         layoutDelegate == null ||
             distribution == ActionRegionMainAxisDistribution.compact,
       );

  final SingleActionRegionSnapshotBuilder<T> snapshotBuilder;
  final double primaryCapacity;
  final Iterable<ActionId> actionIds;
  final double height;
  final Duration fadeDuration;
  final Duration resizeDuration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final ActionRegionMainAxisDistribution distribution;
  final ActionRegionLayoutDelegate? layoutDelegate;
  final AnimatedActionRegionVariantBuilder<T>? variantBuilder;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: LayoutBuilder(
      builder: (context, constraints) => _SingleActionRegionComposition<T>(
        host: this,
        context: context,
        constraints: constraints,
      ).build(),
    ),
  );
}

final class _SingleActionRegionComposition<T extends Object> {
  const _SingleActionRegionComposition({
    required this.host,
    required this.context,
    required this.constraints,
  });

  final SingleActionRegionHost<T> host;
  final BuildContext context;
  final BoxConstraints constraints;

  Widget build() {
    final reservation = _reservation();
    final targetExtent = _targetExtent();
    final effectiveCapacity = _effectiveCapacity(
      reservation: reservation,
      targetExtent: targetExtent,
    );
    final snapshot = host.snapshotBuilder(
      context,
      constraints,
      effectiveCapacity,
    );
    final input = _layoutInput(
      snapshot: snapshot,
      reservation: reservation,
      targetExtent: targetExtent,
      effectiveCapacity: effectiveCapacity,
    );
    final plan = _layoutPlan(input);
    final allocation = _ActionRegionLayoutAllocator<T>(
      slots: snapshot.slots,
      plan: plan,
      input: input,
    ).allocate();
    return _composeRegion(
      snapshot: snapshot,
      allocation: allocation,
      targetExtent: targetExtent,
    );
  }

  ActionRegionLayoutReservation _reservation() =>
      host.layoutDelegate?.reserve(
        ActionRegionLayoutReservationInput(
          constraints: constraints,
          textDirection: Directionality.of(context),
          primaryCapacity: host.primaryCapacity,
          actionIds: host.actionIds,
        ),
      ) ??
      ActionRegionLayoutReservation();

  double? _targetExtent() {
    final stretches =
        host.layoutDelegate != null ||
        host.distribution != ActionRegionMainAxisDistribution.compact;
    if (!stretches || !constraints.hasBoundedWidth) return null;
    return math.min(host.primaryCapacity, constraints.maxWidth);
  }

  double _effectiveCapacity({
    required ActionRegionLayoutReservation reservation,
    required double? targetExtent,
  }) => math.max(
    0.0,
    (targetExtent ?? host.primaryCapacity) - reservation.fixedExtent,
  );

  ActionRegionLayoutInput _layoutInput({
    required SingleActionRegionSnapshot<T> snapshot,
    required ActionRegionLayoutReservation reservation,
    required double? targetExtent,
    required double effectiveCapacity,
  }) => ActionRegionLayoutInput(
    constraints: constraints,
    textDirection: Directionality.of(context),
    primaryCapacity: effectiveCapacity,
    targetExtent: targetExtent,
    reservation: reservation,
    slots: [
      for (final slot in snapshot.slots)
        ActionRegionLayoutSlot(
          id: slot.layoutId,
          minimumExtent: slot.minimumExtent,
        ),
    ],
  );

  ActionRegionLayoutPlan _layoutPlan(ActionRegionLayoutInput input) =>
      host.layoutDelegate?.layout(input) ??
      _ActionRegionDistributionPlanner(
        distribution: host.distribution,
        slots: input.slots,
      ).plan();

  Widget _composeRegion({
    required SingleActionRegionSnapshot<T> snapshot,
    required _ActionRegionAllocation<T> allocation,
    required double? targetExtent,
  }) {
    final region = AnimatedActionRegion<T>(
      items: allocation.slots,
      height: host.height,
      fadeDuration: host.fadeDuration,
      resizeDuration: host.resizeDuration,
      switchInCurve: host.switchInCurve,
      switchOutCurve: host.switchOutCurve,
      variantBuilder: host.variantBuilder,
    );
    if (snapshot.slots.isEmpty ||
        targetExtent == null ||
        !allocation.expandsToTargetExtent) {
      return region;
    }
    return ClipRect(
      child: SizedBox(
        width: math.max(targetExtent, allocation.usedExtent),
        child: OverflowBox(
          alignment: AlignmentDirectional.centerStart,
          minWidth: 0,
          maxWidth: double.infinity,
          child: region,
        ),
      ),
    );
  }
}

final class _ActionRegionDistributionPlanner {
  const _ActionRegionDistributionPlanner({
    required this.distribution,
    required this.slots,
  });

  final ActionRegionMainAxisDistribution distribution;
  final List<ActionRegionLayoutSlot> slots;

  ActionRegionLayoutPlan plan() => switch (distribution) {
    ActionRegionMainAxisDistribution.compact => _compact(),
    ActionRegionMainAxisDistribution.spaceBetween => _spaceBetween(),
    ActionRegionMainAxisDistribution.spaceAround => _spaceAround(),
    ActionRegionMainAxisDistribution.spaceEvenly => _spaceEvenly(),
  };

  ActionRegionLayoutPlan _compact() => ActionRegionLayoutPlan(
    entries: [for (final slot in slots) ActionRegionLayoutEntry.slot(slot.id)],
  );

  ActionRegionLayoutPlan _spaceBetween() {
    if (slots.length < 2) return _compact();
    final entries = <ActionRegionLayoutEntry>[];
    var isFirst = true;
    for (final slot in slots) {
      if (!isFirst) entries.add(ActionRegionLayoutEntry.flexGap());
      entries.add(ActionRegionLayoutEntry.slot(slot.id));
      isFirst = false;
    }
    return ActionRegionLayoutPlan(entries: entries);
  }

  ActionRegionLayoutPlan _spaceAround() {
    if (slots.isEmpty) return _compact();
    final entries = <ActionRegionLayoutEntry>[
      ActionRegionLayoutEntry.flexGap(),
    ];
    var isFirst = true;
    for (final slot in slots) {
      if (!isFirst) {
        entries.add(ActionRegionLayoutEntry.flexGap(flex: 2));
      }
      entries.add(ActionRegionLayoutEntry.slot(slot.id));
      isFirst = false;
    }
    entries.add(ActionRegionLayoutEntry.flexGap());
    return ActionRegionLayoutPlan(entries: entries);
  }

  ActionRegionLayoutPlan _spaceEvenly() {
    if (slots.isEmpty) return _compact();
    final entries = <ActionRegionLayoutEntry>[
      ActionRegionLayoutEntry.flexGap(),
    ];
    for (final slot in slots) {
      entries
        ..add(ActionRegionLayoutEntry.slot(slot.id))
        ..add(ActionRegionLayoutEntry.flexGap());
    }
    return ActionRegionLayoutPlan(entries: entries);
  }
}

final class _ActionRegionLayoutAllocator<T extends Object> {
  _ActionRegionLayoutAllocator({
    required this.slots,
    required this.plan,
    required this.input,
  }) : _slotEntries = plan.entries
           .whereType<ActionRegionSlotLayoutEntry>()
           .toList(growable: false);

  final List<ActionRegionSlot<T>> slots;
  final ActionRegionLayoutPlan plan;
  final ActionRegionLayoutInput input;
  final List<ActionRegionSlotLayoutEntry> _slotEntries;

  _ActionRegionAllocation<T> allocate() {
    _validateSlotOrder();
    _validateFixedGapReservation();
    _validateOverflowExtent();
    if (slots.isEmpty) {
      return _ActionRegionAllocation<T>(
        slots: const [],
        usedExtent: 0,
        expandsToTargetExtent: false,
      );
    }
    return _allocateSlots(_flexUnit());
  }

  void _validateSlotOrder() {
    final expectedIds = [for (final slot in slots) slot.layoutId];
    final actualIds = [for (final entry in _slotEntries) entry.id];
    if (!const ListEquality<ActionRegionLayoutSlotId>().equals(
      expectedIds,
      actualIds,
    )) {
      throw ArgumentError.value(
        plan,
        'plan',
        'must contain every resolved slot exactly once in renderer order',
      );
    }
  }

  void _validateFixedGapReservation() {
    if ((_fixedGapExtent - input.reservation.fixedExtent).abs() <= 0.000001) {
      return;
    }
    throw ArgumentError.value(
      plan,
      'plan',
      'fixed gaps must match the pre-resolution reservation',
    );
  }

  void _validateOverflowExtent() {
    for (final entry in _slotEntries) {
      if (entry.id.isOverflow && entry.extent is! ActionRegionFixedExtent) {
        throw ArgumentError.value(
          plan,
          'plan',
          'the overflow slot must remain fixed',
        );
      }
    }
  }

  double get _fixedGapExtent => plan.entries
      .whereType<ActionRegionFixedGapLayoutEntry>()
      .fold<double>(0, (total, entry) => total + entry.extent);

  double get _minimumExtent => slots.fold<double>(
    _fixedGapExtent,
    (total, slot) => total + slot.minimumExtent,
  );

  int get _totalFlex {
    var total = 0;
    for (final entry in plan.entries) {
      total += switch (entry) {
        ActionRegionSlotLayoutEntry(
          extent: ActionRegionFlexibleExtent(:final flex),
        ) =>
          flex,
        ActionRegionFlexGapLayoutEntry(:final flex) => flex,
        ActionRegionSlotLayoutEntry() || ActionRegionFixedGapLayoutEntry() => 0,
      };
    }
    return total;
  }

  double _flexUnit() {
    final targetExtent = input.targetExtent;
    final remainder = targetExtent == null
        ? 0.0
        : math.max(0.0, targetExtent - _minimumExtent);
    return _totalFlex == 0 ? 0 : remainder / _totalFlex;
  }

  _ActionRegionAllocation<T> _allocateSlots(double flexUnit) {
    final slotsById = {for (final slot in slots) slot.layoutId: slot};
    final allocatedSlots = <ActionRegionSlot<T>>[];
    var pendingGap = 0.0;
    var usedExtent = 0.0;
    for (final entry in plan.entries) {
      switch (entry) {
        case ActionRegionFixedGapLayoutEntry(:final extent):
          pendingGap += extent;
          usedExtent += extent;
        case ActionRegionFlexGapLayoutEntry(:final flex):
          final extent = flexUnit * flex;
          pendingGap += extent;
          usedExtent += extent;
        case ActionRegionSlotLayoutEntry():
          final slot = slotsById[entry.id]!;
          final allocatedExtent = _allocatedExtent(
            slot: slot,
            extent: entry.extent,
            flexUnit: flexUnit,
          );
          allocatedSlots.add(
            slot.withAllocation(
              allocatedExtent: allocatedExtent,
              leadingExtent: pendingGap,
            ),
          );
          pendingGap = 0;
          usedExtent += allocatedExtent;
      }
    }
    _attachTrailingGap(allocatedSlots, pendingGap);
    return _ActionRegionAllocation<T>(
      slots: allocatedSlots,
      usedExtent: usedExtent,
      expandsToTargetExtent: _totalFlex > 0,
    );
  }

  double _allocatedExtent({
    required ActionRegionSlot<T> slot,
    required ActionRegionExtent extent,
    required double flexUnit,
  }) => switch (extent) {
    ActionRegionFixedExtent() => slot.minimumExtent,
    ActionRegionFlexibleExtent(:final flex, fit: ActionRegionFlexFit.tight) =>
      slot.minimumExtent + flexUnit * flex,
    ActionRegionFlexibleExtent(fit: ActionRegionFlexFit.loose) =>
      slot.minimumExtent,
  };

  void _attachTrailingGap(
    List<ActionRegionSlot<T>> allocatedSlots,
    double trailingExtent,
  ) {
    if (trailingExtent == 0) return;
    final last = allocatedSlots.removeLast();
    allocatedSlots.add(
      last.withAllocation(
        allocatedExtent: last.effectiveExtent,
        leadingExtent: last.leadingExtent,
        trailingExtent: trailingExtent,
      ),
    );
  }
}

final class _ActionRegionAllocation<T extends Object> {
  const _ActionRegionAllocation({
    required this.slots,
    required this.usedExtent,
    required this.expandsToTargetExtent,
  });

  final List<ActionRegionSlot<T>> slots;
  final double usedExtent;
  final bool expandsToTargetExtent;
}
