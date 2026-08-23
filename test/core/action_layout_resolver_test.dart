import 'package:adaptive_actions/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AdaptiveAction<String> action(
    String id, {
    ActionPlacement placement = ActionPlacement.automatic,
    List<AdaptiveAction<String>> children = const [],
  }) {
    final policy = ActionPlacementPolicy(placement: placement);
    return children.isEmpty
        ? AdaptiveAction.action(
            id: ActionId(id),
            metadata: ActionMetadata(label: id),
            payload: id,
            placementPolicy: policy,
          )
        : AdaptiveAction.menu(
            id: ActionId(id),
            metadata: ActionMetadata(label: id),
            children: children,
            placementPolicy: policy,
          );
  }

  ActionLayoutProfile costs(String id) => ActionLayoutProfile(
    actionId: ActionId(id),
    options: [
      ActionLayoutOption(id: ActionLayoutOptionId('primary-$id'), cost: 10),
    ],
  );

  ActionLayoutRequest<String> request({
    required List<AdaptiveAction<String>> roots,
    required double capacity,
    List<ActionPlacementConstraints> placementConstraints = const [],
    List<ActionId> primaryOverride = const [],
    List<ActionId> overflowOverride = const [],
  }) => ActionLayoutRequest(
    actions: ActionCollection(
      roots: roots,
      placementConstraints: placementConstraints,
    ),
    constraints: ActionLayoutConstraints(
      primaryCapacity: capacity,
      profiles: [for (final root in roots) costs(root.id.value)],
    ),
    capabilities: const RendererCapabilities(),
    primaryOrderOverride: primaryOverride,
    overflowOrderOverride: overflowOverride,
  );

  Iterable<ActionId> primaryIds(ActionLayoutResult<String> layout) =>
      layout.primary.map((entry) => entry.action.id);

  Iterable<ActionId> overflowIds(ActionLayoutResult<String> layout) =>
      layout.overflow.map((entry) => entry.id);

  group('ActionLayoutResolver', () {
    test(
      'uses the default placement delegate and returns final region order',
      () {
        final roots = ['1', '2', '3', '4'].map(action).toList();
        final resolutionRequest = request(
          roots: roots,
          capacity: 30,
          primaryOverride: [ActionId('3'), ActionId('2')],
          overflowOverride: [ActionId('4'), ActionId('3')],
        );

        final layout = const ActionLayoutResolver().resolve(resolutionRequest);

        expect(primaryIds(layout), [
          ActionId('1'),
          ActionId('3'),
          ActionId('2'),
        ]);
        expect(overflowIds(layout), [ActionId('4')]);
        expect(layout.primary.map((entry) => entry.optionId), [
          ActionLayoutOptionId('primary-1'),
          ActionLayoutOptionId('primary-3'),
          ActionLayoutOptionId('primary-2'),
        ]);
      },
    );

    test('applies standard ordering to an injected placement delegate', () {
      final roots = ['1', '2', '3'].map(action).toList();
      final resolutionRequest = request(
        roots: roots,
        capacity: 30,
        overflowOverride: [ActionId('3'), ActionId('1')],
      );

      final layout = const ActionLayoutResolver(
        placementDelegate: _OverflowPlacementDelegate(),
      ).resolve(resolutionRequest);

      expect(layout.primary, isEmpty);
      expect(overflowIds(layout), [
        ActionId('3'),
        ActionId('2'),
        ActionId('1'),
      ]);
    });

    test(
      'keeps unspecified slots for full, partial, and unknown overrides',
      () {
        final cases =
            <
              ({
                List<String> entries,
                List<String> override,
                List<String> expected,
              })
            >[
              (
                entries: ['1', '2', '3', '4', '5', '6'],
                override: ['5', '3', '1'],
                expected: ['5', '2', '3', '4', '1', '6'],
              ),
              (
                entries: ['1', '2', '3'],
                override: ['3', '2'],
                expected: ['1', '3', '2'],
              ),
              (
                entries: ['1', '2', '3'],
                override: [],
                expected: ['1', '2', '3'],
              ),
              (
                entries: ['1', '2', '3'],
                override: ['unknown', '3'],
                expected: ['1', '2', '3'],
              ),
              (
                entries: ['1', '2', '3'],
                override: ['unknown', '3', '1'],
                expected: ['3', '2', '1'],
              ),
            ];

        for (final testCase in cases) {
          final roots = testCase.entries.map(action).toList();
          final resolutionRequest = request(
            roots: roots,
            capacity: 0,
            overflowOverride: testCase.override.map(ActionId.new).toList(),
          );
          final layout = const ActionLayoutResolver(
            placementDelegate: _OverflowPlacementDelegate(),
          ).resolve(resolutionRequest);

          expect(
            overflowIds(layout),
            testCase.expected.map(ActionId.new),
            reason: 'override: ${testCase.override}',
          );
        }
      },
    );

    test(
      'rejects duplicate overrides before invoking the placement delegate',
      () {
        final roots = ['1', '2'].map(action).toList();

        expect(
          () => request(
            roots: roots,
            capacity: 20,
            overflowOverride: [ActionId('unknown'), ActionId('unknown')],
          ),
          throwsArgumentError,
        );
      },
    );

    test('is deterministic and does not mutate request inputs', () {
      final roots = ['1', '2', '3'].map(action).toList();
      final primaryOverride = [ActionId('3'), ActionId('1')];
      final resolutionRequest = request(
        roots: roots,
        capacity: 30,
        primaryOverride: primaryOverride,
      );
      const resolver = ActionLayoutResolver();

      roots.clear();
      primaryOverride.clear();
      final first = resolver.resolve(resolutionRequest);
      final second = resolver.resolve(resolutionRequest);

      expect(first, second);
      expect(primaryIds(first), [ActionId('3'), ActionId('2'), ActionId('1')]);
      expect(first.primary.clear, throwsUnsupportedError);
      expect(resolutionRequest.actions.roots, hasLength(3));
      expect(resolutionRequest.primaryOrderOverride, [
        ActionId('3'),
        ActionId('1'),
      ]);
    });

    test('keeps capacity placement independent from ordering', () {
      final roots = ['1', '2', '3'].map(action).toList();
      final wideRequest = request(
        roots: roots,
        capacity: 20,
        primaryOverride: [ActionId('3'), ActionId('2')],
        overflowOverride: [ActionId('3'), ActionId('2')],
      );
      final narrowRequest = request(
        roots: roots,
        capacity: 10,
        primaryOverride: [ActionId('3'), ActionId('2')],
        overflowOverride: [ActionId('3'), ActionId('2')],
      );
      const resolver = ActionLayoutResolver();

      final wideLayout = resolver.resolve(wideRequest);
      final narrowLayout = resolver.resolve(narrowRequest);

      expect(primaryIds(wideLayout), [ActionId('1'), ActionId('2')]);
      expect(overflowIds(wideLayout), [ActionId('3')]);
      expect(primaryIds(narrowLayout), [ActionId('1')]);
      expect(overflowIds(narrowLayout), [ActionId('3'), ActionId('2')]);
    });

    test('moves a menu root without reordering its children', () {
      final firstChild = action('first-child');
      final secondChild = action('second-child');
      final menu = action('menu', children: [firstChild, secondChild]);
      final peer = action('peer');
      final resolutionRequest = request(
        roots: [menu, peer],
        capacity: 0,
        overflowOverride: [peer.id, menu.id],
      );

      final layout = const ActionLayoutResolver().resolve(resolutionRequest);

      expect(layout.overflow, [peer, menu]);
      expect(layout.overflow.last.children, [firstChild, secondChild]);
    });

    test('keeps indivisible constraints placed together but orders roots', () {
      final first = action('first');
      final outside = action('outside');
      final second = action('second');
      final resolutionRequest = request(
        roots: [first, outside, second],
        placementConstraints: [
          ActionPlacementConstraints(
            id: ActionPlacementConstraintId('pair'),
            actionIds: [first.id, second.id],
            splitPolicy: ActionPlacementSplitPolicy.indivisible,
            retentionPriority: PrimaryRetentionPriority.normal,
          ),
        ],
        capacity: 30,
        primaryOverride: [second.id, first.id],
      );

      final layout = const ActionLayoutResolver().resolve(resolutionRequest);

      expect(primaryIds(layout), [second.id, outside.id, first.id]);
      expect(layout.overflow, isEmpty);
    });

    test('preserves hidden entries and diagnostics', () {
      final hidden = action('hidden', placement: ActionPlacement.hidden);
      final resolutionRequest = ActionLayoutRequest(
        actions: ActionCollection(roots: [hidden]),
        constraints: ActionLayoutConstraints(primaryCapacity: 0),
        capabilities: const RendererCapabilities(),
      );
      final placementDelegate = _RecordingPlacementDelegate();

      final layout = ActionLayoutResolver(
        placementDelegate: placementDelegate,
      ).resolve(resolutionRequest);
      final placement =
          placementDelegate.lastPlacement! as ActionPlacementResult<String>;

      expect(layout.hidden, placement.hidden);
      expect(layout.diagnostics, placement.diagnostics);
      expect(layout.hidden.single, same(placement.hidden.single));
      expect(layout.diagnostics.single, same(placement.diagnostics.single));
    });
  });
}

final class _OverflowPlacementDelegate implements ActionPlacementDelegate {
  const _OverflowPlacementDelegate();

  @override
  ActionPlacementResult<T> resolve<T extends Object>(
    ActionLayoutRequest<T> request,
  ) => ActionPlacementResult(overflow: request.actions.roots);
}

final class _RecordingPlacementDelegate implements ActionPlacementDelegate {
  Object? lastPlacement;

  @override
  ActionPlacementResult<T> resolve<T extends Object>(
    ActionLayoutRequest<T> request,
  ) {
    final placement = const DefaultActionPlacementDelegate().resolve(request);
    lastPlacement = placement;
    return placement;
  }
}
