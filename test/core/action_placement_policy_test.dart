import 'package:adaptive_actions/adaptive_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrimaryRetentionPriority', () {
    test('provides semantic defaults and custom values', () {
      expect(PrimaryRetentionPriority.low.value, -100);
      expect(PrimaryRetentionPriority.normal.value, 0);
      expect(PrimaryRetentionPriority.high.value, 100);
      expect(const PrimaryRetentionPriority.custom(50).value, 50);
    });

    test('compares values with higher priorities retained first', () {
      expect(
        PrimaryRetentionPriority.low.compareTo(PrimaryRetentionPriority.normal),
        lessThan(0),
      );
      expect(
        PrimaryRetentionPriority.high.compareTo(
          PrimaryRetentionPriority.normal,
        ),
        greaterThan(0),
      );
      expect(
        const PrimaryRetentionPriority.custom(
          50,
        ).compareTo(const PrimaryRetentionPriority.custom(50)),
        0,
      );
    });
  });

  group('AutomaticPlacementPreference', () {
    test('has platform-neutral defaults and value equality', () {
      final first = AutomaticPlacementPreference();
      final second = AutomaticPlacementPreference();

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.retentionPriority, PrimaryRetentionPriority.normal);
      expect(first.allowsHiding, isFalse);
    });

    test('stores explicit retention priority and hiding permission', () {
      final preference = AutomaticPlacementPreference(
        retentionPriority: const PrimaryRetentionPriority.custom(10),
        allowsHiding: true,
      );

      expect(
        preference.retentionPriority,
        const PrimaryRetentionPriority.custom(10),
      );
      expect(preference.allowsHiding, isTrue);
      expect(
        preference,
        AutomaticPlacementPreference(
          retentionPriority: const PrimaryRetentionPriority.custom(10),
          allowsHiding: true,
        ),
      );
    });
  });

  group('ActionPlacementPolicy', () {
    test('defaults to automatic with the default preference', () {
      final policy = ActionPlacementPolicy();

      expect(policy.placement, ActionPlacement.automatic);
      expect(policy.automaticPreference, AutomaticPlacementPreference());
      expect(policy, ActionPlacementPolicy());
    });

    test('represents every fixed placement without automatic preference', () {
      for (final placement in [
        ActionPlacement.pinned,
        ActionPlacement.overflowOnly,
        ActionPlacement.hidden,
      ]) {
        final policy = ActionPlacementPolicy(placement: placement);

        expect(policy.placement, placement);
        expect(policy.automaticPreference, isNull);
      }
    });

    test('rejects automatic preference for fixed placements', () {
      expect(
        () => ActionPlacementPolicy(
          placement: ActionPlacement.pinned,
          automaticPreference: AutomaticPlacementPreference(),
        ),
        throwsArgumentError,
      );
    });
  });

  test('AdaptiveAction carries policy while preserving existing defaults', () {
    final defaultAction = AdaptiveAction<String>.action(
      id: ActionId('default'),
      metadata: const ActionMetadata(label: 'Default'),
      payload: 'default',
    );
    final pinnedAction = AdaptiveAction<String>.action(
      id: ActionId('pinned'),
      metadata: const ActionMetadata(label: 'Pinned'),
      payload: 'pinned',
      placementPolicy: ActionPlacementPolicy(placement: ActionPlacement.pinned),
    );

    expect(defaultAction.placementPolicy, ActionPlacementPolicy());
    expect(pinnedAction.placementPolicy.placement, ActionPlacement.pinned);
    expect(defaultAction, isNot(pinnedAction));
  });
}
