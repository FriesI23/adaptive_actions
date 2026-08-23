/// User-facing text and renderer lookup data for an action.
final class ActionMetadata {
  /// Creates the descriptive data shared by every renderer.
  const ActionMetadata({
    required this.label,
    this.subtitle,
    this.tooltip,
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
  final String? tooltip;

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
          semanticLabel == other.semanticLabel &&
          iconKey == other.iconKey &&
          isDestructive == other.isDestructive;

  @override
  int get hashCode => Object.hash(
    label,
    subtitle,
    tooltip,
    semanticLabel,
    iconKey,
    isDestructive,
  );

  @override
  String toString() =>
      'ActionMetadata(label: $label, subtitle: $subtitle, tooltip: $tooltip, '
      'semanticLabel: $semanticLabel, iconKey: $iconKey, '
      'isDestructive: $isDestructive)';
}
