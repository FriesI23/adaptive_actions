import 'package:adaptive_actions/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('material entrypoint exposes core and renderer APIs', (
    tester,
  ) async {
    final save = AdaptiveAction<String>.action(
      id: ActionId('save'),
      metadata: const ActionMetadata(label: 'Save'),
      payload: 'save-command',
    );
    final invoked = <String>[];
    Widget actionButtonBuilder(
      BuildContext context,
      AdaptiveAction<String> action,
      VoidCallback? onPressed,
      MaterialActionButtonDefaultBuilder<String> defaultBuilder,
    ) => defaultBuilder(context, action, onPressed);
    Widget overflowButtonBuilder(
      BuildContext context,
      VoidCallback onPressed,
      MaterialOverflowButtonDefaultBuilder defaultBuilder,
    ) => defaultBuilder(context, onPressed);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialAdaptiveActions<String>.moreAction(
            actions: ActionCollection(roots: [save]),
            primaryCapacity: 120,
            onInvoke: invoked.add,
            actionButtonBuilder: actionButtonBuilder,
            overflowButtonBuilder: overflowButtonBuilder,
            fadeDuration: Duration.zero,
            resizeDuration: Duration.zero,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));

    expect(invoked, ['save-command']);
  });

  testWidgets('accepts a custom resolver through the public entrypoint', (
    tester,
  ) async {
    final save = AdaptiveAction<String>.action(
      id: ActionId('save'),
      metadata: const ActionMetadata(label: 'Save'),
      payload: 'save-command',
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialAdaptiveActions<String>.moreAction(
            actions: ActionCollection(roots: [save]),
            resolver: ActionLayoutResolver(
              placementDelegate: _OverflowPlacementDelegate(),
            ),
            primaryCapacity: 120,
            onInvoke: invoked.add,
            overflowTooltip: 'More actions',
            fadeDuration: Duration.zero,
            resizeDuration: Duration.zero,
          ),
        ),
      ),
    );

    expect(find.text('Save'), findsNothing);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(invoked, ['save-command']);
  });
}

final class _OverflowPlacementDelegate implements ActionPlacementDelegate {
  @override
  ActionPlacementResult<T> resolve<T extends Object>(
    ActionLayoutRequest<T> request,
  ) => ActionPlacementResult(overflow: request.actions.roots);
}
