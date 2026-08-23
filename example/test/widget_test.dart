import 'package:adaptive_actions/cupertino.dart';
import 'package:adaptive_actions/material.dart';
import 'package:adaptive_actions_example/demo_settings.dart';
import 'package:adaptive_actions_example/demo_widgets.dart';
import 'package:adaptive_actions_example/main.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoIcons,
        CupertinoNavigationBar,
        CupertinoPageScaffold,
        CupertinoSlider,
        CupertinoSwitch,
        CupertinoTheme;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> invokeDemoControl(
    WidgetTester tester, {
    required String label,
    required bool useCupertino,
  }) async {
    final trigger = find.descendant(
      of: find.byKey(appBarActionsKey),
      matching: find.byIcon(
        useCupertino ? CupertinoIcons.ellipsis : Icons.more_vert,
      ),
    );
    expect(trigger, findsOneWidget);
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  test('selects the initial renderer from the target platform', () {
    expect(defaultDemoRenderer(TargetPlatform.iOS), DemoRenderer.apple);
    expect(defaultDemoRenderer(TargetPlatform.macOS), DemoRenderer.apple);
    expect(defaultDemoRenderer(TargetPlatform.android), DemoRenderer.material);
    expect(defaultDemoRenderer(TargetPlatform.linux), DemoRenderer.material);
    expect(defaultDemoRenderer(TargetPlatform.windows), DemoRenderer.material);
    expect(defaultDemoRenderer(TargetPlatform.fuchsia), DemoRenderer.material);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
    testWidgets('defaults to the Apple renderer on ${platform.name}', (
      tester,
    ) async {
      try {
        debugDefaultTargetPlatformOverride = platform;
        await tester.pumpWidget(const AdaptiveActionsExampleApp());
        await tester.pumpAndSettle();

        expect(find.byType(CupertinoPageScaffold), findsOneWidget);
        expect(
          find.byType(CupertinoAdaptiveActions<DemoCommand>),
          findsWidgets,
        );
        expect(find.byType(MaterialAdaptiveActions<DemoCommand>), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets('defaults to Material and reuses one action configuration', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();

    expect(find.byKey(previewListKey), findsOneWidget);
    expect(find.text('Window width: 800 px'), findsOneWidget);
    expect(find.textContaining('Simulated maximum:'), findsOneWidget);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, isFalse);
    expect(find.byKey(titleAlignmentToggleKey), findsOneWidget);
    expect(find.byKey(appBarActionFrameKey), findsOneWidget);
    final scrollable = find
        .descendant(
          of: find.byKey(previewListKey),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Adaptive action preview'),
      300,
      scrollable: scrollable,
    );

    final renderers = tester
        .widgetList<MaterialAdaptiveActions<DemoCommand>>(
          find.byType(MaterialAdaptiveActions<DemoCommand>),
        )
        .toList();
    expect(renderers, hasLength(2));
    expect(find.byType(CupertinoAdaptiveActions<DemoCommand>), findsNothing);
    expect(identical(renderers.first.actions, renderers.last.actions), isTrue);
    expect(renderers.first.primaryCapacity, renderers.last.primaryCapacity);
    expect(
      renderers.first.primaryOrderOverride,
      orderedEquals([ActionId('share'), ActionId('open')]),
    );
    expect(
      renderers.first.overflowOrderOverride,
      orderedEquals([ActionId('delete'), ActionId('share')]),
    );
    expect(
      renderers.every((renderer) => renderer.maxPrimaryActions == null),
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(MaterialAdaptiveActions<DemoCommand>),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Resolved layout'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Primary:'), findsOneWidget);
    expect(find.text('Overflow:'), findsOneWidget);
    expect(find.text('Hidden:'), findsOneWidget);
    expect(find.text('Diagnostics:'), findsOneWidget);
  });

  testWidgets('settings rebuild the preview without persistence', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<DropdownButton<int>>(find.byKey(maxPrimaryActionsKey))
          .items,
      hasLength(10),
    );
    var actionWidthSlider = tester.widget<Slider>(
      find.byKey(actionWidthSliderKey),
    );
    expect(actionWidthSlider.value, actionWidthSlider.max);
    expect(
      find.text('Simulated maximum action width: Unlimited'),
      findsOneWidget,
    );

    await tester.drag(find.byKey(previewListKey), const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(enabledSwitchKey));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byKey(enabledSwitchKey)).value,
      isFalse,
    );

    await tester.drag(find.byKey(actionWidthSliderKey), const Offset(-180, 0));
    await tester.pumpAndSettle();
    actionWidthSlider = tester.widget<Slider>(find.byKey(actionWidthSliderKey));
    expect(actionWidthSlider.value, lessThan(actionWidthSlider.max));

    await tester.drag(find.byKey(actionWidthSliderKey), const Offset(1000, 0));
    await tester.pumpAndSettle();
    actionWidthSlider = tester.widget<Slider>(find.byKey(actionWidthSliderKey));
    expect(actionWidthSlider.value, actionWidthSlider.max);
    expect(
      find.text('Simulated maximum action width: Unlimited'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(maxPrimaryActionsKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButton<int>>(find.byKey(maxPrimaryActionsKey))
          .value,
      1,
    );

    await tester.tap(find.byKey(maxPrimaryActionsKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlimited').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButton<int>>(find.byKey(maxPrimaryActionsKey))
          .value,
      isNull,
    );
  });

  testWidgets('divider visibility selection rebuilds the action collection', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();

    List<AdaptiveMenuDivider<DemoCommand>> dividers() => tester
        .widget<MaterialAdaptiveActions<DemoCommand>>(
          find.byType(MaterialAdaptiveActions<DemoCommand>).first,
        )
        .actions
        .entries
        .whereType<AdaptiveMenuDivider<DemoCommand>>()
        .toList();

    expect(dividers(), hasLength(3));
    expect(dividers().every((divider) => !divider.showInPrimary), isTrue);
    expect(dividers().every((divider) => divider.showInMenu), isTrue);

    final selector = find.byKey(dividerVisibilitySelectorKey);
    expect(
      tester.widget<DropdownButton<DemoDividerVisibility>>(selector).items,
      hasLength(4),
    );

    tester.widget<DropdownButton<DemoDividerVisibility>>(selector).onChanged!(
      DemoDividerVisibility.both,
    );
    await tester.pumpAndSettle();
    expect(dividers().every((divider) => divider.showInPrimary), isTrue);
    expect(dividers().every((divider) => divider.showInMenu), isTrue);
    expect(
      find.descendant(
        of: find.byKey(appBarActionsKey),
        matching: find.byType(VerticalDivider),
      ),
      findsNWidgets(3),
    );
    final deleteIcon = find.descendant(
      of: find.descendant(
        of: find.byKey(appBarActionsKey),
        matching: find.byKey(customDeleteButtonKey),
      ),
      matching: find.byType(Icon),
    );
    expect(tester.getSize(deleteIcon), const Size.square(18));

    tester.widget<DropdownButton<DemoDividerVisibility>>(selector).onChanged!(
      DemoDividerVisibility.primaryOnly,
    );
    await tester.pumpAndSettle();
    expect(dividers().every((divider) => divider.showInPrimary), isTrue);
    expect(dividers().every((divider) => !divider.showInMenu), isTrue);

    tester.widget<DropdownButton<DemoDividerVisibility>>(selector).onChanged!(
      DemoDividerVisibility.hidden,
    );
    await tester.pumpAndSettle();
    expect(dividers().every((divider) => !divider.showInPrimary), isTrue);
    expect(dividers().every((divider) => !divider.showInMenu), isTrue);
    expect(
      find.descendant(
        of: find.byKey(appBarActionsKey),
        matching: find.byType(VerticalDivider),
      ),
      findsNothing,
    );
  });

  testWidgets('custom builders target selected actions and toggle More', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();

    final materialRenderers = tester
        .widgetList<MaterialAdaptiveActions<DemoCommand>>(
          find.byType(MaterialAdaptiveActions<DemoCommand>),
        )
        .toList();
    expect(materialRenderers, isNotEmpty);
    expect(
      materialRenderers.every((value) => value.actionButtonBuilder != null),
      isTrue,
    );
    expect(
      materialRenderers.every((value) => value.overflowButtonBuilder == null),
      isTrue,
    );
    expect(find.byKey(customSaveButtonKey), findsWidgets);
    expect(find.byKey(customOpenButtonKey), findsWidgets);
    expect(find.byKey(customOverflowButtonKey), findsNothing);

    final scrollable = find
        .descendant(
          of: find.byKey(previewListKey),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Custom button builders'),
      300,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(customOverflowButtonSwitchKey))
          .value,
      isFalse,
    );
    await tester.tap(find.byKey(customOverflowButtonSwitchKey));
    await tester.pumpAndSettle();

    expect(find.byKey(customOverflowButtonKey), findsWidgets);
    expect(
      tester
          .widgetList<MaterialAdaptiveActions<DemoCommand>>(
            find.byType(MaterialAdaptiveActions<DemoCommand>),
          )
          .every((value) => value.overflowButtonBuilder != null),
      isTrue,
    );

    final appBarCustomMore = find.descendant(
      of: find.byKey(appBarActionsKey),
      matching: find.byKey(customOverflowButtonKey),
    );
    await tester.tap(appBarCustomMore);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch to Apple').last);
    await tester.pumpAndSettle();

    final cupertinoRenderers = tester
        .widgetList<CupertinoAdaptiveActions<DemoCommand>>(
          find.byType(CupertinoAdaptiveActions<DemoCommand>),
        )
        .toList();
    expect(cupertinoRenderers, isNotEmpty);
    expect(
      cupertinoRenderers.every((value) => value.actionButtonBuilder != null),
      isTrue,
    );
    expect(
      cupertinoRenderers.every((value) => value.overflowButtonBuilder != null),
      isTrue,
    );
    expect(find.byKey(customOverflowButtonKey), findsWidgets);
  });

  testWidgets('AppBar action frame is visible by default and can be hidden', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AppBarActionFrame>(find.byKey(appBarActionFrameKey))
          .showBorder,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(appBarActionFrameSwitchKey))
          .value,
      isTrue,
    );

    await tester.drag(find.byKey(previewListKey), const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(appBarActionFrameSwitchKey));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AppBarActionFrame>(find.byKey(appBarActionFrameKey))
          .showBorder,
      isFalse,
    );
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(appBarActionFrameSwitchKey))
          .value,
      isFalse,
    );
  });

  testWidgets('example renders the configured primary order override', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(previewListKey),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.scrollUntilVisible(
      find.text('Adaptive action preview'),
      300,
      scrollable: scrollable,
    );
    final primaryLabels = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byKey(previewActionsKey),
            matching: find.byType(Semantics),
          ),
        )
        .map((semantics) => semantics.properties.label)
        .where(
          (label) =>
              {'Save', 'Open', 'Share', 'Delete', 'Help'}.contains(label),
        );
    expect(
      primaryLabels,
      orderedEquals(['Save', 'Share', 'Open', 'Delete', 'Help']),
    );
  });

  testWidgets('renderer-specific presentations stay isolated', (tester) async {
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(previewListKey),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.scrollUntilVisible(
      find.byKey(materialPresentationSelectorKey),
      300,
      scrollable: scrollable,
    );
    await tester.ensureVisible(find.byKey(materialPresentationSelectorKey));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<DropdownButton<MaterialActionPresentation>>(
            find.byKey(materialPresentationSelectorKey),
          )
          .value,
      isNull,
    );
    expect(
      tester
          .widgetList<MaterialAdaptiveActions<DemoCommand>>(
            find.byType(MaterialAdaptiveActions<DemoCommand>),
          )
          .every((widget) => widget.presentationOverride == null),
      isTrue,
    );

    await tester.tap(find.byKey(materialPresentationSelectorKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Force icon only').last);
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<MaterialAdaptiveActions<DemoCommand>>(
            find.byType(MaterialAdaptiveActions<DemoCommand>),
          )
          .every(
            (widget) =>
                widget.presentationOverride ==
                MaterialActionPresentation.iconOnly,
          ),
      isTrue,
    );

    await invokeDemoControl(
      tester,
      label: 'Switch to Apple',
      useCupertino: false,
    );

    final appleScrollable = find
        .descendant(
          of: find.byKey(previewListKey),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(cupertinoPresentationSelectorKey),
      300,
      scrollable: appleScrollable,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(cupertinoPresentationSelectorKey)),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(materialPresentationSelectorKey), findsNothing);
    expect(find.byKey(cupertinoPresentationSelectorKey), findsOneWidget);
    expect(
      tester
          .widgetList<CupertinoAdaptiveActions<DemoCommand>>(
            find.byType(CupertinoAdaptiveActions<DemoCommand>),
          )
          .every((widget) => widget.presentationOverride == null),
      isTrue,
    );

    await tester.tap(find.byKey(cupertinoPresentationSelectorKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Force icon + label').last);
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<CupertinoAdaptiveActions<DemoCommand>>(
            find.byType(CupertinoAdaptiveActions<DemoCommand>),
          )
          .every(
            (widget) =>
                widget.presentationOverride ==
                CupertinoActionPresentation.extended,
          ),
      isTrue,
    );

    await invokeDemoControl(
      tester,
      label: 'Switch to Material',
      useCupertino: true,
    );
    expect(
      tester
          .widgetList<MaterialAdaptiveActions<DemoCommand>>(
            find.byType(MaterialAdaptiveActions<DemoCommand>),
          )
          .every(
            (widget) =>
                widget.presentationOverride ==
                MaterialActionPresentation.iconOnly,
          ),
      isTrue,
    );
  });

  testWidgets('parent height constrains both adaptive action regions', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(previewListKey),
          matching: find.byType(Scrollable),
        )
        .first;
    final appBarRenderer = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(MaterialAdaptiveActions<DemoCommand>),
    );

    expect(tester.getSize(appBarRenderer).height, defaultParentActionHeight);
    expect(
      tester
          .widget<MaterialAdaptiveActions<DemoCommand>>(appBarRenderer)
          .style
          .height,
      48,
    );

    await tester.scrollUntilVisible(
      find.byKey(actionHeightSliderKey),
      300,
      scrollable: scrollable,
    );
    await tester.ensureVisible(find.byKey(actionHeightSliderKey));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(actionHeightSliderKey), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Slider>(find.byKey(actionHeightSliderKey)).value,
      minimumParentActionHeight,
    );
    expect(tester.getSize(appBarRenderer).height, minimumParentActionHeight);

    await tester.scrollUntilVisible(
      find.text('Adaptive action preview'),
      300,
      scrollable: scrollable,
    );

    final renderers = find.byType(MaterialAdaptiveActions<DemoCommand>);
    expect(renderers, findsNWidgets(2));
    for (var index = 0; index < 2; index += 1) {
      final renderer = renderers.at(index);
      expect(tester.getSize(renderer).height, minimumParentActionHeight);
      expect(
        tester
            .widget<MaterialAdaptiveActions<DemoCommand>>(renderer)
            .style
            .height,
        48,
      );
    }

    await invokeDemoControl(
      tester,
      label: 'Switch to Apple',
      useCupertino: false,
    );

    await tester.scrollUntilVisible(
      find.text('Adaptive action preview'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(previewListKey),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    final appleRenderers = find.byType(CupertinoAdaptiveActions<DemoCommand>);
    expect(appleRenderers, findsNWidgets(2));
    for (var index = 0; index < 2; index += 1) {
      final renderer = appleRenderers.at(index);
      expect(tester.getSize(renderer).height, minimumParentActionHeight);
      expect(
        tester
            .widget<CupertinoAdaptiveActions<DemoCommand>>(renderer)
            .style
            .height,
        44,
      );
    }
  });

  testWidgets('window and title mode bound the adaptive action capacity', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();

    var appBarActions = tester.widget<MaterialAdaptiveActions<DemoCommand>>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(MaterialAdaptiveActions<DemoCommand>),
      ),
    );
    final wideCapacity = appBarActions.primaryCapacity;
    expect(wideCapacity, greaterThan(maximumSimulatedActionWidth));

    tester.view.physicalSize = const Size(600, 800);
    await tester.pumpAndSettle();
    expect(find.text('Window width: 600 px'), findsOneWidget);
    appBarActions = tester.widget<MaterialAdaptiveActions<DemoCommand>>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(MaterialAdaptiveActions<DemoCommand>),
      ),
    );
    final normalCapacity = appBarActions.primaryCapacity;
    expect(normalCapacity, lessThan(wideCapacity));

    await tester.tap(find.byKey(titleAlignmentToggleKey));
    await tester.pumpAndSettle();
    expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
    appBarActions = tester.widget<MaterialAdaptiveActions<DemoCommand>>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(MaterialAdaptiveActions<DemoCommand>),
      ),
    );
    expect(appBarActions.primaryCapacity, lessThan(normalCapacity));
    expect(appBarActions.primaryCapacity, greaterThanOrEqualTo(48));

    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    appBarActions = tester.widget<MaterialAdaptiveActions<DemoCommand>>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(MaterialAdaptiveActions<DemoCommand>),
      ),
    );
    expect(appBarActions.primaryCapacity, minimumActionWidth);
  });

  testWidgets('renderer control switches the full shell and shared actions', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(previewListKey),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.scrollUntilVisible(
      find.text('Adaptive action preview'),
      300,
      scrollable: scrollable,
    );
    final materialRenderers = tester
        .widgetList<MaterialAdaptiveActions<DemoCommand>>(
          find.byType(MaterialAdaptiveActions<DemoCommand>),
        )
        .toList();
    expect(materialRenderers, hasLength(2));

    await invokeDemoControl(
      tester,
      label: 'Switch to Apple',
      useCupertino: false,
    );

    expect(find.byType(CupertinoPageScaffold), findsOneWidget);
    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    expect(find.byType(CupertinoTheme), findsWidgets);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    final appleWidthSlider = tester.widget<CupertinoSlider>(
      find.byKey(actionWidthSliderKey),
    );
    expect(appleWidthSlider.value, appleWidthSlider.max);
    expect(
      DefaultTextStyle.of(
        tester.element(find.text('Window width: 800 px')),
      ).style.fontSize,
      17,
    );

    final appleScrollable = find
        .descendant(
          of: find.byKey(previewListKey),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Adaptive action preview'),
      300,
      scrollable: appleScrollable,
    );

    expect(find.byType(MaterialAdaptiveActions<DemoCommand>), findsNothing);
    final appleRenderers = tester
        .widgetList<CupertinoAdaptiveActions<DemoCommand>>(
          find.byType(CupertinoAdaptiveActions<DemoCommand>),
        )
        .toList();
    expect(appleRenderers, hasLength(2));
    expect(
      identical(appleRenderers.first.actions, appleRenderers.last.actions),
      isTrue,
    );
    expect(
      appleRenderers.first.primaryCapacity,
      appleRenderers.last.primaryCapacity,
    );
    expect(
      appleRenderers.first.primaryOrderOverride,
      orderedEquals([ActionId('share'), ActionId('open')]),
    );
    expect(
      appleRenderers.first.overflowOrderOverride,
      orderedEquals([ActionId('delete'), ActionId('share')]),
    );
    expect(
      appleRenderers.first.actions.roots.map((action) => action.id),
      materialRenderers.first.actions.roots.map((action) => action.id),
    );
    expect(
      appleRenderers.first.actions.roots.take(5),
      materialRenderers.first.actions.roots.take(5),
    );
    expect(
      identical(
        appleRenderers.first.resolver,
        materialRenderers.first.resolver,
      ),
      isTrue,
    );
    expect(
      appleRenderers.first.fadeDuration,
      materialRenderers.first.fadeDuration,
    );
    expect(
      appleRenderers.first.resizeDuration,
      materialRenderers.first.resizeDuration,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(
      appleRenderers.first.actions.roots.map((action) => action.metadata.label),
      containsAll(['Switch to Material', 'Switch to dark theme', 'Use RTL']),
    );

    final openAction = find.descendant(
      of: find.byKey(previewActionsKey),
      matching: find.byIcon(CupertinoIcons.folder_open),
    );
    await Scrollable.ensureVisible(tester.element(openAction), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(openAction);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Resolved layout'),
      300,
      scrollable: appleScrollable,
    );
    final invocationRow = find.ancestor(
      of: find.text('Last invocation:'),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(of: invocationRow, matching: find.text('Open')),
      findsOneWidget,
    );
  });

  testWidgets('renderer-specific direction controls share the same state', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );

    await invokeDemoControl(tester, label: 'Use RTL', useCupertino: false);

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    await invokeDemoControl(
      tester,
      label: 'Switch to Apple',
      useCupertino: false,
    );
    expect(find.byType(CupertinoPageScaffold), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(CupertinoPageScaffold))),
      TextDirection.rtl,
    );

    await invokeDemoControl(tester, label: 'Use LTR', useCupertino: true);
    expect(
      Directionality.of(tester.element(find.byType(CupertinoPageScaffold))),
      TextDirection.ltr,
    );
  });

  testWidgets(
    'theme control defaults to light and stays shared by both shells',
    (tester) async {
      await tester.pumpWidget(const AdaptiveActionsExampleApp());
      await tester.pumpAndSettle();

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.light,
      );
      await invokeDemoControl(
        tester,
        label: 'Switch to dark theme',
        useCupertino: false,
      );

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark,
      );

      await invokeDemoControl(
        tester,
        label: 'Switch to Apple',
        useCupertino: false,
      );

      expect(
        CupertinoTheme.brightnessOf(
          tester.element(find.byType(CupertinoPageScaffold)),
        ),
        Brightness.dark,
      );
      await invokeDemoControl(
        tester,
        label: 'Switch to light theme',
        useCupertino: true,
      );
      expect(
        CupertinoTheme.brightnessOf(
          tester.element(find.byType(CupertinoPageScaffold)),
        ),
        Brightness.light,
      );

      await invokeDemoControl(
        tester,
        label: 'Switch to Material',
        useCupertino: true,
      );
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.light,
      );
    },
  );

  testWidgets('animation switches configure independent durations', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(previewListKey),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Animation'),
      300,
      scrollable: scrollable,
    );
    await tester.ensureVisible(find.byKey(animationFadeSwitchKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(animationFadeSwitchKey));
    await tester.pump();
    expect(
      tester.widget<SwitchListTile>(find.byKey(animationFadeSwitchKey)).value,
      isFalse,
    );
    expect(
      tester
          .widgetList<MaterialAdaptiveActions<DemoCommand>>(
            find.byType(MaterialAdaptiveActions<DemoCommand>),
          )
          .every(
            (widget) =>
                widget.fadeDuration == Duration.zero &&
                widget.resizeDuration != Duration.zero,
          ),
      isTrue,
    );

    await invokeDemoControl(
      tester,
      label: 'Switch to Apple',
      useCupertino: false,
    );
    await tester.scrollUntilVisible(
      find.text('Animation'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(previewListKey),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(animationResizeSwitchKey)),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<CupertinoAdaptiveActions<DemoCommand>>(
            find.byType(CupertinoAdaptiveActions<DemoCommand>),
          )
          .every(
            (widget) =>
                widget.fadeDuration == Duration.zero &&
                widget.resizeDuration != Duration.zero,
          ),
      isTrue,
    );

    await tester.tap(find.byKey(animationResizeSwitchKey));
    await tester.pump();
    expect(
      tester
          .widget<CupertinoSwitch>(
            find.descendant(
              of: find.byKey(animationEnabledSwitchKey),
              matching: find.byType(CupertinoSwitch),
            ),
          )
          .value,
      isFalse,
    );

    await Scrollable.ensureVisible(
      tester.element(find.byKey(animationEnabledSwitchKey)),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(animationEnabledSwitchKey));
    await tester.pump();
    expect(
      tester
          .widget<CupertinoSwitch>(
            find.descendant(
              of: find.byKey(animationFadeSwitchKey),
              matching: find.byType(CupertinoSwitch),
            ),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<CupertinoSwitch>(
            find.descendant(
              of: find.byKey(animationResizeSwitchKey),
              matching: find.byType(CupertinoSwitch),
            ),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('desktop exposes the shared MenuAnchor verification', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(const AdaptiveActionsExampleApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Desktop MenuAnchor'),
      500,
      scrollable: find
          .descendant(
            of: find.byKey(previewListKey),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Desktop MenuAnchor'), findsOneWidget);
    expect(find.text('Desktop action menu'), findsOneWidget);
    expect(find.byType(MenuAnchor), findsWidgets);

    await invokeDemoControl(
      tester,
      label: 'Switch to Apple',
      useCupertino: false,
    );
    debugDefaultTargetPlatformOverride = null;

    expect(find.text('Desktop MenuAnchor'), findsNothing);
    expect(find.text('Desktop action menu'), findsNothing);
  });
}
