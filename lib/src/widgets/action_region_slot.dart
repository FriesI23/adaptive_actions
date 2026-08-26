import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'action_region_layout.dart';

/// The structural role of one package-owned action-region slot.
@internal
enum ActionRegionSlotRole { action, overflow }

/// An immutable renderer-provided slot consumed by shared composition.
///
/// The shared widgets layer owns identity, role, and minimum extent. The
/// renderer retains ownership of [data] and [child].
@internal
@immutable
final class ActionRegionSlot<T extends Object> {
  ActionRegionSlot({
    required this.id,
    required this.layoutId,
    required this.variant,
    required this.role,
    required this.minimumExtent,
    required this.data,
    required this.child,
    this.allocatedExtent,
    this.leadingExtent = 0,
    this.trailingExtent = 0,
  }) {
    if (!minimumExtent.isFinite) {
      throw ArgumentError.value(
        minimumExtent,
        'minimumExtent',
        'must be finite',
      );
    }
    if (minimumExtent < 0) {
      throw RangeError.value(
        minimumExtent,
        'minimumExtent',
        'must not be negative',
      );
    }
    final allocatedExtent = this.allocatedExtent;
    if (allocatedExtent != null &&
        (!allocatedExtent.isFinite || allocatedExtent < minimumExtent)) {
      throw ArgumentError.value(
        allocatedExtent,
        'allocatedExtent',
        'must be finite and not less than minimumExtent',
      );
    }
    for (final MapEntry(key: name, value: extent) in {
      'leadingExtent': leadingExtent,
      'trailingExtent': trailingExtent,
    }.entries) {
      if (!extent.isFinite || extent < 0) {
        throw ArgumentError.value(
          extent,
          name,
          'must be finite and non-negative',
        );
      }
    }
  }

  final Object id;
  final ActionRegionLayoutSlotId layoutId;
  final Object variant;
  final ActionRegionSlotRole role;
  final double minimumExtent;
  final double? allocatedExtent;
  final double leadingExtent;
  final double trailingExtent;
  final T data;
  final Widget child;

  double get effectiveExtent => allocatedExtent ?? minimumExtent;

  double get totalExtent => leadingExtent + effectiveExtent + trailingExtent;

  ActionRegionSlot<T> withAllocation({
    required double allocatedExtent,
    double leadingExtent = 0,
    double trailingExtent = 0,
  }) => ActionRegionSlot<T>(
    id: id,
    layoutId: layoutId,
    variant: variant,
    role: role,
    minimumExtent: minimumExtent,
    allocatedExtent: allocatedExtent,
    leadingExtent: leadingExtent,
    trailingExtent: trailingExtent,
    data: data,
    child: child,
  );
}
