/// How strongly an automatic action should be retained in primary.
///
/// Higher values are retained in the primary region before lower values.
///
/// ```text
/// primary retention:  high  ->  normal  ->  low
/// move to overflow:    low   ->  normal  ->  high
/// ```
extension type const PrimaryRetentionPriority.custom(int value) {
  /// A commonly used priority for actions that may leave primary early.
  static const low = PrimaryRetentionPriority.custom(-100);

  /// The default priority for actions without special importance.
  static const normal = PrimaryRetentionPriority.custom(0);

  /// A commonly used priority for actions that should leave primary late.
  static const high = PrimaryRetentionPriority.custom(100);

  /// The numeric ordering relative to [other].
  int compareTo(PrimaryRetentionPriority other) => value.compareTo(other.value);
}

/// The layout region policy for an adaptive action.
///
/// The diagrams use `A` for one root action and show its possible resolved
/// region. The renderer decides the actual Widget appearance.
enum ActionPlacement {
  /// The action must remain in the primary region.
  ///
  /// Capacity constraints may produce a diagnostic, but never move the action.
  ///
  /// ```text
  /// primary:   [A]
  /// overflow:
  /// hidden:
  /// ```
  pinned,

  /// The resolver may place the action based on its automatic preference.
  ///
  /// ```text
  /// enough space                 limited space
  /// primary:   [A]               primary:
  /// overflow:                    overflow:  [A]
  ///
  /// If hiding is allowed, limited space may use hidden [A] instead.
  /// ```
  automatic,

  /// The action must remain in the overflow region.
  ///
  /// ```text
  /// primary:
  /// overflow:  [A]
  /// hidden:
  /// ```
  overflowOnly,

  /// The action must not be exposed to the user.
  ///
  /// ```text
  /// primary:
  /// overflow:
  /// hidden:    [A]
  /// ```
  hidden,
}

/// Automatic-placement preferences used when primary space is limited.
final class AutomaticPlacementPreference {
  /// Creates automatic-placement preferences.
  AutomaticPlacementPreference({
    this.retentionPriority = PrimaryRetentionPriority.normal,
    this.allowsHiding = false,
  });

  /// Higher values are retained in primary before lower values.
  final PrimaryRetentionPriority retentionPriority;

  /// Whether the action may be hidden instead of exposed through overflow.
  final bool allowsHiding;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutomaticPlacementPreference &&
          retentionPriority == other.retentionPriority &&
          allowsHiding == other.allowsHiding;

  @override
  int get hashCode => Object.hash(retentionPriority, allowsHiding);

  @override
  String toString() =>
      'AutomaticPlacementPreference(retentionPriority: $retentionPriority, '
      'allowsHiding: $allowsHiding)';
}

/// The placement rule for one root action.
final class ActionPlacementPolicy {
  /// Creates a placement policy, defaulting to automatic placement.
  ///
  /// Automatic policies receive a default [AutomaticPlacementPreference] when
  /// none is supplied. Fixed placement policies reject automatic preferences
  /// because the two concepts are intentionally orthogonal.
  ActionPlacementPolicy({
    this.placement = ActionPlacement.automatic,
    AutomaticPlacementPreference? automaticPreference,
  }) : automaticPreference = switch (placement) {
         ActionPlacement.automatic =>
           automaticPreference ?? AutomaticPlacementPreference(),
         _ => automaticPreference,
       } {
    if (placement != ActionPlacement.automatic &&
        this.automaticPreference != null) {
      throw ArgumentError.value(
        this.automaticPreference,
        'automaticPreference',
        'is only valid for automatic placement',
      );
    }
  }

  /// The region rule considered before capacity-based placement.
  final ActionPlacement placement;

  /// Retention and hiding preferences for automatic placement; otherwise null.
  final AutomaticPlacementPreference? automaticPreference;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionPlacementPolicy &&
          placement == other.placement &&
          automaticPreference == other.automaticPreference;

  @override
  int get hashCode => Object.hash(placement, automaticPreference);

  @override
  String toString() =>
      'ActionPlacementPolicy(placement: $placement, '
      'automaticPreference: $automaticPreference)';
}
