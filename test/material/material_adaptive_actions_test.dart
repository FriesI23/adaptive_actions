import 'package:adaptive_actions/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MaterialAdaptiveActionsStyle copyWith replaces selected metrics', () {
    const original = MaterialAdaptiveActionsStyle(
      height: 52,
      minimumButtonWidth: 50,
      iconButtonWidth: 46,
      submenuButtonWidth: 30,
      overflowButtonWidth: 44,
      iconSize: 20,
      iconLabelSpacing: 6,
      horizontalPadding: 10,
    );

    final changed = original.copyWith(
      height: 64,
      overflowButtonWidth: 52,
      iconSize: 24,
    );

    expect(changed.height, 64);
    expect(changed.iconSize, 24);
    expect(changed.minimumButtonWidth, original.minimumButtonWidth);
    expect(changed.iconButtonWidth, original.iconButtonWidth);
    expect(changed.submenuButtonWidth, original.submenuButtonWidth);
    expect(changed.overflowButtonWidth, 52);
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

  Widget pumpTarget({
    required ActionCollection<String> actions,
    required ValueChanged<String> onInvoke,
    double width = 300,
    Iterable<ActionId> primaryOrderOverride = const [],
    Iterable<ActionId> overflowOrderOverride = const [],
    MaterialActionIconBuilder<String>? iconBuilder,
    MaterialActionButtonBuilder<String>? actionButtonBuilder,
    MaterialOverflowButtonBuilder? overflowButtonBuilder,
    MaterialActionPresentationCallback<String>? presentationForAction,
    MaterialActionLabelLayoutCallback<String>? labelLayoutForAction,
    MaterialActionPresentation? presentationOverride,
    MaterialAdaptiveActionsStyle style = const MaterialAdaptiveActionsStyle(),
    ActionLayoutResolver resolver = const ActionLayoutResolver(),
    int? maxPrimaryActions,
    Widget overflowIcon = const Icon(Icons.more_vert),
    String overflowTooltip = 'More actions',
    bool menuAnimationEnabled = false,
    Duration fadeDuration = Duration.zero,
    Duration resizeDuration = Duration.zero,
    ActionRegionMainAxisDistribution distribution =
        ActionRegionMainAxisDistribution.compact,
    ActionRegionLayoutDelegate? layoutDelegate,
    TextScaler textScaler = TextScaler.noScaling,
  }) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: Scaffold(
      body: MaterialAdaptiveActions<String>.moreAction(
        actions: actions,
        onInvoke: onInvoke,
        primaryCapacity: width,
        primaryOrderOverride: primaryOrderOverride,
        overflowOrderOverride: overflowOrderOverride,
        iconBuilder: iconBuilder,
        actionButtonBuilder: actionButtonBuilder,
        overflowButtonBuilder: overflowButtonBuilder,
        presentationForAction: presentationForAction,
        labelLayoutForAction: labelLayoutForAction,
        presentationOverride: presentationOverride,
        style: style,
        resolver: resolver,
        maxPrimaryActions: maxPrimaryActions,
        overflowIcon: overflowIcon,
        overflowTooltip: overflowTooltip,
        menuAnimationEnabled: menuAnimationEnabled,
        fadeDuration: fadeDuration,
        resizeDuration: resizeDuration,
        distribution: distribution,
        layoutDelegate: layoutDelegate,
      ),
    ),
  );

  Widget? iconBuilder(BuildContext context, AdaptiveAction<String> action) =>
      switch (action.metadata.iconKey) {
        'save' => const Icon(Icons.save),
        'more' => const Icon(Icons.more_horiz),
        'open' => const Icon(Icons.folder_open),
        'share' => const Icon(Icons.share),
        'delete' => const Icon(Icons.delete),
        'help' => const Icon(Icons.help_outline),
        _ => null,
      };

  testWidgets('scales primary text and icons before resolving layout', (
    tester,
  ) async {
    final save = action('save', label: 'Save', iconKey: 'save');

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 140,
        iconBuilder: iconBuilder,
      ),
    );
    expect(find.text('Save'), findsOneWidget);

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 140,
        iconBuilder: iconBuilder,
        textScaler: const TextScaler.linear(2),
      ),
    );

    expect(find.text('Save'), findsNothing);
    final iconContext = tester.element(find.byIcon(Icons.save));
    expect(IconTheme.of(iconContext).size, 36);
    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      60,
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
        presentationOverride: MaterialActionPresentation.extended,
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
    final generic = MaterialAdaptiveActions<String>(
      actions: actions,
      onInvoke: (_) {},
      primaryCapacity: 0,
      overflowIcon: const Icon(Icons.apps),
    );
    final more = MaterialAdaptiveActions<String>.moreAction(
      actions: actions,
      onInvoke: (_) {},
      primaryCapacity: 0,
    );

    expect((generic.overflowIcon as Icon).icon, Icons.apps);
    expect(generic.overflowTooltip, isEmpty);
    expect((more.overflowIcon as Icon).icon, Icons.more_vert);
    expect(more.overflowTooltip, 'More actions');
    expect(generic.distribution, ActionRegionMainAxisDistribution.compact);
    expect(
      () => MaterialAdaptiveActions<String>(
        actions: actions,
        onInvoke: (_) {},
        primaryCapacity: 100,
        overflowIcon: const Icon(Icons.apps),
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
    final menuChild = action('menu-child');
    final compositeChild = action('composite-child');
    final menu = AdaptiveAction<String>.menu(
      id: ActionId('menu'),
      metadata: const ActionMetadata(label: 'menu'),
      children: [menuChild],
    );
    final composite = AdaptiveAction<String>.composite(
      id: ActionId('composite'),
      metadata: const ActionMetadata(label: 'composite'),
      payload: 'composite-command',
      children: [compositeChild],
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
        width: 48,
        maxPrimaryActions: 0,
        overflowButtonBuilder: (context, onPressed, defaultBuilder) =>
            LayoutBuilder(
              builder: (context, value) {
                constraints = value;
                return TextButton(
                  onPressed: onPressed,
                  child: const Text('Custom more'),
                );
              },
            ),
      ),
    );

    expect(constraints, const BoxConstraints.tightFor(width: 48, height: 48));
    await tester.tap(find.text('Custom more'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'save'));
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
        width: 300,
      ),
    );
    final resolvedWidth = tester
        .getSize(find.byType(MaterialAdaptiveActions<String>))
        .width;

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 300,
        actionButtonBuilder: (context, action, onPressed, defaultBuilder) =>
            defaultBuilder(context, replacement, onPressed),
      ),
    );

    expect(find.text('Replacement'), findsOneWidget);
    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      resolvedWidth,
    );
  });

  testWidgets('renders core primary order and invokes an enabled payload', (
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
        iconBuilder: iconBuilder,
      ),
    );

    expect(find.text('share'), findsOneWidget);
    expect(find.text('save'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('share')).dx,
      lessThan(tester.getTopLeft(find.text('save')).dx),
    );

    await tester.tap(find.byTooltip('save'));

    expect(invoked, ['save-command']);
  });

  testWidgets('uses the icon option when label layout does not fit', (
    tester,
  ) async {
    final save = action('save', label: 'Save document', iconKey: 'save');

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 56,
        iconBuilder: iconBuilder,
      ),
    );

    expect(find.text('Save document'), findsNothing);
    expect(find.byIcon(Icons.save), findsOneWidget);
  });

  testWidgets('forces extended and icon-only primary presentations', (
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
        width: 56,
        iconBuilder: iconBuilder,
        presentationOverride: MaterialActionPresentation.extended,
      ),
    );

    expect(find.text('Save document'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 300,
        iconBuilder: iconBuilder,
        presentationOverride: MaterialActionPresentation.iconOnly,
      ),
    );

    expect(find.text('Save document'), findsNothing);
    expect(find.byIcon(Icons.save), findsOneWidget);
  });

  testWidgets('icon-only override falls back when an action has no icon', (
    tester,
  ) async {
    final share = action('share', label: 'Share document');

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [share]),
        onInvoke: (_) {},
        presentationOverride: MaterialActionPresentation.iconOnly,
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
        iconBuilder: iconBuilder,
        presentationForAction: (context, action) => switch (action.id.value) {
          'share' || 'help' => MaterialActionPresentation.extended,
          _ => MaterialActionPresentation.iconOnly,
        },
      ),
    );

    expect(find.text('Save'), findsNothing);
    expect(find.text('Open'), findsNothing);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Help'), findsOneWidget);
    for (final icon in [
      Icons.save,
      Icons.folder_open,
      Icons.share,
      Icons.delete,
      Icons.help_outline,
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
        iconBuilder: iconBuilder,
        presentationForAction: (context, action) =>
            action.id == save.id ? MaterialActionPresentation.extended : null,
        presentationOverride: MaterialActionPresentation.iconOnly,
      ),
    );

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Open'), findsNothing);

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 300,
        iconBuilder: iconBuilder,
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
          width: 48,
          iconBuilder: iconBuilder,
          presentationForAction: (context, action) =>
              MaterialActionPresentation.extended,
        ),
      );

      expect(find.byIcon(Icons.save), findsNothing);
      expect(find.byTooltip('More actions'), findsOneWidget);
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
            MaterialActionPresentation.iconOnly,
      ),
    );

    expect(find.text('Share document'), findsOneWidget);
  });

  testWidgets('animates only the label while an icon option contracts', (
    tester,
  ) async {
    final visible = action('save', label: 'Save document', iconKey: 'save');
    final hidden = action(
      'save',
      label: 'Save document',
      iconKey: 'save',
      placementPolicy: ActionPlacementPolicy(placement: ActionPlacement.hidden),
    );

    Widget target(
      AdaptiveAction<String> current,
      double capacity, {
      Duration duration = const Duration(milliseconds: 400),
    }) => MaterialApp(
      home: Scaffold(
        body: MaterialAdaptiveActions<String>.moreAction(
          actions: ActionCollection(roots: [current]),
          onInvoke: (_) {},
          primaryCapacity: capacity,
          iconBuilder: iconBuilder,
          fadeDuration: duration,
          resizeDuration: duration,
        ),
      ),
    );

    await tester.pumpWidget(target(visible, 300));
    expect(find.text('Save document'), findsOneWidget);
    final expandedWidth = tester
        .getSize(find.byType(MaterialAdaptiveActions<String>))
        .width;

    await tester.pumpWidget(target(visible, 56));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Save document'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byIcon(Icons.save),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('Save document'),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
    final contractingWidth = tester
        .getSize(find.byType(MaterialAdaptiveActions<String>))
        .width;
    expect(contractingWidth, lessThan(expandedWidth));
    expect(contractingWidth, greaterThan(56));
    expect(find.byType(AnimatedSwitcher), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Save document'), findsNothing);

    await tester.pumpWidget(target(visible, 300));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Save document'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byIcon(Icons.save),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('Save document'),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      inExclusiveRange(56, expandedWidth),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(target(hidden, 300));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      inExclusiveRange(0, expandedWidth),
    );

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.save), findsNothing);

    await tester.pumpWidget(target(visible, 300, duration: Duration.zero));
    expect(find.text('Save document'), findsOneWidget);

    await tester.pumpWidget(target(visible, 56, duration: Duration.zero));
    expect(find.text('Save document'), findsNothing);
  });

  testWidgets('replaces the final icon with More using complementary opacity', (
    tester,
  ) async {
    final save = action('save', label: 'Save document', iconKey: 'save');

    Widget target(int maximum) => pumpTarget(
      actions: ActionCollection(roots: [save]),
      onInvoke: (_) {},
      width: 48,
      maxPrimaryActions: maximum,
      iconBuilder: iconBuilder,
      fadeDuration: const Duration(milliseconds: 400),
      resizeDuration: const Duration(milliseconds: 400),
    );

    await tester.pumpWidget(target(1));
    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      48,
    );

    await tester.pumpWidget(target(0));
    await tester.pump(const Duration(milliseconds: 200));

    final saveOpacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.byIcon(Icons.save), matching: find.byType(Opacity))
          .first,
    );
    final moreOpacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byTooltip('More actions'),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(saveOpacity.opacity + moreOpacity.opacity, closeTo(1, 0.0001));
    expect(saveOpacity.opacity, inExclusiveRange(0, 1));
    expect(moreOpacity.opacity, inExclusiveRange(0, 1));
    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      48,
    );

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.save), findsNothing);
    expect(find.byTooltip('More actions'), findsOneWidget);

    await tester.pumpWidget(target(1));
    await tester.pump(const Duration(milliseconds: 200));
    final expandingSaveOpacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.byIcon(Icons.save), matching: find.byType(Opacity))
          .first,
    );
    final outgoingMoreOpacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byTooltip('More actions'),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(
      expandingSaveOpacity.opacity + outgoingMoreOpacity.opacity,
      closeTo(1, 0.0001),
    );

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(find.byTooltip('More actions'), findsNothing);
  });

  testWidgets('animation durations independently control option transitions', (
    tester,
  ) async {
    final save = action('save', label: 'Save document', iconKey: 'save');

    Widget target(
      double width, {
      Duration fadeDuration = const Duration(milliseconds: 400),
      Duration resizeDuration = const Duration(milliseconds: 400),
    }) => MaterialApp(
      home: Scaffold(
        body: MaterialAdaptiveActions<String>.moreAction(
          actions: ActionCollection(roots: [save]),
          onInvoke: (_) {},
          primaryCapacity: width,
          iconBuilder: iconBuilder,
          fadeDuration: fadeDuration,
          resizeDuration: resizeDuration,
          switchInCurve: Curves.linear,
          switchOutCurve: Curves.linear,
        ),
      ),
    );

    await tester.pumpWidget(target(300, fadeDuration: Duration.zero));
    final expandedWidth = tester
        .getSize(find.byType(MaterialAdaptiveActions<String>))
        .width;
    await tester.pumpWidget(target(56, fadeDuration: Duration.zero));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      inExclusiveRange(48, expandedWidth),
    );
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text('Save document'),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      0,
    );

    await tester.pumpAndSettle();
    await tester.pumpWidget(target(300, fadeDuration: Duration.zero));
    await tester.pumpAndSettle();
    await tester.pumpWidget(target(300, resizeDuration: Duration.zero));
    await tester.pumpWidget(target(56, resizeDuration: Duration.zero));

    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      expandedWidth,
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      expandedWidth,
    );
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text('Save document'),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      inExclusiveRange(0, 1),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      48,
    );
  });

  testWidgets('retargets a final-slot replacement from its painted frame', (
    tester,
  ) async {
    final save = action('save', label: 'Save document', iconKey: 'save');

    Widget target({required double width, required int maximum}) => pumpTarget(
      actions: ActionCollection(roots: [save]),
      onInvoke: (_) {},
      width: width,
      maxPrimaryActions: maximum,
      iconBuilder: iconBuilder,
      fadeDuration: const Duration(milliseconds: 400),
      resizeDuration: const Duration(milliseconds: 400),
    );

    await tester.pumpWidget(target(width: 300, maximum: 1));
    await tester.pumpWidget(target(width: 48, maximum: 1));
    await tester.pump(const Duration(milliseconds: 100));
    final widthBeforeRetarget = tester
        .getSize(find.byType(MaterialAdaptiveActions<String>))
        .width;

    await tester.pumpWidget(target(width: 48, maximum: 0));
    final widthAfterRetarget = tester
        .getSize(find.byType(MaterialAdaptiveActions<String>))
        .width;
    expect(widthAfterRetarget, closeTo(widthBeforeRetarget, 0.0001));

    await tester.pump(const Duration(milliseconds: 100));
    final saveOpacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.byIcon(Icons.save), matching: find.byType(Opacity))
          .first,
    );
    final moreOpacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byTooltip('More actions'),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(saveOpacity.opacity + moreOpacity.opacity, closeTo(1, 0.0001));
    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      inInclusiveRange(48, widthBeforeRetarget),
    );

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.save), findsNothing);
    expect(find.byTooltip('More actions'), findsOneWidget);
  });

  testWidgets('animates only the last collapse across multiple actions', (
    tester,
  ) async {
    final actions = ActionCollection(
      roots: [
        action('a', label: 'A'),
        action('b', label: 'B'),
        action('c', label: 'C'),
        action('d', label: 'D'),
      ],
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: actions,
        onInvoke: (_) {},
        width: 400,
        maxPrimaryActions: 4,
        fadeDuration: const Duration(milliseconds: 400),
        resizeDuration: const Duration(milliseconds: 400),
      ),
    );
    final expandedWidth = tester
        .getSize(find.byType(MaterialAdaptiveActions<String>))
        .width;

    await tester.pumpWidget(
      pumpTarget(
        actions: actions,
        onInvoke: (_) {},
        width: 400,
        maxPrimaryActions: 2,
        fadeDuration: const Duration(milliseconds: 400),
        resizeDuration: const Duration(milliseconds: 400),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('D'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('C'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text('A'), matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(
      find.ancestor(of: find.text('B'), matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.byTooltip('More actions'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(find.byType(Opacity), findsOneWidget);
    final contractingWidth = tester
        .getSize(find.byType(MaterialAdaptiveActions<String>))
        .width;
    expect(contractingWidth, lessThan(expandedWidth));

    await tester.pumpAndSettle();
    expect(find.text('C'), findsNothing);
    expect(find.byTooltip('More actions'), findsOneWidget);
  });

  testWidgets('animates only the last expansion across multiple actions', (
    tester,
  ) async {
    final actions = ActionCollection(
      roots: [
        action('a', label: 'A'),
        action('b', label: 'B'),
        action('c', label: 'C'),
        action('d', label: 'D'),
      ],
    );

    Widget target(int maximum) => pumpTarget(
      actions: actions,
      onInvoke: (_) {},
      width: 400,
      maxPrimaryActions: maximum,
      fadeDuration: const Duration(milliseconds: 400),
      resizeDuration: const Duration(milliseconds: 400),
    );

    await tester.pumpWidget(target(2));
    final collapsedWidth = tester
        .getSize(find.byType(MaterialAdaptiveActions<String>))
        .width;
    await tester.pumpWidget(target(4));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byTooltip('More actions'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('C'), matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(
      find.ancestor(of: find.text('D'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
    expect(find.byType(Opacity), findsOneWidget);
    final expandingWidth = tester
        .getSize(find.byType(MaterialAdaptiveActions<String>))
        .width;
    expect(expandingWidth, greaterThan(collapsedWidth));

    await tester.pumpAndSettle();
    expect(find.text('D'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('D'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('a new layout finishes the previous outgoing action', (
    tester,
  ) async {
    final actions = ActionCollection(
      roots: [
        action('a', label: 'A'),
        action('b', label: 'B'),
        action('c', label: 'C'),
        action('d', label: 'D'),
      ],
    );

    Widget target(int maximum) => pumpTarget(
      actions: actions,
      onInvoke: (_) {},
      width: 400,
      maxPrimaryActions: maximum,
      fadeDuration: const Duration(milliseconds: 400),
      resizeDuration: const Duration(milliseconds: 400),
    );

    await tester.pumpWidget(target(4));
    await tester.pumpWidget(target(3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('D'), findsOneWidget);

    await tester.pumpWidget(target(2));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('D'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('C'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text('A'), matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(find.byType(Opacity), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('C'), findsNothing);
  });

  testWidgets('capacity rebuilds keep the active target transition running', (
    tester,
  ) async {
    final actions = ActionCollection(
      roots: [
        action('a', label: 'A'),
        action('b', label: 'B'),
        action('c', label: 'C'),
        action('d', label: 'D'),
      ],
    );

    Widget target({required double width, required int maximum}) => pumpTarget(
      actions: actions,
      onInvoke: (_) {},
      width: width,
      maxPrimaryActions: maximum,
      fadeDuration: const Duration(milliseconds: 400),
      resizeDuration: const Duration(milliseconds: 400),
    );

    await tester.pumpWidget(target(width: 400, maximum: 4));
    await tester.pumpWidget(target(width: 300, maximum: 2));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('C'), findsOneWidget);

    await tester.pumpWidget(target(width: 290, maximum: 2));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('C'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('C'), matching: find.byType(Opacity)),
      findsOneWidget,
    );

    await tester.pumpAndSettle();
    expect(find.text('C'), findsNothing);
  });

  testWidgets('applies configurable primary layout metrics', (tester) async {
    final save = action('save', label: 'Save document', iconKey: 'save');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialAdaptiveActions<String>.moreAction(
            actions: ActionCollection(roots: [save]),
            onInvoke: (_) {},
            primaryCapacity: 60,
            iconBuilder: iconBuilder,
            style: const MaterialAdaptiveActionsStyle(
              height: 64,
              iconButtonWidth: 60,
              iconSize: 24,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).height,
      64,
    );
    expect(tester.getSize(find.byIcon(Icons.save)), const Size.square(24));
  });

  testWidgets('uses parent height constraints before the preferred height', (
    tester,
  ) async {
    final save = action('save', iconKey: 'save');

    Widget target(BoxConstraints constraints) => MaterialApp(
      home: Scaffold(
        body: Align(
          child: ConstrainedBox(
            constraints: constraints,
            child: MaterialAdaptiveActions<String>.moreAction(
              actions: ActionCollection(roots: [save]),
              onInvoke: (_) {},
              primaryCapacity: 100,
              iconBuilder: iconBuilder,
              presentationOverride: MaterialActionPresentation.iconOnly,
              fadeDuration: Duration.zero,
              resizeDuration: Duration.zero,
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(target(const BoxConstraints.tightFor(height: 20)));

    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).height,
      20,
    );
    expect(tester.getSize(find.byType(IconButton)).height, 20);

    await tester.pumpWidget(target(const BoxConstraints(maxHeight: 64)));

    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).height,
      48,
    );

    await tester.pumpWidget(target(const BoxConstraints(maxHeight: 20)));

    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).height,
      20,
    );
  });

  testWidgets('remains compatible with intrinsic-height parents', (
    tester,
  ) async {
    final save = action('save', iconKey: 'save');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntrinsicHeight(
            child: MaterialAdaptiveActions<String>.moreAction(
              actions: ActionCollection(roots: [save]),
              onInvoke: (_) {},
              primaryCapacity: 100,
              iconBuilder: iconBuilder,
              fadeDuration: Duration.zero,
              resizeDuration: Duration.zero,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).height,
      48,
    );
  });

  testWidgets('composite controls match their resolver layout cost', (
    tester,
  ) async {
    final open = AdaptiveAction<String>.composite(
      id: ActionId('open'),
      metadata: const ActionMetadata(label: 'Open', iconKey: 'open'),
      payload: 'open-command',
      children: [action('recent')],
    );

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [open]),
        onInvoke: (_) {},
        width: 80,
        iconBuilder: iconBuilder,
      ),
    );

    expect(
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
      80,
    );
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.byIcon(Icons.arrow_drop_down),
              matching: find.byType(IconButton),
            ),
          )
          .width,
      32,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('composite menu affordance uses caller-owned tooltip text', (
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

    final tooltip = tester.widget<Tooltip>(
      find.ancestor(
        of: find.byIcon(Icons.arrow_drop_down),
        matching: find.byType(Tooltip),
      ),
    );
    expect(tooltip.message, '打开子菜单');
  });

  testWidgets(
    'provides a primary profile after a constraint placement override',
    (tester) async {
      final save = action(
        'save',
        iconKey: 'save',
        placementPolicy: ActionPlacementPolicy(
          placement: ActionPlacement.overflowOnly,
        ),
      );

      await tester.pumpWidget(
        pumpTarget(
          actions: ActionCollection(
            roots: [save],
            placementConstraints: [
              ActionPlacementConstraints(
                id: ActionPlacementConstraintId('promote-save'),
                actionIds: [save.id],
                placementOverride: ActionPlacement.pinned,
              ),
            ],
          ),
          onInvoke: (_) {},
          iconBuilder: iconBuilder,
        ),
      );

      expect(find.byTooltip('save'), findsOneWidget);
    },
  );

  testWidgets('can be used directly in AppBar actions', (tester) async {
    final save = action('save', iconKey: 'save');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Document'),
            actions: [
              MaterialAdaptiveActions<String>.moreAction(
                actions: ActionCollection(roots: [save]),
                onInvoke: (_) {},
                primaryCapacity: 120,
                iconBuilder: iconBuilder,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disabled primary action keeps semantics and suppresses payload',
    (tester) async {
      final save = action(
        'save',
        tooltip: 'Save changes',
        semanticLabel: 'Save document',
        iconKey: 'save',
        isEnabled: false,
      );
      final invoked = <String>[];

      await tester.pumpWidget(
        pumpTarget(
          actions: ActionCollection(roots: [save]),
          onInvoke: invoked.add,
          iconBuilder: iconBuilder,
        ),
      );

      expect(find.byTooltip('Save changes'), findsOneWidget);
      expect(find.bySemanticsLabel('Save document'), findsOneWidget);

      await tester.tap(find.byTooltip('Save changes'));

      expect(invoked, isEmpty);
    },
  );

  testWidgets('renders Material menu subtitles without changing primary', (
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
        width: 48,
        iconBuilder: iconBuilder,
      ),
    );

    expect(find.text('Current document'), findsNothing);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();

    expect(find.text('save'), findsOneWidget);
    expect(find.text('Current document'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);
    final subtitleContext = tester.element(find.text('Current document'));
    final subtitleStyle = DefaultTextStyle.of(subtitleContext).style;
    expect(
      subtitleStyle.fontSize,
      Theme.of(subtitleContext).textTheme.bodyMedium?.fontSize,
    );
    expect(
      subtitleStyle.color,
      Theme.of(subtitleContext).colorScheme.onSurfaceVariant,
    );
    expect(
      tester.getCenter(find.byIcon(Icons.save)).dy,
      closeTo(
        tester
            .getCenter(
              find
                  .ancestor(
                    of: find.text('Current document'),
                    matching: find.byType(Column),
                  )
                  .first,
            )
            .dy,
        0.01,
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp(r'save[\s\S]*Current document')),
      findsOneWidget,
    );
  });

  testWidgets('uses explicit menu semantics and disabled subtitle color', (
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

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [disabled]),
        onInvoke: (_) {},
        width: 48,
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Unavailable command'), findsOneWidget);
    final subtitleContext = tester.element(
      find.text('Not currently available'),
    );
    expect(
      DefaultTextStyle.of(subtitleContext).style.color,
      Theme.of(subtitleContext).colorScheme.onSurface.withValues(alpha: 0.38),
    );
  });

  testWidgets('renders subtitles on submenu and composite menu entries', (
    tester,
  ) async {
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
        actions: ActionCollection(roots: [menu, composite]),
        onInvoke: (_) {},
        width: 48,
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();

    expect(find.text('Choose an arrangement'), findsOneWidget);
    expect(find.text('Most recent document'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Most recent document'), findsNWidgets(2));
  });

  testWidgets('allows long menu subtitles with large text scaling', (
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
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: MaterialAdaptiveActions<String>.moreAction(
              actions: ActionCollection(roots: [details]),
              onInvoke: (_) {},
              primaryCapacity: 48,
              fadeDuration: Duration.zero,
              resizeDuration: Duration.zero,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();

    expect(find.text(details.metadata.subtitle!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Material menu animation defaults on and reaches nested submenus',
    (tester) async {
      final leaf = action('leaf');
      final nested = AdaptiveAction<String>.menu(
        id: ActionId('nested'),
        metadata: const ActionMetadata(label: 'Nested'),
        children: [leaf],
      );
      final root = AdaptiveAction<String>.menu(
        id: ActionId('root'),
        metadata: const ActionMetadata(label: 'Root'),
        children: [nested],
      );

      Widget target({bool? menuAnimationEnabled}) => MaterialApp(
        home: Scaffold(
          body: menuAnimationEnabled == null
              ? MaterialAdaptiveActions<String>.moreAction(
                  actions: ActionCollection(roots: [root]),
                  onInvoke: (_) {},
                  primaryCapacity: 300,
                )
              : MaterialAdaptiveActions<String>.moreAction(
                  actions: ActionCollection(roots: [root]),
                  onInvoke: (_) {},
                  primaryCapacity: 300,
                  menuAnimationEnabled: menuAnimationEnabled,
                ),
        ),
      );

      await tester.pumpWidget(target());
      expect(
        tester.widget<MenuAnchor>(find.byType(MenuAnchor)).animated,
        isTrue,
      );
      await tester.tap(find.text('Root'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SubmenuButton>(find.byType(SubmenuButton)).animated,
        isTrue,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(target(menuAnimationEnabled: false));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MenuAnchor>(find.byType(MenuAnchor)).animated,
        isFalse,
      );
      await tester.tap(find.text('Root'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SubmenuButton>(find.byType(SubmenuButton)).animated,
        isFalse,
      );
    },
  );

  for (final menuAnimationEnabled in [false, true]) {
    testWidgets(
      'overflow invocation safely replaces an AppBar LayoutBuilder host '
      'with menuAnimationEnabled: $menuAnimationEnabled',
      (tester) async {
        final invoked = <String>[];
        final replace = action(
          'replace',
          placementPolicy: ActionPlacementPolicy(
            placement: ActionPlacement.overflowOnly,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: _MaterialInvocationReplacementHost(
              actions: ActionCollection(roots: [replace]),
              menuAnimationEnabled: menuAnimationEnabled,
              onInvoke: invoked.add,
            ),
          ),
        );
        await tester.tap(find.byTooltip('More actions'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(MenuItemButton, 'replace'));
        expect(invoked, isEmpty);
        await tester.pumpAndSettle();

        expect(find.text('replacement'), findsOneWidget);
        expect(invoked, ['replace-command']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('nested menu invocation safely replaces its AppBar host', (
    tester,
  ) async {
    final invoked = <String>[];
    final leaf = action('replace');
    final inner = AdaptiveAction<String>.menu(
      id: ActionId('inner'),
      metadata: const ActionMetadata(label: 'Inner'),
      children: [leaf],
    );
    final outer = AdaptiveAction<String>.menu(
      id: ActionId('outer'),
      metadata: const ActionMetadata(label: 'Outer'),
      children: [inner],
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: _MaterialInvocationReplacementHost(
          actions: ActionCollection(roots: [outer]),
          menuAnimationEnabled: true,
          onInvoke: invoked.add,
        ),
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inner'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'replace'));
    expect(invoked, isEmpty);
    await tester.pumpAndSettle();

    expect(find.text('replacement'), findsOneWidget);
    expect(invoked, ['replace-command']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'primary menu opens direct children and dispatches their payload',
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
          iconBuilder: iconBuilder,
        ),
      );

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      expect(find.text('recent'), findsOneWidget);

      await tester.tap(find.text('recent'));
      await tester.pumpAndSettle();
      expect(invoked, ['recent-command']);
    },
  );

  testWidgets('primary menu renders a PopupMenuDivider between actions', (
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
        iconBuilder: iconBuilder,
      ),
    );

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuDivider), findsOneWidget);

    await tester.tap(find.widgetWithText(MenuItemButton, 'second'));
    await tester.pumpAndSettle();
    expect(invoked, ['second-command']);
  });

  testWidgets('top-level divider independently targets primary and menu', (
    tester,
  ) async {
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
    expect(find.byType(VerticalDivider), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      pumpTarget(
        actions: menuOnly,
        onInvoke: (_) {},
        width: 48,
        maxPrimaryActions: 0,
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuDivider), findsOneWidget);

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
    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(tester.getSize(find.byType(VerticalDivider)).width, 16);
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
        iconBuilder: iconBuilder,
      ),
    );
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuDivider), findsNothing);
    expect(find.widgetWithText(MenuItemButton, 'first'), findsOneWidget);
    expect(find.widgetWithText(MenuItemButton, 'second'), findsOneWidget);
  });

  testWidgets('composite primary action exposes invoke and direct menu paths', (
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
        iconBuilder: iconBuilder,
      ),
    );

    await tester.tap(find.text('Open'));
    expect(invoked, ['open-command']);

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('recent'));
    await tester.pumpAndSettle();

    expect(invoked, ['open-command', 'recent-command']);
  });

  testWidgets('invocation guard dispatches only enabled non-null payloads', (
    tester,
  ) async {
    final enabled = action('enabled');
    final disabled = action('disabled', isEnabled: false);
    final menu = AdaptiveAction<String>.menu(
      id: ActionId('menu'),
      metadata: const ActionMetadata(label: 'Menu'),
      children: [action('child')],
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [enabled, disabled, menu]),
        onInvoke: invoked.add,
        width: 1000,
      ),
    );

    await tester.tap(find.text('enabled'));
    await tester.tap(find.text('disabled'));
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    expect(invoked, ['enabled-command']);
  });

  testWidgets('shows overflow trigger only for a non-empty overflow result', (
    tester,
  ) async {
    final save = action('save');
    final forcedOverflow = action(
      'forced',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final actions = ActionCollection(roots: [save, forcedOverflow]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaterialAdaptiveActions<String>(
            actions: actions,
            onInvoke: (_) {},
            primaryCapacity: 96,
            style: const MaterialAdaptiveActionsStyle(overflowButtonWidth: 56),
            overflowIcon: const Icon(Icons.more_horiz),
            overflowTooltip: 'Commands',
            fadeDuration: Duration.zero,
            resizeDuration: Duration.zero,
          ),
        ),
      ),
    );

    expect(find.text('save'), findsNothing);
    expect(find.byTooltip('Commands'), findsOneWidget);
    expect(tester.getSize(find.byTooltip('Commands')).width, 56);

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [save]),
        onInvoke: (_) {},
        width: 96,
      ),
    );

    expect(find.text('save'), findsOneWidget);
    expect(find.byTooltip('More actions'), findsNothing);
  });

  testWidgets('preserves final overflow sibling order and invokes a leaf', (
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
        width: 48,
        overflowOrderOverride: [third.id, first.id],
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();

    final thirdY = tester.getTopLeft(find.text('third')).dy;
    final secondY = tester.getTopLeft(find.text('second')).dy;
    final firstY = tester.getTopLeft(find.text('first')).dy;
    expect(thirdY, lessThan(secondY));
    expect(secondY, lessThan(firstY));

    await tester.tap(find.text('second'));
    await tester.pumpAndSettle();
    expect(invoked, ['second-command']);
  });

  testWidgets('opens arbitrary-depth submenus in declaration order', (
    tester,
  ) async {
    final deepFirst = action('deep-first');
    final deepSecond = action('deep-second');
    final inner = AdaptiveAction<String>.menu(
      id: ActionId('inner'),
      metadata: const ActionMetadata(label: 'inner'),
      children: [deepFirst, deepSecond],
    );
    final outerLast = action('outer-last');
    final outer = AdaptiveAction<String>.menu(
      id: ActionId('outer'),
      metadata: const ActionMetadata(label: 'outer'),
      children: [inner, outerLast],
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final rootsBefore = <AdaptiveAction<String>>[outer];
    final childrenBefore = List<AdaptiveMenuEntry<String>>.of(outer.children);
    final deepChildrenBefore = List<AdaptiveMenuEntry<String>>.of(
      inner.children,
    );
    final collection = ActionCollection(roots: rootsBefore);
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(actions: collection, onInvoke: invoked.add, width: 48),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('outer'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('inner')).dy,
      lessThan(tester.getTopLeft(find.text('outer-last')).dy),
    );

    await tester.tap(find.text('inner'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('deep-first')).dy,
      lessThan(tester.getTopLeft(find.text('deep-second')).dy),
    );

    await tester.tap(find.text('deep-second'));
    await tester.pumpAndSettle();
    expect(invoked, ['deep-second-command']);
    expect(collection.roots, orderedEquals(rootsBefore));
    expect(outer.children, orderedEquals(childrenBefore));
    expect(inner.children, orderedEquals(deepChildrenBefore));
  });

  testWidgets('overflow composite keeps invoke and submenu behaviors', (
    tester,
  ) async {
    final recent = action('recent');
    final open = AdaptiveAction<String>.composite(
      id: ActionId('open'),
      metadata: const ActionMetadata(label: 'Open'),
      payload: 'open-command',
      children: [recent],
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [open]),
        onInvoke: invoked.add,
        width: 48,
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open').first);
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsNWidgets(2));
    expect(find.text('recent'), findsOneWidget);
    await tester.tap(find.text('Open').last);
    await tester.pumpAndSettle();
    expect(invoked, ['open-command']);

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('recent'));
    await tester.pumpAndSettle();
    expect(invoked, ['open-command', 'recent-command']);
  });

  testWidgets('disabled overflow branch suppresses payload and submenu', (
    tester,
  ) async {
    final child = action('blocked-child');
    final disabled = AdaptiveAction<String>.composite(
      id: ActionId('disabled'),
      metadata: const ActionMetadata(
        label: 'Disabled',
        tooltip: 'Unavailable command',
        semanticLabel: 'Disabled command',
        iconKey: 'open',
        isDestructive: true,
      ),
      payload: 'disabled-command',
      children: [child],
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
        width: 48,
        iconBuilder: iconBuilder,
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Unavailable command'), findsOneWidget);
    expect(find.bySemanticsLabel('Disabled command'), findsOneWidget);
    expect(find.byIcon(Icons.folder_open), findsOneWidget);
    await tester.tap(find.text('Disabled'));
    await tester.pumpAndSettle();

    expect(invoked, isEmpty);
    expect(find.text('blocked-child'), findsNothing);
  });

  testWidgets('overflow menu supports keyboard invocation', (tester) async {
    final run = action(
      'run',
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final invoked = <String>[];

    await tester.pumpWidget(
      pumpTarget(
        actions: ActionCollection(roots: [run]),
        onInvoke: invoked.add,
        width: 48,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('run'), findsOneWidget);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.moveTo(tester.getCenter(find.text('run')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await pointer.removePointer();

    expect(invoked, ['run-command']);
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

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('L'), findsNothing);
    expect(find.text('O'), findsNothing);
    expect(find.text('X'), findsNothing);
    expect(
      tester.getTopLeft(find.text('H')).dx,
      lessThan(tester.getTopLeft(find.text('P')).dx),
    );

    await tester.tap(find.text('H'));
    expect(invoked, ['high-command']);

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('O')).dy,
      lessThan(tester.getTopLeft(find.text('L')).dy),
    );
    await tester.tap(find.text('O'));
    await tester.pumpAndSettle();
    expect(invoked, ['high-command', 'overflow-command']);
  });

  testWidgets('leaves unsatisfied pinned overflow behavior to the caller', (
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
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(
      tester.getSize(find.widgetWithText(TextButton, 'Pinned command')).width,
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
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(delegate.resolveCount, 2);
  });

  testWidgets('keeps primaryCapacity authoritative under a narrower parent', (
    tester,
  ) async {
    final delegate = _RecordingPlacementDelegate();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: MaterialAdaptiveActions<String>.moreAction(
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
      tester.getSize(find.byType(MaterialAdaptiveActions<String>)).width,
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

    await tester.tap(find.byTooltip('More actions'));
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
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('third'));
    await tester.pumpAndSettle();
    expect(invoked, ['first-command', 'third-command']);
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

final class _MaterialInvocationReplacementHost extends StatefulWidget {
  const _MaterialInvocationReplacementHost({
    required this.actions,
    required this.menuAnimationEnabled,
    required this.onInvoke,
  });

  final ActionCollection<String> actions;
  final bool menuAnimationEnabled;
  final ValueChanged<String> onInvoke;

  @override
  State<_MaterialInvocationReplacementHost> createState() =>
      _MaterialInvocationReplacementHostState();
}

final class _MaterialInvocationReplacementHostState
    extends State<_MaterialInvocationReplacementHost> {
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
      return const Scaffold(body: Center(child: Text('replacement')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actions'),
        actions: [
          SizedBox(
            width: 48,
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  MaterialAdaptiveActions<String>.moreAction(
                    actions: widget.actions,
                    onInvoke: _handleInvoke,
                    primaryCapacity: constraints.maxWidth,
                    maxPrimaryActions: 0,
                    menuAnimationEnabled: widget.menuAnimationEnabled,
                    fadeDuration: Duration.zero,
                    resizeDuration: Duration.zero,
                  ),
            ),
          ),
        ],
      ),
      body: const SizedBox(),
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
