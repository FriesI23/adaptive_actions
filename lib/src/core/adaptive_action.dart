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

  /// Creates a divider that is drawn only inside menus.
  const AdaptiveMenuDivider.menuOnly()
    : showInPrimary = false,
      showInMenu = true;

  /// Creates a divider that is drawn only between primary actions.
  const AdaptiveMenuDivider.primaryOnly()
    : showInPrimary = true,
      showInMenu = false;

  /// Creates a declared divider that is not drawn in either target.
  const AdaptiveMenuDivider.hidden()
    : showInPrimary = false,
      showInMenu = false;

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
/// A node can carry an invocation [payload], menu structure, or both. Menu
/// structure is explicit through [hasMenu], while its content can come from
/// declared [children] or a platform renderer's action-menu builder. Moving a
/// node never changes or flattens its declared children. Core never invokes
/// [payload]. A renderer hands an enabled node's payload back to a caller-owned
/// handler and preserves menu navigation as a separate interaction.
///
/// ```text
/// action       payload
/// menu                  -> declared or renderer-provided content
/// composite    payload  -> declared or renderer-provided content
/// ```
final class AdaptiveAction<T extends Object> extends AdaptiveMenuEntry<T> {
  AdaptiveAction._({
    required this.id,
    required this.metadata,
    required this.isEnabled,
    required this.placementPolicy,
    required this.payload,
    required this.hasMenu,
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
    hasMenu: false,
    children: const [],
  );

  /// Creates a branch that opens [children] without invoking a payload.
  ///
  /// [children] may be empty when a platform renderer supplies this action's
  /// complete menu through its action-menu builder.
  ///
  /// Throws an [ArgumentError] when a non-empty [children] list contains only
  /// dividers.
  factory AdaptiveAction.menu({
    required ActionId id,
    required ActionMetadata metadata,
    Iterable<AdaptiveMenuEntry<T>> children = const [],
    bool isEnabled = true,
    ActionPlacementPolicy? placementPolicy,
  }) {
    final immutableChildren = List<AdaptiveMenuEntry<T>>.unmodifiable(children);
    _requireValidChildren(immutableChildren);
    return AdaptiveAction._(
      id: id,
      metadata: metadata,
      isEnabled: isEnabled,
      placementPolicy: placementPolicy ?? ActionPlacementPolicy(),
      payload: null,
      hasMenu: true,
      children: immutableChildren,
    );
  }

  /// Creates a branch that can both invoke [payload] and open [children].
  ///
  /// [children] may be empty when a platform renderer supplies this action's
  /// complete menu through its action-menu builder.
  ///
  /// Throws an [ArgumentError] when a non-empty [children] list contains only
  /// dividers.
  factory AdaptiveAction.composite({
    required ActionId id,
    required ActionMetadata metadata,
    required T payload,
    Iterable<AdaptiveMenuEntry<T>> children = const [],
    bool isEnabled = true,
    ActionPlacementPolicy? placementPolicy,
  }) {
    final immutableChildren = List<AdaptiveMenuEntry<T>>.unmodifiable(children);
    _requireValidChildren(immutableChildren);
    return AdaptiveAction._(
      id: id,
      metadata: metadata,
      isEnabled: isEnabled,
      placementPolicy: placementPolicy ?? ActionPlacementPolicy(),
      payload: payload,
      hasMenu: true,
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

  /// Whether this node opens a menu independently of its invocation payload.
  ///
  /// This is `true` for nodes created with [AdaptiveAction.menu] and
  /// [AdaptiveAction.composite], including when [children] is empty because a
  /// platform renderer supplies the complete menu content.
  final bool hasMenu;

  /// The node's menu entries in declaration order.
  ///
  /// Entries may be nested [AdaptiveAction]s or visual
  /// [AdaptiveMenuDivider]s. Dividers are rendered only inside this node's
  /// menu and never participate in root placement. This list may be empty when
  /// [hasMenu] is true and a platform renderer supplies the complete content.
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
          hasMenu == other.hasMenu &&
          const ListEquality<Object?>().equals(children, other.children);

  @override
  int get hashCode => Object.hash(
    id,
    metadata,
    isEnabled,
    placementPolicy,
    payload,
    hasMenu,
    const ListEquality<Object?>().hash(children),
  );

  @override
  String toString() =>
      'AdaptiveAction(id: $id, isEnabled: $isEnabled, '
      'placementPolicy: $placementPolicy, '
      'isInvokable: $isInvokable, hasMenu: $hasMenu, '
      'children: ${children.length})';

  static void _requireValidChildren<T extends Object>(
    List<AdaptiveMenuEntry<T>> children,
  ) {
    if (children.isNotEmpty &&
        !children.any((entry) => entry is AdaptiveAction<T>)) {
      throw ArgumentError.value(children, 'children', 'must contain an action');
    }
  }
}
