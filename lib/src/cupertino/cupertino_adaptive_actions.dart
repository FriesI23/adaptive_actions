import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

import '../../core.dart';
import '../widgets/action_invocation.dart';
import '../widgets/action_region_layout.dart';
import '../widgets/action_region_slot.dart';
import '../widgets/single_action_region_host.dart';
import 'adaptive_cupertino_tooltip.dart';

const _kCupertinoPrimaryDividerWidth = 12.0;

final _cupertinoLabelOptionId = ActionLayoutOptionId('cupertino.label');
final _cupertinoIconOptionId = ActionLayoutOptionId('cupertino.icon');

Icon _cupertinoForwardIcon(TextDirection textDirection) => Icon(
  textDirection == TextDirection.rtl
      ? CupertinoIcons.chevron_back
      : CupertinoIcons.chevron_forward,
);

final class _CupertinoTooltip extends StatelessWidget {
  const _CupertinoTooltip({
    required this.message,
    required this.child,
    this.builder,
    this.visible = true,
  });

  final String message;
  final Widget child;
  final AdaptiveCupertinoTooltipBuilder? builder;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible || message.isEmpty) return child;
    return builder?.call(context, message, child) ??
        AdaptiveCupertinoTooltip(
          message: message,
          excludeFromSemantics: true,
          child: child,
        );
  }
}

final class _CupertinoActionTooltip extends StatelessWidget {
  const _CupertinoActionTooltip({
    required this.metadata,
    required this.surface,
    required this.child,
    this.builder,
  });

  final ActionMetadata metadata;
  final ActionTooltipSurface surface;
  final Widget child;
  final AdaptiveCupertinoTooltipBuilder? builder;

  String _tooltipMessage() => metadata.tooltip ?? metadata.label;

  @override
  Widget build(BuildContext context) => _CupertinoTooltip(
    message: _tooltipMessage(),
    visible: metadata.tooltipPolicy.allows(surface),
    builder: builder,
    child: child,
  );
}

/// Builds the Cupertino icon associated with an adaptive [action].
///
/// Return `null` when the action has no Cupertino icon. The renderer then uses
/// its label-only primary layout option.
///
/// ```dart
/// Widget? buildCupertinoIcon(
///   BuildContext context,
///   AdaptiveAction<String> action,
/// ) => switch (action.metadata.iconKey) {
///   'save' => const Icon(CupertinoIcons.floppy_disk),
///   _ => null,
/// };
/// ```
typedef CupertinoActionIconBuilder<T extends Object> =
    Widget? Function(BuildContext context, AdaptiveAction<T> action);

/// Builds the default Cupertino primary action button.
typedef CupertinoActionButtonDefaultBuilder<T extends Object> =
    Widget Function(
      BuildContext context,
      AdaptiveAction<T> action,
      VoidCallback? onPressed,
    );

/// Overrides a Cupertino primary action button.
///
/// Call [defaultBuilder] with the supplied arguments to retain the platform
/// implementation, or replace them to customize this render only. Replacing
/// [action] does not rerun layout resolution or change the allocated slot.
typedef CupertinoActionButtonBuilder<T extends Object> =
    Widget Function(
      BuildContext context,
      AdaptiveAction<T> action,
      VoidCallback? onPressed,
      CupertinoActionButtonDefaultBuilder<T> defaultBuilder,
    );

/// Builds the complete Cupertino menu content for one adaptive [action].
///
/// Return `null` to use the renderer's default recursive rendering of
/// [AdaptiveAction.children]. A non-null result replaces that complete menu
/// subtree and must not be empty.
typedef CupertinoActionMenuBuilder<T extends Object> =
    List<Widget>? Function(BuildContext context, AdaptiveAction<T> action);

/// Builds the default Cupertino overflow-menu trigger.
///
/// Pass [icon] to override only the trigger icon while retaining the default
/// Cupertino button, focus, semantics, and menu-anchor behavior.
typedef CupertinoOverflowButtonDefaultBuilder =
    Widget Function(
      BuildContext context,
      VoidCallback onPressed, {
      Widget? icon,
    });

/// Overrides the Cupertino overflow-menu trigger.
///
/// The renderer continues to own the menu and supplies its toggle callback.
typedef CupertinoOverflowButtonBuilder =
    Widget Function(
      BuildContext context,
      VoidCallback onPressed,
      CupertinoOverflowButtonDefaultBuilder defaultBuilder,
    );

/// A forced primary-button presentation for [CupertinoAdaptiveActions].
///
/// This only selects between Cupertino-owned layout options. It does not
/// change whether an action is placed in primary, overflow, or hidden.
///
/// ```text
/// automatic:   wide [S Save]  -> narrow [ S ]
/// extended:         [S Save]  ->        [S Save]
/// iconOnly:         [ S ]     ->        [ S ]
/// ```
enum CupertinoActionPresentation {
  /// Shows the action label and, when available, its icon.
  ///
  /// ```text
  /// icon available:      [S Save]
  /// icon unavailable:    [  Save  ]
  /// ```
  extended,

  /// Shows only the action icon.
  ///
  /// An action without an icon falls back to [extended].
  ///
  /// ```text
  /// icon available:      [ S ]
  /// icon unavailable:    [  Save  ]
  /// ```
  iconOnly,
}

/// Selects a Cupertino primary-button presentation for one root [action].
///
/// Return `null` to fall back to
/// [CupertinoAdaptiveActions.presentationOverride] or, when that is also
/// `null`, to automatic layout selection.
typedef CupertinoActionPresentationCallback<T extends Object> =
    CupertinoActionPresentation? Function(
      BuildContext context,
      AdaptiveAction<T> action,
    );

/// Selects the single-line label layout for one Cupertino root action.
typedef CupertinoActionLabelLayoutCallback<T extends Object> =
    ActionLabelLayout Function(BuildContext context, AdaptiveAction<T> action);

/// Visual and layout configuration used by [CupertinoAdaptiveActions].
///
/// These values describe renderer-owned Cupertino geometry. They affect both
/// the widgets and the costs submitted to the core resolver, so the visual
/// layout and placement decision remain consistent.
///
/// ```dart
/// const regular = CupertinoAdaptiveActionsStyle();
/// final compact = regular.copyWith(height: 40, iconSize: 18);
/// ```
final class CupertinoAdaptiveActionsStyle {
  /// Creates a Cupertino adaptive-actions style.
  const CupertinoAdaptiveActionsStyle({
    this.height = 44,
    this.minimumButtonWidth = 44,
    this.iconButtonWidth = 44,
    this.submenuButtonWidth = 28,
    this.overflowButtonWidth = 44,
    this.iconSize = 20,
    this.iconLabelSpacing = 6,
    this.horizontalPadding = 10,
  }) : assert(height > 0 && height < double.infinity),
       assert(minimumButtonWidth >= 0 && minimumButtonWidth < double.infinity),
       assert(iconButtonWidth >= 0 && iconButtonWidth < double.infinity),
       assert(submenuButtonWidth >= 0 && submenuButtonWidth < double.infinity),
       assert(
         overflowButtonWidth >= 0 && overflowButtonWidth < double.infinity,
       ),
       assert(iconSize >= 0 && iconSize < double.infinity),
       assert(iconLabelSpacing >= 0 && iconLabelSpacing < double.infinity),
       assert(horizontalPadding >= 0 && horizontalPadding < double.infinity);

  /// The preferred action region and button height.
  ///
  /// Parent constraints take precedence. A tight 20-pixel-high parent, for
  /// example, makes the complete action region and its controls 20 pixels high
  /// without requiring a second height value on this widget.
  ///
  /// ```text
  /// height: 44    [  Save  ]
  /// height: 56    [        ]
  ///               [  Save  ]
  ///               [        ]
  /// ```
  final double height;

  /// The minimum width of a label-based primary button.
  ///
  /// ```text
  /// minimumButtonWidth: 44    [ OK ]
  /// minimumButtonWidth: 68    [  OK  ]
  /// ```
  final double minimumButtonWidth;

