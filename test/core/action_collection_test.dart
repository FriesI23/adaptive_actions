import 'package:adaptive_actions/adaptive_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AdaptiveAction<String> action(String id) => AdaptiveAction.action(
    id: ActionId(id),
    metadata: ActionMetadata(label: id),
    payload: id,
  );

  ActionPlacementConstraints placementConstraintsFor(
    String id,
    List<String> actionIds, {
    ActionPlacementSplitPolicy splitPolicy =
        ActionPlacementSplitPolicy.splittable,
    ActionPlacement? placementOverride,
    PrimaryRetentionPriority? retentionPriority,
  }) => ActionPlacementConstraints(
    id: ActionPlacementConstraintId(id),
    actionIds: actionIds.map(ActionId.new),
    splitPolicy: splitPolicy,
    placementOverride: placementOverride,
    retentionPriority: retentionPriority,
  );

  group('ActionPlacementConstraints', () {
    test('preserves action ID order and defaults to an unconfigured split', () {
      final editingConstraints = placementConstraintsFor('editing', [
        'cut',
        'copy',
      ]);

      expect(editingConstraints.actionIds, [ActionId('cut'), ActionId('copy')]);
      expect(
        editingConstraints.splitPolicy,
        ActionPlacementSplitPolicy.splittable,
      );
      expect(editingConstraints.placementOverride, isNull);
      expect(editingConstraints.retentionPriority, isNull);
      expect(
        editingConstraints,
        placementConstraintsFor('editing', ['cut', 'copy']),
      );
    });

    test('stores a constraint-level retention priority', () {
      final editingConstraints = placementConstraintsFor('editing', [
        'cut',
        'copy',
      ], retentionPriority: PrimaryRetentionPriority.high);

      expect(
        editingConstraints.retentionPriority,
        PrimaryRetentionPriority.high,
      );
      expect(
        editingConstraints,
        isNot(placementConstraintsFor('editing', ['cut', 'copy'])),
      );
    });

    test('supports indivisible constraints and placement overrides', () {
      final editingConstraints = placementConstraintsFor(
        'editing',
        ['cut', 'copy'],
        splitPolicy: ActionPlacementSplitPolicy.indivisible,
        placementOverride: ActionPlacement.pinned,
      );

      expect(
        editingConstraints.splitPolicy,
        ActionPlacementSplitPolicy.indivisible,
      );
      expect(editingConstraints.placementOverride, ActionPlacement.pinned);
    });

    test('rejects automatic as a placement override', () {
      expect(
        () => placementConstraintsFor('automatic', [
          'save',
        ], placementOverride: ActionPlacement.automatic),
        throwsArgumentError,
      );
    });

    test('rejects empty and duplicate action IDs', () {
      expect(() => placementConstraintsFor('empty', []), throwsArgumentError);
      expect(
        () => placementConstraintsFor('duplicate', ['save', 'save']),
        throwsArgumentError,
      );
    });

    test('defensively copies and exposes unmodifiable action IDs', () {
      final input = [ActionId('cut')];
      final constrainedActions = ActionPlacementConstraints(
        id: ActionPlacementConstraintId('editing'),
        actionIds: input,
      );

      input.add(ActionId('copy'));

      expect(constrainedActions.actionIds, [ActionId('cut')]);
      expect(
        () => constrainedActions.actionIds.add(ActionId('paste')),
        throwsUnsupportedError,
      );
    });

    test('creates the same ID relationship from action instances', () {
      final cut = action('cut');
      final copy = action('copy');
      final actions = [cut, copy];
      final constrainedActions = ActionPlacementConstraints.fromActions(
        id: ActionPlacementConstraintId('editing'),
        actions: actions,
        splitPolicy: ActionPlacementSplitPolicy.indivisible,
      );

      actions.clear();

      expect(constrainedActions.actionIds, [cut.id, copy.id]);
      expect(
        constrainedActions.splitPolicy,
        ActionPlacementSplitPolicy.indivisible,
      );
    });
  });

  group('ActionCollection', () {
    test('accepts empty roots and placement constraints', () {
      final collection = ActionCollection<String>(roots: const []);

      expect(collection.roots, isEmpty);
      expect(collection.placementConstraints, isEmpty);
    });

    test(
      'preserves roots and keeps placement constraints separate from the tree',
      () {
        final cut = action('cut');
        final copy = action('copy');
        final editingConstraints = placementConstraintsFor('editing', [
          'cut',
          'copy',
        ]);
        final collection = ActionCollection(
          roots: [cut, copy],
          placementConstraints: [editingConstraints],
        );

        expect(collection.roots, [cut, copy]);
        expect(collection.entries, [cut, copy]);
        expect(collection.placementConstraints, [editingConstraints]);
        expect(collection.roots.every((root) => root.children.isEmpty), isTrue);
      },
    );

    test(
      'withEntries preserves top-level dividers outside placement roots',
      () {
        final first = action('first');
        final second = action('second');
        const divider = AdaptiveMenuDivider<String>.menuOnly();
        final input = <AdaptiveMenuEntry<String>>[first, divider, second];
        final collection = ActionCollection<String>.withEntries(entries: input);

        input.clear();

        expect(collection.entries, [first, divider, second]);
        expect(collection.roots, [first, second]);
        expect(collection.entries, isA<List<AdaptiveMenuEntry<String>>>());
        expect(collection.entries.clear, throwsUnsupportedError);
        expect(
          collection,
          ActionCollection<String>.withEntries(
            entries: [first, divider, second],
          ),
        );
        expect(
          collection,
          isNot(ActionCollection<String>(roots: [first, second])),
        );
      },
    );

    test('withEntries accepts a divider-only declaration', () {
      final collection = ActionCollection<String>.withEntries(
        entries: const [AdaptiveMenuDivider<String>()],
      );

      expect(collection.entries, const [AdaptiveMenuDivider<String>()]);
      expect(collection.roots, isEmpty);
    });

    test('withEntries accepts a divider hidden in both targets', () {
      final first = action('first');
      final second = action('second');
      const divider = AdaptiveMenuDivider<String>.hidden();

      final collection = ActionCollection<String>.withEntries(
        entries: [first, divider, second],
      );

      expect(collection.entries, [first, divider, second]);
      expect(collection.roots, [first, second]);
    });

    test('defensively copies and exposes unmodifiable collections', () {
      final roots = [action('save')];
      final placementConstraints = <ActionPlacementConstraints>[];
      final collection = ActionCollection(
        roots: roots,
        placementConstraints: placementConstraints,
      );

      roots.add(action('open'));
      placementConstraints.add(placementConstraintsFor('late', ['save']));

      expect(collection.roots.map((root) => root.id), [ActionId('save')]);
      expect(collection.placementConstraints, isEmpty);
      expect(
        () => collection.roots.add(action('close')),
        throwsUnsupportedError,
      );
      expect(
        () => collection.placementConstraints.add(
          placementConstraintsFor('more', ['save']),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects duplicate IDs anywhere in the tree', () {
      final duplicateChild = AdaptiveAction<String>.menu(
        id: ActionId('menu'),
        metadata: const ActionMetadata(label: 'Menu'),
        children: [action('duplicate')],
      );

      expect(
        () => ActionCollection(roots: [action('duplicate'), duplicateChild]),
        throwsArgumentError,
      );
      expect(
        () => ActionCollection(roots: [action('same'), action('same')]),
        throwsArgumentError,
      );
    });

    test('rejects missing, non-root, and duplicate constrained action IDs', () {
      final menu = AdaptiveAction<String>.menu(
        id: ActionId('menu'),
        metadata: const ActionMetadata(label: 'Menu'),
        children: [action('child')],
      );

      expect(
        () => ActionCollection(
          roots: [menu],
          placementConstraints: [
            placementConstraintsFor('missing', ['unknown']),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ActionCollection(
          roots: [menu],
          placementConstraints: [
            placementConstraintsFor('nested', ['child']),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => placementConstraintsFor('duplicates', ['menu', 'menu']),
        throwsArgumentError,
      );
    });

    test(
      'rejects overlapping placement constraints and duplicate constraint IDs',
      () {
        final roots = [action('cut'), action('copy'), action('paste')];

        expect(
          () => ActionCollection(
            roots: roots,
            placementConstraints: [
              placementConstraintsFor('first', ['cut', 'copy']),
              placementConstraintsFor('second', ['copy', 'paste']),
            ],
          ),
          throwsArgumentError,
        );
        expect(
          () => ActionCollection(
            roots: roots,
            placementConstraints: [
              placementConstraintsFor('same', ['cut']),
              placementConstraintsFor('same', ['copy']),
            ],
          ),
          throwsArgumentError,
        );
      },
    );

    test('prevents a cycle introduced through a mutable source list', () {
      final children = <AdaptiveAction<String>>[];
      final leaf = action('leaf');
      children.add(leaf);
      final menu = AdaptiveAction<String>.menu(
        id: ActionId('menu'),
        metadata: const ActionMetadata(label: 'Menu'),
        children: children,
      );

      children
        ..clear()
        ..add(menu);
      final collection = ActionCollection(roots: [menu]);

      expect(collection.roots.single.children, [leaf]);
      expect(
        (collection.roots.single.children.single as AdaptiveAction<String>)
            .children,
        isEmpty,
      );
    });

    test('has structural equality and hashing', () {
      ActionCollection<String> buildCollection() => ActionCollection(
        roots: [action('cut'), action('copy')],
        placementConstraints: [
          placementConstraintsFor('editing', ['cut', 'copy']),
        ],
      );

      final first = buildCollection();
      final second = buildCollection();

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test(
      'fromEntries flattens contiguous constrained actions into canonical inputs',
      () {
        final save = action('save');
        final cut = action('cut');
        final copy = action('copy');
        final search = action('search');
        final entryActions = [cut, copy];
        final constrainedEntry =
            ActionCollectionEntry<String>.constrainedActions(
              id: ActionPlacementConstraintId('editing'),
              actions: entryActions,
              splitPolicy: ActionPlacementSplitPolicy.indivisible,
            );
        entryActions.clear();
        final collection = ActionCollection<String>.fromEntries([
          ActionCollectionEntry.action(save),
          constrainedEntry,
          ActionCollectionEntry.action(search),
        ]);

        expect(collection.roots, [save, cut, copy, search]);
        expect(constrainedEntry.roots, [cut, copy]);
        expect(collection.placementConstraints.single.actionIds, [
          cut.id,
          copy.id,
        ]);
        expect(
          collection.placementConstraints.single.splitPolicy,
          ActionPlacementSplitPolicy.indivisible,
        );
      },
    );

    test('fromEntries preserves collection validation', () {
      final duplicate = action('duplicate');

      expect(
        () => ActionCollection<String>.fromEntries([
          ActionCollectionEntry.action(duplicate),
          ActionCollectionEntry.constrainedActions(
            id: ActionPlacementConstraintId('duplicate'),
            actions: [duplicate],
          ),
        ]),
        throwsArgumentError,
      );
    });

    test('fromEntries accepts custom normalized entry implementations', () {
      final cut = action('cut');
      final copy = action('copy');
      final constrainedActions = ActionPlacementConstraints.fromActions(
        id: ActionPlacementConstraintId('editing'),
        actions: [cut, copy],
      );
      final collection = ActionCollection<String>.fromEntries([
        _CustomCollectionEntry(
          roots: [cut, copy],
          placementConstraints: [constrainedActions],
        ),
      ]);

      expect(collection.roots, [cut, copy]);
      expect(collection.placementConstraints, [constrainedActions]);
    });
  });
}

final class _CustomCollectionEntry<T extends Object>
    implements ActionCollectionEntry<T> {
  _CustomCollectionEntry({
    required Iterable<AdaptiveAction<T>> roots,
    required Iterable<ActionPlacementConstraints> placementConstraints,
  }) : roots = List.unmodifiable(roots),
       placementConstraints = List.unmodifiable(placementConstraints);

  @override
  final List<AdaptiveAction<T>> roots;

  @override
  final List<ActionPlacementConstraints> placementConstraints;
}
