import 'package:adaptive_actions/adaptive_actions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('layout inputs and plans defensively copy caller collections', () {
    final actionIds = [ActionId('a')];
    final reservationInput = ActionRegionLayoutReservationInput(
      constraints: const BoxConstraints(maxWidth: 200),
      textDirection: TextDirection.ltr,
      primaryCapacity: 200,
      actionIds: actionIds,
    );
    final slots = [
      ActionRegionLayoutSlot(
        id: ActionRegionLayoutSlotId.action(ActionId('a')),
        minimumExtent: 40,
      ),
    ];
    final layoutInput = ActionRegionLayoutInput(
      constraints: const BoxConstraints(maxWidth: 200),
      textDirection: TextDirection.ltr,
      primaryCapacity: 192,
      targetExtent: 200,
      reservation: ActionRegionLayoutReservation(fixedExtent: 8),
      slots: slots,
    );
    final entries = <ActionRegionLayoutEntry>[
      ActionRegionLayoutEntry.slot(slots.single.id),
    ];
    final plan = ActionRegionLayoutPlan(entries: entries);

    actionIds.clear();
    slots.clear();
    entries.clear();

    expect(reservationInput.actionIds, [ActionId('a')]);
    expect(layoutInput.slots, hasLength(1));
    expect(plan.entries, hasLength(1));
    expect(reservationInput.actionIds.clear, throwsUnsupportedError);
    expect(layoutInput.slots.clear, throwsUnsupportedError);
    expect(plan.entries.clear, throwsUnsupportedError);
  });

  test('layout values reject invalid extents and flex weights', () {
    expect(
      () => ActionRegionLayoutSlot(
        id: ActionRegionLayoutSlotId.action(ActionId('a')),
        minimumExtent: double.infinity,
      ),
      throwsArgumentError,
    );
    expect(
      () => ActionRegionLayoutReservationInput(
        constraints: const BoxConstraints(),
        textDirection: TextDirection.ltr,
        primaryCapacity: -1,
        actionIds: const [],
      ),
      throwsRangeError,
    );
    expect(
      () => ActionRegionLayoutReservation(fixedExtent: double.infinity),
      throwsArgumentError,
    );
    expect(
      () => ActionRegionLayoutReservation(fixedExtent: -1),
      throwsRangeError,
    );
    expect(
      () => ActionRegionLayoutEntry.fixedGap(double.nan),
      throwsArgumentError,
    );
    expect(() => ActionRegionLayoutEntry.fixedGap(-1), throwsRangeError);
    expect(() => ActionRegionLayoutEntry.flexGap(flex: 0), throwsRangeError);
    expect(() => ActionRegionExtent.flex(flex: -1), throwsRangeError);
  });

  test('slot IDs distinguish action roots from the overflow trigger', () {
    final first = ActionRegionLayoutSlotId.action(ActionId('a'));
    final equal = ActionRegionLayoutSlotId.action(ActionId('a'));
    const overflow = ActionRegionLayoutSlotId.overflow();

    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(first.isOverflow, isFalse);
    expect(first.actionId, ActionId('a'));
    expect(overflow.isOverflow, isTrue);
    expect(overflow.actionId, isNull);
    expect(first, isNot(overflow));
  });
}