  /// The width reserved for an icon-only primary button.
  ///
  /// ```text
  /// iconButtonWidth: 36    [S]
  /// iconButtonWidth: 52    [ S ]
  /// ```
  final double iconButtonWidth;

  /// The width reserved for a composite action's submenu affordance.
  ///
  /// ```text
  /// submenuButtonWidth: 24    [ Open ][v]
  /// submenuButtonWidth: 36    [ Open ][ v ]
  /// ```
  final double submenuButtonWidth;

  /// The width reserved for the overflow menu trigger.
  ///
  /// This value is also submitted to the core resolver as its overflow trigger
  /// cost, so placement accounts for the trigger before it is rendered.
  ///
  /// ```text
  /// overflowButtonWidth: 36    [...]
  /// overflowButtonWidth: 52    [ ... ]
  /// ```
  final double overflowButtonWidth;

  /// The base Cupertino icon size used by primary buttons.
  ///
  /// The ambient [TextScaler] scales this value before rendering and before
  /// the renderer submits the action's layout cost to Core.
  ///
  /// ```text
  /// iconSize: 16    [ s ]
  /// iconSize: 24    [ S ]
  /// ```
  final double iconSize;

  /// The spacing between an icon and label in an extended button.
  ///
  /// ```text
  /// iconLabelSpacing: 4     [S Save]
  /// iconLabelSpacing: 12    [S   Save]
  /// ```
  final double iconLabelSpacing;

  /// The padding applied to each horizontal side of a label button.
  ///
  /// ```text
  /// horizontalPadding: 6     [ Save ]
  /// horizontalPadding: 14    [   Save   ]
  /// ```
  final double horizontalPadding;

  /// Returns a copy with the supplied fields replaced.
  ///
  /// Unspecified fields retain their current values.
  CupertinoAdaptiveActionsStyle copyWith({
    double? height,
    double? minimumButtonWidth,
    double? iconButtonWidth,
    double? submenuButtonWidth,
    double? overflowButtonWidth,
    double? iconSize,
    double? iconLabelSpacing,
    double? horizontalPadding,
  }) => CupertinoAdaptiveActionsStyle(
    height: height ?? this.height,
    minimumButtonWidth: minimumButtonWidth ?? this.minimumButtonWidth,
    iconButtonWidth: iconButtonWidth ?? this.iconButtonWidth,
    submenuButtonWidth: submenuButtonWidth ?? this.submenuButtonWidth,
    overflowButtonWidth: overflowButtonWidth ?? this.overflowButtonWidth,
    iconSize: iconSize ?? this.iconSize,
    iconLabelSpacing: iconLabelSpacing ?? this.iconLabelSpacing,
    horizontalPadding: horizontalPadding ?? this.horizontalPadding,
  );
}

/// A Cupertino action region backed by [ActionLayoutResolver].
///
/// [primaryCapacity] is the maximum width available to the action region. The
/// host owns that layout policy because a widget context can expose the whole
/// window through `MediaQuery`, but cannot infer how much width a surrounding
/// navigation bar reserves for its leading widget and title. On every build
/// this widget creates Cupertino-owned layout options, resolves the supplied
/// [actions], and draws the ordered primary and overflow result without
/// changing the action collection. Declared children use one recursive
/// Cupertino anchored-menu renderer, while [menuBuilderForAction] can replace
/// one action's complete menu subtree with caller-owned content.
///
/// Layout changes animate one boundary action instead of replacing the whole
/// row. Stable actions remain visible while the changing slot fades and
/// expands or contracts. When one result changes several actions, earlier
/// changes complete immediately and only the final boundary action animates.
/// The region therefore retains at most one outgoing and one incoming child
/// while rapid capacity updates never accumulate outgoing rows.
///
/// The following example places one adaptive action directly in a
/// [CupertinoNavigationBar]:
///
/// ```dart
/// final save = AdaptiveAction<String>.action(
///   id: ActionId('save'),
///   metadata: const ActionMetadata(
///     label: 'Save',
///     tooltip: 'Save document',
///     iconKey: 'save',
///   ),
///   payload: 'save-document',
/// );
///
/// final page = CupertinoPageScaffold(
///   navigationBar: CupertinoNavigationBar(
///     middle: const Text('Document'),
///     trailing: CupertinoAdaptiveActions<String>.moreAction(
///       actions: ActionCollection(roots: [save]),
///       primaryCapacity: 140,
///       onInvoke: (command) => handleCommand(command),
///       iconBuilder: (context, action) => switch (action.metadata.iconKey) {
///         'save' => const Icon(CupertinoIcons.floppy_disk),
///         _ => null,
///       },
///     ),
///   ),
///   child: const SizedBox(),
/// );
/// ```
final class CupertinoAdaptiveActions<T extends Object> extends StatelessWidget {
  /// Creates a generic Cupertino action region.
  ///
  /// The host must provide [overflowIcon]. Use
  /// [CupertinoAdaptiveActions.moreAction] for the conventional Cupertino More
  /// icon.
  const CupertinoAdaptiveActions({
    super.key,
    required this.actions,
    required this.onInvoke,
    required this.primaryCapacity,
    this.primaryOrderOverride = const [],
    this.overflowOrderOverride = const [],
    this.resolver = const ActionLayoutResolver(),
    this.maxPrimaryActions,
    this.iconBuilder,
    this.actionButtonBuilder,
    this.menuBuilderForAction,
    this.overflowButtonBuilder,
    this.tooltipBuilder,
    this.onOverflowMenuOpened,
    this.onOverflowMenuClosed,
    this.invokeAfterMenuClosed = false,
    required this.overflowIcon,
    this.overflowTooltip = '',
    this.presentationForAction,
    this.labelLayoutForAction,
    this.presentationOverride,
    this.style = const CupertinoAdaptiveActionsStyle(),
    this.fadeDuration = const Duration(milliseconds: 200),
    this.resizeDuration = const Duration(milliseconds: 200),
    this.switchInCurve = Curves.easeOut,
    this.switchOutCurve = Curves.easeIn,
    this.distribution = ActionRegionMainAxisDistribution.compact,
    this.layoutDelegate,
  }) : assert(primaryCapacity >= 0 && primaryCapacity < double.infinity),
       assert(
         layoutDelegate == null ||
             distribution == ActionRegionMainAxisDistribution.compact,
       );

  /// Creates a Cupertino action region with the conventional More icon.
  ///
  /// [overflowTooltip] defaults to "More actions" and can be replaced with a
  /// localized description by the host.
  const CupertinoAdaptiveActions.moreAction({
    super.key,
    required this.actions,
    required this.onInvoke,
    required this.primaryCapacity,
    this.primaryOrderOverride = const [],
    this.overflowOrderOverride = const [],
    this.resolver = const ActionLayoutResolver(),
    this.maxPrimaryActions,
    this.iconBuilder,
    this.actionButtonBuilder,
    this.menuBuilderForAction,
    this.overflowButtonBuilder,
    this.tooltipBuilder,
    this.onOverflowMenuOpened,
    this.onOverflowMenuClosed,
    this.invokeAfterMenuClosed = false,
    this.presentationForAction,
    this.labelLayoutForAction,
    this.presentationOverride,
    this.style = const CupertinoAdaptiveActionsStyle(),
    this.overflowIcon = const Icon(CupertinoIcons.ellipsis),
    this.overflowTooltip = 'More actions',
    this.fadeDuration = const Duration(milliseconds: 200),
    this.resizeDuration = const Duration(milliseconds: 200),
    this.switchInCurve = Curves.easeOut,
    this.switchOutCurve = Curves.easeIn,
    this.distribution = ActionRegionMainAxisDistribution.compact,
    this.layoutDelegate,
  }) : assert(primaryCapacity >= 0 && primaryCapacity < double.infinity),
       assert(
         layoutDelegate == null ||
             distribution == ActionRegionMainAxisDistribution.compact,
       );

  /// The action roots and placement constraints to resolve.
  ///
  /// ```text
  /// actions: [Save, Search, More]
  ///                         |
  ///                         v
  /// primary: [Save] [Search] [More v]
  /// ```
  final ActionCollection<T> actions;

