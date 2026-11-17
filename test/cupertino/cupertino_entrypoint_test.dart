import 'package:adaptive_actions/cupertino.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
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
    const primaryColor = CupertinoColors.systemTeal;
    Widget actionButtonBuilder(
      BuildContext context,
      AdaptiveAction<String> action,
      VoidCallback? onPressed,
      CupertinoActionButtonDefaultBuilder<String> defaultBuilder,
    ) {
      expect(
        CupertinoTheme.of(context).primaryColor,
        CupertinoDynamicColor.resolve(primaryColor, context),
      );
      expect(Localizations.localeOf(context), const Locale('zh'));
      expect(
        CupertinoLocalizations.of(context),
        isA<GlobalCupertinoLocalizations>(),
      );
      return defaultBuilder(context, action, onPressed);
    }

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
        theme: const CupertinoThemeData(primaryColor: primaryColor),
        locale: const Locale('zh'),
        supportedLocales: const [Locale('en'), Locale('zh')],
        localizationsDelegates: GlobalCupertinoLocalizations.delegates,
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));

    expect(invoked, ['save-command']);
  });
}
