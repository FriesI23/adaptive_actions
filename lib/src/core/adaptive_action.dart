import 'package:collection/collection.dart';

import 'action_id.dart';
import 'action_metadata.dart';
import 'action_placement_policy.dart';

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
final class AdaptiveAction<T extends Object> {
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
    required Iterable<AdaptiveAction<T>> children,
    bool isEnabled = true,
    ActionPlacementPolicy? placementPolicy,
  }) {
    final immutableChildren = List<AdaptiveAction<T>>.unmodifiable(children);
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
    required Iterable<AdaptiveAction<T>> children,
    bool isEnabled = true,
    ActionPlacementPolicy? placementPolicy,
  }) {
    final immutableChildren = List<AdaptiveAction<T>>.unmodifiable(children);
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

  /// The node's children in declaration order.
  final List<AdaptiveAction<T>> children;

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

  static void _requireChildren(List<Object> children) {
    if (children.isEmpty) {
      throw ArgumentError.value(children, 'children', 'must not be empty');
    }
  }
}
