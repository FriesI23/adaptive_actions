import 'package:adaptive_actions/adaptive_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AdaptiveAction<String> action(
    String id, {
    ActionPlacement placement = ActionPlacement.automatic,
    PrimaryRetentionPriority retentionPriority =
        PrimaryRetentionPriority.normal,
    bool allowsHiding = false,
    List<AdaptiveAction<String>> children = const [],
  }) {
    final policy = ActionPlacementPolicy(
      placement: placement,
      automaticPreference: placement == ActionPlacement.automatic
          ? AutomaticPlacementPreference(
              retentionPriority: retentionPriority,
              allowsHiding: allowsHiding,
            )
          : null,
    );
    if (children.isNotEmpty) {
      return AdaptiveAction.menu(
        id: ActionId(id),
        metadata: ActionMetadata(label: id),
        children: children,
        placementPolicy: policy,
      );
    }
    return AdaptiveAction.action(
      id: ActionId(id),
      metadata: ActionMetadata(label: id),
      payload: id,
      placementPolicy: policy,
    );
  }

  ActionLayoutProfile costs(
    String id, {
    Map<String, double> options = const {'preferred': 10},
  }) => ActionLayoutProfile(
    actionId: ActionId(id),
    options: [
      for (final entry in options.entries)
        ActionLayoutOption(
          id: ActionLayoutOptionId(entry.key),
          cost: entry.value,
        ),
    ],
  );

  ActionLayoutRequest<String> request({
    required List<AdaptiveAction<String>> roots,
    List<ActionPlacementConstraints> placementConstraints = const [],
    double capacity = 100,
    int? maxPrimaryActions,
    double triggerCost = 0,
    List<ActionLayoutProfile>? profiles,
  }) => ActionLayoutRequest(
    actions: ActionCollection(
      roots: roots,
      placementConstraints: placementConstraints,
    ),
    constraints: ActionLayoutConstraints(
      primaryCapacity: capacity,
      maxPrimaryActions: maxPrimaryActions,
      overflowTriggerCost: triggerCost,
      profiles: profiles ?? [for (final root in roots) costs(root.id.value)],
    ),
    capabilities: const RendererCapabilities(),
  );

  const delegate = DefaultActionPlacementDelegate();

  Iterable<ActionId> primaryIds(ActionPlacementResult<String> result) =>
      result.primary.map((entry) => entry.action.id);

  Iterable<ActionLayoutOptionId> primaryOptions(
    ActionPlacementResult<String> result,
  ) => result.primary.map((entry) => entry.optionId);

  Iterable<ActionId> overflowIds(ActionPlacementResult<String> result) =>
      result.overflow.map((action) => action.id);

  group('fixed placement', () {
    test('resolves all regions in root declaration order', () {
      final automatic = action('automatic');
      final hidden = action('hidden', placement: ActionPlacement.hidden);
      final pinned = action('pinned', placement: ActionPlacement.pinned);
      final overflow = action(
        'overflow',
        placement: ActionPlacement.overflowOnly,
      );

      final result = delegate.resolve(
        request(roots: [automatic, hidden, pinned, overflow]),
      );

      expect(primaryIds(result), [automatic.id, pinned.id]);
      expect(overflowIds(result), [overflow.id]);
      expect(result.hidden.map((entry) => entry.action.id), [hidden.id]);
      expect(result.hidden.single.reason, HiddenActionReason.forcedHidden);
      expect(
        result.diagnostics.single.code,
        ResolutionDiagnosticCode.forcedHidden,
      );
    });

    test('keeps a complete subtree attached to its root', () {
      final child = action('child');
      final menu = action(
        'menu',
        placement: ActionPlacement.overflowOnly,
        children: [child],
      );

      final result = delegate.resolve(request(roots: [menu]));

      expect(result.overflow.single, same(menu));
      expect(result.overflow.single.children, [child]);
    });

    test(
      'retains pinned roots and diagnoses exact capacity and count limits',
      () {
        final first = action('first', placement: ActionPlacement.pinned);
        final second = action('second', placement: ActionPlacement.pinned);
        final exact = delegate.resolve(
          request(roots: [first], capacity: 10, maxPrimaryActions: 1),
        );
        final exceeded = delegate.resolve(
          request(roots: [first, second], capacity: 19, maxPrimaryActions: 1),
        );

        expect(exact.diagnostics, isEmpty);
        expect(primaryIds(exceeded), [first.id, second.id]);
        expect(
          exceeded.diagnostics.single.code,
          ResolutionDiagnosticCode.unsatisfiedPinnedConstraint,
        );
        expect(exceeded.diagnostics.single.actionIds, [first.id, second.id]);
      },
    );
  });

  group('automatic placement and layout options', () {
    test(
      'retains higher priorities with stable ties but outputs root order',
      () {
        final low = action(
          'low',
          retentionPriority: PrimaryRetentionPriority.low,
        );
        final firstHigh = action(
          'first-high',
          retentionPriority: PrimaryRetentionPriority.high,
        );
        final secondHigh = action(
          'second-high',
          retentionPriority: PrimaryRetentionPriority.high,
        );

        final result = delegate.resolve(
          request(
            roots: [low, firstHigh, secondHigh],
            capacity: 20,
            maxPrimaryActions: 2,
          ),
        );

        expect(primaryIds(result), [firstHigh.id, secondHigh.id]);
        expect(overflowIds(result), [low.id]);
        expect(result.diagnostics.single.actionIds, [low.id]);
      },
    );

    test('places with minimum costs then upgrades pinned before automatic', () {
      final automatic = action(
        'automatic',
        retentionPriority: PrimaryRetentionPriority.high,
      );
      final pinned = action('pinned', placement: ActionPlacement.pinned);
      final result = delegate.resolve(
        request(
          roots: [automatic, pinned],
          capacity: 100,
          profiles: [
            costs('automatic', options: {'rich': 70, 'minimum': 30}),
            costs('pinned', options: {'rich': 70, 'minimum': 40}),
          ],
        ),
      );

      expect(primaryIds(result), [automatic.id, pinned.id]);
      expect(primaryOptions(result), [
        ActionLayoutOptionId('minimum'),
        ActionLayoutOptionId('rich'),
      ]);
    });

    test(
      'upgrades automatic options by retention priority after placement',
      () {
        final low = action(
          'low',
          retentionPriority: PrimaryRetentionPriority.low,
        );
        final high = action(
          'high',
          retentionPriority: PrimaryRetentionPriority.high,
        );
        final result = delegate.resolve(
          request(
            roots: [low, high],
            capacity: 90,
            profiles: [
              costs('low', options: {'rich': 60, 'minimum': 30}),
              costs('high', options: {'rich': 60, 'minimum': 30}),
            ],
          ),
        );

        expect(primaryOptions(result), [
          ActionLayoutOptionId('minimum'),
          ActionLayoutOptionId('rich'),
        ]);
      },
    );

    test('uses renderer order to break equal minimum-cost options', () {
      final save = action('save');
      final result = delegate.resolve(
        request(
          roots: [save],
          capacity: 10,
          profiles: [
            costs('save', options: {'first': 10, 'second': 10}),
          ],
        ),
      );

      expect(result.primary.single.optionId, ActionLayoutOptionId('first'));
    });

    test('recomputes once with a newly required overflow trigger', () {
      final roots = [for (var index = 0; index < 4; index++) action('a$index')];
      final result = delegate.resolve(
        request(
          roots: roots,
          capacity: 100,
          triggerCost: 20,
          profiles: [
            for (final root in roots)
              costs(root.id.value, options: const {'minimum': 30}),
          ],
        ),
      );

      expect(primaryIds(result), [roots[0].id, roots[1].id]);
      expect(overflowIds(result), [roots[2].id, roots[3].id]);
      expect(result.diagnostics.single.actionIds, [roots[2].id, roots[3].id]);
    });

    test('reserves the trigger immediately for forced overflow', () {
      final overflow = action(
        'overflow',
        placement: ActionPlacement.overflowOnly,
      );
      final first = action('first');
      final second = action('second');
      final third = action('third');
      final roots = [first, overflow, second, third];

      final result = delegate.resolve(
        request(
          roots: roots,
          capacity: 80,
          triggerCost: 20,
          profiles: [
            for (final root in roots)
              costs(root.id.value, options: const {'minimum': 30}),
          ],
        ),
      );

      expect(primaryIds(result), [first.id, second.id]);
      expect(overflowIds(result), [overflow.id, third.id]);
    });
  });

  group('capacity-aware hiding', () {
    test('hides an optional overflow when its trigger alone breaks pinned', () {
      final pinned = action('pinned', placement: ActionPlacement.pinned);
      final optional = action('optional', allowsHiding: true);
      final result = delegate.resolve(
        request(
          roots: [pinned, optional],
          capacity: 100,
          triggerCost: 30,
          profiles: [
            costs('pinned', options: const {'minimum': 80}),
            costs('optional', options: const {'minimum': 30}),
          ],
        ),
      );

      expect(primaryIds(result), [pinned.id]);
      expect(result.overflow, isEmpty);
      expect(result.hidden.single.action.id, optional.id);
      expect(
        result.hidden.single.reason,
        HiddenActionReason.insufficientCapacity,
      );
      expect(
        result.diagnostics.single.code,
        ResolutionDiagnosticCode.insufficientCapacity,
      );
    });

    test('keeps optional actions accessible when the trigger fits', () {
      final pinned = action('pinned', placement: ActionPlacement.pinned);
      final optional = action('optional', allowsHiding: true);
      final result = delegate.resolve(
        request(
          roots: [pinned, optional],
          capacity: 100,
          triggerCost: 30,
          profiles: [
            costs('pinned', options: const {'minimum': 70}),
            costs('optional', options: const {'minimum': 40}),
          ],
        ),
      );

      expect(overflowIds(result), [optional.id]);
      expect(result.hidden, isEmpty);
      expect(result.diagnostics.single.actionIds, [optional.id]);
    });

    test('keeps overflow when any automatic action cannot be hidden', () {
      final pinned = action('pinned', placement: ActionPlacement.pinned);
      final required = action('required');
      final result = delegate.resolve(
        request(
          roots: [pinned, required],
          capacity: 100,
          triggerCost: 30,
          profiles: [
            costs('pinned', options: const {'minimum': 80}),
            costs('required', options: const {'minimum': 30}),
          ],
        ),
      );

      expect(overflowIds(result), [required.id]);
      expect(result.hidden, isEmpty);
      expect(result.diagnostics.map((item) => item.code), [
        ResolutionDiagnosticCode.insufficientCapacity,
        ResolutionDiagnosticCode.unsatisfiedPinnedConstraint,
      ]);
    });
  });

  group('placement constraints', () {
    test('unconfigured splittable constraints resolve as flat actions', () {
      final low = action(
        'low',
        retentionPriority: PrimaryRetentionPriority.low,
      );
      final high = action(
        'high',
        retentionPriority: PrimaryRetentionPriority.high,
      );
      final placementConstraints = ActionPlacementConstraints(
        id: ActionPlacementConstraintId('flat'),
        actionIds: [low.id, high.id],
      );

      final result = delegate.resolve(
        request(
          roots: [low, high],
          placementConstraints: [placementConstraints],
          capacity: 10,
          maxPrimaryActions: 1,
        ),
      );

      expect(primaryIds(result), [high.id]);
      expect(overflowIds(result), [low.id]);
    });

    test(
      'splittable constraint retention priority overrides action priorities',
      () {
        final first = action(
          'first',
          retentionPriority: PrimaryRetentionPriority.low,
        );
        final second = action(
          'second',
          retentionPriority: PrimaryRetentionPriority.high,
        );
        final outside = action(
          'outside',
          retentionPriority: PrimaryRetentionPriority.normal,
        );
        final placementConstraints = ActionPlacementConstraints(
          id: ActionPlacementConstraintId('same-retentionPriority'),
          actionIds: [first.id, second.id],
          retentionPriority: PrimaryRetentionPriority.high,
        );

        final result = delegate.resolve(
          request(
            roots: [outside, first, second],
            placementConstraints: [placementConstraints],
            capacity: 20,
            maxPrimaryActions: 2,
          ),
        );

        expect(primaryIds(result), [first.id, second.id]);
        expect(overflowIds(result), [outside.id]);
      },
    );

    test('constraint placement override replaces action placements', () {
      final hidden = action('hidden', placement: ActionPlacement.hidden);
      final overflow = action(
        'overflow',
        placement: ActionPlacement.overflowOnly,
      );
      final placementConstraints = ActionPlacementConstraints(
        id: ActionPlacementConstraintId('pinned'),
        actionIds: [hidden.id, overflow.id],
        placementOverride: ActionPlacement.pinned,
      );

      final result = delegate.resolve(
        request(
          roots: [hidden, overflow],
          placementConstraints: [placementConstraints],
          capacity: 20,
        ),
      );

      expect(primaryIds(result), [hidden.id, overflow.id]);
      expect(result.overflow, isEmpty);
      expect(result.hidden, isEmpty);
    });

    test('places non-contiguous indivisible constraints as one unit', () {
      final first = action('first');
      final outside = action('outside');
      final second = action('second');
      final placementConstraints = ActionPlacementConstraints(
        id: ActionPlacementConstraintId('pair'),
        actionIds: [first.id, second.id],
        splitPolicy: ActionPlacementSplitPolicy.indivisible,
        retentionPriority: PrimaryRetentionPriority.high,
      );

      final result = delegate.resolve(
        request(
          roots: [first, outside, second],
          placementConstraints: [placementConstraints],
          capacity: 20,
          maxPrimaryActions: 2,
        ),
      );

      expect(primaryIds(result), [first.id, second.id]);
      expect(overflowIds(result), [outside.id]);
    });

    test('upgrades indivisible actions in constraint action ID order', () {
      final first = action('first');
      final second = action('second');
      final placementConstraints = ActionPlacementConstraints(
        id: ActionPlacementConstraintId('pair'),
        actionIds: [second.id, first.id],
        splitPolicy: ActionPlacementSplitPolicy.indivisible,
        retentionPriority: PrimaryRetentionPriority.normal,
      );

      final result = delegate.resolve(
        request(
          roots: [first, second],
          placementConstraints: [placementConstraints],
          capacity: 70,
          profiles: [
            costs('first', options: {'rich': 50, 'minimum': 20}),
            costs('second', options: {'rich': 50, 'minimum': 20}),
          ],
        ),
      );

      expect(primaryOptions(result), [
        ActionLayoutOptionId('minimum'),
        ActionLayoutOptionId('rich'),
      ]);
    });

    test(
      'moves indivisible constraints together when minimum cost does not fit',
      () {
        final first = action('first');
        final second = action('second');
        final placementConstraints = ActionPlacementConstraints(
          id: ActionPlacementConstraintId('pair'),
          actionIds: [first.id, second.id],
          splitPolicy: ActionPlacementSplitPolicy.indivisible,
          retentionPriority: PrimaryRetentionPriority.normal,
        );

        final result = delegate.resolve(
          request(
            roots: [first, second],
            placementConstraints: [placementConstraints],
            capacity: 30,
            profiles: [
              costs('first', options: const {'minimum': 20}),
              costs('second', options: const {'minimum': 20}),
            ],
          ),
        );

        expect(result.primary, isEmpty);
        expect(overflowIds(result), [first.id, second.id]);
      },
    );

    test(
      'a pinned action keeps indivisible constraints and diagnoses all actions',
      () {
        final automatic = action('automatic');
        final pinned = action('pinned', placement: ActionPlacement.pinned);
        final placementConstraints = ActionPlacementConstraints(
          id: ActionPlacementConstraintId('pinned-pair'),
          actionIds: [pinned.id, automatic.id],
          splitPolicy: ActionPlacementSplitPolicy.indivisible,
        );

        final result = delegate.resolve(
          request(
            roots: [automatic, pinned],
            placementConstraints: [placementConstraints],
            capacity: 15,
          ),
        );

        expect(primaryIds(result), [automatic.id, pinned.id]);
        expect(
          result.diagnostics.single.code,
          ResolutionDiagnosticCode.unsatisfiedPinnedConstraint,
        );
        expect(result.diagnostics.single.actionIds, [automatic.id, pinned.id]);
      },
    );

    test('hides indivisible constraints only when every action permits it', () {
      final pinned = action('pinned', placement: ActionPlacement.pinned);
      final first = action('first', allowsHiding: true);
      final second = action('second', allowsHiding: true);
      final placementConstraints = ActionPlacementConstraints(
        id: ActionPlacementConstraintId('optional-pair'),
        actionIds: [first.id, second.id],
        splitPolicy: ActionPlacementSplitPolicy.indivisible,
        retentionPriority: PrimaryRetentionPriority.normal,
      );

      final result = delegate.resolve(
        request(
          roots: [pinned, first, second],
          placementConstraints: [placementConstraints],
          capacity: 100,
          triggerCost: 30,
          profiles: [
            costs('pinned', options: const {'minimum': 80}),
            costs('first', options: const {'minimum': 15}),
            costs('second', options: const {'minimum': 15}),
          ],
        ),
      );

      expect(result.overflow, isEmpty);
      expect(result.hidden.map((entry) => entry.action.id), [
        first.id,
        second.id,
      ]);
      expect(
        result.hidden.every(
          (entry) => entry.reason == HiddenActionReason.insufficientCapacity,
        ),
        isTrue,
      );
    });

    test('keeps menu subtrees intact when indivisible constraints move', () {
      final child = action('child');
      final menu = action('menu', children: [child]);
      final peer = action('peer');
      final placementConstraints = ActionPlacementConstraints(
        id: ActionPlacementConstraintId('menu-pair'),
        actionIds: [menu.id, peer.id],
        splitPolicy: ActionPlacementSplitPolicy.indivisible,
        retentionPriority: PrimaryRetentionPriority.normal,
      );

      final result = delegate.resolve(
        request(
          roots: [menu, peer],
          placementConstraints: [placementConstraints],
          capacity: 10,
        ),
      );

      expect(result.overflow.first, same(menu));
      expect(result.overflow.first.children, [child]);
    });
  });

  test('repeated resolution is deterministic and does not mutate inputs', () {
    final roots = [action('first'), action('second')];
    final profiles = [
      costs('first', options: {'rich': 20, 'minimum': 10}),
      costs('second', options: {'rich': 20, 'minimum': 10}),
    ];
    final resolutionRequest = request(
      roots: roots,
      capacity: 30,
      profiles: profiles,
    );

    final first = delegate.resolve(resolutionRequest);
    final second = delegate.resolve(resolutionRequest);

    expect(first, second);
    expect(resolutionRequest.actions.roots, roots);
    expect(resolutionRequest.constraints.profiles.values, profiles);
  });
}