  /// Receives the payload of an enabled action after the user invokes it.
  ///
  /// ```text
  /// user taps [Save] -> onInvoke('save-document') -> host business logic
  /// ```
  final ValueChanged<T> onInvoke;

  /// The finite, non-negative width available to the primary action region.
  ///
  /// A window-level host can derive this from `MediaQuery.sizeOf(context)`, but
  /// should reserve space for adjacent navigation-bar content. This value is a
  /// layout decision input, not a clipping or scrolling constraint. If hard
  /// placement produces a wider result, the caller owns the surrounding
  /// overflow policy.
  ///
  /// ```text
  /// primaryCapacity: 200    [Save] [Search]
  /// primaryCapacity: 88     [ S ]  [ ? ]
  /// pinned over capacity:   [Pinned] ---> caller-owned boundary
  /// ```
  final double primaryCapacity;

  /// Region-local primary ordering applied by the core resolver.
  ///
  /// ```text
  /// primary:             [Save] [Search] [Share]
  /// override:            [Share, Save]
  /// rendered primary:    [Share] [Search] [Save]
  /// ```
  final Iterable<ActionId> primaryOrderOverride;

  /// Region-local overflow ordering applied by the core resolver.
  ///
  /// ```text
  /// overflow:             [Cut] [Copy] [Delete]
  /// override:             [Delete, Cut]
  /// resolved overflow:    [Delete] [Copy] [Cut]
  /// ```
  final Iterable<ActionId> overflowOrderOverride;

  /// The layout resolver used with Cupertino-owned constraints.
  final ActionLayoutResolver resolver;

  /// The optional maximum number of root actions shown in primary.
  ///
  /// ```text
  /// maxPrimaryActions: 3    [Save] [Search] [Share]
  /// maxPrimaryActions: 2    [Save] [Search] [overflow]
  /// ```
  final int? maxPrimaryActions;

  /// Resolves platform-specific icons from platform-neutral metadata.
  ///
  /// ```text
  /// iconBuilder returns null:                       [ Save ]
  /// iconBuilder returns CupertinoIcons.floppy_disk: [S Save] -> narrow -> [ S ]
  /// ```
  final CupertinoActionIconBuilder<T>? iconBuilder;

  /// Overrides leaf actions, primary menu triggers, and composite invoke
  /// buttons while preserving the renderer-owned slot constraints.
  final CupertinoActionButtonBuilder<T>? actionButtonBuilder;

  /// Optionally replaces the complete menu content of each menu action.
  ///
  /// Returning `null` retains the default recursive rendering of the action's
  /// [AdaptiveAction.children]. The builder owns state, callbacks, nested
  /// content, and item close behavior for every non-null result.
  final CupertinoActionMenuBuilder<T>? menuBuilderForAction;

  /// Overrides the overflow trigger without replacing its anchored menu.
  final CupertinoOverflowButtonBuilder? overflowButtonBuilder;

  /// Overrides the visual tooltip wrapper used by this renderer.
  ///
  /// When null, [AdaptiveCupertinoTooltip] provides the Cupertino appearance.
  /// Visibility, resolved action text, and accessibility semantics remain
  /// renderer-owned.
  final AdaptiveCupertinoTooltipBuilder? tooltipBuilder;

  /// Called when the overflow menu begins opening.
  final VoidCallback? onOverflowMenuOpened;

  /// Called after the overflow menu finishes closing.
  final VoidCallback? onOverflowMenuClosed;

  /// Whether menu actions wait for the root menu to finish closing before
  /// invoking their payload.
  ///
  /// When false, menu actions are invoked after the close request at the next
  /// post-frame boundary. When true, they are invoked one post-frame after the
  /// root menu's [CupertinoMenuAnchor.onClose] callback. Menu actions are never
  /// invoked synchronously. Primary toolbar actions are unaffected.
  final bool invokeAfterMenuClosed;

  /// Selects a primary-button presentation independently for each root action.
  ///
  /// A non-null result overrides [presentationOverride] for that action. A
  /// `null` result falls back to [presentationOverride], then to automatic
  /// layout selection when the global override is also `null`.
  final CupertinoActionPresentationCallback<T>? presentationForAction;

  /// Selects an independent label width and overflow policy for each action.
  ///
  /// Actions for which this callback is absent use an unconstrained,
  /// single-line label.
  final CupertinoActionLabelLayoutCallback<T>? labelLayoutForAction;

  /// Forces one Cupertino primary presentation for every root action.
  ///
  /// When `null`, the resolver automatically selects extended or icon-only
  /// layouts from the available width. [CupertinoActionPresentation.iconOnly]
  /// falls back to the extended layout for actions whose [iconBuilder] result
  /// is `null`.
  final CupertinoActionPresentation? presentationOverride;

  /// The built-in horizontal distribution for this single action region.
  final ActionRegionMainAxisDistribution distribution;

  /// An optional advanced layout policy for fixed and flexible slots or gaps.
  ///
  /// When supplied, [distribution] must remain
  /// [ActionRegionMainAxisDistribution.compact].
  final ActionRegionLayoutDelegate? layoutDelegate;

  /// Renderer-owned Cupertino visual and layout configuration.
  ///
  /// ```text
  /// default style:                 [S Save]
  /// style.copyWith(height: 56):    [      ]
  ///                                [S Save]
  ///                                [      ]
  /// ```
  final CupertinoAdaptiveActionsStyle style;

  /// The icon reserved for the overflow trigger.
  ///
  /// ```text
  /// overflowIcon: CupertinoIcons.ellipsis          [...]
  /// overflowIcon: CupertinoIcons.ellipsis_circle   [(...)]
  /// ```
  final Widget overflowIcon;

  /// Accessibility description for the overflow trigger.
  ///
  /// ```text
  /// overflowTooltip: localizedMoreActions -> [...] -> localized description
  /// ```
  final String overflowTooltip;

  /// The duration of action and label visibility animations.
  ///
  /// Use [Duration.zero] to switch changing content immediately while keeping
  /// the independently configured [resizeDuration].
  ///
  /// ```text
  /// fadeDuration: 200ms    [Save] --fade--> [S]
  /// fadeDuration: zero     [Save] ---------> [S]
  /// ```
  final Duration fadeDuration;

  /// The duration of boundary width expansion and contraction.
  ///
  /// Use [Duration.zero] to remove width interpolation. During a fade-only
  /// removal, the old boundary is retained until the fade completes and then
  /// snaps to its final width so the outgoing action remains visible.
  ///
  /// ```text
  /// resizeDuration: 200ms    [Save] --shrink--> [S]
  /// resizeDuration: zero     [Save] ----------> [S]
  /// ```
  final Duration resizeDuration;

  /// The curve used while a boundary action or label appears and expands.
  ///
  /// ```text
  /// switchInCurve: easeOut    new layout:  . .. ... [S]
  /// ```
  final Curve switchInCurve;

  /// The curve used while a boundary action or label disappears and contracts.
  ///
  /// ```text
  /// switchOutCurve: easeIn    old layout: [Save] ... .. .
  /// ```
  final Curve switchOutCurve;

