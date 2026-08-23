/// Interaction features available from an action renderer.
///
/// These flags describe behavior, not layout. Widget shapes and their measured
/// costs belong in `ActionLayoutProfile`.
final class RendererCapabilities {
  /// Creates a description of the renderer's supported interactions.
  const RendererCapabilities({this.supportsCompositeActions = false});

  /// Whether payload-plus-children nodes have a native combined interaction.
  ///
  /// A value of `false` does not make composite nodes invalid. Renderers remain
  /// responsible for preserving both behaviors through a suitable fallback,
  /// such as separate invoke and submenu affordances. Core keeps the composite
  /// subtree intact in either case.
  final bool supportsCompositeActions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RendererCapabilities &&
          supportsCompositeActions == other.supportsCompositeActions;

  @override
  int get hashCode => supportsCompositeActions.hashCode;

  @override
  String toString() =>
      'RendererCapabilities(supportsCompositeActions: '
      '$supportsCompositeActions)';
}
