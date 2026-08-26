import 'dart:math' as math;

import 'package:adaptive_actions/cupertino.dart';
import 'package:flutter/cupertino.dart';

import 'demo_settings.dart';

double maximumCupertinoDemoActionWidth(double windowWidth) =>
    math.max(minimumActionWidth, windowWidth - 16);

final class CupertinoDemoPage<T extends Object> extends StatelessWidget {
  const CupertinoDemoPage({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    required this.resolver,
    required this.primaryOrderOverride,
    required this.overflowOrderOverride,
    required this.actionWidth,
    required this.actionHeight,
    required this.maxPrimaryActions,
    required this.presentation,
    required this.actionRegionLayout,
    required this.fadeDuration,
    required this.resizeDuration,
    required this.brightness,
    required this.onInvoke,
    this.customOverflowButton = false,
  });

  final String title;
  final Widget body;
  final ActionCollection<T> actions;
  final ActionLayoutResolver resolver;
  final Iterable<ActionId> primaryOrderOverride;
  final Iterable<ActionId> overflowOrderOverride;
  final double actionWidth;
  final double actionHeight;
  final int? maxPrimaryActions;
  final DemoPresentation presentation;
  final DemoActionRegionLayout actionRegionLayout;
  final Duration fadeDuration;
  final Duration resizeDuration;
  final Brightness brightness;
  final ValueChanged<T> onInvoke;
  final bool customOverflowButton;