  @override
  Widget build(BuildContext context) {
    return SingleActionRegionHost<_CupertinoRegionSlot<T>>(
      primaryCapacity: primaryCapacity,
      actionIds: actions.roots.map((action) => action.id),
      distribution: distribution,
      layoutDelegate: layoutDelegate,
      snapshotBuilder: (context, constraints, effectiveCapacity) {
        final visuals = _buildVisuals(context);
        final result = resolver.resolve(
          ActionLayoutRequest(
            actions: actions,
            constraints: ActionLayoutConstraints(
              primaryCapacity: effectiveCapacity,
              maxPrimaryActions: maxPrimaryActions,
              overflowTriggerCost: style.overflowButtonWidth,
              profiles: visuals.values.map((visual) => visual.profile),
            ),
            capabilities: const RendererCapabilities(),
            primaryOrderOverride: primaryOrderOverride,
            overflowOrderOverride: overflowOrderOverride,
          ),
        );
        final data = _CupertinoRegionData<T>(
          primaryEntries: result.primary,
          overflowEntries: result.overflow,
          primaryDividerBeforeActionIds: result.primaryDividerBeforeActionIds,
          overflowDividerBeforeActionIds: result.overflowDividerBeforeActionIds,
          visuals: visuals,
          onInvoke: onInvoke,
          iconBuilder: iconBuilder,
          actionButtonBuilder: actionButtonBuilder,
          menuBuilderForAction: menuBuilderForAction,
          overflowButtonBuilder: overflowButtonBuilder,
          tooltipBuilder: tooltipBuilder,
          onOverflowMenuOpened: onOverflowMenuOpened,
          onOverflowMenuClosed: onOverflowMenuClosed,
          invokeAfterMenuClosed: invokeAfterMenuClosed,
          style: style,
          overflowIcon: overflowIcon,
          overflowTooltip: overflowTooltip,
        );
        return SingleActionRegionSnapshot(slots: data.slots);
      },
      height: style.height,
      fadeDuration: fadeDuration,
      resizeDuration: resizeDuration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      variantBuilder: (context, from, to, fadeProgress, resizeProgress) {
        final fromSlot = from.data;
        final toSlot = to.data;
        if (fromSlot is! _CupertinoPrimarySlot<T> ||
            toSlot is! _CupertinoPrimarySlot<T>) {
          return to.child;
        }
        return _CupertinoRegionSlotView<T>(
          slot: toSlot,
          optionTransition: _CupertinoOptionTransition(
            from: fromSlot.entry.optionId,
            to: toSlot.entry.optionId,
            fadeProgress: fadeProgress,
            resizeProgress: resizeProgress,
          ),
        );
      },
    );
  }

  Map<ActionId, _CupertinoActionVisual<T>> _buildVisuals(BuildContext context) {
    final visuals = <ActionId, _CupertinoActionVisual<T>>{};
    for (final action in actions.roots) {
      final labelLayout =
          labelLayoutForAction?.call(context, action) ??
          const ActionLabelLayout();
      visuals[action.id] = _CupertinoActionVisual<T>(
        action: action,
        icon: iconBuilder?.call(context, action),
        labelLayout: labelLayout,
        labelWidth: _labelWidth(context, action.metadata.label, labelLayout),
        iconSize: style.iconSize,
        presentationOverride:
            presentationForAction?.call(context, action) ??
            presentationOverride,
        style: style,
      );
    }
    return visuals;
  }

  double _labelWidth(
    BuildContext context,
    String label,
    ActionLabelLayout labelLayout,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: CupertinoTheme.of(context).textTheme.actionTextStyle,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
      ellipsis: labelLayout.overflow == TextOverflow.ellipsis ? '\u2026' : null,
    )..layout(maxWidth: labelLayout.maxWidth ?? double.infinity);
    return painter.width;
  }
}

final class _CupertinoRegionData<T extends Object> {
  const _CupertinoRegionData({
    required this.primaryEntries,
    required this.overflowEntries,
    required this.primaryDividerBeforeActionIds,
    required this.overflowDividerBeforeActionIds,
    required this.visuals,
    required this.onInvoke,
    required this.iconBuilder,
    required this.actionButtonBuilder,
    required this.menuBuilderForAction,
    required this.overflowButtonBuilder,
    required this.tooltipBuilder,
    required this.onOverflowMenuOpened,
    required this.onOverflowMenuClosed,
    required this.invokeAfterMenuClosed,
    required this.style,
    required this.overflowIcon,
    required this.overflowTooltip,
  });

  final List<ResolvedPrimaryAction<T>> primaryEntries;
  final List<AdaptiveAction<T>> overflowEntries;
  final List<ActionId> primaryDividerBeforeActionIds;
  final List<ActionId> overflowDividerBeforeActionIds;
  final Map<ActionId, _CupertinoActionVisual<T>> visuals;
  final ValueChanged<T> onInvoke;
  final CupertinoActionIconBuilder<T>? iconBuilder;
  final CupertinoActionButtonBuilder<T>? actionButtonBuilder;
  final CupertinoActionMenuBuilder<T>? menuBuilderForAction;
  final CupertinoOverflowButtonBuilder? overflowButtonBuilder;
  final AdaptiveCupertinoTooltipBuilder? tooltipBuilder;
  final VoidCallback? onOverflowMenuOpened;
  final VoidCallback? onOverflowMenuClosed;
  final bool invokeAfterMenuClosed;
  final CupertinoAdaptiveActionsStyle style;
  final Widget overflowIcon;
  final String overflowTooltip;

  List<ActionRegionSlot<_CupertinoRegionSlot<T>>> get slots => [
    for (final entry in primaryEntries) _primaryItem(entry),
    if (overflowEntries.isNotEmpty) _overflowItem(),
  ];

  ActionRegionSlot<_CupertinoRegionSlot<T>> _primaryItem(
    ResolvedPrimaryAction<T> entry,
  ) {
    final slot = _CupertinoPrimarySlot<T>(data: this, entry: entry);
    return ActionRegionSlot<_CupertinoRegionSlot<T>>(
      id: ('cupertino-primary', entry.action.id),
      layoutId: ActionRegionLayoutSlotId.action(entry.action.id),
      variant: ('cupertino-option', entry.optionId),
      role: ActionRegionSlotRole.action,
      minimumExtent: slot.width,
      data: slot,
      child: _CupertinoRegionSlotView<T>(slot: slot),
    );
  }

  ActionRegionSlot<_CupertinoRegionSlot<T>> _overflowItem() {
    final slot = _CupertinoOverflowSlot<T>(data: this);
    return ActionRegionSlot<_CupertinoRegionSlot<T>>(
      id: 'cupertino-overflow',
      layoutId: const ActionRegionLayoutSlotId.overflow(),
      variant: 'cupertino-overflow-trigger',
      role: ActionRegionSlotRole.overflow,
      minimumExtent: slot.width,
      data: slot,
      child: _CupertinoRegionSlotView<T>(slot: slot),
    );
  }
}

/// Renderer-owned data for one animated Cupertino action-region slot.
sealed class _CupertinoRegionSlot<T extends Object> {
  const _CupertinoRegionSlot({required this.data});

  final _CupertinoRegionData<T> data;
  double get width;
}

final class _CupertinoPrimarySlot<T extends Object>
    extends _CupertinoRegionSlot<T> {
  const _CupertinoPrimarySlot({required super.data, required this.entry});

  final ResolvedPrimaryAction<T> entry;

  bool get showDividerBefore =>
      data.primaryDividerBeforeActionIds.contains(entry.action.id);

  double get actionWidth =>
      data.visuals[entry.action.id]!.costFor(entry.optionId);

  @override
  double get width =>
      actionWidth + (showDividerBefore ? _kCupertinoPrimaryDividerWidth : 0);
}

final class _CupertinoOverflowSlot<T extends Object>
    extends _CupertinoRegionSlot<T> {
  const _CupertinoOverflowSlot({required super.data});

  @override
  double get width => data.style.overflowButtonWidth;
}

final class _CupertinoOptionTransition {
  const _CupertinoOptionTransition({
    required this.from,
    required this.to,
    required this.fadeProgress,
    required this.resizeProgress,
  });

  final ActionLayoutOptionId from;
  final ActionLayoutOptionId to;
  final Animation<double> fadeProgress;
  final Animation<double> resizeProgress;
}

/// Builds the Cupertino widget represented by one region [slot].
final class _CupertinoRegionSlotView<T extends Object> extends StatelessWidget {
  const _CupertinoRegionSlotView({required this.slot, this.optionTransition});

  final _CupertinoRegionSlot<T> slot;
  final _CupertinoOptionTransition? optionTransition;

