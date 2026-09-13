/// A rendered surface that can show an action tooltip.
enum ActionTooltipSurface {
  /// An icon-only primary control.
  primaryIconOnly,

  /// A label-bearing primary control.
  primaryLabeled,

  /// An overflow or nested menu item.
  menuItem,
}

/// Selects the rendered surfaces that show an action tooltip.
///
/// The default shows tooltips only for icon-only controls. This keeps a label
/// from being repeated when it is already visible while preserving a textual
/// explanation for icon-only affordances.
final class ActionTooltipPolicy {
  /// Allows tooltips only on the selected rendered surfaces.
  ///
  /// With no overrides, this uses the package default of allowing only
  /// [ActionTooltipSurface.primaryIconOnly].
  const ActionTooltipPolicy.allowed({
    bool primaryIconOnly = true,
    bool primaryLabeled = false,
    bool menuItem = false,
  }) : _primaryIconOnly = primaryIconOnly,
       _primaryLabeled = primaryLabeled,
       _menuItem = menuItem;

  /// Allows tooltips on every rendered surface except the selected ones.
  ///
  /// With no overrides, this describes the same package default as
  /// [ActionTooltipPolicy.allowed]: labeled primary controls and menu items are
  /// denied while icon-only primary controls remain allowed.
  const ActionTooltipPolicy.denied({
    bool primaryIconOnly = false,
    bool primaryLabeled = true,
    bool menuItem = true,
  }) : _primaryIconOnly = !primaryIconOnly,
       _primaryLabeled = !primaryLabeled,
       _menuItem = !menuItem;

  /// Shows the tooltip on every action-owned surface.
  const ActionTooltipPolicy.always()
    : this.allowed(primaryIconOnly: true, primaryLabeled: true, menuItem: true);

  /// Never shows a visual tooltip for the action.
  const ActionTooltipPolicy.never()
    : this.allowed(
        primaryIconOnly: false,
        primaryLabeled: false,
        menuItem: false,
      );

  final bool _primaryIconOnly;
  final bool _primaryLabeled;
  final bool _menuItem;

  /// Whether the action tooltip is allowed on [surface].
  bool allows(ActionTooltipSurface surface) => switch (surface) {
    ActionTooltipSurface.primaryIconOnly => _primaryIconOnly,
    ActionTooltipSurface.primaryLabeled => _primaryLabeled,
    ActionTooltipSurface.menuItem => _menuItem,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionTooltipPolicy &&
          _primaryIconOnly == other._primaryIconOnly &&
          _primaryLabeled == other._primaryLabeled &&
          _menuItem == other._menuItem;

  @override
  int get hashCode => Object.hash(_primaryIconOnly, _primaryLabeled, _menuItem);

  @override
  String toString() =>
      'ActionTooltipPolicy(primaryIconOnly: $_primaryIconOnly, '
      'primaryLabeled: $_primaryLabeled, menuItem: $_menuItem)';
}

/// User-facing text and renderer lookup data for an action.
final class ActionMetadata {
  /// Creates the descriptive data shared by every renderer.
  const ActionMetadata({
    required this.label,
    this.subtitle,
    this.tooltip,
    this.tooltipPolicy = const ActionTooltipPolicy.allowed(),
    this.semanticLabel,
    this.iconKey,
    this.isDestructive = false,
  });

  /// The action's user-visible label.
  final String label;

  /// Optional supporting text shown below [label] in menu items.
  ///
  /// Primary action buttons do not display this value.
  final String? subtitle;

  /// Optional text shown on hover or long press by a renderer.
  ///
  /// When omitted, renderers use [label]. [tooltipPolicy] decides which
  /// action-owned surfaces expose the resolved text as a visual tooltip.
  final String? tooltip;

  /// Selects where this action shows its visual tooltip.
  ///
  /// The global overflow trigger is not action-owned and continues to use the
  /// renderer's separate `overflowTooltip` configuration.
  final ActionTooltipPolicy tooltipPolicy;

  /// Optional accessibility label that overrides the visible menu text.
  final String? semanticLabel;

  /// The optional key a renderer uses to look up an icon.
  final String? iconKey;

  /// Whether invoking this action can cause irreversible loss.
  final bool isDestructive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionMetadata &&
          label == other.label &&
          subtitle == other.subtitle &&
          tooltip == other.tooltip &&
          tooltipPolicy == other.tooltipPolicy &&
          semanticLabel == other.semanticLabel &&
          iconKey == other.iconKey &&
          isDestructive == other.isDestructive;

  @override
  int get hashCode => Object.hash(
    label,
    subtitle,
    tooltip,
    tooltipPolicy,
    semanticLabel,
    iconKey,
    isDestructive,
  );

  @override
  String toString() =>
      'ActionMetadata(label: $label, subtitle: $subtitle, tooltip: $tooltip, '
      'tooltipPolicy: $tooltipPolicy, semanticLabel: $semanticLabel, '
      'iconKey: $iconKey, '
      'isDestructive: $isDestructive)';
}
