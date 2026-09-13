import 'package:adaptive_actions/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cupertino entrypoint exposes core and renderer APIs', (
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
      CupertinoActionButtonDefaultBuilder<String> defaultBuilder,
    ) => defaultBuilder(context, action, onPressed);
    Widget overflowButtonBuilder(
      BuildContext context,
      VoidCallback onPressed,
      CupertinoOverflowButtonDefaultBuilder defaultBuilder,
    ) => defaultBuilder(context, onPressed);
    CupertinoActionPresentation? presentationForAction(
      BuildContext context,
      AdaptiveAction<String> action,
    ) => CupertinoActionPresentation.extended;
    Widget tooltipBuilder(BuildContext context, String message, Widget child) =>
        AdaptiveCupertinoTooltip(
          message: message,
          excludeFromSemantics: true,
          child: child,
        );

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoAdaptiveActions<String>.moreAction(
            actions: ActionCollection(roots: [save]),
            primaryCapacity: 120,
            onInvoke: invoked.add,
            actionButtonBuilder: actionButtonBuilder,
            overflowButtonBuilder: overflowButtonBuilder,
            tooltipBuilder: tooltipBuilder,
            presentationForAction: presentationForAction,
            fadeDuration: Duration.zero,
            resizeDuration: Duration.zero,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));

    expect(invoked, ['save-command']);
  });
}