  @override
  Widget build(BuildContext context) {
    final slot = this.slot;
    if (slot is _CupertinoOverflowSlot<T>) {
      final data = slot.data;
      return _CupertinoOverflowAction<T>(
        entries: data.overflowEntries,
        dividerBeforeActionIds: data.overflowDividerBeforeActionIds,
        onInvoke: data.onInvoke,
        iconBuilder: data.iconBuilder,
        menuBuilderForAction: data.menuBuilderForAction,
        overflowButtonBuilder: data.overflowButtonBuilder,
        tooltipBuilder: data.tooltipBuilder,
        onMenuOpened: data.onOverflowMenuOpened,
        onMenuClosed: data.onOverflowMenuClosed,
        invokeAfterMenuClosed: data.invokeAfterMenuClosed,
        style: data.style,
        icon: data.overflowIcon,
        tooltip: data.overflowTooltip,
      );
    }
    final primarySlot = slot as _CupertinoPrimarySlot<T>;
    final data = primarySlot.data;
    final entry = primarySlot.entry;
    final action = entry.action;
    final visual = data.visuals[action.id]!;
    final primaryAction = Semantics(
      label: action.metadata.semanticLabel ?? action.metadata.label,
      tooltip: action.metadata.tooltip,
      button: true,
      enabled: action.isEnabled,
      child: switch (action) {
        _ when !action.hasMenu => _CustomizableCupertinoActionButton<T>(
          action: action,
          visual: visual,
          optionId: entry.optionId,
          width: primarySlot.actionWidth,
          onPressed: action.isEnabled
              ? () => invokeAdaptiveAction(action, data.onInvoke)
              : null,
          builder: data.actionButtonBuilder,
          tooltipBuilder: data.tooltipBuilder,
          style: data.style,
          optionTransition: optionTransition,
        ),
        _ when action.payload == null => _CupertinoActionMenuAnchor<T>(
          entries: action.children,
          menuAction: action,
          onInvoke: data.onInvoke,
          iconBuilder: data.iconBuilder,
          menuBuilderForAction: data.menuBuilderForAction,
          tooltipBuilder: data.tooltipBuilder,
          invokeAfterMenuClosed: data.invokeAfterMenuClosed,
          triggerBuilder: (context, toggle, focusNode) =>
              _CupertinoMenuTriggerFocusHalo(
                child: _CustomizableCupertinoActionButton<T>(
                  action: action,
                  visual: visual,
                  optionId: entry.optionId,
                  width: primarySlot.actionWidth,
                  onPressed: action.isEnabled ? toggle : null,
                  builder: data.actionButtonBuilder,
                  tooltipBuilder: data.tooltipBuilder,
                  style: data.style,
                  focusColor: CupertinoColors.transparent,
                  focusNode: focusNode,
                  optionTransition: optionTransition,
                ),
              ),
        ),
        _ => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CustomizableCupertinoActionButton<T>(
              action: action,
              visual: visual,
              optionId: entry.optionId,
              width: primarySlot.actionWidth - data.style.submenuButtonWidth,
              onPressed: action.isEnabled
                  ? () => invokeAdaptiveAction(action, data.onInvoke)
                  : null,
              builder: data.actionButtonBuilder,
              tooltipBuilder: data.tooltipBuilder,
              style: data.style,
              optionTransition: optionTransition,
            ),
            _CupertinoActionMenuAnchor<T>(
              entries: action.children,
              menuAction: action,
              includeActionInvocation: true,
              onInvoke: data.onInvoke,
              iconBuilder: data.iconBuilder,
              menuBuilderForAction: data.menuBuilderForAction,
              tooltipBuilder: data.tooltipBuilder,
              invokeAfterMenuClosed: data.invokeAfterMenuClosed,
              triggerBuilder: (context, toggle, focusNode) => Semantics(
                label:
                    action.metadata.semanticLabel ??
                    action.metadata.tooltip ??
                    action.metadata.label,
                button: true,
                enabled: action.isEnabled,
                child: SizedBox(
                  width: data.style.submenuButtonWidth,
                  height: data.style.height,
                  child: _CupertinoMenuTriggerFocusHalo(
                    child: _CupertinoActionTooltip(
                      metadata: action.metadata,
                      surface: ActionTooltipSurface.primaryIconOnly,
                      builder: data.tooltipBuilder,
                      child: CupertinoButton(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        focusColor: CupertinoColors.transparent,
                        focusNode: focusNode,
                        onPressed: action.isEnabled ? toggle : null,
                        child: Icon(
                          CupertinoIcons.chevron_down,
                          size: data.style.iconSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      },
    );
    if (!primarySlot.showDividerBefore) return primaryAction;
    final pixelWidth = 1 / MediaQuery.devicePixelRatioOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _kCupertinoPrimaryDividerWidth,
          height: data.style.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: ColoredBox(
                color: CupertinoColors.separator.resolveFrom(context),
                child: SizedBox(width: pixelWidth, height: double.infinity),
              ),
            ),
          ),
        ),
        primaryAction,
      ],
    );
  }
}

final class _CustomizableCupertinoActionButton<T extends Object>
    extends StatelessWidget {
  const _CustomizableCupertinoActionButton({
    required this.action,
    required this.visual,
    required this.optionId,
    required this.width,
    required this.onPressed,
    required this.builder,
    required this.tooltipBuilder,
    required this.style,
    this.focusColor,
    this.focusNode,
    this.optionTransition,
  });

  final AdaptiveAction<T> action;
  final _CupertinoActionVisual<T> visual;
  final ActionLayoutOptionId optionId;
  final double width;
  final VoidCallback? onPressed;
  final CupertinoActionButtonBuilder<T>? builder;
  final AdaptiveCupertinoTooltipBuilder? tooltipBuilder;
  final CupertinoAdaptiveActionsStyle style;
  final Color? focusColor;
  final FocusNode? focusNode;
  final _CupertinoOptionTransition? optionTransition;

  @override
  Widget build(BuildContext context) {
    Widget defaultBuilder(
      BuildContext context,
      AdaptiveAction<T> action,
      VoidCallback? onPressed,
    ) => _CupertinoActionButton<T>(
      action: action,
      visual: visual,
      optionId: optionId,
      width: width,
      onPressed: onPressed,
      style: style,
      focusColor: focusColor,
      focusNode: focusNode,
      optionTransition: optionTransition,
    );

    final button =
        builder?.call(context, action, onPressed, defaultBuilder) ??
        defaultBuilder(context, action, onPressed);
    final targetOptionId = optionTransition?.to ?? optionId;
    return _CupertinoActionTooltip(
      metadata: action.metadata,
      surface: targetOptionId == _cupertinoIconOptionId
          ? ActionTooltipSurface.primaryIconOnly
          : ActionTooltipSurface.primaryLabeled,
      builder: tooltipBuilder,
      child: button,
    );
  }
}

final class _CupertinoActionButton<T extends Object> extends StatelessWidget {
  const _CupertinoActionButton({
    required this.action,
    required this.visual,
    required this.optionId,
    required this.width,
    required this.onPressed,
    required this.style,
    this.focusColor,
    this.focusNode,
    this.optionTransition,
  });

  final AdaptiveAction<T> action;
  final _CupertinoActionVisual<T> visual;
  final ActionLayoutOptionId optionId;
  final double width;
  final VoidCallback? onPressed;
  final CupertinoAdaptiveActionsStyle style;
  final Color? focusColor;
  final FocusNode? focusNode;
  final _CupertinoOptionTransition? optionTransition;

  @override
  Widget build(BuildContext context) {
    if (optionId != _cupertinoLabelOptionId &&
        optionId != _cupertinoIconOptionId) {
      throw StateError(
        'No Cupertino layout is registered for option $optionId on action '
        '${action.id}.',
      );
    }
    final transition = optionTransition;
    if (transition != null && visual.icon != null) {
      return _AnimatedCupertinoActionButton<T>(
        action: action,
        visual: visual,
        onPressed: onPressed,
        style: style,
        transition: transition,
        focusColor: focusColor,
        focusNode: focusNode,
      );
    }
    return SizedBox(
      width: width,
      height: style.height,
      child: CupertinoButton(
        minimumSize: Size.zero,
        padding: EdgeInsets.symmetric(horizontal: style.horizontalPadding),
        focusColor: focusColor,
        focusNode: focusNode,
        foregroundColor: action.metadata.isDestructive
            ? CupertinoDynamicColor.resolve(CupertinoColors.systemRed, context)
            : null,
        onPressed: action.isEnabled ? onPressed : null,
        child: optionId == _cupertinoIconOptionId
            ? IconTheme.merge(
                data: IconThemeData(size: visual.iconSize),
                child: visual.icon!,
              )
            : _CupertinoExtendedContent<T>(
                action: action,
                icon: visual.icon,
                iconSize: visual.iconSize,
                labelLayout: visual.labelLayout,
                style: style,
              ),
      ),
    );
  }
}

final class _AnimatedCupertinoActionButton<T extends Object>
    extends StatelessWidget {
  const _AnimatedCupertinoActionButton({
    required this.action,
    required this.visual,
    required this.onPressed,
    required this.style,
    required this.transition,
    this.focusColor,
    this.focusNode,
  });

  final AdaptiveAction<T> action;
  final _CupertinoActionVisual<T> visual;
  final VoidCallback? onPressed;
  final CupertinoAdaptiveActionsStyle style;
  final _CupertinoOptionTransition transition;
  final Color? focusColor;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      transition.fadeProgress,
      transition.resizeProgress,
    ]),
    builder: (context, child) {
      final fromWidth = _invokeWidth(transition.from);
      final toWidth = _invokeWidth(transition.to);
      final width =
          fromWidth + (toWidth - fromWidth) * transition.resizeProgress.value;
      final targetHasLabel = transition.to == _cupertinoLabelOptionId;
      final labelProgress = targetHasLabel
          ? transition.fadeProgress.value
          : 1 - transition.fadeProgress.value;
      return SizedBox(
        width: width,
        height: style.height,
        child: CupertinoButton(
          minimumSize: Size.zero,
          padding: EdgeInsets.symmetric(horizontal: style.horizontalPadding),
          focusColor: focusColor,
          focusNode: focusNode,
          foregroundColor: action.metadata.isDestructive
              ? CupertinoDynamicColor.resolve(
                  CupertinoColors.systemRed,
                  context,
                )
              : null,
          onPressed: action.isEnabled ? onPressed : null,
          child: ClipRect(
            child: OverflowBox(
              maxWidth: double.infinity,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme.merge(
                    data: IconThemeData(size: visual.iconSize),
                    child: visual.icon!,
                  ),
                  ClipRect(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: labelProgress,
                      child: Opacity(
                        opacity: labelProgress,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: style.iconLabelSpacing,
                          ),
                          child: _CupertinoPrimaryLabel(
                            label: action.metadata.label,
                            layout: visual.labelLayout,
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
    },
  );

  double _invokeWidth(ActionLayoutOptionId optionId) {
    final total = visual.costFor(optionId);
    final isComposite = action.payload != null && action.hasMenu;
    return isComposite ? total - style.submenuButtonWidth : total;
  }
}

final class _CupertinoExtendedContent<T extends Object>
    extends StatelessWidget {
  const _CupertinoExtendedContent({
    required this.action,
    required this.icon,
    required this.iconSize,
    required this.labelLayout,
    required this.style,
  });

  final AdaptiveAction<T> action;
  final Widget? icon;
  final double iconSize;
  final ActionLabelLayout labelLayout;
  final CupertinoAdaptiveActionsStyle style;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    if (icon == null) {
      return _CupertinoPrimaryLabel(
        label: action.metadata.label,
        layout: labelLayout,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTheme.merge(
          data: IconThemeData(size: iconSize),
          child: icon,
        ),
        SizedBox(width: style.iconLabelSpacing),
        _CupertinoPrimaryLabel(
          label: action.metadata.label,
          layout: labelLayout,
        ),
      ],
    );
  }
}

final class _CupertinoPrimaryLabel extends StatelessWidget {
  const _CupertinoPrimaryLabel({required this.label, required this.layout});

  final String label;
  final ActionLabelLayout layout;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: layout.maxWidth == null ? null : layout.overflow,
    );
    final labelMaxWidth = layout.maxWidth;
    return labelMaxWidth == null
        ? text
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: labelMaxWidth),
            child: text,
          );
  }
}

