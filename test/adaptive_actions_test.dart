import 'package:adaptive_actions/adaptive_actions.dart';
import 'package:adaptive_actions/core.dart' as core;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('public core API', () {
    test('is available from the dedicated core entrypoint', () {
      expect(
        const core.DefaultActionPlacementDelegate(),
        isA<core.ActionPlacementDelegate>(),
      );
      expect(core.ActionId('save'), core.ActionId('save'));
    });

    test('supports the complete renderer-facing resolution flow', () {
      final save = core.AdaptiveAction<String>.action(
        id: core.ActionId('save'),
        metadata: const core.ActionMetadata(label: 'Save'),
        payload: 'save-document',
      );
      final request = core.ActionLayoutRequest(
        actions: core.ActionCollection(roots: [save]),
        constraints: core.ActionLayoutConstraints(
          primaryCapacity: 48,
          profiles: [
            core.ActionLayoutProfile(
              actionId: save.id,
              options: [
                core.ActionLayoutOption(
                  id: core.ActionLayoutOptionId('icon'),
                  cost: 48,
                ),
              ],
            ),
          ],
        ),
        capabilities: const core.RendererCapabilities(),
      );

      final layout = const core.ActionLayoutResolver(
        placementDelegate: core.DefaultActionPlacementDelegate(),
      ).resolve(request);

      expect(layout, isA<core.ActionLayoutResult<String>>());
      expect(layout.primary.single.action.payload, 'save-document');
      expect(layout.primary.single.optionId, core.ActionLayoutOptionId('icon'));
    });

    test('exports both placement-constraint authoring forms', () {
      core.AdaptiveAction<String> action(String id) =>
          core.AdaptiveAction.action(
            id: core.ActionId(id),
            metadata: core.ActionMetadata(label: id),
            payload: id,
          );

      final cut = action('cut');
      final copy = action('copy');
      final relationship = core.ActionPlacementConstraints.fromActions(
        id: core.ActionPlacementConstraintId('editing'),
        actions: [cut, copy],
      );
      final entries = core.ActionCollection<String>.fromEntries([
        core.ActionCollectionEntry.constrainedActions(
          id: core.ActionPlacementConstraintId('editing'),
          actions: [cut, copy],
        ),
      ]);

      expect(relationship.actionIds, [cut.id, copy.id]);
      expect(entries.roots, [cut, copy]);
      expect(entries.placementConstraints.single, relationship);
    });

    test('exports zero-cost statically typed identifiers', () {
      final firstActionId = ActionId('save');
      final sameActionId = ActionId('save');
      final constraintId = ActionPlacementConstraintId('editing');
      final optionId = ActionLayoutOptionId('primary-a');

      expect(firstActionId, sameActionId);
      expect(firstActionId.hashCode, sameActionId.hashCode);
      expect(firstActionId.value, 'save');
      expect(firstActionId.toString(), 'save');
      expect(constraintId, ActionPlacementConstraintId('editing'));
      expect(constraintId.value, 'editing');
      expect(constraintId.toString(), 'editing');
      expect(optionId.value, 'primary-a');
      expect(firstActionId, isNot(equals(constraintId)));
      expect(firstActionId, isA<String>());
      expect(ActionId('shared'), equals(ActionPlacementConstraintId('shared')));
    });

    test('rejects empty and padded identifier values', () {
      for (final invalidValue in ['', ' ', ' save', 'save ']) {
        expect(() => ActionId(invalidValue), throwsArgumentError);
        expect(
          () => ActionPlacementConstraintId(invalidValue),
          throwsArgumentError,
        );
        expect(() => ActionLayoutOptionId(invalidValue), throwsArgumentError);
      }
    });
  });
}
