import 'package:adaptive_actions/cupertino.dart';
import 'package:flutter/cupertino.dart';
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
    CupertinoOverflowButtonBuilder? overflowButtonBuilder,
    CupertinoActionPresentation? presentationOverride,
    CupertinoAdaptiveActionsStyle style = const CupertinoAdaptiveActionsStyle(),
    int? maxPrimaryActions,
    Duration fadeDuration = Duration.zero,
    Duration resizeDuration = Duration.zero,
    Widget overflowIcon = const Icon(CupertinoIcons.ellipsis),
    String overflowTooltip = 'More actions',
    ActionLayoutResolver resolver = const ActionLayoutResolver(),
    Brightness brightness = Brightness.light,
  }) => CupertinoApp(
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
          overflowButtonBuilder: overflowButtonBuilder,
          presentationOverride: presentationOverride,
          style: style,
          maxPrimaryActions: maxPrimaryActions,
          fadeDuration: fadeDuration,
          resizeDuration: resizeDuration,
          overflowIcon: overflowIcon,
          overflowTooltip: overflowTooltip,
          resolver: resolver,
        ),
      ),
    ),
  );

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

    expect((generic.overflowIcon as Icon).icon, CupertinoIcons.square_grid_2x2);
    expect(generic.overflowTooltip, isEmpty);
    expect((more.overflowIcon as Icon).icon, CupertinoIcons.ellipsis);
    expect(more.overflowTooltip, 'More actions');
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
        ),
      );
      expect(find.byType(CupertinoFocusHalo), findsOneWidget);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoPopupSurface), findsOneWidget);
      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(find.text('recent'), findsOneWidget);
      await tester.tap(find.text('recent'));
      await tester.pumpAndSettle();

      expect(invoked, ['recent-command']);
      expect(find.byType(CupertinoPopupSurface), findsNothing);
    },
  );

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
    await tester.pumpAndSettle();

    expect(invoked, ['open-command', 'recent-command']);
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

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [overflow]),
        onInvoke: (_) {},
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

    await tester.tap(trigger);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPopupSurface), findsNothing);
  });

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

final class _RecordingPlacementDelegate implements ActionPlacementDelegate {
  final _delegate = const DefaultActionPlacementDelegate();

  int resolveCount = 0;
  List<ResolutionDiagnosticCode> diagnosticCodes = const [];

  @override
  ActionPlacementResult<T> resolve<T extends Object>(
    ActionLayoutRequest<T> request,
  ) {
    resolveCount += 1;
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