typedef _CupertinoMenuTriggerBuilder =
    Widget Function(
      BuildContext context,
      VoidCallback toggle,
      FocusNode focusNode,
    );

final class _CupertinoMenuTriggerFocusHalo extends StatelessWidget {
  const _CupertinoMenuTriggerFocusHalo({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CupertinoFocusHalo.withRoundedSuperellipse(
        borderRadius:
            kCupertinoButtonSizeBorderRadius[CupertinoButtonSize.large]!,
        child: child,
      );
}

final class _CupertinoActionMenuAnchor<T extends Object>
    extends StatefulWidget {
  const _CupertinoActionMenuAnchor({
    required this.entries,
    required this.onInvoke,
    required this.iconBuilder,
    required this.menuBuilderForAction,
    required this.tooltipBuilder,
    required this.invokeAfterMenuClosed,
    required this.triggerBuilder,
    this.menuAction,
    this.includeActionInvocation = false,
    this.onMenuOpened,
    this.onMenuClosed,
  });

  final List<AdaptiveMenuEntry<T>> entries;
  final ValueChanged<T> onInvoke;
  final CupertinoActionIconBuilder<T>? iconBuilder;
  final CupertinoActionMenuBuilder<T>? menuBuilderForAction;
  final AdaptiveCupertinoTooltipBuilder? tooltipBuilder;
  final bool invokeAfterMenuClosed;
  final _CupertinoMenuTriggerBuilder triggerBuilder;
  final AdaptiveAction<T>? menuAction;
  final bool includeActionInvocation;
  final VoidCallback? onMenuOpened;
  final VoidCallback? onMenuClosed;

  @override
  State<_CupertinoActionMenuAnchor<T>> createState() =>
      _CupertinoActionMenuAnchorState<T>();
}

final class _CupertinoActionMenuAnchorState<T extends Object>
    extends State<_CupertinoActionMenuAnchor<T>> {
  final _controller = MenuController();
  final _focusNode = FocusNode(debugLabel: 'Cupertino menu trigger');
  bool _pointerActivationPending = false;
  bool _openedWithKeyboard = false;
  bool _closing = false;
  bool _reopenAfterClose = false;
  bool _closeRequestedForInvocation = false;
  ({T payload, ValueChanged<T> callback})? _pendingInvocation;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_closing) {
      if (_closeRequestedForInvocation) return;
      _reopenAfterClose = !_reopenAfterClose;
      return;
    }
    if (_controller.isOpen) {
      _closing = true;
      _controller.close();
      return;
    }

    final opensWithKeyboard = !_pointerActivationPending && _focusNode.hasFocus;
    _openedWithKeyboard = opensWithKeyboard;
    _pointerActivationPending = false;
    if (!opensWithKeyboard) {
      _focusNode.unfocus();
    }
    _controller.open();
  }

  void _closeMenu() {
    _reopenAfterClose = false;
    if (!_controller.isOpen) return;
    _closing = true;
    _controller.close();
  }

  void _requestMenuInvocation(T payload) {
    if (_closeRequestedForInvocation) return;
    _closeRequestedForInvocation = true;
    _pendingInvocation = (payload: payload, callback: widget.onInvoke);
    _reopenAfterClose = false;
    _closeMenu();
    if (!widget.invokeAfterMenuClosed) {
      _schedulePendingInvocation(
        debugLabel: 'CupertinoAdaptiveActions.invokeNextFrame',
      );
    }
  }

  void _schedulePendingInvocation({required String debugLabel}) {
    final pendingInvocation = _pendingInvocation;
    _pendingInvocation = null;
    if (pendingInvocation == null) return;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => pendingInvocation.callback(pendingInvocation.payload),
      debugLabel: debugLabel,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerActivationPending = true;
  }

