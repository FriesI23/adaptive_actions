import 'package:flutter/material.dart';

import '../../core.dart';
import '../widgets/action_invocation.dart';
import '../widgets/action_region_layout.dart';
import '../widgets/action_region_slot.dart';
import '../widgets/single_action_region_host.dart';

const _kMaterialPrimaryDividerWidth = 16.0;

const _kCompactIconButtonStyle = ButtonStyle(
  padding: WidgetStatePropertyAll(EdgeInsets.zero),
  minimumSize: WidgetStatePropertyAll(Size.zero),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

final _materialLabelOptionId = ActionLayoutOptionId('material.label');
final _materialIconOptionId = ActionLayoutOptionId('material.icon');

/// Builds the Material icon associated with an adaptive [action].
///
/// Return `null` when the action has no Material icon. The renderer then uses
/// its label-only primary layout option.
typedef MaterialActionIconBuilder<T extends Object> =
    Widget? Function(BuildContext context, AdaptiveAction<T> action);

/// Builds the default Material primary action button.
typedef MaterialActionButtonDefaultBuilder<T extends Object> =
    Widget Function(
      BuildContext context,
      AdaptiveAction<T> action,
      VoidCallback? onPressed,
    );

/// Overrides a Material primary action button.
///
/// Call [defaultBuilder] with the supplied arguments to retain the platform
/// implementation, or replace them to customize this render only. Replacing
/// [action] does not rerun layout resolution or change the allocated slot.
typedef MaterialActionButtonBuilder<T extends Object> =
    Widget Function(
      BuildContext context,
      AdaptiveAction<T> action,
      VoidCallback? onPressed,
      MaterialActionButtonDefaultBuilder<T> defaultBuilder,
    );

/// Builds the default Material overflow-menu trigger.
typedef MaterialOverflowButtonDefaultBuilder =
    Widget Function(BuildContext context, VoidCallback onPressed);

/// Overrides the Material overflow-menu trigger.
///
/// The renderer continues to own the menu and supplies its toggle callback.
typedef MaterialOverflowButtonBuilder =
    Widget Function(
      BuildContext context,
      VoidCallback onPressed,
      MaterialOverflowButtonDefaultBuilder defaultBuilder,
    );

/// A forced primary-button presentation for [MaterialAdaptiveActions].
///
/// This only selects between Material-owned layout options. It does not change
/// whether an action is placed in primary, overflow, or hidden.
enum MaterialActionPresentation {
  /// Shows the action label and, when available, its icon.
  extended,

  /// Shows only the action icon.
  ///
  /// An action without an icon falls back to [extended].
  iconOnly,
}

/// Selects a Material primary-button presentation for one root [action].
///
/// Return `null` to fall back to [MaterialAdaptiveActions.presentationOverride]
/// or, when that is also `null`, to automatic layout selection.
typedef MaterialActionPresentationCallback<T extends Object> =
    MaterialActionPresentation? Function(
      BuildContext context,
      AdaptiveAction<T> action,
    );

/// Visual and layout configuration used by [MaterialAdaptiveActions].
///
/// These values describe renderer-owned Material geometry. They affect both
/// the widgets and the costs submitted to the core resolver, so the visual
/// layout and placement decision remain consistent.
///
/// ```dart
/// const regular = MaterialAdaptiveActionsStyle();
/// final compact = regular.copyWith(height: 40, iconSize: 16);
/// ```
final class MaterialAdaptiveActionsStyle {
  /// Creates a Material adaptive-actions style.
  const MaterialAdaptiveActionsStyle({
    this.height = 48,
    this.minimumButtonWidth = 48,
    this.iconButtonWidth = 48,
    this.submenuButtonWidth = 32,
    this.overflowButtonWidth = 48,
    this.iconSize = 18,
    this.iconLabelSpacing = 8,
    this.horizontalPadding = 12,
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
  /// height: 48    [  Save  ]
  /// height: 64    [        ]
  ///               [  Save  ]
  ///               [        ]
  /// ```
  final double height;

  /// The minimum width of a label-based primary button.
  ///
  /// ```text
  /// minimumButtonWidth: 48    [ OK ]
  /// minimumButtonWidth: 72    [   OK   ]
  /// ```
  final double minimumButtonWidth;

  /// The width reserved for an icon-only primary button.
  ///
  /// ```text
  /// iconButtonWidth: 40    [ S ]
  /// iconButtonWidth: 56    [  S  ]
  /// ```
  final double iconButtonWidth;

  /// The width reserved for a composite action's submenu affordance.
  ///
  /// ```text
  /// submenuButtonWidth: 24    [ Open ][v]
  /// submenuButtonWidth: 40    [ Open ][ v ]
  /// ```
  final double submenuButtonWidth;

  /// The width reserved for the overflow menu trigger.
  ///
  /// This value is also submitted to the core resolver as its overflow trigger
  /// cost, so a visible trigger does not exceed [MaterialAdaptiveActions]
  /// capacity unnoticed.
  ///
  /// ```text
  /// overflowButtonWidth: 40    [⋮]
  /// overflowButtonWidth: 56    [ ⋮ ]
  /// ```
  final double overflowButtonWidth;

  /// The Material icon size used by primary buttons.
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
  /// horizontalPadding: 8     [ Save ]
  /// horizontalPadding: 16    [   Save   ]
  /// ```
  final double horizontalPadding;

  /// Returns a copy with the supplied fields replaced.
  ///
  /// Unspecified fields retain their current values.
  MaterialAdaptiveActionsStyle copyWith({
    double? height,
    double? minimumButtonWidth,
    double? iconButtonWidth,
    double? submenuButtonWidth,
    double? overflowButtonWidth,
    double? iconSize,
    double? iconLabelSpacing,
    double? horizontalPadding,
  }) => MaterialAdaptiveActionsStyle(
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

/// A Material primary and overflow action region backed by
/// [ActionLayoutResolver].
///
/// [primaryCapacity] is the maximum width available to the action region. The
/// host owns that layout policy because a widget context can expose the whole
/// window through `MediaQuery`, but cannot infer how much width a surrounding
/// toolbar reserves for its leading widget and title. On every build this
/// widget creates Material-owned layout options, resolves the supplied
/// [actions], and draws the ordered primary and overflow results without
/// changing the action collection. The overflow trigger is present only while
/// the resolved overflow region is non-empty. Menu subtrees retain arbitrary
/// depth and declaration order.
///
/// Layout changes animate one boundary action instead of replacing the whole
/// row. Stable actions remain visible while the changing slot fades and
/// expands or contracts. When one result changes several actions, earlier
/// changes complete immediately and only the final boundary action animates.
/// A variant interrupted by the next change contributes one frozen current
/// frame; structural transitions otherwise finish before the latest boundary
/// starts. The region therefore retains at most one outgoing and one incoming
/// child while rapid capacity updates never accumulate outgoing rows.
///
/// The following example places one adaptive action directly in an [AppBar]:
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
/// final appBar = AppBar(
///   title: const Text('Document'),
///   actions: [
///     MaterialAdaptiveActions<String>.moreAction(
///       actions: ActionCollection(roots: [save]),
///       primaryCapacity: 160,
///       onInvoke: (command) => handleCommand(command),
///       iconBuilder: (context, action) => switch (action.metadata.iconKey) {
///         'save' => const Icon(Icons.save),
///         _ => null,
///       },
///     ),
///   ],
/// );
/// ```
final class MaterialAdaptiveActions<T extends Object> extends StatelessWidget {
  /// Creates a generic Material primary action region.
  ///
  /// The host must provide [overflowIcon]. Use [MaterialAdaptiveActions.moreAction]
  /// for the conventional Material More icon.
  const MaterialAdaptiveActions({
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
    this.overflowButtonBuilder,
    required this.overflowIcon,
    this.overflowTooltip = '',
    this.presentationForAction,
    this.presentationOverride,
    this.style = const MaterialAdaptiveActionsStyle(),
    this.menuAnimationEnabled = true,
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

  /// Creates a Material action region with the conventional More icon.
  ///
  /// [overflowTooltip] defaults to "More actions" and can be replaced with a
  /// localized description by the host.
  const MaterialAdaptiveActions.moreAction({
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
    this.overflowButtonBuilder,
    this.presentationForAction,
    this.presentationOverride,
    this.style = const MaterialAdaptiveActionsStyle(),
    this.overflowIcon = const Icon(Icons.more_vert),
    this.overflowTooltip = 'More actions',
    this.menuAnimationEnabled = true,
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
  /// should reserve space for adjacent toolbar content. This value is a layout
  /// decision input, not a clipping or scrolling constraint. If hard placement
  /// produces a wider result, the caller owns the surrounding overflow policy.
  ///
  /// ```text
  /// primaryCapacity: 220    [Save] [Search]
  /// primaryCapacity: 96     [ S ]  [ ? ]
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
  /// rendered overflow:    [Delete] [Copy] [Cut]
  /// ```
  final Iterable<ActionId> overflowOrderOverride;

  /// The layout resolver used to consume renderer-owned constraints.
  final ActionLayoutResolver resolver;

  /// The optional maximum number of root actions shown in primary.
  ///
  /// ```text
  /// maxPrimaryActions: 3    [Save] [Search] [Share]
  /// maxPrimaryActions: 2    [Save] [Search] [overflow]
  /// ```
  final int? maxPrimaryActions;

  /// Resolves platform-specific icons from the platform-neutral metadata.
  ///
  /// ```text
  /// iconBuilder returns null:          [ Save ]
  /// iconBuilder returns Icons.save:    [S Save] -> narrow -> [ S ]
  /// ```
  final MaterialActionIconBuilder<T>? iconBuilder;

  /// Overrides leaf actions, primary menu triggers, and composite invoke
  /// buttons while preserving the renderer-owned slot constraints.
  final MaterialActionButtonBuilder<T>? actionButtonBuilder;

  /// Overrides the overflow trigger without replacing its anchored menu.
  final MaterialOverflowButtonBuilder? overflowButtonBuilder;

  /// Selects a primary-button presentation independently for each root action.
  ///
  /// A non-null result overrides [presentationOverride] for that action. A
  /// `null` result falls back to [presentationOverride], then to automatic
  /// layout selection when the global override is also `null`.
  final MaterialActionPresentationCallback<T>? presentationForAction;

  /// Forces one Material primary-button presentation for every root action.
  ///
  /// When `null`, the resolver automatically selects extended or icon-only
  /// layouts from the available width. [MaterialActionPresentation.iconOnly]
  /// falls back to the extended layout for actions whose [iconBuilder] result
  /// is `null`.
  final MaterialActionPresentation? presentationOverride;

  /// The built-in horizontal distribution for this single action region.
  final ActionRegionMainAxisDistribution distribution;

  /// An optional advanced layout policy for fixed and flexible slots or gaps.
  ///
  /// When supplied, [distribution] must remain
  /// [ActionRegionMainAxisDistribution.compact].
  final ActionRegionLayoutDelegate? layoutDelegate;

  /// Renderer-owned Material visual and layout configuration.
  ///
  /// ```text
  /// default style:                 [S Save]
  /// style.copyWith(height: 64):    [      ]
  ///                                [S Save]
  ///                                [      ]
  /// ```
  final MaterialAdaptiveActionsStyle style;

  /// The icon used by the overflow trigger.
  ///
  /// ```text
  /// overflowIcon: Icons.more_vert    [⋮]
  /// overflowIcon: Icons.more_horiz   […]
  /// ```
  final Widget overflowIcon;

  /// Tooltip and accessibility label for the overflow trigger.
  ///
  /// ```text
  /// overflowTooltip: localizedMoreActions -> [⋮] -> localized description
  /// ```
  final String overflowTooltip;

  /// Whether anchored Material menus animate while opening and closing.
  ///
  /// This is forwarded to Flutter's official [MenuAnchor.animated] and every
  /// nested [SubmenuButton.animated]. It defaults to `true`, overriding those
  /// widgets' non-animated default consistently across the complete action
  /// tree.
  final bool menuAnimationEnabled;

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
    return SingleActionRegionHost<_MaterialRegionSlot<T>>(
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
        final data = _MaterialRegionData<T>(
          primaryEntries: result.primary,
          overflowEntries: result.overflow,
          primaryDividerBeforeActionIds: result.primaryDividerBeforeActionIds,
          overflowDividerBeforeActionIds: result.overflowDividerBeforeActionIds,
          visuals: visuals,
          onInvoke: onInvoke,
          iconBuilder: iconBuilder,
          actionButtonBuilder: actionButtonBuilder,
          overflowButtonBuilder: overflowButtonBuilder,
          style: style,
          overflowIcon: overflowIcon,
          overflowTooltip: overflowTooltip,
          menuAnimationEnabled: menuAnimationEnabled,
        );
        return SingleActionRegionSnapshot(slots: data.slots);
      },
      height: style.height,
      fadeDuration: fadeDuration,
      resizeDuration: resizeDuration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      variantBuilder: (context, from, to, fadeProgress, resizeProgress) =>
          _MaterialRegionVariantTransition<T>(
            from: from,
            to: to,
            fadeProgress: fadeProgress,
            resizeProgress: resizeProgress,
          ),
    );
  }

  Map<ActionId, _MaterialActionVisual<T>> _buildVisuals(BuildContext context) =>
      {
        for (final action in actions.roots)
          action.id: _MaterialActionVisual(
            action: action,
            icon: iconBuilder?.call(context, action),
            labelWidth: _labelWidth(context, action.metadata.label),
            presentationOverride:
                presentationForAction?.call(context, action) ??
                presentationOverride,
            style: style,
          ),
      };

  double _labelWidth(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

final class _MaterialRegionVariantTransition<T extends Object>
    extends StatelessWidget {
  const _MaterialRegionVariantTransition({
    required this.from,
    required this.to,
    required this.fadeProgress,
    required this.resizeProgress,
  });

  final ActionRegionSlot<_MaterialRegionSlot<T>> from;
  final ActionRegionSlot<_MaterialRegionSlot<T>> to;
  final Animation<double> fadeProgress;
  final Animation<double> resizeProgress;

  @override
  Widget build(BuildContext context) {
    final fromSlot = from.data;
    final toSlot = to.data;
    if (fromSlot is! _MaterialPrimarySlot<T> ||
        toSlot is! _MaterialPrimarySlot<T>) {
      return to.child;
    }
    return _MaterialRegionSlotView<T>(
      slot: toSlot,
      optionTransition: _MaterialOptionTransition(
        from: fromSlot.entry.optionId,
        to: toSlot.entry.optionId,
        fadeProgress: fadeProgress,
        resizeProgress: resizeProgress,
      ),
    );
  }
}

final class _MaterialRegionData<T extends Object> {
  const _MaterialRegionData({
    required this.primaryEntries,
    required this.overflowEntries,
    required this.primaryDividerBeforeActionIds,
    required this.overflowDividerBeforeActionIds,
    required this.visuals,
    required this.onInvoke,
    required this.iconBuilder,
    required this.actionButtonBuilder,
    required this.overflowButtonBuilder,
    required this.style,
    required this.overflowIcon,
    required this.overflowTooltip,
    required this.menuAnimationEnabled,
  });

  final List<ResolvedPrimaryAction<T>> primaryEntries;
  final List<AdaptiveAction<T>> overflowEntries;
  final List<ActionId> primaryDividerBeforeActionIds;
  final List<ActionId> overflowDividerBeforeActionIds;
  final Map<ActionId, _MaterialActionVisual<T>> visuals;
  final ValueChanged<T> onInvoke;
  final MaterialActionIconBuilder<T>? iconBuilder;
  final MaterialActionButtonBuilder<T>? actionButtonBuilder;
  final MaterialOverflowButtonBuilder? overflowButtonBuilder;
  final MaterialAdaptiveActionsStyle style;
  final Widget overflowIcon;
  final String overflowTooltip;
  final bool menuAnimationEnabled;

  List<ActionRegionSlot<_MaterialRegionSlot<T>>> get slots => [
    for (final entry in primaryEntries) primaryItem(entry),
    if (overflowEntries.isNotEmpty) overflowItem(),
  ];

  ActionRegionSlot<_MaterialRegionSlot<T>> primaryItem(
    ResolvedPrimaryAction<T> entry,
  ) {
    final slot = primarySlot(entry);
    return ActionRegionSlot<_MaterialRegionSlot<T>>(
      id: ('material-primary', entry.action.id),
      layoutId: ActionRegionLayoutSlotId.action(entry.action.id),
      variant: ('material-option', entry.optionId),
      role: ActionRegionSlotRole.action,
      minimumExtent: slot.width,
      data: slot,
      child: _MaterialRegionSlotView<T>(slot: slot),
    );
  }

  ActionRegionSlot<_MaterialRegionSlot<T>> overflowItem() {
    final slot = overflowSlot();
    return ActionRegionSlot<_MaterialRegionSlot<T>>(
      id: 'material-overflow',
      layoutId: const ActionRegionLayoutSlotId.overflow(),
      variant: 'material-overflow-trigger',
      role: ActionRegionSlotRole.overflow,
      minimumExtent: slot.width,
      data: slot,
      child: _MaterialRegionSlotView<T>(slot: slot),
    );
  }

  _MaterialPrimarySlot<T> primarySlot(ResolvedPrimaryAction<T> entry) =>
      _MaterialPrimarySlot<T>(data: this, entry: entry);

  _MaterialOverflowSlot<T> overflowSlot() =>
      _MaterialOverflowSlot<T>(data: this);
}

/// Renderer-owned data for one animated Material action-region slot.
sealed class _MaterialRegionSlot<T extends Object> {
  const _MaterialRegionSlot({required this.data});

  final _MaterialRegionData<T> data;
  double get width;
}

final class _MaterialPrimarySlot<T extends Object>
    extends _MaterialRegionSlot<T> {
  const _MaterialPrimarySlot({required super.data, required this.entry});

  final ResolvedPrimaryAction<T> entry;

  bool get showDividerBefore =>
      data.primaryDividerBeforeActionIds.contains(entry.action.id);

  @override
  double get width =>
      data.visuals[entry.action.id]!.costFor(entry.optionId) +
      (showDividerBefore ? _kMaterialPrimaryDividerWidth : 0);
}

final class _MaterialOverflowSlot<T extends Object>
    extends _MaterialRegionSlot<T> {
  const _MaterialOverflowSlot({required super.data});

  @override
  double get width => data.style.overflowButtonWidth;
}

/// Builds the Material widget represented by one region [slot].
final class _MaterialRegionSlotView<T extends Object> extends StatelessWidget {
  const _MaterialRegionSlotView({
    super.key,
    required this.slot,
    this.optionTransition,
  });

  final _MaterialRegionSlot<T> slot;
  final _MaterialOptionTransition? optionTransition;

  @override
  Widget build(BuildContext context) {
    final slot = this.slot;
    if (slot is _MaterialPrimarySlot<T>) {
      final data = slot.data;
      final entry = slot.entry;
      final action = _MaterialPrimaryAction<T>(
        entry: entry,
        visual: data.visuals[entry.action.id]!,
        onInvoke: data.onInvoke,
        iconBuilder: data.iconBuilder,
        actionButtonBuilder: data.actionButtonBuilder,
        style: data.style,
        menuAnimationEnabled: data.menuAnimationEnabled,
        optionTransition: optionTransition,
      );
      if (!slot.showDividerBefore) return action;
      final dividerTheme = DividerTheme.of(context);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VerticalDivider(
            width: _kMaterialPrimaryDividerWidth,
            thickness: dividerTheme.thickness ?? 1,
            indent: 8,
            endIndent: 8,
            color: dividerTheme.color,
          ),
          action,
        ],
      );
    }
    final overflow = slot as _MaterialOverflowSlot<T>;
    final data = overflow.data;
    return _MaterialOverflowAction<T>(
      entries: data.overflowEntries,
      dividerBeforeActionIds: data.overflowDividerBeforeActionIds,
      onInvoke: data.onInvoke,
      iconBuilder: data.iconBuilder,
      overflowButtonBuilder: data.overflowButtonBuilder,
      style: data.style,
      icon: data.overflowIcon,
      tooltip: data.overflowTooltip,
      menuAnimationEnabled: data.menuAnimationEnabled,
    );
  }
}

final class _MaterialOptionTransition {
  const _MaterialOptionTransition({
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

final class _MaterialPrimaryAction<T extends Object> extends StatelessWidget {
  const _MaterialPrimaryAction({
    super.key,
    required this.entry,
    required this.visual,
    required this.onInvoke,
    required this.iconBuilder,
    required this.actionButtonBuilder,
    required this.style,
    required this.menuAnimationEnabled,
    this.optionTransition,
  });

  final ResolvedPrimaryAction<T> entry;
  final _MaterialActionVisual<T> visual;
  final ValueChanged<T> onInvoke;
  final MaterialActionIconBuilder<T>? iconBuilder;
  final MaterialActionButtonBuilder<T>? actionButtonBuilder;
  final MaterialAdaptiveActionsStyle style;
  final bool menuAnimationEnabled;
  final _MaterialOptionTransition? optionTransition;

  @override
  Widget build(BuildContext context) {
    final action = entry.action;
    final child = switch (action) {
      _ when action.children.isEmpty => _MaterialInvokeAction<T>(
        action: action,
        visual: visual,
        optionId: entry.optionId,
        onInvoke: onInvoke,
        actionButtonBuilder: actionButtonBuilder,
        style: style,
        optionTransition: optionTransition,
      ),
      _ when action.payload == null => _MaterialMenuAction<T>(
        action: action,
        visual: visual,
        optionId: entry.optionId,
        onInvoke: onInvoke,
        iconBuilder: iconBuilder,
        actionButtonBuilder: actionButtonBuilder,
        style: style,
        menuAnimationEnabled: menuAnimationEnabled,
        optionTransition: optionTransition,
      ),
      _ => _MaterialCompositeAction<T>(
        action: action,
        visual: visual,
        optionId: entry.optionId,
        onInvoke: onInvoke,
        iconBuilder: iconBuilder,
        actionButtonBuilder: actionButtonBuilder,
        style: style,
        menuAnimationEnabled: menuAnimationEnabled,
        optionTransition: optionTransition,
      ),
    };

    return Semantics(
      label: action.metadata.semanticLabel ?? action.metadata.label,
      child: child,
    );
  }
}

final class _MaterialInvokeAction<T extends Object> extends StatelessWidget {
  const _MaterialInvokeAction({
    required this.action,
    required this.visual,
    required this.optionId,
    required this.onInvoke,
    required this.actionButtonBuilder,
    required this.style,
    this.optionTransition,
  });

  final AdaptiveAction<T> action;
  final _MaterialActionVisual<T> visual;
  final ActionLayoutOptionId optionId;
  final ValueChanged<T> onInvoke;
  final MaterialActionButtonBuilder<T>? actionButtonBuilder;
  final MaterialAdaptiveActionsStyle style;
  final _MaterialOptionTransition? optionTransition;

  @override
  Widget build(BuildContext context) => _CustomizableMaterialActionButton<T>(
    action: action,
    visual: visual,
    optionId: optionId,
    onPressed: action.isEnabled
        ? () => invokeAdaptiveAction(action, onInvoke)
        : null,
    builder: actionButtonBuilder,
    style: style,
    optionTransition: optionTransition,
  );
}

final class _MaterialMenuAction<T extends Object> extends StatelessWidget {
  const _MaterialMenuAction({
    required this.action,
    required this.visual,
    required this.optionId,
    required this.onInvoke,
    required this.iconBuilder,
    required this.actionButtonBuilder,
    required this.style,
    required this.menuAnimationEnabled,
    this.optionTransition,
  });

  final AdaptiveAction<T> action;
  final _MaterialActionVisual<T> visual;
  final ActionLayoutOptionId optionId;
  final ValueChanged<T> onInvoke;
  final MaterialActionIconBuilder<T>? iconBuilder;
  final MaterialActionButtonBuilder<T>? actionButtonBuilder;
  final MaterialAdaptiveActionsStyle style;
  final bool menuAnimationEnabled;
  final _MaterialOptionTransition? optionTransition;

  @override
  Widget build(BuildContext context) => MenuAnchor(
    animated: menuAnimationEnabled,
    menuChildren: [
      for (final child in action.children)
        if (_materialMenuEntryIsVisible(child))
          _MaterialMenuEntry<T>(
            entry: child,
            onInvoke: onInvoke,
            iconBuilder: iconBuilder,
            menuAnimationEnabled: menuAnimationEnabled,
          ),
    ],
    builder: (context, controller, child) =>
        _CustomizableMaterialActionButton<T>(
          action: action,
          visual: visual,
          optionId: optionId,
          onPressed: action.isEnabled ? controller.open : null,
          builder: actionButtonBuilder,
          style: style,
          optionTransition: optionTransition,
        ),
  );
}

final class _MaterialCompositeAction<T extends Object> extends StatelessWidget {
  const _MaterialCompositeAction({
    required this.action,
    required this.visual,
    required this.optionId,
    required this.onInvoke,
    required this.iconBuilder,
    required this.actionButtonBuilder,
    required this.style,
    required this.menuAnimationEnabled,
    this.optionTransition,
  });

  final AdaptiveAction<T> action;
  final _MaterialActionVisual<T> visual;
  final ActionLayoutOptionId optionId;
  final ValueChanged<T> onInvoke;
  final MaterialActionIconBuilder<T>? iconBuilder;
  final MaterialActionButtonBuilder<T>? actionButtonBuilder;
  final MaterialAdaptiveActionsStyle style;
  final bool menuAnimationEnabled;
  final _MaterialOptionTransition? optionTransition;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _MaterialInvokeAction<T>(
        action: action,
        visual: visual,
        optionId: optionId,
        onInvoke: onInvoke,
        actionButtonBuilder: actionButtonBuilder,
        style: style,
        optionTransition: optionTransition,
      ),
      MenuAnchor(
        animated: menuAnimationEnabled,
        menuChildren: [
          for (final child in action.children)
            if (_materialMenuEntryIsVisible(child))
              _MaterialMenuEntry<T>(
                entry: child,
                onInvoke: onInvoke,
                iconBuilder: iconBuilder,
                menuAnimationEnabled: menuAnimationEnabled,
              ),
        ],
        builder: (context, controller, child) => Tooltip(
          message:
              action.metadata.tooltip ??
              action.metadata.semanticLabel ??
              action.metadata.label,
          child: SizedBox(
            width: style.submenuButtonWidth,
            height: style.height,
            child: IconButton(
              style: _kCompactIconButtonStyle,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: style.iconSize,
              onPressed: action.isEnabled ? controller.open : null,
            ),
          ),
        ),
      ),
    ],
  );
}

final class _MaterialOverflowAction<T extends Object> extends StatefulWidget {
  const _MaterialOverflowAction({
    required this.entries,
    required this.dividerBeforeActionIds,
    required this.onInvoke,
    required this.iconBuilder,
    required this.overflowButtonBuilder,
    required this.style,
    required this.icon,
    required this.tooltip,
    required this.menuAnimationEnabled,
  });

  final List<AdaptiveAction<T>> entries;
  final List<ActionId> dividerBeforeActionIds;
  final ValueChanged<T> onInvoke;
  final MaterialActionIconBuilder<T>? iconBuilder;
  final MaterialOverflowButtonBuilder? overflowButtonBuilder;
  final MaterialAdaptiveActionsStyle style;
  final Widget icon;
  final String tooltip;
  final bool menuAnimationEnabled;

  @override
  State<_MaterialOverflowAction<T>> createState() =>
      _MaterialOverflowActionState<T>();
}

final class _MaterialOverflowActionState<T extends Object>
    extends State<_MaterialOverflowAction<T>> {
  final _focusNode = FocusNode(debugLabel: 'Material overflow trigger');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MenuAnchor(
    animated: widget.menuAnimationEnabled,
    childFocusNode: _focusNode,
    menuChildren: [
      for (final action in widget.entries) ...[
        if (widget.dividerBeforeActionIds.contains(action.id))
          const PopupMenuDivider(),
        _MaterialMenuEntry<T>(
          entry: action,
          onInvoke: widget.onInvoke,
          iconBuilder: widget.iconBuilder,
          menuAnimationEnabled: widget.menuAnimationEnabled,
        ),
      ],
    ],
    builder: (context, controller, child) {
      final onPressed = controller.isOpen ? controller.close : controller.open;
      Widget defaultBuilder(BuildContext context, VoidCallback onPressed) =>
          IconButton(
            focusNode: _focusNode,
            style: _kCompactIconButtonStyle,
            tooltip: widget.tooltip,
            icon: widget.icon,
            iconSize: widget.style.iconSize,
            onPressed: onPressed,
          );
      return widget.overflowButtonBuilder?.call(
            context,
            onPressed,
            defaultBuilder,
          ) ??
          defaultBuilder(context, onPressed);
    },
  );
}

final class _MaterialMenuEntry<T extends Object> extends StatelessWidget {
  const _MaterialMenuEntry({
    required this.entry,
    required this.onInvoke,
    required this.iconBuilder,
    required this.menuAnimationEnabled,
  });

  final AdaptiveMenuEntry<T> entry;
  final ValueChanged<T> onInvoke;
  final MaterialActionIconBuilder<T>? iconBuilder;
  final bool menuAnimationEnabled;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    if (entry is AdaptiveMenuDivider<T>) {
      return entry.showInMenu
          ? const PopupMenuDivider()
          : const SizedBox.shrink();
    }
    final action = entry as AdaptiveAction<T>;
    if (action.children.isEmpty || !action.isEnabled) {
      return _MaterialMenuInvokeItem<T>(
        action: action,
        onInvoke: onInvoke,
        iconBuilder: iconBuilder,
        showsSubmenuAffordance: action.children.isNotEmpty,
      );
    }

    return _MaterialSubmenuItem<T>(
      action: action,
      onInvoke: onInvoke,
      iconBuilder: iconBuilder,
      menuAnimationEnabled: menuAnimationEnabled,
    );
  }
}

bool _materialMenuEntryIsVisible<T extends Object>(
  AdaptiveMenuEntry<T> entry,
) => entry is! AdaptiveMenuDivider<T> || entry.showInMenu;

String? _materialMenuSemanticsLabel(ActionMetadata metadata) =>
    metadata.semanticLabel ??
    (metadata.subtitle == null ? metadata.label : null);

final class _MaterialMenuLabel<T extends Object> extends StatelessWidget {
  const _MaterialMenuLabel({required this.action});

  final AdaptiveAction<T> action;

  @override
  Widget build(BuildContext context) {
    final subtitle = action.metadata.subtitle;
    if (subtitle == null) {
      return Text(action.metadata.label);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final subtitleColor = action.isEnabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface.withValues(alpha: 0.38);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(action.metadata.label),
        DefaultTextStyle.merge(
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
          child: Text(subtitle),
        ),
      ],
    );
  }
}

final class _MaterialMenuInvokeItem<T extends Object> extends StatelessWidget {
  const _MaterialMenuInvokeItem({
    required this.action,
    required this.onInvoke,
    required this.iconBuilder,
    this.showsSubmenuAffordance = false,
  });

  final AdaptiveAction<T> action;
  final ValueChanged<T> onInvoke;
  final MaterialActionIconBuilder<T>? iconBuilder;
  final bool showsSubmenuAffordance;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final tooltip = action.metadata.tooltip ?? action.metadata.label;
    return Tooltip(
      message: tooltip,
      child: MenuItemButton(
        semanticsLabel: _materialMenuSemanticsLabel(action.metadata),
        leadingIcon: iconBuilder?.call(context, action),
        trailingIcon: showsSubmenuAffordance
            ? const Icon(Icons.arrow_right)
            : null,
        style: action.metadata.isDestructive
            ? MenuItemButton.styleFrom(foregroundColor: error, iconColor: error)
            : null,
        onPressed: action.isEnabled && action.payload != null
            ? () => invokeAdaptiveAction(action, onInvoke)
            : null,
        child: _MaterialMenuLabel(action: action),
      ),
    );
  }
}

final class _MaterialSubmenuItem<T extends Object> extends StatelessWidget {
  const _MaterialSubmenuItem({
    required this.action,
    required this.onInvoke,
    required this.iconBuilder,
    required this.menuAnimationEnabled,
  });

  final AdaptiveAction<T> action;
  final ValueChanged<T> onInvoke;
  final MaterialActionIconBuilder<T>? iconBuilder;
  final bool menuAnimationEnabled;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final tooltip = action.metadata.tooltip ?? action.metadata.label;
    return Semantics(
      label: _materialMenuSemanticsLabel(action.metadata),
      excludeSemantics: action.metadata.semanticLabel != null,
      child: Tooltip(
        message: tooltip,
        child: SubmenuButton(
          animated: menuAnimationEnabled,
          leadingIcon: iconBuilder?.call(context, action),
          style: action.metadata.isDestructive
              ? SubmenuButton.styleFrom(
                  foregroundColor: error,
                  iconColor: error,
                )
              : null,
          menuChildren: [
            if (action.payload != null)
              _MaterialMenuInvokeItem<T>(
                action: action,
                onInvoke: onInvoke,
                iconBuilder: iconBuilder,
              ),
            for (final child in action.children)
              if (_materialMenuEntryIsVisible(child))
                _MaterialMenuEntry<T>(
                  entry: child,
                  onInvoke: onInvoke,
                  iconBuilder: iconBuilder,
                  menuAnimationEnabled: menuAnimationEnabled,
                ),
          ],
          child: _MaterialMenuLabel(action: action),
        ),
      ),
    );
  }
}

final class _CustomizableMaterialActionButton<T extends Object>
    extends StatelessWidget {
  const _CustomizableMaterialActionButton({
    required this.action,
    required this.visual,
    required this.optionId,
    required this.onPressed,
    required this.builder,
    required this.style,
    this.optionTransition,
  });

  final AdaptiveAction<T> action;
  final _MaterialActionVisual<T> visual;
  final ActionLayoutOptionId optionId;
  final VoidCallback? onPressed;
  final MaterialActionButtonBuilder<T>? builder;
  final MaterialAdaptiveActionsStyle style;
  final _MaterialOptionTransition? optionTransition;

  @override
  Widget build(BuildContext context) {
    Widget defaultBuilder(
      BuildContext context,
      AdaptiveAction<T> action,
      VoidCallback? onPressed,
    ) => _MaterialActionButton<T>(
      action: action,
      visual: visual,
      optionId: optionId,
      onPressed: onPressed,
      style: style,
      optionTransition: optionTransition,
    );

    return builder?.call(context, action, onPressed, defaultBuilder) ??
        defaultBuilder(context, action, onPressed);
  }
}

final class _MaterialActionButton<T extends Object> extends StatelessWidget {
  const _MaterialActionButton({
    required this.action,
    required this.visual,
    required this.optionId,
    required this.onPressed,
    required this.style,
    this.optionTransition,
  });

  final AdaptiveAction<T> action;
  final _MaterialActionVisual<T> visual;
  final ActionLayoutOptionId optionId;
  final VoidCallback? onPressed;
  final MaterialAdaptiveActionsStyle style;
  final _MaterialOptionTransition? optionTransition;

  @override
  Widget build(BuildContext context) {
    if (optionId != _materialLabelOptionId &&
        optionId != _materialIconOptionId) {
      throw StateError(
        'No Material layout is registered for option $optionId on action '
        '${action.id}.',
      );
    }
    final optionTransition = this.optionTransition;
    if (optionTransition != null) {
      return _AnimatedMaterialActionButton<T>(
        action: action,
        visual: visual,
        onPressed: onPressed,
        style: style,
        transition: optionTransition,
      );
    }
    final tooltip = action.metadata.tooltip ?? action.metadata.label;
    if (optionId == _materialIconOptionId) {
      return Tooltip(
        message: tooltip,
        child: SizedBox(
          width: style.iconButtonWidth,
          height: style.height,
          child: IconButton(
            style: _kCompactIconButtonStyle,
            icon: visual.icon!,
            iconSize: style.iconSize,
            color: action.metadata.isDestructive
                ? Theme.of(context).colorScheme.error
                : null,
            onPressed: action.isEnabled ? onPressed : null,
          ),
        ),
      );
    }

    final textStyle = action.metadata.isDestructive
        ? TextStyle(color: Theme.of(context).colorScheme.error)
        : null;
    final label = Text(action.metadata.label, style: textStyle);
    final child = visual.icon == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(
                  end: style.iconLabelSpacing,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(size: style.iconSize),
                  child: visual.icon!,
                ),
              ),
              label,
            ],
          );

    return Tooltip(
      message: tooltip,
      child: TextButton(
        onPressed: action.isEnabled ? onPressed : null,
        style: TextButton.styleFrom(
          minimumSize: Size(style.minimumButtonWidth, style.height),
          padding: EdgeInsets.symmetric(horizontal: style.horizontalPadding),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: child,
      ),
    );
  }
}

final class _AnimatedMaterialActionButton<T extends Object>
    extends StatelessWidget {
  const _AnimatedMaterialActionButton({
    required this.action,
    required this.visual,
    required this.onPressed,
    required this.style,
    required this.transition,
  });

  final AdaptiveAction<T> action;
  final _MaterialActionVisual<T> visual;
  final VoidCallback? onPressed;
  final MaterialAdaptiveActionsStyle style;
  final _MaterialOptionTransition transition;

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
      final targetHasLabel = transition.to == _materialLabelOptionId;
      final labelProgress = targetHasLabel
          ? transition.fadeProgress.value
          : 1 - transition.fadeProgress.value;
      final error = Theme.of(context).colorScheme.error;
      final tooltip = action.metadata.tooltip ?? action.metadata.label;
      return Tooltip(
        message: tooltip,
        child: SizedBox(
          width: width,
          height: style.height,
          child: TextButton(
            onPressed: action.isEnabled ? onPressed : null,
            style: TextButton.styleFrom(
              foregroundColor: action.metadata.isDestructive ? error : null,
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(
                horizontal: style.horizontalPadding,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTheme.merge(
                      data: IconThemeData(size: style.iconSize),
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
                            child: Text(action.metadata.label),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  double _invokeWidth(ActionLayoutOptionId optionId) {
    final total = visual.costFor(optionId);
    final isComposite = action.payload != null && action.children.isNotEmpty;
    return isComposite ? total - style.submenuButtonWidth : total;
  }
}

final class _MaterialActionVisual<T extends Object> {
  _MaterialActionVisual({
    required AdaptiveAction<T> action,
    required this.icon,
    required double labelWidth,
    required MaterialActionPresentation? presentationOverride,
    required MaterialAdaptiveActionsStyle style,
  }) : _options = _buildOptions(
         action: action,
         icon: icon,
         labelWidth: labelWidth,
         style: style,
       ) {
    final options = switch (presentationOverride) {
      null => [_options.extended, ?_options.iconOnly],
      MaterialActionPresentation.extended => [_options.extended],
      MaterialActionPresentation.iconOnly => [
        _options.iconOnly ?? _options.extended,
      ],
    };
    profile = ActionLayoutProfile(actionId: action.id, options: options);
  }

  final Widget? icon;
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
        'No Material layout is registered for option $optionId on action '
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
    required MaterialAdaptiveActionsStyle style,
  }) => (
    extended: ActionLayoutOption(
      id: _materialLabelOptionId,
      cost: _labelCost(
        labelWidth,
        hasIcon: icon != null,
        isComposite: action.payload != null && action.children.isNotEmpty,
        style: style,
      ),
    ),
    iconOnly: icon == null
        ? null
        : ActionLayoutOption(
            id: _materialIconOptionId,
            cost: _iconCost(
              isComposite: action.payload != null && action.children.isNotEmpty,
              style: style,
            ),
          ),
  );

  static double _labelCost(
    double labelWidth, {
    required bool hasIcon,
    required bool isComposite,
    required MaterialAdaptiveActionsStyle style,
  }) {
    final invokeCost =
        (labelWidth +
                style.horizontalPadding * 2 +
                (hasIcon ? style.iconSize + style.iconLabelSpacing : 0))
            .clamp(style.minimumButtonWidth, double.infinity);
    return isComposite ? invokeCost + style.submenuButtonWidth : invokeCost;
  }

  static double _iconCost({
    required bool isComposite,
    required MaterialAdaptiveActionsStyle style,
  }) => isComposite
      ? style.iconButtonWidth + style.submenuButtonWidth
      : style.iconButtonWidth;
}
