import 'package:adaptive_actions/cupertino.dart' as adaptive_cupertino;
import 'package:adaptive_actions/material.dart' as adaptive_material;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Material and Cupertino preserve equivalent placement and final order',
    (tester) async {
      adaptive_cupertino.AdaptiveAction<String> action(
        String id,
        String label,
        adaptive_cupertino.ActionPlacementPolicy placementPolicy,
      ) => adaptive_cupertino.AdaptiveAction.action(
        id: adaptive_cupertino.ActionId(id),
        metadata: adaptive_cupertino.ActionMetadata(label: label),
        payload: '$id-command',
        placementPolicy: placementPolicy,
      );

      final low = action(
        'low',
        'L',
        adaptive_cupertino.ActionPlacementPolicy(
          automaticPreference: adaptive_cupertino.AutomaticPlacementPreference(
            retentionPriority: adaptive_cupertino.PrimaryRetentionPriority.low,
          ),
        ),
      );
      final pinned = action(
        'pinned',
        'P',
        adaptive_cupertino.ActionPlacementPolicy(
          placement: adaptive_cupertino.ActionPlacement.pinned,
        ),
      );
      final high = action(
        'high',
        'H',
        adaptive_cupertino.ActionPlacementPolicy(
          automaticPreference: adaptive_cupertino.AutomaticPlacementPreference(
            retentionPriority: adaptive_cupertino.PrimaryRetentionPriority.high,
          ),
        ),
      );
      final overflowOnly = action(
        'overflow',
        'O',
        adaptive_cupertino.ActionPlacementPolicy(
          placement: adaptive_cupertino.ActionPlacement.overflowOnly,
        ),
      );
      final hidden = action(
        'hidden',
        'X',
        adaptive_cupertino.ActionPlacementPolicy(
          placement: adaptive_cupertino.ActionPlacement.hidden,
        ),
      );
      final collection = adaptive_cupertino.ActionCollection(
        roots: [low, pinned, high, overflowOnly, hidden],
      );
      final primaryOrder = [high.id, pinned.id];
      final overflowOrder = [overflowOnly.id, low.id];
      final materialDelegate = _PlacementSnapshotDelegate();
      final cupertinoDelegate = _PlacementSnapshotDelegate();

      await tester.pumpWidget(
        material.MaterialApp(
          home: material.Scaffold(
            body: adaptive_material.MaterialAdaptiveActions<String>.moreAction(
              actions: collection,
              onInvoke: (_) {},
              primaryCapacity: 144,
              primaryOrderOverride: primaryOrder,
              overflowOrderOverride: overflowOrder,
              resolver: adaptive_material.ActionLayoutResolver(
                placementDelegate: materialDelegate,
              ),
              overflowTooltip: 'More actions',
              fadeDuration: Duration.zero,
              resizeDuration: Duration.zero,
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text('H')).dx,
        lessThan(tester.getTopLeft(find.text('P')).dx),
      );
      expect(find.text('L'), findsNothing);
      expect(find.text('O'), findsNothing);
      expect(find.text('X'), findsNothing);
      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('O')).dy,
        lessThan(tester.getTopLeft(find.text('L')).dy),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child:
                adaptive_cupertino.CupertinoAdaptiveActions<String>.moreAction(
                  actions: collection,
                  onInvoke: (_) {},
                  primaryCapacity: 144,
                  primaryOrderOverride: primaryOrder,
                  overflowOrderOverride: overflowOrder,
                  resolver: adaptive_cupertino.ActionLayoutResolver(
                    placementDelegate: cupertinoDelegate,
                  ),
                  fadeDuration: Duration.zero,
                  resizeDuration: Duration.zero,
                ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text('H')).dx,
        lessThan(tester.getTopLeft(find.text('P')).dx),
      );
      expect(find.text('L'), findsNothing);
      expect(find.text('O'), findsNothing);
      expect(find.text('X'), findsNothing);
      await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('O')).dy,
        lessThan(tester.getTopLeft(find.text('L')).dy),
      );

      expect(cupertinoDelegate.primaryIds, materialDelegate.primaryIds);
      expect(cupertinoDelegate.overflowIds, materialDelegate.overflowIds);
      expect(cupertinoDelegate.hiddenIds, materialDelegate.hiddenIds);
      expect(
        cupertinoDelegate.selectedOptionIds,
        isNot(materialDelegate.selectedOptionIds),
      );
      expect(
        cupertinoDelegate.preferredCosts[high.id],
        isNot(materialDelegate.preferredCosts[high.id]),
      );
    },
  );
}

final class _PlacementSnapshotDelegate
    implements adaptive_cupertino.ActionPlacementDelegate {
  final _delegate = const adaptive_cupertino.DefaultActionPlacementDelegate();

  List<adaptive_cupertino.ActionId> primaryIds = const [];
  List<adaptive_cupertino.ActionId> overflowIds = const [];
  List<adaptive_cupertino.ActionId> hiddenIds = const [];
  List<adaptive_cupertino.ActionLayoutOptionId> selectedOptionIds = const [];
  Map<adaptive_cupertino.ActionId, double> preferredCosts = const {};

  @override
  adaptive_cupertino.ActionPlacementResult<T> resolve<T extends Object>(
    adaptive_cupertino.ActionLayoutRequest<T> request,
  ) {
    final result = _delegate.resolve(request);
    primaryIds = [for (final entry in result.primary) entry.action.id];
    overflowIds = [for (final action in result.overflow) action.id];
    hiddenIds = [for (final entry in result.hidden) entry.action.id];
    selectedOptionIds = [for (final entry in result.primary) entry.optionId];
    preferredCosts = {
      for (final profile in request.constraints.profiles.values)
        profile.actionId: profile.options.first.cost,
    };
    return result;
  }
}
