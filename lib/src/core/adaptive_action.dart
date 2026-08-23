import 'package:collection/collection.dart';

import 'action_id.dart';
import 'action_metadata.dart';
import 'action_placement_policy.dart';

/// A platform-neutral entry in an adaptive action declaration.
///
/// Menu entries are either invokable/navigable [AdaptiveAction] nodes or
/// visual [AdaptiveMenuDivider]s. Only actions participate in primary,
/// overflow, or hidden placement.
sealed class AdaptiveMenuEntry<T extends Object> {
  const AdaptiveMenuEntry();
}

/// A visual separator between groups of adaptive action entries.
///
/// A divider has no identity, payload, enabled state, or placement policy. It
/// marks a boundary in declaration order. Nested dividers render in their
/// containing action's menu; top-level dividers can render between primary
/// actions and between overflow menu entries.
final class AdaptiveMenuDivider<T extends Object> extends AdaptiveMenuEntry<T> {
  /// Creates a menu divider.
  const AdaptiveMenuDivider({
    this.showInPrimary = true,
    this.showInMenu = true,
  });

  /// Whether a top-level divider is drawn between primary actions.
  ///
  /// This has no effect when the divider is nested inside an action menu.
  final bool showInPrimary;

  /// Whether the divider is drawn inside action and overflow menus.
  final bool showInMenu;

  @override
  bool operator ==(Object other) =>
      other is AdaptiveMenuDivider<T> &&
      showInPrimary == other.showInPrimary &&
      showInMenu == other.showInMenu;

  @override
  int get hashCode => Object.hash(runtimeType, showInPrimary, showInMenu);

  @override
  String toString() =>
      'AdaptiveMenuDivider<$T>(showInPrimary: $showInPrimary, '
      'showInMenu: $showInMenu)';
}

/// An immutable, platform-neutral action node.
///
/// A node can carry an invocation [payload], [children], or both. Renderers
/// decide how to present the node in its resolved region; moving a node never
/// changes or flattens its children. Core never invokes [payload]. A renderer
/// hands an enabled node's payload back to a caller-owned handler and preserves
/// child navigation as a separate interaction.
///
/// ```text
/// action       payload
/// menu                  -> child -> child
/// composite    payload  -> child -> child
/// ```
final class AdaptiveAction<T extends Object> extends AdaptiveMenuEntry<T> {
  AdaptiveAction._({
    required this.id,
    required this.metadata,
    required this.isEnabled,
    required this.placementPolicy,
    required this.payload,
    required this.children,
  });

  /// Creates a leaf that invokes [payload].
  factory AdaptiveAction.action({
    required ActionId id,
    required ActionMetadata metadata,
    required T payload,
    bool isEnabled = true,
    ActionPlacementPolicy? placementPolicy,
  }) => AdaptiveAction._(
    id: id,
    metadata: metadata,
    isEnabled: isEnabled,
    placementPolicy: placementPolicy ?? ActionPlacementPolicy(),
    payload: payload,
    children: const [],
  );

  /// Creates a branch that opens [children] without invoking a payload.
  ///
  /// Throws an [ArgumentError] when [children] is empty.
  factory AdaptiveAction.menu({
    required ActionId id,
    required ActionMetadata metadata,
    required Iterable<AdaptiveMenuEntry<T>> children,
    bool isEnabled = true,
    ActionPlacementPolicy? placementPolicy,
  }) {
    final immutableChildren = List<AdaptiveMenuEntry<T>>.unmodifiable(children);
    _requireChildren(immutableChildren);
    return AdaptiveAction._(
      id: id,
      metadata: metadata,
      isEnabled: isEnabled,
      placementPolicy: placementPolicy ?? ActionPlacementPolicy(),
      payload: null,
      children: immutableChildren,
    );
  }

  /// Creates a branch that can both invoke [payload] and open [children].
  ///
  /// Throws an [ArgumentError] when [children] is empty.
  factory AdaptiveAction.composite({
    required ActionId id,
    required ActionMetadata metadata,
    required T payload,
    required Iterable<AdaptiveMenuEntry<T>> children,
    bool isEnabled = true,
    ActionPlacementPolicy? placementPolicy,
  }) {
    final immutableChildren = List<AdaptiveMenuEntry<T>>.unmodifiable(children);
    _requireChildren(immutableChildren);
    return AdaptiveAction._(
      id: id,
      metadata: metadata,
      isEnabled: isEnabled,
      placementPolicy: placementPolicy ?? ActionPlacementPolicy(),
      payload: payload,
      children: immutableChildren,
    );
  }

  /// The node's identity across rebuilds and resolution passes.
  final ActionId id;

  /// User-facing text and renderer lookup data.
  final ActionMetadata metadata;

  /// Whether the node can currently be invoked or opened.
  ///
  /// A renderer must suppress both payload invocation and child navigation
  /// while this is `false`.
  final bool isEnabled;

  /// Placement behavior used when this node is a collection root.
  ///
  /// Resolution reads this policy only when the node is a collection root.
  /// Children always move with their complete subtree.
  final ActionPlacementPolicy placementPolicy;

  /// The invocation value owned and interpreted by the caller.
  ///
  /// This is `null` only for a node created with [AdaptiveAction.menu]. Core
  /// stores and returns this value without executing it or interpreting its
  /// type.
  final T? payload;

  /// The node's menu entries in declaration order.
  ///
  /// Entries may be nested [AdaptiveAction]s or visual
  /// [AdaptiveMenuDivider]s. Dividers are rendered only inside this node's
  /// menu and never participate in root placement.
  final List<AdaptiveMenuEntry<T>> children;

  /// Whether this node carries an invocation payload.
  bool get isInvokable => payload != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveAction<T> &&
          id == other.id &&
          metadata == other.metadata &&
          isEnabled == other.isEnabled &&
          placementPolicy == other.placementPolicy &&
          payload == other.payload &&
          const ListEquality<Object?>().equals(children, other.children);

  @override
  int get hashCode => Object.hash(
    id,
    metadata,
    isEnabled,
    placementPolicy,
    payload,
    const ListEquality<Object?>().hash(children),
  );

  @override
  String toString() =>
      'AdaptiveAction(id: $id, isEnabled: $isEnabled, '
      'placementPolicy: $placementPolicy, '
      'isInvokable: $isInvokable, children: ${children.length})';

  static void _requireChildren<T extends Object>(
    List<AdaptiveMenuEntry<T>> children,
  ) {
    if (children.isEmpty) {
      throw ArgumentError.value(children, 'children', 'must not be empty');
    }
    if (!children.any((entry) => entry is AdaptiveAction<T>)) {
      throw ArgumentError.value(children, 'children', 'must contain an action');
    }
  }
}