  void _handlePointerUp(PointerUpEvent event) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pointerActivationPending = false;
    });
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerActivationPending = false;
  }

  void _handleMenuOpened() {
    if (!_openedWithKeyboard) _focusNode.unfocus();
    widget.onMenuOpened?.call();
  }

  void _handleMenuClosed() {
    if (!_openedWithKeyboard) _focusNode.unfocus();
    _openedWithKeyboard = false;
    _closing = false;
    if (_closeRequestedForInvocation) {
      _reopenAfterClose = false;
    }
    _closeRequestedForInvocation = false;
    widget.onMenuClosed?.call();
    _schedulePendingInvocation(
      debugLabel: 'CupertinoAdaptiveActions.invokeAfterMenuClosed',
    );
    if (_reopenAfterClose) {
      _reopenAfterClose = false;
      scheduleMicrotask(() {
        if (mounted) _toggleMenu();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    return CupertinoMenuAnchor(
      controller: _controller,
      childFocusNode: _focusNode,
      onOpen: _handleMenuOpened,
      onClose: _handleMenuClosed,
      menuChildren: widget.menuAction == null
          ? [
              for (final entry in widget.entries)
                if (_cupertinoMenuEntryIsVisible(entry))
                  _CupertinoMenuEntry<T>(
                    entry: entry,
                    onRequestInvoke: _requestMenuInvocation,
                    iconBuilder: widget.iconBuilder,
                    menuBuilderForAction: widget.menuBuilderForAction,
                    tooltipBuilder: widget.tooltipBuilder,
                    textDirection: textDirection,
                  ),
            ]
          : _cupertinoMenuChildren<T>(
              context: context,
              action: widget.menuAction!,
              onRequestInvoke: _requestMenuInvocation,
              iconBuilder: widget.iconBuilder,
              menuBuilderForAction: widget.menuBuilderForAction,
              tooltipBuilder: widget.tooltipBuilder,
              textDirection: textDirection,
              includeActionInvocation: widget.includeActionInvocation,
            ),
      builder: (context, controller, child) => Listener(
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: widget.triggerBuilder(context, _toggleMenu, _focusNode),
      ),
    );
  }
}

final class _CupertinoOverflowAction<T extends Object> extends StatelessWidget {
  const _CupertinoOverflowAction({
    required this.entries,
    required this.dividerBeforeActionIds,
    required this.onInvoke,
    required this.iconBuilder,
    required this.menuBuilderForAction,
    required this.overflowButtonBuilder,
    required this.tooltipBuilder,
    required this.onMenuOpened,
    required this.onMenuClosed,
    required this.invokeAfterMenuClosed,
    required this.style,
    required this.icon,
    required this.tooltip,
  });

  final List<AdaptiveAction<T>> entries;
  final List<ActionId> dividerBeforeActionIds;
  final ValueChanged<T> onInvoke;
  final CupertinoActionIconBuilder<T>? iconBuilder;
  final CupertinoActionMenuBuilder<T>? menuBuilderForAction;
  final CupertinoOverflowButtonBuilder? overflowButtonBuilder;
  final AdaptiveCupertinoTooltipBuilder? tooltipBuilder;
  final VoidCallback? onMenuOpened;
  final VoidCallback? onMenuClosed;
  final bool invokeAfterMenuClosed;
  final CupertinoAdaptiveActionsStyle style;
  final Widget icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) => _CupertinoActionMenuAnchor<T>(
    entries: [
      for (final action in entries) ...[
        if (dividerBeforeActionIds.contains(action.id))
          AdaptiveMenuDivider<T>(),
        action,
      ],
    ],
    onInvoke: onInvoke,
    iconBuilder: iconBuilder,
    menuBuilderForAction: menuBuilderForAction,
    tooltipBuilder: tooltipBuilder,
    onMenuOpened: onMenuOpened,
    onMenuClosed: onMenuClosed,
    invokeAfterMenuClosed: invokeAfterMenuClosed,
    triggerBuilder: (context, toggle, focusNode) {
      Widget defaultBuilder(
        BuildContext context,
        VoidCallback onPressed, {
        Widget? icon,
      }) => Semantics(
        label: tooltip,
        tooltip: tooltip,
        button: true,
        child: _CupertinoMenuTriggerFocusHalo(
          child: _CupertinoTooltip(
            message: tooltip,
            builder: tooltipBuilder,
            child: CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              focusColor: CupertinoColors.transparent,
              focusNode: focusNode,
              onPressed: onPressed,
              child: IconTheme.merge(
                data: IconThemeData(size: style.iconSize),
                child: icon ?? this.icon,
              ),
            ),
          ),
        ),
      );
      return overflowButtonBuilder?.call(context, toggle, defaultBuilder) ??
          defaultBuilder(context, toggle);
    },
  );
}

final class _CupertinoMenuEntry<T extends Object> extends StatelessWidget {
  const _CupertinoMenuEntry({
    required this.entry,
    required this.onRequestInvoke,
    required this.iconBuilder,
    required this.menuBuilderForAction,
    required this.tooltipBuilder,
    required this.textDirection,
  });

  final AdaptiveMenuEntry<T> entry;
  final ValueChanged<T> onRequestInvoke;
  final CupertinoActionIconBuilder<T>? iconBuilder;
  final CupertinoActionMenuBuilder<T>? menuBuilderForAction;
  final AdaptiveCupertinoTooltipBuilder? tooltipBuilder;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    if (entry is AdaptiveMenuDivider<T>) {
      return entry.showInMenu
          ? const CupertinoMenuDivider()
          : const SizedBox.shrink();
    }
    final action = entry as AdaptiveAction<T>;
    if (!action.hasMenu || !action.isEnabled) {
      return _CupertinoMenuInvokeItem<T>(
        action: action,
        onRequestInvoke: onRequestInvoke,
        iconBuilder: iconBuilder,
        tooltipBuilder: tooltipBuilder,
        textDirection: textDirection,
        showsSubmenuAffordance: action.hasMenu,
      );
    }

    return _CupertinoSubmenuItem<T>(
      action: action,
      onRequestInvoke: onRequestInvoke,
      iconBuilder: iconBuilder,
      menuBuilderForAction: menuBuilderForAction,
      tooltipBuilder: tooltipBuilder,
      textDirection: textDirection,
    );
  }
}

List<Widget> _cupertinoMenuChildren<T extends Object>({
  required BuildContext context,
  required AdaptiveAction<T> action,
  required ValueChanged<T> onRequestInvoke,
  required CupertinoActionIconBuilder<T>? iconBuilder,
  required CupertinoActionMenuBuilder<T>? menuBuilderForAction,
  required AdaptiveCupertinoTooltipBuilder? tooltipBuilder,
  required TextDirection textDirection,
  bool includeActionInvocation = false,
}) {
  final customChildren = menuBuilderForAction?.call(context, action);
  if (customChildren != null) {
    if (customChildren.isEmpty) {
      throw FlutterError.fromParts([
        ErrorSummary('A custom Cupertino action menu cannot be empty.'),
        ErrorDescription(
          'The menu builder returned no widgets for action ${action.id}.',
        ),
        ErrorHint(
          'Return at least one menu widget, or return null to render the '
          "action's declared children.",
        ),
      ]);
    }
    return customChildren;
  }
  if (action.children.isEmpty) {
    throw FlutterError.fromParts([
      ErrorSummary('A Cupertino menu action has no menu content.'),
      ErrorDescription(
        'Action ${action.id} declares hasMenu == true but has no children '
        'and its menu builder returned null.',
      ),
      ErrorHint(
        'Provide menuBuilderForAction content for this action or declare at '
        'least one child action.',
      ),
    ]);
  }
  return [
    if (includeActionInvocation && action.payload != null)
      _CupertinoMenuInvokeItem<T>(
        action: action,
        onRequestInvoke: onRequestInvoke,
        iconBuilder: iconBuilder,
        tooltipBuilder: tooltipBuilder,
        textDirection: textDirection,
      ),
    for (final child in action.children)
      if (_cupertinoMenuEntryIsVisible(child))
        _CupertinoMenuEntry<T>(
          entry: child,
          onRequestInvoke: onRequestInvoke,
          iconBuilder: iconBuilder,
          menuBuilderForAction: menuBuilderForAction,
          tooltipBuilder: tooltipBuilder,
          textDirection: textDirection,
        ),
  ];
}

