import 'package:adaptive_actions/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testPrimaryColor = Color(0xFF6750A4);

  test('CupertinoAdaptiveActionsStyle copyWith replaces selected metrics', () {
    const original = CupertinoAdaptiveActionsStyle(
      height: 46,
      minimumButtonWidth: 45,
      iconButtonWidth: 43,
      submenuButtonWidth: 26,
      overflowButtonWidth: 42,
      iconSize: 19,
      iconLabelSpacing: 5,
      horizontalPadding: 9,
    );

    final changed = original.copyWith(
      height: 52,
      overflowButtonWidth: 48,
      iconSize: 22,
    );

    expect(changed.height, 52);
    expect(changed.iconSize, 22);
    expect(changed.minimumButtonWidth, original.minimumButtonWidth);
    expect(changed.iconButtonWidth, original.iconButtonWidth);
    expect(changed.submenuButtonWidth, original.submenuButtonWidth);
    expect(changed.overflowButtonWidth, 48);
    expect(changed.iconLabelSpacing, original.iconLabelSpacing);
    expect(changed.horizontalPadding, original.horizontalPadding);
  });

  AdaptiveAction<String> action(
    String id, {
    String? label,
    String? subtitle,
    String? tooltip,
    ActionTooltipPolicy tooltipPolicy = const ActionTooltipPolicy.allowed(),
    String? semanticLabel,
    String? iconKey,
    bool isDestructive = false,
    bool isEnabled = true,
    ActionPlacementPolicy? placementPolicy,
  }) => AdaptiveAction.action(
    id: ActionId(id),
    metadata: ActionMetadata(
      label: label ?? id,
      subtitle: subtitle,
      tooltip: tooltip,
      tooltipPolicy: tooltipPolicy,
      semanticLabel: semanticLabel,
      iconKey: iconKey,
      isDestructive: isDestructive,
    ),
    payload: '$id-command',
    isEnabled: isEnabled,
    placementPolicy: placementPolicy,
  );

  Widget? iconBuilder(BuildContext context, AdaptiveAction<String> action) =>
      switch (action.metadata.iconKey) {
        'save' => const Icon(CupertinoIcons.floppy_disk),
        'open' => const Icon(CupertinoIcons.folder_open),
        'more' => const Icon(CupertinoIcons.ellipsis),
        'share' => const Icon(CupertinoIcons.share),
        'delete' => const Icon(CupertinoIcons.delete),
        'help' => const Icon(CupertinoIcons.question_circle),
        _ => null,
      };

  Widget pumpTarget({
    required ActionCollection<String> actions,
    required ValueChanged<String> onInvoke,
    double width = 300,
    Iterable<ActionId> primaryOrderOverride = const [],
    Iterable<ActionId> overflowOrderOverride = const [],
    CupertinoActionIconBuilder<String>? actionIconBuilder,
    CupertinoActionButtonBuilder<String>? actionButtonBuilder,
    CupertinoActionMenuBuilder<String>? menuBuilderForAction,
    CupertinoOverflowButtonBuilder? overflowButtonBuilder,
    CupertinoActionPresentationCallback<String>? presentationForAction,
    CupertinoActionLabelLayoutCallback<String>? labelLayoutForAction,
    CupertinoActionPresentation? presentationOverride,
    CupertinoAdaptiveActionsStyle style = const CupertinoAdaptiveActionsStyle(),
    int? maxPrimaryActions,
    Duration fadeDuration = Duration.zero,
    Duration resizeDuration = Duration.zero,
    Widget overflowIcon = const Icon(CupertinoIcons.ellipsis),
    String overflowTooltip = 'More actions',
    VoidCallback? onOverflowMenuOpened,
    VoidCallback? onOverflowMenuClosed,
    bool invokeAfterMenuClosed = false,
    ActionLayoutResolver resolver = const ActionLayoutResolver(),
    Brightness brightness = Brightness.light,
    ActionRegionMainAxisDistribution distribution =
        ActionRegionMainAxisDistribution.compact,
    ActionRegionLayoutDelegate? layoutDelegate,
    TextScaler textScaler = TextScaler.noScaling,
  }) => CupertinoApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    theme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: testPrimaryColor,
    ),
    home: CupertinoPageScaffold(
      child: Center(
        child: CupertinoAdaptiveActions<String>.moreAction(
          actions: actions,
          onInvoke: onInvoke,
          primaryCapacity: width,
          primaryOrderOverride: primaryOrderOverride,
          overflowOrderOverride: overflowOrderOverride,
          iconBuilder: actionIconBuilder,
          actionButtonBuilder: actionButtonBuilder,
          menuBuilderForAction: menuBuilderForAction,
          overflowButtonBuilder: overflowButtonBuilder,
          presentationForAction: presentationForAction,
          labelLayoutForAction: labelLayoutForAction,
          presentationOverride: presentationOverride,
          style: style,
          maxPrimaryActions: maxPrimaryActions,
          fadeDuration: fadeDuration,
          resizeDuration: resizeDuration,
          overflowIcon: overflowIcon,
          overflowTooltip: overflowTooltip,
          onOverflowMenuOpened: onOverflowMenuOpened,
          onOverflowMenuClosed: onOverflowMenuClosed,
          invokeAfterMenuClosed: invokeAfterMenuClosed,
          resolver: resolver,
          distribution: distribution,
          layoutDelegate: layoutDelegate,
        ),
      ),
    ),
  );

  testWidgets('scales primary text but keeps icon geometry fixed', (
    tester,
  ) async {
    final save = action('save', label: 'Save', iconKey: 'save');

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 140,
        actionIconBuilder: iconBuilder,
      ),
    );
    expect(find.text('Save'), findsOneWidget);

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 140,
        actionIconBuilder: iconBuilder,
        textScaler: const TextScaler.linear(2),
      ),
    );

    expect(find.text('Save'), findsNothing);
    final iconContext = tester.element(find.byIcon(CupertinoIcons.floppy_disk));
    expect(IconTheme.of(iconContext).size, 20);
    expect(
      tester.getSize(find.byType(CupertinoAdaptiveActions<String>)).width,
      44,
    );
  });

  testWidgets('configures single-line overflow independently per action', (
    tester,
  ) async {
    final save = action(
      'save',
      label: 'Save this document with a deliberately long label',
    );
    final share = action(
      'share',
      label: 'Share this document with another deliberately long label',
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save, share]),
        onInvoke: (_) {},
        width: 300,
        presentationOverride: CupertinoActionPresentation.extended,
        labelLayoutForAction: (context, action) => switch (action.id.value) {
          'save' => const ActionLabelLayout(
            maxWidth: 72,
            overflow: TextOverflow.fade,
          ),
          _ => const ActionLabelLayout(
            maxWidth: 96,
            overflow: TextOverflow.clip,
          ),
        },
      ),
    );

    final label = tester.widget<Text>(find.text(save.metadata.label));
    expect(label.maxLines, 1);
    expect(label.softWrap, isFalse);
    expect(label.overflow, TextOverflow.fade);
    expect(tester.getSize(find.text(save.metadata.label)).width, 72);
    final shareLabel = tester.widget<Text>(find.text(share.metadata.label));
    expect(shareLabel.overflow, TextOverflow.clip);
    expect(tester.getSize(find.text(share.metadata.label)).width, 96);
  });

  test('constructors keep generic and More overflow semantics separate', () {
    final actions = ActionCollection<String>(roots: []);
    final generic = CupertinoAdaptiveActions<String>(
      actions: actions,
      onInvoke: (_) {},
      primaryCapacity: 0,
      overflowIcon: const Icon(CupertinoIcons.square_grid_2x2),
    );
    final more = CupertinoAdaptiveActions<String>.moreAction(
      actions: actions,
      onInvoke: (_) {},
      primaryCapacity: 0,
    );
    final waitsForClose = CupertinoAdaptiveActions<String>.moreAction(
      actions: actions,
      onInvoke: (_) {},
      primaryCapacity: 0,
      invokeAfterMenuClosed: true,
    );

    expect((generic.overflowIcon as Icon).icon, CupertinoIcons.square_grid_2x2);
    expect(generic.overflowTooltip, isEmpty);
    expect((more.overflowIcon as Icon).icon, CupertinoIcons.ellipsis);
    expect(more.overflowTooltip, 'More actions');
    expect(generic.distribution, ActionRegionMainAxisDistribution.compact);
    expect(generic.invokeAfterMenuClosed, isFalse);
    expect(more.invokeAfterMenuClosed, isFalse);
    expect(waitsForClose.invokeAfterMenuClosed, isTrue);
    expect(
      () => CupertinoAdaptiveActions<String>(
        actions: actions,
        onInvoke: (_) {},
        primaryCapacity: 100,
        overflowIcon: const Icon(CupertinoIcons.square_grid_2x2),
        distribution: ActionRegionMainAxisDistribution.spaceBetween,
        layoutDelegate: const _SingleFlexibleActionLayoutDelegate(),
      ),
      throwsAssertionError,
    );
  });

  testWidgets('customizes every primary button through the default builder', (
    tester,
  ) async {
    final leaf = action('leaf');
    final disabled = action('disabled', isEnabled: false);
    final menu = AdaptiveAction<String>.menu(
      id: ActionId('menu'),
      metadata: const ActionMetadata(label: 'menu'),
      children: [action('menu-child')],
    );
    final composite = AdaptiveAction<String>.composite(
      id: ActionId('composite'),
      metadata: const ActionMetadata(label: 'composite'),
      payload: 'composite-command',
      children: [action('composite-child')],
    );
    final seen = <ActionId>{};
    final enabledById = <ActionId, bool>{};
    BoxConstraints? constraints;
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [leaf, disabled, menu, composite]),
        onInvoke: invoked.add,
        width: 1000,
        actionButtonBuilder: (context, action, onPressed, defaultBuilder) {
          seen.add(action.id);
          enabledById[action.id] = onPressed != null;
          return LayoutBuilder(
            builder: (context, value) {
              if (action.id == leaf.id) constraints = value;
              return defaultBuilder(
                context,
                action,
                onPressed == null
                    ? null
                    : () {
                        invoked.add('wrapped');
                        onPressed();
                      },
              );
            },
          );
        },
      ),
    );

    expect(seen, {leaf.id, disabled.id, menu.id, composite.id});
    expect(enabledById[leaf.id], isTrue);
    expect(enabledById[disabled.id], isFalse);
    expect(constraints!.hasTightWidth, isTrue);
    expect(constraints!.hasTightHeight, isTrue);

    await tester.tap(find.text('leaf'));
    expect(invoked, ['wrapped', 'leaf-command']);
  });

  testWidgets('passes the final flexible width to a custom action button', (
    tester,
  ) async {
    BoxConstraints? constraints;
    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [action('save')]),
        onInvoke: (_) {},
        width: 200,
        layoutDelegate: const _SingleFlexibleActionLayoutDelegate(),
        actionButtonBuilder: (context, action, onPressed, defaultBuilder) =>
            LayoutBuilder(
              builder: (context, value) {
                constraints = value;
                return defaultBuilder(context, action, onPressed);
              },
            ),
      ),
    );

    expect(constraints!.hasTightWidth, isTrue);
    expect(constraints!.maxWidth, 200);
  });

  testWidgets('customizes the overflow trigger without replacing its menu', (
    tester,
  ) async {
    final save = action('save');
    BoxConstraints? constraints;
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: invoked.add,
        width: 44,
        maxPrimaryActions: 0,
        overflowButtonBuilder: (context, onPressed, defaultBuilder) =>
            LayoutBuilder(
              builder: (context, value) {
                constraints = value;
                return CupertinoButton(
                  onPressed: onPressed,
                  child: const Text('Custom more'),
                );
              },
            ),
      ),
    );

    expect(constraints, const BoxConstraints.tightFor(width: 44, height: 44));
    await tester.tap(find.text('Custom more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
    expect(invoked, ['save-command']);
  });

  testWidgets('default overflow builder can override only its icon', (
    tester,
  ) async {
    final save = action('save');
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: invoked.add,
        width: 44,
        maxPrimaryActions: 0,
        overflowButtonBuilder: (context, onPressed, defaultBuilder) =>
            defaultBuilder(
              context,
              onPressed,
              icon: const Icon(CupertinoIcons.chevron_forward),
            ),
      ),
    );

    expect(find.byIcon(CupertinoIcons.chevron_forward), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.chevron_forward));
    await tester.pumpAndSettle();
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
    expect(invoked, ['save-command']);
  });

  testWidgets('default builder replacement is render-only', (tester) async {
    final save = action('save');
    final replacement = action('replacement', label: 'Replacement');

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
      ),
    );
    final resolvedWidth = tester
        .getSize(find.byType(CupertinoAdaptiveActions<String>))
        .width;

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        actionButtonBuilder: (context, action, onPressed, defaultBuilder) =>
            defaultBuilder(context, replacement, onPressed),
      ),
    );

    expect(find.text('Replacement'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CupertinoAdaptiveActions<String>)).width,
      resolvedWidth,
    );
  });

  testWidgets('renders final primary order and invokes an enabled payload', (
    tester,
  ) async {
    final save = action('save', iconKey: 'save');
    final share = action('share');
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save, share]),
        onInvoke: invoked.add,
        primaryOrderOverride: [share.id, save.id],
        actionIconBuilder: iconBuilder,
      ),
    );

    expect(
      tester.getTopLeft(find.text('share')).dx,
      lessThan(tester.getTopLeft(find.text('save')).dx),
    );
    await tester.tap(find.text('save'));

    expect(invoked, ['save-command']);
  });

  testWidgets('uses icon option when the extended layout does not fit', (
    tester,
  ) async {
    final save = action('save', label: 'Save document', iconKey: 'save');

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 44,
        actionIconBuilder: iconBuilder,
      ),
    );

    expect(find.text('Save document'), findsNothing);
    expect(find.byIcon(CupertinoIcons.floppy_disk), findsOneWidget);
    expect(
      tester.getSize(find.byType(CupertinoAdaptiveActions<String>)).width,
      44,
    );
  });

  testWidgets('forces extended and icon-only presentations with fallback', (
    tester,
  ) async {
    final save = action(
      'save',
      label: 'Save document',
      iconKey: 'save',
      placementPolicy: ActionPlacementPolicy(placement: ActionPlacement.pinned),
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 44,
        actionIconBuilder: iconBuilder,
        presentationOverride: CupertinoActionPresentation.extended,
      ),
    );
    expect(find.text('Save document'), findsOneWidget);

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 300,
        actionIconBuilder: iconBuilder,
        presentationOverride: CupertinoActionPresentation.iconOnly,
      ),
    );
    expect(find.text('Save document'), findsNothing);

    final noIcon = action('share', label: 'Share document');
    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [noIcon]),
        onInvoke: (_) {},
        presentationOverride: CupertinoActionPresentation.iconOnly,
      ),
    );
    expect(find.text('Share document'), findsOneWidget);
  });

  testWidgets('supports per-action mixed primary presentations', (
    tester,
  ) async {
    final actions = [
      action('save', label: 'Save', iconKey: 'save'),
      action('open', label: 'Open', iconKey: 'open'),
      action('share', label: 'Share', iconKey: 'share'),
      action('delete', label: 'Delete', iconKey: 'delete'),
      action('help', label: 'Help', iconKey: 'help'),
    ];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: actions),
        onInvoke: (_) {},
        width: 500,
        actionIconBuilder: iconBuilder,
        presentationForAction: (context, action) => switch (action.id.value) {
          'share' || 'help' => CupertinoActionPresentation.extended,
          _ => CupertinoActionPresentation.iconOnly,
        },
      ),
    );

    expect(find.text('Save'), findsNothing);
    expect(find.text('Open'), findsNothing);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Help'), findsOneWidget);
    for (final icon in [
      CupertinoIcons.floppy_disk,
      CupertinoIcons.folder_open,
      CupertinoIcons.share,
      CupertinoIcons.delete,
      CupertinoIcons.question_circle,
    ]) {
      expect(find.byIcon(icon), findsOneWidget);
    }
  });

  testWidgets('per-action presentation falls back to global then automatic', (
    tester,
  ) async {
    final save = action('save', label: 'Save', iconKey: 'save');
    final open = action('open', label: 'Open', iconKey: 'open');

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save, open]),
        onInvoke: (_) {},
        width: 300,
        actionIconBuilder: iconBuilder,
        presentationForAction: (context, action) =>
            action.id == save.id ? CupertinoActionPresentation.extended : null,
        presentationOverride: CupertinoActionPresentation.iconOnly,
      ),
    );

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Open'), findsNothing);

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 300,
        actionIconBuilder: iconBuilder,
        presentationForAction: (context, action) => null,
      ),
    );

    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets(
    'forced per-action extended presentation overflows before downgrade',
    (tester) async {
      final save = action('save', label: 'Save document', iconKey: 'save');

      await tester.pumpWidget(
        pumpTarget(
          actions: ActionCollection(roots: [save]),
          onInvoke: (_) {},
          width: 44,
          actionIconBuilder: iconBuilder,
          presentationForAction: (context, action) =>
              CupertinoActionPresentation.extended,
        ),
      );

      expect(find.byIcon(CupertinoIcons.floppy_disk), findsNothing);
      expect(find.byIcon(CupertinoIcons.ellipsis), findsOneWidget);
    },
  );

  testWidgets('per-action icon-only falls back when an action has no icon', (
    tester,
  ) async {
    final share = action('share', label: 'Share document');

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [share]),
        onInvoke: (_) {},
        presentationForAction: (context, action) =>
            CupertinoActionPresentation.iconOnly,
      ),
    );

    expect(find.text('Share document'), findsOneWidget);
  });

  testWidgets('applies style metrics and parent height constraints', (
    tester,
  ) async {
    final save = action('save', iconKey: 'save');
    const style = CupertinoAdaptiveActionsStyle(
      height: 52,
      iconButtonWidth: 50,
      iconSize: 24,
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: SizedBox(
            height: 30,
            child: CupertinoAdaptiveActions<String>.moreAction(
              actions: ActionCollection(roots: [save]),
              onInvoke: (_) {},
              primaryCapacity: 50,
              iconBuilder: iconBuilder,
              style: style,
              fadeDuration: Duration.zero,
              resizeDuration: Duration.zero,
            ),
          ),
        ),
      ),
    );

    final renderer = find.byType(CupertinoAdaptiveActions<String>);
    expect(tester.getSize(renderer), const Size(50, 30));
    expect(tester.getSize(find.byIcon(CupertinoIcons.floppy_disk)).height, 24);
  });

  testWidgets('disabled primary keeps semantics and suppresses payload', (
    tester,
  ) async {
    final save = action(
      'save',
      tooltip: 'Save changes',
      semanticLabel: 'Save document',
      isEnabled: false,
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: invoked.add,
      ),
    );

    expect(find.bySemanticsLabel('Save document'), findsOneWidget);
    await tester.tap(find.text('save'));
    expect(invoked, isEmpty);
  });

  testWidgets('applies tooltip policy to each primary presentation', (
    tester,
  ) async {
    final icon = action('icon', iconKey: 'save');
    final labeled = action('labeled', label: 'Labeled');
    final optedIn = action(
      'opted-in',
      label: 'Opted in',
      tooltipPolicy: const ActionTooltipPolicy.allowed(primaryLabeled: true),
    );
    final hiddenIcon = action(
      'hidden-icon',
      iconKey: 'open',
      tooltipPolicy: const ActionTooltipPolicy.never(),
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [icon, labeled, optedIn, hiddenIcon]),
        onInvoke: (_) {},
        width: 600,
        actionIconBuilder: iconBuilder,
        presentationForAction: (context, current) =>
            current.id == icon.id || current.id == hiddenIcon.id
            ? CupertinoActionPresentation.iconOnly
            : CupertinoActionPresentation.extended,
      ),
    );

    expect(
      find.ancestor(
        of: find.byIcon(CupertinoIcons.floppy_disk),
        matching: find.byType(RawTooltip),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Labeled'),
        matching: find.byType(RawTooltip),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('Opted in'),
        matching: find.byType(RawTooltip),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byIcon(CupertinoIcons.folder_open),
        matching: find.byType(RawTooltip),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'shows primary, overflow, and menu trigger tooltips on mouse hover',
    (tester) async {
      final save = action(
        'save',
        label: 'Save',
        tooltip: 'Save this document',
        iconKey: 'save',
      );
      final archive = action(
        'archive',
        label: 'Archive',
        tooltip: 'Move to archive',
        tooltipPolicy: const ActionTooltipPolicy.allowed(menuItem: true),
        placementPolicy: ActionPlacementPolicy(
          placement: ActionPlacement.overflowOnly,
        ),
      );
      final sort = AdaptiveAction<String>.menu(
        id: ActionId('sort'),
        metadata: const ActionMetadata(
          label: 'Sort',
          tooltip: 'Choose sort order',
          tooltipPolicy: ActionTooltipPolicy.allowed(menuItem: true),
        ),
        children: [action('date')],
        placementPolicy: ActionPlacementPolicy(
          placement: ActionPlacement.overflowOnly,
        ),
      );

      await tester.pumpWidget(
        pumpTarget(
          actions: ActionCollection(roots: [save, archive, sort]),
          onInvoke: (_) {},
          width: 88,
          actionIconBuilder: iconBuilder,
        ),
      );

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: Offset.zero);

      Future<void> hoverTooltip(Finder target, String message) async {
        expect(
          find.ancestor(of: target, matching: find.byType(RawTooltip)),
          findsOneWidget,
        );
        await pointer.moveTo(tester.getCenter(target));
        await tester.pumpAndSettle();
        expect(find.text(message), findsOneWidget);
      }

      await hoverTooltip(
        find.byIcon(CupertinoIcons.floppy_disk),
        'Save this document',
      );
      await pointer.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      await hoverTooltip(find.byIcon(CupertinoIcons.ellipsis), 'More actions');
      await pointer.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
      await tester.pumpAndSettle();

      final archiveItem = find.widgetWithText(CupertinoMenuItem, 'Archive');
      final sortItem = find.widgetWithText(CupertinoMenuItem, 'Sort');
      await hoverTooltip(archiveItem, 'Move to archive');
      await pointer.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      await hoverTooltip(sortItem, 'Choose sort order');
      await pointer.removePointer();
    },
  );

  testWidgets('uses label fallback for touch long-press tooltips', (
    tester,
  ) async {
    final save = action('save', label: 'Save', iconKey: 'save');
    final archive = action(
      'archive',
      label: 'Archive',
      tooltipPolicy: const ActionTooltipPolicy.allowed(menuItem: true),
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save, archive]),
        onInvoke: invoked.add,
        width: 88,
        actionIconBuilder: iconBuilder,
      ),
    );

    final saveButton = find.byIcon(CupertinoIcons.floppy_disk);
    expect(
      find.ancestor(of: saveButton, matching: find.byType(RawTooltip)),
      findsOneWidget,
    );
    expect(tester.getSemantics(find.bySemanticsLabel('Save')).tooltip, isEmpty);
    await tester.longPress(saveButton);
    await tester.pump();
    expect(find.text('Save'), findsOneWidget);
    expect(invoked, isEmpty);

    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    final archiveItem = find.widgetWithText(CupertinoMenuItem, 'Archive');
    expect(
      find.ancestor(of: archiveItem, matching: find.byType(RawTooltip)),
      findsOneWidget,
    );
    await tester.longPress(archiveItem);
    await tester.pump();
    expect(invoked, isEmpty);
  });

  testWidgets('renders native Cupertino menu subtitles but not in primary', (
    tester,
  ) async {
    final save = action(
      'save',
      subtitle: 'Current document',
      iconKey: 'save',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 44,
        actionIconBuilder: iconBuilder,
      ),
    );

    expect(find.text('Current document'), findsNothing);
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();

    final menuItem = tester.widget<CupertinoMenuItem>(
      find.widgetWithText(CupertinoMenuItem, 'save'),
    );
    expect((menuItem.subtitle! as Text).data, 'Current document');
    expect(find.byIcon(CupertinoIcons.floppy_disk), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'save[\s\S]*Current document')),
      findsOneWidget,
    );
  });

  testWidgets('renders subtitles for disabled, submenu, and composite items', (
    tester,
  ) async {
    final disabled = action(
      'disabled',
      subtitle: 'Not currently available',
      semanticLabel: 'Unavailable command',
      isEnabled: false,
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final menu = AdaptiveAction<String>.menu(
      id: ActionId('sort'),
      metadata: const ActionMetadata(
        label: 'Sort',
        subtitle: 'Choose an arrangement',
      ),
      children: [action('date')],
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final composite = AdaptiveAction<String>.composite(
      id: ActionId('open'),
      metadata: const ActionMetadata(
        label: 'Open',
        subtitle: 'Most recent document',
      ),
      payload: 'open-command',
      children: [action('recent')],
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [disabled, menu, composite]),
        onInvoke: (_) {},
        width: 44,
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Unavailable command'), findsOneWidget);
    for (final entry in <(String, String)>[
      ('disabled', 'Not currently available'),
      ('Sort', 'Choose an arrangement'),
      ('Open', 'Most recent document'),
    ]) {
      final item = tester.widget<CupertinoMenuItem>(
        find.widgetWithText(CupertinoMenuItem, entry.$1),
      );
      expect((item.subtitle! as Text).data, entry.$2);
    }

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Most recent document'), findsNWidgets(2));
  });

  testWidgets('allows long native subtitles with large text scaling', (
    tester,
  ) async {
    final details = action(
      'Arrangement options',
      subtitle: 'Choose how every document is arranged in this workspace',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: CupertinoPageScaffold(
            child: CupertinoAdaptiveActions<String>.moreAction(
              actions: ActionCollection(roots: [details]),
              onInvoke: (_) {},
              primaryCapacity: 44,
              fadeDuration: Duration.zero,
              resizeDuration: Duration.zero,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();

    expect(find.text(details.metadata.subtitle!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'primary menu opens an anchored Cupertino menu and invokes child',
    (tester) async {
      final child = action('recent');
      final menu = AdaptiveAction<String>.menu(
        id: ActionId('more'),
        metadata: const ActionMetadata(label: 'More', iconKey: 'more'),
        children: [child],
      );
      final invoked = <String>[];

      await tester.pumpWidget(
        pumpTarget(
          actions: ActionCollection(roots: [menu]),
          onInvoke: invoked.add,
          actionIconBuilder: iconBuilder,
          invokeAfterMenuClosed: true,
        ),
      );
      expect(find.byType(CupertinoFocusHalo), findsOneWidget);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoPopupSurface), findsOneWidget);
      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(find.text('recent'), findsOneWidget);
      await tester.tap(find.text('recent'));
      expect(invoked, isEmpty);
      await tester.pumpAndSettle();

      expect(invoked, ['recent-command']);
      expect(find.byType(CupertinoPopupSurface), findsNothing);
    },
  );

  testWidgets('custom primary menu owns persistent checked state', (
    tester,
  ) async {
    final legacyChild = action('legacy');
    final filters = AdaptiveAction<String>.menu(
      id: ActionId('filters'),
      metadata: const ActionMetadata(label: 'Filters'),
      children: [legacyChild],
    );
    var selected = false;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setHostState) => pumpTarget(
          actions: ActionCollection(roots: [filters]),
          onInvoke: (_) {},
          menuBuilderForAction: (context, current) => current.id != filters.id
              ? null
              : [
                  Semantics(
                    key: const ValueKey('selected-semantics'),
                    checked: selected,
                    child: CupertinoMenuItem(
                      leading: selected
                          ? const Icon(CupertinoIcons.check_mark)
                          : const SizedBox(width: 18),
                      requestCloseOnActivate: false,
                      onPressed: () => setHostState(() => selected = !selected),
                      child: const Text('Selected'),
                    ),
                  ),
                ],
        ),
      ),
    );

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('legacy'), findsNothing);
    await tester.tap(find.text('Selected'));
    await tester.pump();

    expect(selected, isTrue);
    expect(find.text('Selected'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
    final semantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('selected-semantics')),
    );
    expect(semantics.properties.checked, isTrue);
  });

  testWidgets('custom menu remains action-owned after moving to overflow', (
    tester,
  ) async {
    final filters = AdaptiveAction<String>.menu(
      id: ActionId('filters'),
      metadata: const ActionMetadata(label: 'Filters'),
    );
    var selected = false;

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [filters]),
        onInvoke: (_) {},
        width: 44,
        maxPrimaryActions: 0,
        menuBuilderForAction: (context, current) => current.id != filters.id
            ? null
            : [
                StatefulBuilder(
                  builder: (context, setMenuState) => CupertinoMenuItem(
                    leading: selected
                        ? const Icon(CupertinoIcons.check_mark)
                        : const SizedBox(width: 18),
                    requestCloseOnActivate: false,
                    onPressed: () => setMenuState(() => selected = !selected),
                    child: const Text('Selected'),
                  ),
                ),
              ],
      ),
    );

    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selected'));
    await tester.pump();

    expect(selected, isTrue);
    expect(find.text('Selected'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.ellipsis), findsOneWidget);
  });

  testWidgets('reports a menu action without declared or custom content', (
    tester,
  ) async {
    final empty = AdaptiveAction<String>.menu(
      id: ActionId('empty-menu'),
      metadata: const ActionMetadata(label: 'Empty'),
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [empty]),
        onInvoke: (_) {},
      ),
    );

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(error.toString(), contains('empty-menu'));
    expect(error.toString(), contains('menuBuilderForAction'));
  });

  testWidgets('reports an empty custom menu for its action', (tester) async {
    final empty = AdaptiveAction<String>.menu(
      id: ActionId('empty-custom-menu'),
      metadata: const ActionMetadata(label: 'Empty'),
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [empty]),
        onInvoke: (_) {},
        menuBuilderForAction: (context, action) => const [],
      ),
    );

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(error.toString(), contains('empty-custom-menu'));
    expect(error.toString(), contains('at least one menu widget'));
  });

  testWidgets('primary menu renders a CupertinoMenuDivider between actions', (
    tester,
  ) async {
    final first = action('first');
    final second = action('second');
    final menu = AdaptiveAction<String>.menu(
      id: ActionId('more'),
      metadata: const ActionMetadata(label: 'More', iconKey: 'more'),
      children: [first, const AdaptiveMenuDivider<String>(), second],
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [menu]),
        onInvoke: invoked.add,
        actionIconBuilder: iconBuilder,
      ),
    );

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoMenuDivider), findsOneWidget);

    await tester.tap(find.text('second'));
    await tester.pumpAndSettle();
    expect(invoked, ['second-command']);
  });

  testWidgets('top-level divider independently targets primary and menu', (
    tester,
  ) async {
    Finder primaryDivider() => find.byWidgetPredicate(
      (widget) =>
          widget is ColoredBox &&
          widget.child is SizedBox &&
          (widget.child! as SizedBox).width != null,
      description: 'Cupertino primary divider',
    );

    final first = action('first');
    final second = action('second');
    final menuOnly = ActionCollection<String>.withEntries(
      entries: [
        first,
        const AdaptiveMenuDivider<String>(showInPrimary: false),
        second,
      ],
    );

    await tester.pumpWidget(
      pumpTarget(actions: menuOnly, onInvoke: (_) {}, width: 300),
    );
    expect(primaryDivider(), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      pumpTarget(
        actions: menuOnly,
        onInvoke: (_) {},
        width: 44,
        maxPrimaryActions: 0,
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoMenuDivider), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final primaryOnly = ActionCollection<String>.withEntries(
      entries: [
        first,
        const AdaptiveMenuDivider<String>(showInMenu: false),
        second,
      ],
    );
    await tester.pumpWidget(
      pumpTarget(actions: primaryOnly, onInvoke: (_) {}, width: 300),
    );
    expect(primaryDivider(), findsOneWidget);
    expect(tester.getSize(primaryDivider()).height, 28);
  });

  testWidgets('menu-hidden nested divider leaves no placeholder', (
    tester,
  ) async {
    final menu = AdaptiveAction<String>.menu(
      id: ActionId('more'),
      metadata: const ActionMetadata(label: 'More', iconKey: 'more'),
      children: [
        action('first'),
        const AdaptiveMenuDivider<String>(showInMenu: false),
        action('second'),
      ],
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [menu]),
        onInvoke: (_) {},
        actionIconBuilder: iconBuilder,
      ),
    );
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoMenuDivider), findsNothing);
    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('composite primary preserves invoke and submenu paths', (
    tester,
  ) async {
    final recent = action('recent');
    final open = AdaptiveAction<String>.composite(
      id: ActionId('open'),
      metadata: const ActionMetadata(label: 'Open', iconKey: 'open'),
      payload: 'open-command',
      children: [recent],
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [open]),
        onInvoke: invoked.add,
        actionIconBuilder: iconBuilder,
      ),
    );
    expect(find.byType(CupertinoFocusHalo), findsOneWidget);

    await tester.tap(find.text('Open'));
    expect(invoked, ['open-command']);

    await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('recent'));
    expect(invoked, ['open-command']);
    await tester.pumpAndSettle();

    expect(invoked, ['open-command', 'recent-command']);
  });

  testWidgets('custom composite menu replaces its submenu but not invocation', (
    tester,
  ) async {
    final open = AdaptiveAction<String>.composite(
      id: ActionId('open'),
      metadata: const ActionMetadata(label: 'Open', iconKey: 'open'),
      payload: 'open-command',
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [open]),
        onInvoke: invoked.add,
        actionIconBuilder: iconBuilder,
        menuBuilderForAction: (context, current) => current.id == open.id
            ? [
                CupertinoMenuItem(
                  onPressed: () => invoked.add('custom-command'),
                  child: const Text('Custom open'),
                ),
              ]
            : null,
      ),
    );

    await tester.tap(find.text('Open'));
    expect(invoked, ['open-command']);
    await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsNothing);
    await tester.tap(find.text('Custom open'));
    await tester.pumpAndSettle();
    expect(invoked, ['open-command', 'custom-command']);
  });

  testWidgets('animates the label while an icon option contracts', (
    tester,
  ) async {
    final save = action('save', label: 'Save document', iconKey: 'save');

    Widget target(double width) => pumpTarget(
      actions: ActionCollection(roots: [save]),
      onInvoke: (_) {},
      width: width,
      actionIconBuilder: iconBuilder,
      fadeDuration: const Duration(milliseconds: 400),
      resizeDuration: const Duration(milliseconds: 400),
    );

    await tester.pumpWidget(target(300));
    final expandedWidth = tester
        .getSize(find.byType(CupertinoAdaptiveActions<String>))
        .width;

    await tester.pumpWidget(target(44));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(CupertinoIcons.floppy_disk), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Save document'),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(CupertinoAdaptiveActions<String>)).width,
      inExclusiveRange(44, expandedWidth),
    );

    await tester.pumpAndSettle();
    expect(find.text('Save document'), findsNothing);
  });

  testWidgets('shows a styled overflow trigger only for non-empty overflow', (
    tester,
  ) async {
    final primary = action('primary');
    final overflow = action(
      'overflow',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [primary]),
        onInvoke: (_) {},
        overflowIcon: const Icon(CupertinoIcons.ellipsis_circle),
      ),
    );
    expect(find.byIcon(CupertinoIcons.ellipsis_circle), findsNothing);

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [overflow]),
        onInvoke: (_) {},
        width: 52,
        style: const CupertinoAdaptiveActionsStyle(overflowButtonWidth: 52),
        overflowIcon: const Icon(CupertinoIcons.ellipsis_circle),
        overflowTooltip: 'Document commands',
      ),
    );

    expect(find.byIcon(CupertinoIcons.ellipsis_circle), findsOneWidget);
    expect(find.bySemanticsLabel('Document commands'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CupertinoAdaptiveActions<String>)).width,
      52,
    );
  });

  testWidgets('overflow trigger toggles and an outside tap closes the menu', (
    tester,
  ) async {
    final overflow = action(
      'overflow',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [overflow]),
        onInvoke: invoked.add,
        width: 44,
      ),
    );

    final trigger = find.byIcon(CupertinoIcons.ellipsis);
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPopupSurface), findsOneWidget);
    final triggerButton = tester.widget<CupertinoButton>(
      find.ancestor(of: trigger, matching: find.byType(CupertinoButton)),
    );
    expect(triggerButton.focusNode!.hasFocus, isFalse);
    final pointerFocusedHaloShapes = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(CupertinoFocusHalo),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<ShapeDecoration>()
        .map((decoration) => decoration.shape)
        .whereType<RoundedSuperellipseBorder>()
        .where((shape) => shape.side.style != BorderStyle.none);
    expect(pointerFocusedHaloShapes, isEmpty);

    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPopupSurface), findsNothing);
    expect(invoked, isEmpty);

    await tester.tap(trigger);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPopupSurface), findsNothing);
    expect(invoked, isEmpty);

    await tester.tap(trigger);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPopupSurface), findsNothing);
    expect(invoked, isEmpty);
  });

  testWidgets('overflow invocation waits for close and a post-frame boundary', (
    tester,
  ) async {
    final save = action(
      'save',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final events = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (payload) => events.add('invoked:$payload'),
        width: 44,
        onOverflowMenuOpened: () => events.add('opened'),
        onOverflowMenuClosed: () => events.add('closed'),
        invokeAfterMenuClosed: true,
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    expect(events, ['opened']);

    await tester.tap(find.text('save'));
    expect(events, ['opened']);
    await tester.pumpAndSettle();

    expect(events, ['opened', 'closed', 'invoked:save-command']);
    expect(find.byType(CupertinoPopupSurface), findsNothing);
  });

  testWidgets('default overflow invocation runs next frame before close', (
    tester,
  ) async {
    final save = action(
      'save',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final events = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (payload) => events.add('invoked:$payload'),
        width: 44,
        onOverflowMenuOpened: () => events.add('opened'),
        onOverflowMenuClosed: () => events.add('closed'),
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    await tester.tap(find.text('save'));
    expect(events, ['opened']);
    await tester.pump();

    expect(events, ['opened', 'invoked:save-command']);
    expect(find.byType(CupertinoPopupSurface), findsOneWidget);
    await tester.pumpAndSettle();

    expect(events, ['opened', 'invoked:save-command', 'closed']);
    expect(find.byType(CupertinoPopupSurface), findsNothing);
  });

  for (final invokeAfterMenuClosed in [false, true]) {
    testWidgets('overflow invocation safely replaces a LayoutBuilder host with '
        'invokeAfterMenuClosed: $invokeAfterMenuClosed', (tester) async {
      final invoked = <String>[];
      final replace = action(
        'replace',
        placementPolicy: ActionPlacementPolicy(
          placement: ActionPlacement.overflowOnly,
        ),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: _CupertinoInvocationReplacementHost(
            actions: ActionCollection(roots: [replace]),
            onInvoke: invoked.add,
            invokeAfterMenuClosed: invokeAfterMenuClosed,
          ),
        ),
      );
      await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
      await tester.pumpAndSettle();
      await tester.tap(find.text('replace'));
      expect(invoked, isEmpty);
      await tester.pumpAndSettle();

      expect(find.text('replacement'), findsOneWidget);
      expect(invoked, ['replace-command']);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a rapid third overflow tap reopens a closing menu', (
    tester,
  ) async {
    final overflow = action(
      'overflow',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [overflow]),
        onInvoke: (_) {},
        width: 44,
      ),
    );

    final trigger = find.byIcon(CupertinoIcons.ellipsis);
    await tester.tap(trigger);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(trigger);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(trigger);
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoPopupSurface), findsOneWidget);
  });

  testWidgets('pointer menu restores focus before lifecycle changes', (
    tester,
  ) async {
    final save = action('save');

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 44,
      ),
    );

    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const CupertinoApp(home: SizedBox()));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(tester.takeException(), isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('nested pointer menu releases scopes before lifecycle changes', (
    tester,
  ) async {
    final nested = action('nested');
    final filters = AdaptiveAction<String>.menu(
      id: ActionId('filters'),
      metadata: const ActionMetadata(label: 'Filters'),
      children: [nested],
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [filters]),
        onInvoke: (_) {},
        width: 44,
      ),
    );

    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('nested'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const CupertinoApp(home: SizedBox()));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(tester.takeException(), isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('overflow menu supports keyboard submenu navigation', (
    tester,
  ) async {
    final child = action('nested');
    final overflow = AdaptiveAction<String>.menu(
      id: ActionId('overflow'),
      metadata: const ActionMetadata(label: 'Overflow'),
      children: [child],
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [overflow]),
        onInvoke: invoked.add,
        width: 44,
      ),
    );

    final trigger = tester.widget<CupertinoButton>(
      find.ancestor(
        of: find.byIcon(CupertinoIcons.ellipsis),
        matching: find.byType(CupertinoButton),
      ),
    );
    expect(trigger.focusColor, CupertinoColors.transparent);
    expect(find.byType(CupertinoFocusHalo), findsOneWidget);
    trigger.focusNode!.requestFocus();
    await tester.pump();

    final focusedHaloShapes = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(CupertinoFocusHalo),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<ShapeDecoration>()
        .map((decoration) => decoration.shape)
        .whereType<RoundedSuperellipseBorder>()
        .where((shape) => shape.side.style != BorderStyle.none)
        .toList();
    expect(focusedHaloShapes, hasLength(1));
    expect(
      focusedHaloShapes.single.side.strokeAlign,
      BorderSide.strokeAlignInside,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPopupSurface), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPopupSurface), findsNWidgets(2));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(invoked, ['nested-command']);
    expect(find.byType(CupertinoPopupSurface), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'primary and overflow icons inherit the Cupertino button color in '
      '${brightness.name} mode',
      (tester) async {
        final save = action('save', iconKey: 'save');
        final overflow = action(
          'overflow',
          placementPolicy: ActionPlacementPolicy(
            placement: ActionPlacement.overflowOnly,
          ),
        );
        final actions = ActionCollection(roots: [save, overflow]);

        await tester.pumpWidget(
          pumpTarget(
            actions: actions,
            onInvoke: (_) {},
            actionIconBuilder: iconBuilder,
            brightness: brightness,
          ),
        );

        expect(
          IconTheme.of(
            tester.element(find.byIcon(CupertinoIcons.floppy_disk)),
          ).color,
          testPrimaryColor,
        );
        expect(
          IconTheme.of(
            tester.element(find.byIcon(CupertinoIcons.ellipsis)),
          ).color,
          testPrimaryColor,
        );

        await tester.pumpWidget(
          pumpTarget(
            actions: actions,
            onInvoke: (_) {},
            width: 88,
            actionIconBuilder: iconBuilder,
            brightness: brightness,
          ),
        );

        expect(find.text('save'), findsNothing);
        expect(
          IconTheme.of(
            tester.element(find.byIcon(CupertinoIcons.floppy_disk)),
          ).color,
          testPrimaryColor,
        );
        await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
        await tester.pumpAndSettle();
        expect(find.byType(CupertinoPopupSurface), findsOneWidget);
      },
    );
  }

  testWidgets('preserves final overflow order and invokes a leaf', (
    tester,
  ) async {
    final first = action(
      'first',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final second = action(
      'second',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final third = action(
      'third',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [first, second, third]),
        onInvoke: invoked.add,
        width: 44,
        overflowOrderOverride: [third.id, first.id],
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();

    final thirdY = tester.getTopLeft(find.text('third')).dy;
    final secondY = tester.getTopLeft(find.text('second')).dy;
    final firstY = tester.getTopLeft(find.text('first')).dy;
    expect(thirdY, lessThan(secondY));
    expect(secondY, lessThan(firstY));

    await tester.tap(find.text('second'));
    await tester.pumpAndSettle();
    expect(invoked, ['second-command']);
    expect(find.byType(CupertinoPopupSurface), findsNothing);
  });

  testWidgets(
    'opens arbitrary-depth anchored submenus and closes from a leaf',
    (tester) async {
      final deepFirst = action('deep first');
      final deepSecond = action('deep second');
      final levelTwo = AdaptiveAction<String>.menu(
        id: ActionId('level-two'),
        metadata: const ActionMetadata(label: 'Level two'),
        children: [deepFirst, deepSecond],
      );
      final levelOne = AdaptiveAction<String>.menu(
        id: ActionId('level-one'),
        metadata: const ActionMetadata(label: 'Level one'),
        children: [levelTwo],
        placementPolicy: ActionPlacementPolicy(
          placement: ActionPlacement.overflowOnly,
        ),
      );
      final invoked = <String>[];

      await tester.pumpWidget(
        pumpTarget(
          actions: ActionCollection(roots: [levelOne]),
          onInvoke: invoked.add,
          width: 44,
          invokeAfterMenuClosed: true,
        ),
      );
      await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Level one'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Level two'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(find.byType(CupertinoPopupSurface), findsNWidgets(3));
      expect(find.text('Back'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
      expect(
        tester.getTopLeft(find.text('deep first')).dy,
        lessThan(tester.getTopLeft(find.text('deep second')).dy),
      );
      await tester.tap(find.text('deep first'));
      expect(invoked, isEmpty);
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoPopupSurface), findsNothing);
      expect(invoked, ['deep first-command']);
    },
  );

  testWidgets('mirrors overflow submenu affordances with text direction', (
    tester,
  ) async {
    final enabledMenu = AdaptiveAction<String>.menu(
      id: ActionId('enabled-menu'),
      metadata: const ActionMetadata(label: 'Enabled menu'),
      children: [action('enabled child')],
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final disabledBranch = AdaptiveAction<String>.composite(
      id: ActionId('disabled-branch'),
      metadata: const ActionMetadata(label: 'Disabled branch'),
      payload: 'disabled-command',
      children: [action('disabled child')],
      isEnabled: false,
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final actions = ActionCollection(roots: [enabledMenu, disabledBranch]);

    Future<void> pumpDirection(TextDirection textDirection) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: textDirection,
            child: CupertinoPageScaffold(
              child: CupertinoAdaptiveActions<String>.moreAction(
                actions: actions,
                onInvoke: (_) {},
                primaryCapacity: 44,
                fadeDuration: Duration.zero,
                resizeDuration: Duration.zero,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
      await tester.pumpAndSettle();
    }

    await pumpDirection(TextDirection.ltr);
    expect(find.byIcon(CupertinoIcons.chevron_forward), findsNWidgets(2));
    expect(find.byIcon(CupertinoIcons.chevron_back), findsNothing);

    await pumpDirection(TextDirection.rtl);
    expect(find.byIcon(CupertinoIcons.chevron_back), findsNWidgets(2));
    expect(find.byIcon(CupertinoIcons.chevron_forward), findsNothing);
  });

  testWidgets('overflow composite exposes invoke before its children', (
    tester,
  ) async {
    final child = action('recent file');
    final composite = AdaptiveAction<String>.composite(
      id: ActionId('open'),
      metadata: const ActionMetadata(label: 'Open'),
      payload: 'open-command',
      children: [child],
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [composite]),
        onInvoke: invoked.add,
        width: 44,
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsNWidgets(2));
    expect(find.text('recent file'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Open').last).dy,
      lessThan(tester.getTopLeft(find.text('recent file')).dy),
    );
    await tester.tap(find.text('Open').last);
    expect(invoked, isEmpty);
    await tester.pumpAndSettle();
    expect(invoked, ['open-command']);
    expect(find.byType(CupertinoPopupSurface), findsNothing);

    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('recent file'));
    await tester.pumpAndSettle();
    expect(invoked, ['open-command', 'recent file-command']);
  });

  testWidgets(
    'disabled overflow branch hides descendants and suppresses invoke',
    (tester) async {
      final descendant = action('inaccessible child');
      final disabled = AdaptiveAction<String>.composite(
        id: ActionId('disabled'),
        metadata: const ActionMetadata(label: 'Disabled branch'),
        payload: 'disabled-command',
        children: [descendant],
        isEnabled: false,
        placementPolicy: ActionPlacementPolicy(
          placement: ActionPlacement.overflowOnly,
        ),
      );
      final invoked = <String>[];

      await tester.pumpWidget(
        pumpTarget(
          actions: ActionCollection(roots: [disabled]),
          onInvoke: invoked.add,
          width: 44,
        ),
      );
      await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disabled branch'));
      await tester.pumpAndSettle();

      expect(find.text('inaccessible child'), findsNothing);
      expect(invoked, isEmpty);
    },
  );

  testWidgets('maps overflow metadata and leaves inputs unchanged', (
    tester,
  ) async {
    final destructive = action(
      'delete',
      tooltip: 'Delete this document',
      semanticLabel: 'Delete document',
      iconKey: 'save',
      isDestructive: true,
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final roots = [destructive];
    final collection = ActionCollection(roots: roots);
    final overflowOrder = [destructive.id];

    await tester.pumpWidget(
      pumpTarget(
        actions: collection,
        onInvoke: (_) {},
        width: 44,
        overflowOrderOverride: overflowOrder,
        actionIconBuilder: iconBuilder,
      ),
    );
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();

    final menuItem = tester.widget<CupertinoMenuItem>(
      find.widgetWithText(CupertinoMenuItem, 'delete'),
    );
    expect(menuItem.isDestructiveAction, isTrue);
    expect(find.bySemanticsLabel('Delete document'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Delete document')).tooltip,
      'Delete this document',
    );
    expect(find.byIcon(CupertinoIcons.floppy_disk), findsOneWidget);
    expect(roots, orderedEquals([destructive]));
    expect(collection.roots, orderedEquals([destructive]));
    expect(overflowOrder, orderedEquals([destructive.id]));
  });

  testWidgets('composite menu affordance uses caller-owned semantics', (
    tester,
  ) async {
    final open = AdaptiveAction<String>.composite(
      id: ActionId('open'),
      metadata: const ActionMetadata(
        label: '打开',
        tooltip: '打开子菜单',
        semanticLabel: '打开选项',
      ),
      payload: 'open-command',
      children: [action('recent')],
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [open]),
        onInvoke: (_) {},
      ),
    );

    final labels = tester
        .widgetList<Semantics>(
          find.ancestor(
            of: find.byIcon(CupertinoIcons.chevron_down),
            matching: find.byType(Semantics),
          ),
        )
        .map((semantics) => semantics.properties.label);
    expect(labels, contains('打开选项'));
    expect(labels, isNot(contains('打开 menu')));
  });

  testWidgets('integrates placement retention and both region orders', (
    tester,
  ) async {
    final low = action(
      'low',
      label: 'L',
      placementPolicy: ActionPlacementPolicy(
        automaticPreference: AutomaticPlacementPreference(
          retentionPriority: PrimaryRetentionPriority.low,
        ),
      ),
    );
    final pinned = action(
      'pinned',
      label: 'P',
      placementPolicy: ActionPlacementPolicy(placement: ActionPlacement.pinned),
    );
    final high = action(
      'high',
      label: 'H',
      placementPolicy: ActionPlacementPolicy(
        automaticPreference: AutomaticPlacementPreference(
          retentionPriority: PrimaryRetentionPriority.high,
        ),
      ),
    );
    final overflowOnly = action(
      'overflow',
      label: 'O',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final hidden = action(
      'hidden',
      label: 'X',
      placementPolicy: ActionPlacementPolicy(placement: ActionPlacement.hidden),
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(
          roots: [low, pinned, high, overflowOnly, hidden],
        ),
        onInvoke: invoked.add,
        width: 144,
        primaryOrderOverride: [high.id, pinned.id],
        overflowOrderOverride: [overflowOnly.id, low.id],
      ),
    );

    expect(find.text('L'), findsNothing);
    expect(find.text('O'), findsNothing);
    expect(find.text('X'), findsNothing);
    expect(
      tester.getTopLeft(find.text('H')).dx,
      lessThan(tester.getTopLeft(find.text('P')).dx),
    );

    await tester.tap(find.text('H'));
    expect(invoked, ['high-command']);

    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('O')).dy,
      lessThan(tester.getTopLeft(find.text('L')).dy),
    );
    await tester.tap(find.text('O'));
    await tester.pumpAndSettle();
    expect(invoked, ['high-command', 'overflow-command']);
  });

  testWidgets('reports over-capacity pinned diagnostics without hiding it', (
    tester,
  ) async {
    final pinned = action(
      'pinned',
      label: 'Pinned command',
      placementPolicy: ActionPlacementPolicy(placement: ActionPlacement.pinned),
    );
    final delegate = _RecordingPlacementDelegate();
    final resolver = ActionLayoutResolver(placementDelegate: delegate);

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [pinned]),
        onInvoke: (_) {},
        width: 24,
        resolver: resolver,
      ),
    );

    expect(find.text('Pinned command'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CupertinoAdaptiveActions<String>)).width,
      greaterThan(24),
    );
    expect(
      delegate.diagnosticCodes,
      contains(ResolutionDiagnosticCode.unsatisfiedPinnedConstraint),
    );
    expect(delegate.resolveCount, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [pinned]),
        onInvoke: (_) {},
        width: 300,
        resolver: resolver,
      ),
    );

    expect(find.text('Pinned command'), findsOneWidget);
    expect(delegate.resolveCount, 2);
  });

  testWidgets('keeps primaryCapacity authoritative under a narrower parent', (
    tester,
  ) async {
    final delegate = _RecordingPlacementDelegate();

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: CupertinoAdaptiveActions<String>.moreAction(
                actions: ActionCollection(roots: [action('a', label: 'A')]),
                onInvoke: (_) {},
                primaryCapacity: 300,
                resolver: ActionLayoutResolver(placementDelegate: delegate),
                fadeDuration: Duration.zero,
                resizeDuration: Duration.zero,
              ),
            ),
          ),
        ),
      ),
    );

    expect(delegate.resolveCount, 1);
    expect(delegate.lastPrimaryCapacity, 300);
    expect(
      tester.getSize(find.byType(CupertinoAdaptiveActions<String>)).width,
      lessThan(100),
    );
  });

  testWidgets('renders a scripted result without replacing its decisions', (
    tester,
  ) async {
    final roots = [
      action('a', label: 'A'),
      action('b', label: 'B'),
      action('c', label: 'C'),
      action('d', label: 'D'),
      action('e', label: 'E'),
    ];
    final rootsBefore = List<AdaptiveAction<String>>.of(roots);
    final collection = ActionCollection(roots: roots);
    final delegate = _ScriptedPlacementDelegate();
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: collection,
        onInvoke: invoked.add,
        resolver: ActionLayoutResolver(placementDelegate: delegate),
      ),
    );

    expect(
      tester.getTopLeft(find.text('C')).dx,
      lessThan(tester.getTopLeft(find.text('A')).dx),
    );
    expect(find.text('B'), findsNothing);
    expect(find.text('D'), findsNothing);
    expect(find.text('E'), findsNothing);
    await tester.tap(find.text('C'));

    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('D')).dy,
      lessThan(tester.getTopLeft(find.text('B')).dy),
    );
    await tester.tap(find.text('D'));
    await tester.pumpAndSettle();

    expect(invoked, ['c-command', 'd-command']);
    expect(collection.roots, orderedEquals(rootsBefore));
    expect(delegate.resolveCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated rebuilds keep inputs and callbacks stable', (
    tester,
  ) async {
    final first = action('first');
    final second = action('second');
    final third = action('third');
    final roots = [first, second, third];
    final primaryOrder = [second.id, first.id];
    final overflowOrder = [third.id];
    final rootsBefore = List<AdaptiveAction<String>>.of(roots);
    final primaryOrderBefore = List<ActionId>.of(primaryOrder);
    final overflowOrderBefore = List<ActionId>.of(overflowOrder);
    final collection = ActionCollection(roots: roots);
    final delegate = _RecordingPlacementDelegate();
    final resolver = ActionLayoutResolver(placementDelegate: delegate);
    final invoked = <String>[];

    for (var rebuild = 0; rebuild < 3; rebuild += 1) {
      await tester.pumpWidget(
        pumpTarget(
          actions: collection,
          onInvoke: invoked.add,
          primaryOrderOverride: primaryOrder,
          overflowOrderOverride: overflowOrder,
          maxPrimaryActions: 2,
          resolver: resolver,
        ),
      );
    }

    expect(delegate.resolveCount, 3);
    expect(collection.roots, orderedEquals(rootsBefore));
    expect(primaryOrder, orderedEquals(primaryOrderBefore));
    expect(overflowOrder, orderedEquals(overflowOrderBefore));
    expect(
      tester.getTopLeft(find.text('second')).dx,
      lessThan(tester.getTopLeft(find.text('first')).dx),
    );

    await tester.tap(find.text('first'));
    expect(invoked, ['first-command']);
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();
    await tester.tap(find.text('third'));
    await tester.pumpAndSettle();
    expect(invoked, ['first-command', 'third-command']);
  });

  testWidgets('can be embedded in a Cupertino navigation bar', (tester) async {
    final save = action('save');

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Document'),
            trailing: CupertinoAdaptiveActions<String>.moreAction(
              actions: ActionCollection(roots: [save]),
              onInvoke: (_) {},
              primaryCapacity: 100,
            ),
          ),
          child: const SizedBox(),
        ),
      ),
    );

    expect(find.text('save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final class _SingleFlexibleActionLayoutDelegate
    implements ActionRegionLayoutDelegate {
  const _SingleFlexibleActionLayoutDelegate();

  @override
  ActionRegionLayoutReservation reserve(
    ActionRegionLayoutReservationInput input,
  ) => ActionRegionLayoutReservation();

  @override
  ActionRegionLayoutPlan layout(ActionRegionLayoutInput input) =>
      ActionRegionLayoutPlan(
        entries: [
          for (final slot in input.slots)
            ActionRegionLayoutEntry.slot(
              slot.id,
              extent: slot.id.isOverflow
                  ? const ActionRegionExtent.fixed()
                  : ActionRegionExtent.flex(),
            ),
        ],
      );
}

final class _CupertinoInvocationReplacementHost extends StatefulWidget {
  const _CupertinoInvocationReplacementHost({
    required this.actions,
    required this.onInvoke,
    required this.invokeAfterMenuClosed,
  });

  final ActionCollection<String> actions;
  final ValueChanged<String> onInvoke;
  final bool invokeAfterMenuClosed;

  @override
  State<_CupertinoInvocationReplacementHost> createState() =>
      _CupertinoInvocationReplacementHostState();
}

final class _CupertinoInvocationReplacementHostState
    extends State<_CupertinoInvocationReplacementHost> {
  bool _replaced = false;

  void _handleInvoke(String payload) {
    widget.onInvoke(payload);
    setState(() {
      _replaced = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_replaced) {
      return const CupertinoPageScaffold(
        child: Center(child: Text('replacement')),
      );
    }

    return CupertinoPageScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: CupertinoAdaptiveActions<String>.moreAction(
            actions: widget.actions,
            onInvoke: _handleInvoke,
            primaryCapacity: 44,
            maxPrimaryActions: 0,
            invokeAfterMenuClosed: widget.invokeAfterMenuClosed,
            fadeDuration: Duration.zero,
            resizeDuration: Duration.zero,
          ),
        ),
      ),
    );
  }
}

