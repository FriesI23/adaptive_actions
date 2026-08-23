import 'package:adaptive_actions/adaptive_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ActionLayoutOption option(String id, double cost) =>
      ActionLayoutOption(id: ActionLayoutOptionId(id), cost: cost);

  ActionLayoutProfile costs(String id, Iterable<ActionLayoutOption> options) =>
      ActionLayoutProfile(actionId: ActionId(id), options: options);

  group('ActionLayoutOptionId', () {
    test('is statically distinct and validates its string value', () {
      expect(ActionLayoutOptionId('candidate-a').value, 'candidate-a');
      expect(
        ActionLayoutOptionId('candidate-a'),
        ActionLayoutOptionId('candidate-a'),
      );
      for (final invalid in ['', ' candidate-a', 'candidate-a ']) {
        expect(() => ActionLayoutOptionId(invalid), throwsArgumentError);
      }
    });
  });

  group('ActionLayoutOption', () {
    test('stores an opaque ID and a finite non-negative cost', () {
      expect(option('preferred', 48), option('preferred', 48));
      expect(option('zero', 0).cost, 0);
      for (final invalid in [-1.0, double.nan, double.infinity]) {
        expect(
          () => option('invalid', invalid),
          anyOf(throwsArgumentError, throwsRangeError),
        );
      }
    });
  });

  group('ActionLayoutProfile', () {
    test('preserves renderer preference order and is immutable', () {
      final input = [option('preferred', 72), option('fallback', 40)];
      final profile = costs('save', input);

      input.clear();

      expect(profile.options.map((item) => item.id), [
        ActionLayoutOptionId('preferred'),
        ActionLayoutOptionId('fallback'),
      ]);
      expect(profile.optionFor(ActionLayoutOptionId('fallback'))?.cost, 40);
      expect(profile.optionFor(ActionLayoutOptionId('missing')), isNull);
      expect(profile.options.clear, throwsUnsupportedError);
      expect(
        profile,
        costs('save', [option('preferred', 72), option('fallback', 40)]),
      );
    });

    test('rejects empty options and duplicate option IDs', () {
      expect(() => costs('empty', const []), throwsArgumentError);
      expect(
        () => costs('duplicate', [option('same', 48), option('same', 32)]),
        throwsArgumentError,
      );
    });

    test('allows the same option ID in different action profiles', () {
      expect(
        () => ActionLayoutConstraints(
          primaryCapacity: 100,
          profiles: [
            costs('save', [option('fallback', 48)]),
            costs('share', [option('fallback', 40)]),
          ],
        ),
        returnsNormally,
      );
    });
  });

  group('ActionLayoutConstraints', () {
    test('stores optional limits and immutable profiles', () {
      final profiles = [
        costs('save', [option('preferred', 48)]),
      ];
      final constraints = ActionLayoutConstraints(
        primaryCapacity: 200,
        maxPrimaryActions: 3,
        overflowTriggerCost: 40,
        profiles: profiles,
      );

      profiles.clear();

      expect(constraints.primaryCapacity, 200);
      expect(constraints.maxPrimaryActions, 3);
      expect(constraints.overflowTriggerCost, 40);
      expect(constraints.profileFor(ActionId('save')), isNotNull);
      expect(constraints.profiles.clear, throwsUnsupportedError);
      expect(
        constraints,
        ActionLayoutConstraints(
          primaryCapacity: 200,
          maxPrimaryActions: 3,
          overflowTriggerCost: 40,
          profiles: [
            costs('save', [option('preferred', 48)]),
          ],
        ),
      );
    });

    test('supports zero capacity and an omitted quantity limit', () {
      final constraints = ActionLayoutConstraints(primaryCapacity: 0);

      expect(constraints.maxPrimaryActions, isNull);
      expect(constraints.overflowTriggerCost, 0);
      expect(constraints.profiles, isEmpty);
    });

    test('rejects invalid capacities and quantity limits', () {
      for (final invalid in [-1.0, double.nan, double.infinity]) {
        expect(
          () => ActionLayoutConstraints(primaryCapacity: invalid),
          anyOf(throwsArgumentError, throwsRangeError),
        );
        expect(
          () => ActionLayoutConstraints(
            primaryCapacity: 1,
            overflowTriggerCost: invalid,
          ),
          anyOf(throwsArgumentError, throwsRangeError),
        );
      }
      expect(
        () =>
            ActionLayoutConstraints(primaryCapacity: 1, maxPrimaryActions: -1),
        throwsRangeError,
      );
    });

    test('rejects duplicate action layout profiles', () {
      expect(
        () => ActionLayoutConstraints(
          primaryCapacity: 100,
          profiles: [
            costs('save', [option('first', 48)]),
            costs('save', [option('second', 32)]),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('RendererCapabilities', () {
    test('only describes renderer interaction capabilities', () {
      expect(const RendererCapabilities(), const RendererCapabilities());
      expect(
        const RendererCapabilities(
          supportsCompositeActions: true,
        ).supportsCompositeActions,
        isTrue,
      );
    });
  });
}
