import 'package:adaptive_actions/adaptive_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AdaptiveAction<String> action(
    String id, {
    ActionPlacement placement = ActionPlacement.automatic,
  }) => AdaptiveAction.action(
    id: ActionId(id),
    metadata: ActionMetadata(label: id),
    payload: id,
    placementPolicy: ActionPlacementPolicy(placement: placement),
  );

  ActionLayoutProfile costs(String id, [double cost = 48]) =>
      ActionLayoutProfile(
        actionId: ActionId(id),
        options: [
          ActionLayoutOption(id: ActionLayoutOptionId('primary'), cost: cost),
        ],
      );

  const capabilities = RendererCapabilities();

  group('ActionLayoutRequest', () {
    test('is immutable and structurally comparable', () {
      final save = action('save');
      final collection = ActionCollection(roots: [save]);
      final constraints = ActionLayoutConstraints(
        primaryCapacity: 100,
        profiles: [costs('save')],
      );
      final primaryOverride = [ActionId('unknown'), ActionId('save')];
      final overflowOverride = [ActionId('save')];
      final request = ActionLayoutRequest(
        actions: collection,
        constraints: constraints,
        capabilities: capabilities,
        primaryOrderOverride: primaryOverride,
        overflowOrderOverride: overflowOverride,
      );

      primaryOverride.clear();
      overflowOverride.clear();

      expect(request.primaryOrderOverride, [
        ActionId('unknown'),
        ActionId('save'),
      ]);
      expect(request.overflowOrderOverride, [ActionId('save')]);
      expect(request.primaryOrderOverride.clear, throwsUnsupportedError);
      expect(request.overflowOrderOverride.clear, throwsUnsupportedError);
      expect(
        request,
        ActionLayoutRequest(
          actions: collection,
          constraints: constraints,
          capabilities: capabilities,
          primaryOrderOverride: [ActionId('unknown'), ActionId('save')],
          overflowOrderOverride: [ActionId('save')],
        ),
      );
    });

    test('accepts omitted options for effective overflow and hidden roots', () {
      final request = ActionLayoutRequest(
        actions: ActionCollection(
          roots: [
            action('overflow', placement: ActionPlacement.overflowOnly),
            action('hidden', placement: ActionPlacement.hidden),
          ],
        ),
        constraints: ActionLayoutConstraints(primaryCapacity: 0),
        capabilities: capabilities,
      );

      expect(request.constraints.profiles, isEmpty);
    });

    test('rejects missing options for roots that may enter primary', () {
      for (final placement in [
        ActionPlacement.automatic,
        ActionPlacement.pinned,
      ]) {
        expect(
          () => ActionLayoutRequest(
            actions: ActionCollection(
              roots: [action('save', placement: placement)],
            ),
            constraints: ActionLayoutConstraints(primaryCapacity: 100),
            capabilities: capabilities,
          ),
          throwsArgumentError,
        );
      }
    });

    test('validates costs after splittable constraint placement override', () {
      final hidden = action('hidden', placement: ActionPlacement.hidden);
      final actions = ActionCollection(
        roots: [hidden],
        placementConstraints: [
          ActionPlacementConstraints(
            id: ActionPlacementConstraintId('visible'),
            actionIds: [hidden.id],
            placementOverride: ActionPlacement.pinned,
          ),
        ],
      );

      expect(
        () => ActionLayoutRequest(
          actions: actions,
          constraints: ActionLayoutConstraints(primaryCapacity: 100),
          capabilities: capabilities,
        ),
        throwsArgumentError,
      );
      expect(
        () => ActionLayoutRequest(
          actions: actions,
          constraints: ActionLayoutConstraints(
            primaryCapacity: 100,
            profiles: [costs('hidden')],
          ),
          capabilities: capabilities,
        ),
        returnsNormally,
      );
    });

    test(
      'rejects invalid indivisible automatic and conflicting placement inputs',
      () {
        final first = action('first');
        final second = action('second');
        expect(
          () => ActionLayoutRequest(
            actions: ActionCollection(
              roots: [first, second],
              placementConstraints: [
                ActionPlacementConstraints(
                  id: ActionPlacementConstraintId('automatic'),
                  actionIds: [first.id, second.id],
                  splitPolicy: ActionPlacementSplitPolicy.indivisible,
                ),
              ],
            ),
            constraints: ActionLayoutConstraints(
              primaryCapacity: 100,
              profiles: [costs('first'), costs('second')],
            ),
            capabilities: capabilities,
          ),
          throwsArgumentError,
        );

        final pinned = action('pinned', placement: ActionPlacement.pinned);
        final overflow = action(
          'overflow',
          placement: ActionPlacement.overflowOnly,
        );
        expect(
          () => ActionLayoutRequest(
            actions: ActionCollection(
              roots: [pinned, overflow],
              placementConstraints: [
                ActionPlacementConstraints(
                  id: ActionPlacementConstraintId('conflict'),
                  actionIds: [pinned.id, overflow.id],
                  splitPolicy: ActionPlacementSplitPolicy.indivisible,
                ),
              ],
            ),
            constraints: ActionLayoutConstraints(
              primaryCapacity: 100,
              profiles: [costs('pinned')],
            ),
            capabilities: capabilities,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      'accepts explicit retention priority for indivisible automatic constraints',
      () {
        final first = action('first');
        final second = action('second');
        expect(
          () => ActionLayoutRequest(
            actions: ActionCollection(
              roots: [first, second],
              placementConstraints: [
                ActionPlacementConstraints(
                  id: ActionPlacementConstraintId('automatic'),
                  actionIds: [first.id, second.id],
                  splitPolicy: ActionPlacementSplitPolicy.indivisible,
                  retentionPriority: PrimaryRetentionPriority.high,
                ),
              ],
            ),
            constraints: ActionLayoutConstraints(
              primaryCapacity: 100,
              profiles: [costs('first'), costs('second')],
            ),
            capabilities: capabilities,
          ),
          returnsNormally,
        );
      },
    );

    test('rejects layout profiles for unknown and non-root actions', () {
      final child = action('child');
      final menu = AdaptiveAction<String>.menu(
        id: ActionId('menu'),
        metadata: const ActionMetadata(label: 'Menu'),
        children: [child],
      );
      final collection = ActionCollection(roots: [menu]);

      for (final id in ['unknown', 'child']) {
        expect(
          () => ActionLayoutRequest(
            actions: collection,
            constraints: ActionLayoutConstraints(
              primaryCapacity: 100,
              profiles: [costs('menu'), costs(id)],
            ),
            capabilities: capabilities,
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects duplicate IDs within either order override', () {
      final collection = ActionCollection<String>(roots: const []);
      final constraints = ActionLayoutConstraints(primaryCapacity: 0);

      expect(
        () => ActionLayoutRequest(
          actions: collection,
          constraints: constraints,
          capabilities: capabilities,
          primaryOrderOverride: [ActionId('a'), ActionId('a')],
        ),
        throwsArgumentError,
      );
      expect(
        () => ActionLayoutRequest(
          actions: collection,
          constraints: constraints,
          capabilities: capabilities,
          overflowOrderOverride: [ActionId('a'), ActionId('a')],
        ),
        throwsArgumentError,
      );
    });
  });

  group('layout outputs', () {
    test('strongly separates primary options from overflow actions', () {
      final child = action('child');
      final menu = AdaptiveAction<String>.menu(
        id: ActionId('menu'),
        metadata: const ActionMetadata(label: 'Menu'),
        children: [child],
      );
      final overflow = action(
        'overflow',
        placement: ActionPlacement.overflowOnly,
      );
      final hidden = action('hidden', placement: ActionPlacement.hidden);
      final primaryEntry = ResolvedPrimaryAction(
        action: menu,
        optionId: ActionLayoutOptionId('primary'),
      );
      final hiddenEntry = HiddenAction(
        action: hidden,
        reason: HiddenActionReason.forcedHidden,
      );
      final diagnostic = ResolutionDiagnostic(
        code: ResolutionDiagnosticCode.forcedHidden,
        actionIds: [hidden.id],
      );
      final placement = ActionPlacementResult(
        primary: [primaryEntry],
        overflow: [overflow],
        hidden: [hiddenEntry],
        diagnostics: [diagnostic],
      );
      final layout = ActionLayoutResult(
        primary: [primaryEntry],
        overflow: [overflow],
        hidden: [hiddenEntry],
        diagnostics: [diagnostic],
      );

      expect(placement.primary.single.action.children, [child]);
      expect(placement.overflow, [overflow]);
      expect(placement.hidden, [hiddenEntry]);
      expect(
        layout,
        ActionLayoutResult(
          primary: [primaryEntry],
          overflow: [overflow],
          hidden: [hiddenEntry],
          diagnostics: [diagnostic],
        ),
      );
      expect(layout.primary.clear, throwsUnsupportedError);
      expect(layout.overflow.clear, throwsUnsupportedError);
      expect(layout.hidden.clear, throwsUnsupportedError);
      expect(layout.diagnostics.clear, throwsUnsupportedError);
    });

    test('defensively copies every result and diagnostic collection', () {
      final save = action('save');
      final resolved = ResolvedPrimaryAction(
        action: save,
        optionId: ActionLayoutOptionId('primary'),
      );
      final primary = [resolved];
      final actionIds = [save.id];
      final diagnostic = ResolutionDiagnostic(
        code: ResolutionDiagnosticCode.unsatisfiedPinnedConstraint,
        actionIds: actionIds,
      );
      final diagnostics = [diagnostic];
      final result = ActionPlacementResult(
        primary: primary,
        diagnostics: diagnostics,
      );

      primary.clear();
      actionIds.clear();
      diagnostics.clear();

      expect(result.primary, [resolved]);
      expect(result.diagnostics.single.actionIds, [save.id]);
      expect(result.primary.clear, throwsUnsupportedError);
      expect(result.diagnostics.clear, throwsUnsupportedError);
      expect(result.diagnostics.single.actionIds.clear, throwsUnsupportedError);
    });

    test('exposes all diagnostic and hidden reason categories', () {
      expect(ResolutionDiagnosticCode.values, [
        ResolutionDiagnosticCode.forcedHidden,
        ResolutionDiagnosticCode.insufficientCapacity,
        ResolutionDiagnosticCode.unsatisfiedPinnedConstraint,
        ResolutionDiagnosticCode.invalidRequest,
      ]);
      expect(HiddenActionReason.values, [
        HiddenActionReason.forcedHidden,
        HiddenActionReason.insufficientCapacity,
      ]);
    });
  });
}