final class _RecordingPlacementDelegate implements ActionPlacementDelegate {
  final _delegate = const DefaultActionPlacementDelegate();

  int resolveCount = 0;
  double? lastPrimaryCapacity;
  List<ResolutionDiagnosticCode> diagnosticCodes = const [];

  @override
  ActionPlacementResult<T> resolve<T extends Object>(
    ActionLayoutRequest<T> request,
  ) {
    resolveCount += 1;
    lastPrimaryCapacity = request.constraints.primaryCapacity;
    final result = _delegate.resolve(request);
    diagnosticCodes = [
      for (final diagnostic in result.diagnostics) diagnostic.code,
    ];
    return result;
  }
}

final class _ScriptedPlacementDelegate implements ActionPlacementDelegate {
  int resolveCount = 0;

  @override
  ActionPlacementResult<T> resolve<T extends Object>(
    ActionLayoutRequest<T> request,
  ) {
    resolveCount += 1;
    final roots = request.actions.roots;
    ResolvedPrimaryAction<T> primary(AdaptiveAction<T> action) {
      final profile = request.constraints.profileFor(action.id)!;
      return ResolvedPrimaryAction(
        action: action,
        optionId: profile.options.first.id,
      );
    }

    return ActionPlacementResult(
      primary: [primary(roots[2]), primary(roots[0])],
      overflow: [roots[3], roots[1]],
      hidden: [
        HiddenAction(action: roots[4], reason: HiddenActionReason.forcedHidden),
      ],
      diagnostics: [
        ResolutionDiagnostic(
          code: ResolutionDiagnosticCode.forcedHidden,
          actionIds: [roots[4].id],
        ),
      ],
    );
  }
}