bool _cupertinoMenuEntryIsVisible<T extends Object>(
  AdaptiveMenuEntry<T> entry,
) => entry is! AdaptiveMenuDivider<T> || entry.showInMenu;

String? _cupertinoMenuSemanticsLabel(ActionMetadata metadata) =>
    metadata.semanticLabel ??
    (metadata.subtitle == null ? metadata.label : null);

final class _CupertinoMenuInvokeItem<T extends Object> extends StatelessWidget {
  const _CupertinoMenuInvokeItem({
    required this.action,
    required this.onRequestInvoke,
    required this.iconBuilder,
    required this.tooltipBuilder,
    required this.textDirection,
    this.showsSubmenuAffordance = false,
  });

  final AdaptiveAction<T> action;
  final ValueChanged<T> onRequestInvoke;
  final CupertinoActionIconBuilder<T>? iconBuilder;
  final AdaptiveCupertinoTooltipBuilder? tooltipBuilder;
  final TextDirection textDirection;
  final bool showsSubmenuAffordance;

  @override
  Widget build(BuildContext context) => Semantics(
    label: _cupertinoMenuSemanticsLabel(action.metadata),
    excludeSemantics: action.metadata.semanticLabel != null,
    tooltip: action.metadata.tooltip,
    button: true,
    enabled: action.isEnabled,
    child: _CupertinoActionTooltip(
      metadata: action.metadata,
      surface: ActionTooltipSurface.menuItem,
      builder: tooltipBuilder,
      child: CupertinoMenuItem(
        leading: iconBuilder?.call(context, action),
        subtitle: action.metadata.subtitle == null
            ? null
            : Text(action.metadata.subtitle!),
        trailing: showsSubmenuAffordance
            ? _cupertinoForwardIcon(textDirection)
            : null,
        isDestructiveAction: action.metadata.isDestructive,
        requestCloseOnActivate: false,
        onPressed: action.isEnabled && action.payload != null
            ? () => invokeAdaptiveAction(action, onRequestInvoke)
            : null,
        child: Text(action.metadata.label),
      ),
    ),
  );
}

final class _CupertinoSubmenuItem<T extends Object> extends StatefulWidget {
  const _CupertinoSubmenuItem({
    required this.action,
    required this.onRequestInvoke,
    required this.iconBuilder,
    required this.menuBuilderForAction,
    required this.tooltipBuilder,
    required this.textDirection,
  });

  final AdaptiveAction<T> action;
  final ValueChanged<T> onRequestInvoke;
  final CupertinoActionIconBuilder<T>? iconBuilder;
  final CupertinoActionMenuBuilder<T>? menuBuilderForAction;
  final AdaptiveCupertinoTooltipBuilder? tooltipBuilder;
  final TextDirection textDirection;

  @override
  State<_CupertinoSubmenuItem<T>> createState() =>
      _CupertinoSubmenuItemState<T>();
}

final class _CupertinoSubmenuItemState<T extends Object>
    extends State<_CupertinoSubmenuItem<T>> {
  final _controller = MenuController();
  final _focusNode = FocusNode(debugLabel: 'Cupertino submenu item');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    return CupertinoMenuAnchor(
      controller: _controller,
      childFocusNode: _focusNode,
      menuChildren: _cupertinoMenuChildren<T>(
        context: context,
        action: action,
        onRequestInvoke: widget.onRequestInvoke,
        iconBuilder: widget.iconBuilder,
        menuBuilderForAction: widget.menuBuilderForAction,
        tooltipBuilder: widget.tooltipBuilder,
        textDirection: widget.textDirection,
        includeActionInvocation: true,
      ),
      builder: (context, controller, child) => Semantics(
        label: _cupertinoMenuSemanticsLabel(action.metadata),
        excludeSemantics: action.metadata.semanticLabel != null,
        tooltip: action.metadata.tooltip,
        button: true,
        enabled: true,
        child: _CupertinoActionTooltip(
          metadata: action.metadata,
          surface: ActionTooltipSurface.menuItem,
          builder: widget.tooltipBuilder,
          child: CupertinoMenuItem(
            leading: widget.iconBuilder?.call(context, action),
            subtitle: action.metadata.subtitle == null
                ? null
                : Text(action.metadata.subtitle!),
            trailing: _cupertinoForwardIcon(widget.textDirection),
            focusNode: _focusNode,
            isDestructiveAction: action.metadata.isDestructive,
            requestCloseOnActivate: false,
            onPressed: controller.isOpen ? controller.close : controller.open,
            child: Text(action.metadata.label),
          ),
        ),
      ),
    );
  }
}

final class _CupertinoActionVisual<T extends Object> {
  _CupertinoActionVisual({
    required AdaptiveAction<T> action,
    required this.icon,
    required double labelWidth,
    required this.labelLayout,
    required this.iconSize,
    required CupertinoActionPresentation? presentationOverride,
    required CupertinoAdaptiveActionsStyle style,
  }) : _options = _buildOptions(
         action: action,
         icon: icon,
         labelWidth: labelWidth,
         iconSize: iconSize,
         style: style,
       ) {
    final options = switch (presentationOverride) {
      null => [_options.extended, ?_options.iconOnly],
      CupertinoActionPresentation.extended => [_options.extended],
      CupertinoActionPresentation.iconOnly => [
        _options.iconOnly ?? _options.extended,
      ],
    };
    profile = ActionLayoutProfile(actionId: action.id, options: options);
  }

  final Widget? icon;
  final ActionLabelLayout labelLayout;
  final double iconSize;
  final ({ActionLayoutOption extended, ActionLayoutOption? iconOnly}) _options;
  late final ActionLayoutProfile profile;

  double costFor(ActionLayoutOptionId optionId) {
    final option = switch (optionId) {
      _ when optionId == _options.extended.id => _options.extended,
      _ when optionId == _options.iconOnly?.id => _options.iconOnly,
      _ => null,
    };
    if (option == null) {
      throw StateError(
        'No Cupertino layout is registered for option $optionId on action '
        '${profile.actionId}.',
      );
    }
    return option.cost;
  }

  static ({ActionLayoutOption extended, ActionLayoutOption? iconOnly})
  _buildOptions<T extends Object>({
    required AdaptiveAction<T> action,
    required Widget? icon,
    required double labelWidth,
    required double iconSize,
    required CupertinoAdaptiveActionsStyle style,
  }) => (
    extended: ActionLayoutOption(
      id: _cupertinoLabelOptionId,
      cost: _labelCost(
        labelWidth,
        hasIcon: icon != null,
        iconSize: iconSize,
        isComposite: action.payload != null && action.hasMenu,
        style: style,
      ),
    ),
    iconOnly: icon == null
        ? null
        : ActionLayoutOption(
            id: _cupertinoIconOptionId,
            cost: _iconCost(
              isComposite: action.payload != null && action.hasMenu,
              iconSize: iconSize,
              style: style,
            ),
          ),
  );

  static double _labelCost(
    double labelWidth, {
    required bool hasIcon,
    required double iconSize,
    required bool isComposite,
    required CupertinoAdaptiveActionsStyle style,
  }) {
    final invokeCost =
        (labelWidth +
                style.horizontalPadding * 2 +
                (hasIcon ? iconSize + style.iconLabelSpacing : 0))
            .clamp(style.minimumButtonWidth, double.infinity);
    return isComposite ? invokeCost + style.submenuButtonWidth : invokeCost;
  }

  static double _iconCost({
    required bool isComposite,
    required double iconSize,
    required CupertinoAdaptiveActionsStyle style,
  }) {
    final invokeCost = math.max(
      style.iconButtonWidth,
      iconSize + style.horizontalPadding * 2,
    );
    return isComposite ? invokeCost + style.submenuButtonWidth : invokeCost;
  }
}