  @override
  Widget build(BuildContext context) => CupertinoTheme(
    data: CupertinoThemeData(
      brightness: brightness,
      primaryColor: CupertinoColors.activeBlue,
      scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    ),
    child: Builder(
      builder: (context) => DefaultTextStyle(
        style: CupertinoTheme.of(context).textTheme.textStyle,
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: Text(title)),
          child: Column(
            children: [
              Expanded(child: body),
              _CupertinoDemoActionBar(
                actionRegion: SizedBox(
                  key: appBarActionFrameKey,
                  width: actionWidth,
                  height: actionHeight,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: AlignmentDirectional.centerEnd,
                      minWidth: 0,
                      maxWidth: double.infinity,
                      child: CupertinoDemoActions<T>(
                        key: appBarActionsKey,
                        actions: actions,
                        resolver: resolver,
                        primaryOrderOverride: primaryOrderOverride,
                        overflowOrderOverride: overflowOrderOverride,
                        actionWidth: actionWidth,
                        maxPrimaryActions: maxPrimaryActions,
                        presentation: presentation,
                        actionRegionLayout: actionRegionLayout,
                        fadeDuration: fadeDuration,
                        resizeDuration: resizeDuration,
                        onInvoke: onInvoke,
                        customOverflowButton: customOverflowButton,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class CupertinoDemoActions<T extends Object> extends StatelessWidget {
  const CupertinoDemoActions({
    super.key,
    required this.actions,
    required this.resolver,
    required this.primaryOrderOverride,
    required this.overflowOrderOverride,
    required this.actionWidth,
    required this.maxPrimaryActions,
    required this.presentation,
    required this.actionRegionLayout,
    required this.fadeDuration,
    required this.resizeDuration,
    required this.onInvoke,
    this.customOverflowButton = false,
  });

  final ActionCollection<T> actions;
  final ActionLayoutResolver resolver;
  final Iterable<ActionId> primaryOrderOverride;
  final Iterable<ActionId> overflowOrderOverride;
  final double actionWidth;
  final int? maxPrimaryActions;
  final DemoPresentation presentation;
  final DemoActionRegionLayout actionRegionLayout;
  final Duration fadeDuration;
  final Duration resizeDuration;
  final ValueChanged<T> onInvoke;
  final bool customOverflowButton;

  @override
  Widget build(BuildContext context) {
    final region = CupertinoAdaptiveActions<T>.moreAction(
      actions: actions,
      resolver: resolver,
      primaryOrderOverride: primaryOrderOverride,
      overflowOrderOverride: overflowOrderOverride,
      primaryCapacity: actionWidth,
      maxPrimaryActions: maxPrimaryActions,
      presentationForAction: presentation == DemoPresentation.mixed
          ? _cupertinoMixedPresentationForAction
          : null,
      presentationOverride: _cupertinoPresentationOverride(presentation),
      onInvoke: onInvoke,
      iconBuilder: _cupertinoIconBuilder,
      actionButtonBuilder: _cupertinoActionButtonBuilder,
      overflowButtonBuilder: customOverflowButton
          ? _cupertinoOverflowButtonBuilder
          : null,
      overflowTooltip: 'More actions',
      fadeDuration: fadeDuration,
      resizeDuration: resizeDuration,
      distribution: actionRegionLayout.distribution,
      layoutDelegate: actionRegionLayout.layoutDelegate,
    );
    if (!actionRegionLayout.usesFiniteTarget) return region;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: actionWidth),
      child: region,
    );
  }
}

CupertinoActionPresentation? _cupertinoPresentationOverride(
  DemoPresentation presentation,
) => switch (presentation) {
  DemoPresentation.extended => CupertinoActionPresentation.extended,
  DemoPresentation.iconOnly => CupertinoActionPresentation.iconOnly,
  DemoPresentation.automatic || DemoPresentation.mixed => null,
};

CupertinoActionPresentation? _cupertinoMixedPresentationForAction<
  T extends Object
>(BuildContext context, AdaptiveAction<T> action) => switch (action.id.value) {
  'save' || 'open' || 'delete' => CupertinoActionPresentation.iconOnly,
  'share' || 'help' => CupertinoActionPresentation.extended,
  _ => null,
};

Widget _cupertinoActionButtonBuilder<T extends Object>(
  BuildContext context,
  AdaptiveAction<T> action,
  VoidCallback? onPressed,
  CupertinoActionButtonDefaultBuilder<T> defaultBuilder,
) => switch (action.id.value) {
  'save' => KeyedSubtree(
    key: customSaveButtonKey,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.activeBlue.resolveFrom(context).withAlpha(36),
        borderRadius: BorderRadius.circular(12),
      ),
      child: defaultBuilder(context, action, onPressed),
    ),
  ),
  'open' => KeyedSubtree(
    key: customOpenButtonKey,
    child: Stack(
      children: [
        defaultBuilder(context, action, onPressed),
        PositionedDirectional(
          top: 5,
          end: 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.resolveFrom(context),
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(dimension: 6),
          ),
        ),
      ],
    ),
  ),
  'delete' => KeyedSubtree(
    key: customDeleteButtonKey,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Icon(
        CupertinoIcons.delete_solid,
        color: CupertinoColors.systemRed.resolveFrom(context),
      ),
    ),
  ),
  _ => defaultBuilder(context, action, onPressed),
};

Widget _cupertinoOverflowButtonBuilder(
  BuildContext context,
  VoidCallback onPressed,
  CupertinoOverflowButtonDefaultBuilder defaultBuilder,
) => CupertinoButton.tinted(
  key: customOverflowButtonKey,
  padding: EdgeInsets.zero,
  onPressed: onPressed,
  child: const Icon(CupertinoIcons.square_grid_2x2),
);

final class _CupertinoDemoActionBar extends StatelessWidget {
  const _CupertinoDemoActionBar({required this.actionRegion});

  final Widget actionRegion;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      border: Border(
        top: BorderSide(color: CupertinoColors.separator.resolveFrom(context)),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: actionRegion,
        ),
      ),
    ),
  );
}

Widget? _cupertinoIconBuilder<T extends Object>(
  BuildContext context,
  AdaptiveAction<T> action,
) => switch (action.metadata.iconKey) {
  'save' => const Icon(CupertinoIcons.floppy_disk),
  'open' => const Icon(CupertinoIcons.folder_open),
  'history' => const Icon(CupertinoIcons.clock),
  'browse' => const Icon(CupertinoIcons.folder),
  'share' => const Icon(CupertinoIcons.share),
  'link' => const Icon(CupertinoIcons.link),
  'email' => const Icon(CupertinoIcons.mail),
  'delete' => const Icon(CupertinoIcons.delete),
  'help' => const Icon(CupertinoIcons.question_circle),
  'renderer' => const Icon(CupertinoIcons.device_phone_portrait),
  'theme-dark' => const Icon(CupertinoIcons.moon),
  'theme-light' => const Icon(CupertinoIcons.sun_max),
  'text-direction' => const Icon(CupertinoIcons.textformat),
  _ => null,
};
