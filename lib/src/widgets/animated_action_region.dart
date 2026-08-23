import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// The structural role of an item in an [AnimatedActionRegion].
@internal
enum AnimatedActionRegionItemRole { action, overflow }

/// One renderer-owned item consumed by [AnimatedActionRegion].
///
/// This type is package-internal. Renderers retain ownership of [data] and
/// [child]; the shared region uses only [id], [variant], [role], and [width] to
/// plan a single boundary transition.
@internal
@immutable
final class AnimatedActionRegionItem<T extends Object> {
  const AnimatedActionRegionItem({
    required this.id,
    required this.variant,
    required this.role,
    required this.width,
    required this.data,
    required this.child,
  }) : assert(width >= 0 && width < double.infinity);

  final Object id;
  final Object variant;
  final AnimatedActionRegionItemRole role;
  final double width;
  final T data;
  final Widget child;
}

/// Builds a renderer-specific transition between variants of the same item.
@internal
typedef AnimatedActionRegionVariantBuilder<T extends Object> =
    Widget Function(
      BuildContext context,
      AnimatedActionRegionItem<T> from,
      AnimatedActionRegionItem<T> to,
      Animation<double> fadeProgress,
      Animation<double> resizeProgress,
    );

/// Animates one changing boundary while keeping stable action items untouched.
///
/// This package-internal widget contains no Material, Cupertino, or core action
/// types. A renderer supplies already resolved items and optionally describes
/// how two variants of the same item morph. At most one outgoing and one
/// incoming child are retained.
@internal
final class AnimatedActionRegion<T extends Object> extends StatefulWidget {
  const AnimatedActionRegion({
    super.key,
    required this.items,
    required this.height,
    required this.fadeDuration,
    required this.resizeDuration,
    required this.switchInCurve,
    required this.switchOutCurve,
    this.variantBuilder,
  }) : assert(height > 0 && height < double.infinity);

  final List<AnimatedActionRegionItem<T>> items;
  final double height;
  final Duration fadeDuration;
  final Duration resizeDuration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final AnimatedActionRegionVariantBuilder<T>? variantBuilder;

  @override
  State<AnimatedActionRegion<T>> createState() =>
      _AnimatedActionRegionState<T>();
}

final class _AnimatedActionRegionState<T extends Object>
    extends State<AnimatedActionRegion<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  _ActionRegionTransition<T>? _transition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _transition = null);
        }
      });
  }

  @override
  void didUpdateWidget(AnimatedActionRegion<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_animationsEnabled) {
      _controller.stop();
      _transition = null;
      return;
    }
    if (_sameLayout(oldWidget, widget)) {
      if (oldWidget.fadeDuration != widget.fadeDuration ||
          oldWidget.resizeDuration != widget.resizeDuration) {
        _controller.stop();
        _transition = null;
      }
      return;
    }

    final active = _transition;
    _controller.stop();
    _transition = null;
    var next = _ActionRegionTransition.between<T>(
      oldWidget.items,
      widget.items,
    );
    if (next == null) {
      return;
    }

    if (active != null &&
        active.isVariant &&
        widget.variantBuilder != null &&
        next.continuesFrom(active)) {
      next = next.withVariantSnapshot(
        active.snapshot(
          _controller.value,
          fadeDuration: oldWidget.fadeDuration,
          resizeDuration: oldWidget.resizeDuration,
          switchInCurve: oldWidget.switchInCurve,
          switchOutCurve: oldWidget.switchOutCurve,
        ),
      );
    }

    _transition = next;
    _controller.duration = _longerDuration(
      widget.fadeDuration,
      widget.resizeDuration,
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _animationsEnabled =>
      widget.fadeDuration != Duration.zero ||
      widget.resizeDuration != Duration.zero;

  bool _sameLayout(
    AnimatedActionRegion<T> oldRegion,
    AnimatedActionRegion<T> newRegion,
  ) {
    if (oldRegion.height != newRegion.height ||
        oldRegion.items.length != newRegion.items.length) {
      return false;
    }
    for (var index = 0; index < oldRegion.items.length; index += 1) {
      final oldItem = oldRegion.items[index];
      final newItem = newRegion.items[index];
      if (oldItem.id != newItem.id ||
          oldItem.variant != newItem.variant ||
          oldItem.role != newItem.role ||
          oldItem.width != newItem.width) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      for (final item in widget.items)
        _ActionRegionTargetItem<T>(
          key: ValueKey(item.id),
          item: item,
          height: widget.height,
        ),
    ];
    final transition = _transition;
    if (transition != null) {
      final transitionView = _ActionRegionTransitionView<T>(
        transition: transition,
        progress: _controller,
        height: widget.height,
        fadeDuration: widget.fadeDuration,
        resizeDuration: widget.resizeDuration,
        switchInCurve: widget.switchInCurve,
        switchOutCurve: widget.switchOutCurve,
        variantBuilder: widget.variantBuilder,
      );
      if (transition.replacesTarget) {
        children[transition.slotIndex] = transitionView;
      } else {
        children.insert(transition.slotIndex, transitionView);
      }
    }

    return SizedBox(
      height: widget.height,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

enum _ActionRegionTransitionKind { structural, variant }

final class _ActionRegionTransition<T extends Object> {
  const _ActionRegionTransition({
    required this.kind,
    required this.from,
    required this.to,
    required this.slotIndex,
    required this.isEntering,
    this.variantSnapshot,
  });

  static _ActionRegionTransition<T>? between<T extends Object>(
    List<AnimatedActionRegionItem<T>> oldItems,
    List<AnimatedActionRegionItem<T>> newItems,
  ) {
    final oldActions = _actions(oldItems);
    final newActions = _actions(newItems);
    final oldOverflow = _overflow(oldItems);
    final newOverflow = _overflow(newItems);
    final oldById = {for (final item in oldActions) item.id: item};
    final newById = {for (final item in newActions) item.id: item};

    final removed = oldActions
        .where((item) => !newById.containsKey(item.id))
        .toList();
    if (removed.isNotEmpty) {
      final selected = removed.first;
      final replacesWithOverflow =
          oldOverflow == null &&
          newOverflow != null &&
          oldActions.last.id == selected.id;
      return _ActionRegionTransition<T>(
        kind: _ActionRegionTransitionKind.structural,
        from: selected,
        to: replacesWithOverflow ? newOverflow : null,
        slotIndex: replacesWithOverflow
            ? newActions.length
            : _removalSlotIndex(selected, oldActions, newById.keys.toSet()),
        isEntering: false,
      );
    }

    final added = newActions
        .where((item) => !oldById.containsKey(item.id))
        .toList();
    if (added.isNotEmpty) {
      final selected = added.last;
      final replacesOverflow =
          added.length == 1 &&
          oldOverflow != null &&
          newOverflow == null &&
          newActions.last.id == selected.id;
      return _ActionRegionTransition<T>(
        kind: _ActionRegionTransitionKind.structural,
        from: replacesOverflow ? oldOverflow : null,
        to: selected,
        slotIndex: newActions.indexOf(selected),
        isEntering: true,
      );
    }

    final changed = newActions.where((item) {
      final oldItem = oldById[item.id];
      return oldItem != null && oldItem.variant != item.variant;
    }).toList();
    if (changed.isNotEmpty) {
      final isEntering = _totalWidth(newItems) > _totalWidth(oldItems);
      final selected = isEntering ? changed.last : changed.first;
      final oldItem = oldById[selected.id]!;
      return _ActionRegionTransition<T>(
        kind: _ActionRegionTransitionKind.variant,
        from: oldItem,
        to: selected,
        slotIndex: newActions.indexOf(selected),
        isEntering: isEntering,
      );
    }

    if ((oldOverflow == null) != (newOverflow == null)) {
      final isEntering = newOverflow != null;
      return _ActionRegionTransition<T>(
        kind: _ActionRegionTransitionKind.structural,
        from: isEntering ? null : oldOverflow,
        to: isEntering ? newOverflow : null,
        slotIndex: newActions.length,
        isEntering: isEntering,
      );
    }

    return null;
  }

  final _ActionRegionTransitionKind kind;
  final AnimatedActionRegionItem<T>? from;
  final AnimatedActionRegionItem<T>? to;
  final int slotIndex;
  final bool isEntering;
  final _ActionRegionVariantSnapshot<T>? variantSnapshot;

  bool get isVariant => kind == _ActionRegionTransitionKind.variant;
  bool get replacesTarget => to != null;

  bool continuesFrom(_ActionRegionTransition<T> active) =>
      slotIndex == active.slotIndex && _sameEndpoint(active.to, from);

  _ActionRegionTransition<T> withVariantSnapshot(
    _ActionRegionVariantSnapshot<T> snapshot,
  ) => _ActionRegionTransition<T>(
    kind: kind,
    from: from,
    to: to,
    slotIndex: slotIndex,
    isEntering: isEntering,
    variantSnapshot: snapshot,
  );

  _ActionRegionVariantSnapshot<T> snapshot(
    double rawProgress, {
    required Duration fadeDuration,
    required Duration resizeDuration,
    required Curve switchInCurve,
    required Curve switchOutCurve,
  }) {
    assert(isVariant);
    final totalDuration = _longerDuration(fadeDuration, resizeDuration);
    final curve = isEntering ? switchInCurve : switchOutCurve;
    final fadeProgress = _effectProgressValue(
      rawProgress,
      duration: fadeDuration,
      totalDuration: totalDuration,
      curve: curve,
    );
    var resizeProgress = _effectProgressValue(
      rawProgress,
      duration: resizeDuration,
      totalDuration: totalDuration,
      curve: curve,
    );
    if (resizeDuration == Duration.zero &&
        fadeDuration != Duration.zero &&
        !isEntering) {
      resizeProgress = fadeProgress == 1 ? 1 : 0;
    }
    final fromItem = from!;
    final toItem = to!;
    return _ActionRegionVariantSnapshot<T>(
      from: fromItem,
      to: toItem,
      fadeProgress: fadeProgress,
      resizeProgress: resizeProgress,
      width: _lerp(fromItem.width, toItem.width, resizeProgress),
    );
  }

  static List<AnimatedActionRegionItem<T>> _actions<T extends Object>(
    List<AnimatedActionRegionItem<T>> items,
  ) => items
      .where((item) => item.role == AnimatedActionRegionItemRole.action)
      .toList();

  static AnimatedActionRegionItem<T>? _overflow<T extends Object>(
    List<AnimatedActionRegionItem<T>> items,
  ) {
    for (final item in items) {
      if (item.role == AnimatedActionRegionItemRole.overflow) {
        return item;
      }
    }
    return null;
  }

  static int _removalSlotIndex<T extends Object>(
    AnimatedActionRegionItem<T> selected,
    List<AnimatedActionRegionItem<T>> oldActions,
    Set<Object> targetIds,
  ) {
    var index = 0;
    for (final item in oldActions) {
      if (item.id == selected.id) {
        return index;
      }
      if (targetIds.contains(item.id)) {
        index += 1;
      }
    }
    return index;
  }

  static double _totalWidth<T extends Object>(
    List<AnimatedActionRegionItem<T>> items,
  ) => items.fold<double>(0, (width, item) => width + item.width);

  static bool _sameEndpoint<T extends Object>(
    AnimatedActionRegionItem<T>? first,
    AnimatedActionRegionItem<T>? second,
  ) {
    if (first == null || second == null) {
      return first == null && second == null;
    }
    return first.id == second.id &&
        first.variant == second.variant &&
        first.width == second.width;
  }
}

final class _ActionRegionVariantSnapshot<T extends Object> {
  const _ActionRegionVariantSnapshot({
    required this.from,
    required this.to,
    required this.fadeProgress,
    required this.resizeProgress,
    required this.width,
  });

  final AnimatedActionRegionItem<T> from;
  final AnimatedActionRegionItem<T> to;
  final double fadeProgress;
  final double resizeProgress;
  final double width;
}

final class _ActionRegionTargetItem<T extends Object> extends StatelessWidget {
  const _ActionRegionTargetItem({
    super.key,
    required this.item,
    required this.height,
  });

  final AnimatedActionRegionItem<T> item;
  final double height;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: item.width, height: height, child: item.child);
}

final class _ActionRegionTransitionView<T extends Object>
    extends StatelessWidget {
  const _ActionRegionTransitionView({
    required this.transition,
    required this.progress,
    required this.height,
    required this.fadeDuration,
    required this.resizeDuration,
    required this.switchInCurve,
    required this.switchOutCurve,
    required this.variantBuilder,
  });

  final _ActionRegionTransition<T> transition;
  final Animation<double> progress;
  final double height;
  final Duration fadeDuration;
  final Duration resizeDuration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final AnimatedActionRegionVariantBuilder<T>? variantBuilder;

  @override
  Widget build(BuildContext context) {
    final curve = transition.isEntering ? switchInCurve : switchOutCurve;
    final totalDuration = _longerDuration(fadeDuration, resizeDuration);
    final fadeProgress = _effectAnimation(
      progress,
      duration: fadeDuration,
      totalDuration: totalDuration,
      curve: curve,
    );
    var resizeProgress = _effectAnimation(
      progress,
      duration: resizeDuration,
      totalDuration: totalDuration,
      curve: curve,
    );
    if (resizeDuration == Duration.zero &&
        fadeDuration != Duration.zero &&
        !transition.isEntering) {
      resizeProgress = CurvedAnimation(
        parent: fadeProgress,
        curve: const Threshold(1),
      );
    }
    if (transition.isVariant &&
        transition.variantSnapshot == null &&
        variantBuilder != null) {
      return _ActionRegionVariantSlot<T>(
        from: transition.from!,
        to: transition.to!,
        fadeProgress: fadeProgress,
        resizeProgress: resizeProgress,
        height: height,
        builder: variantBuilder!,
      );
    }

    return _ActionRegionStructuralSlot<T>(
      transition: transition,
      progress: progress,
      fadeProgress: fadeProgress,
      resizeProgress: resizeProgress,
      height: height,
      fadeDuration: fadeDuration,
      variantBuilder: variantBuilder,
    );
  }
}

final class _ActionRegionVariantSlot<T extends Object> extends StatelessWidget {
  const _ActionRegionVariantSlot({
    required this.from,
    required this.to,
    required this.fadeProgress,
    required this.resizeProgress,
    required this.height,
    required this.builder,
  });

  final AnimatedActionRegionItem<T> from;
  final AnimatedActionRegionItem<T> to;
  final Animation<double> fadeProgress;
  final Animation<double> resizeProgress;
  final double height;
  final AnimatedActionRegionVariantBuilder<T> builder;

  @override
  Widget build(BuildContext context) {
    final child = builder(context, from, to, fadeProgress, resizeProgress);
    return AnimatedBuilder(
      animation: resizeProgress,
      child: child,
      builder: (context, child) => ClipRect(
        child: SizedBox(
          width: _lerp(from.width, to.width, resizeProgress.value),
          height: height,
          child: child,
        ),
      ),
    );
  }
}

final class _ActionRegionStructuralSlot<T extends Object>
    extends StatelessWidget {
  const _ActionRegionStructuralSlot({
    required this.transition,
    required this.progress,
    required this.fadeProgress,
    required this.resizeProgress,
    required this.height,
    required this.fadeDuration,
    required this.variantBuilder,
  });

  final _ActionRegionTransition<T> transition;
  final Animation<double> progress;
  final Animation<double> fadeProgress;
  final Animation<double> resizeProgress;
  final double height;
  final Duration fadeDuration;
  final AnimatedActionRegionVariantBuilder<T>? variantBuilder;

  @override
  Widget build(BuildContext context) {
    final snapshot = transition.variantSnapshot;
    final from = transition.from;
    final to = transition.to;
    final fromWidth = snapshot?.width ?? from?.width ?? 0;
    final toWidth = to?.width ?? 0;
    final fromChild = snapshot == null
        ? from?.child
        : variantBuilder?.call(
            context,
            snapshot.from,
            snapshot.to,
            AlwaysStoppedAnimation<double>(snapshot.fadeProgress),
            AlwaysStoppedAnimation<double>(snapshot.resizeProgress),
          );
    final toChild = to?.child;

    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final fade = fadeProgress.value;
        final resize = resizeProgress.value;
        final width = _lerp(fromWidth, toWidth, resize);
        return ClipRect(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              alignment: AlignmentDirectional.centerEnd,
              children: [
                if (fromChild != null)
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    bottom: 0,
                    width: fromWidth,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: Opacity(
                          opacity: fadeDuration == Duration.zero ? 0 : 1 - fade,
                          child: fromChild,
                        ),
                      ),
                    ),
                  ),
                if (toChild != null)
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    bottom: 0,
                    width: toWidth,
                    child: IgnorePointer(
                      ignoring: fadeDuration != Duration.zero && fade < 1,
                      child: Opacity(
                        opacity: fadeDuration == Duration.zero ? 1 : fade,
                        child: toChild,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Animation<double> _effectAnimation(
  Animation<double> parent, {
  required Duration duration,
  required Duration totalDuration,
  required Curve curve,
}) {
  if (duration == Duration.zero) {
    return const AlwaysStoppedAnimation<double>(1);
  }
  final intervalEnd = duration.inMicroseconds / totalDuration.inMicroseconds;
  return CurvedAnimation(
    parent: parent,
    curve: Interval(0, intervalEnd, curve: curve),
  );
}

double _effectProgressValue(
  double progress, {
  required Duration duration,
  required Duration totalDuration,
  required Curve curve,
}) {
  if (duration == Duration.zero) {
    return 1;
  }
  final intervalEnd = duration.inMicroseconds / totalDuration.inMicroseconds;
  final intervalProgress = (progress / intervalEnd).clamp(0.0, 1.0);
  return curve.transform(intervalProgress).clamp(0.0, 1.0).toDouble();
}

Duration _longerDuration(Duration first, Duration second) =>
    first >= second ? first : second;

double _lerp(double from, double to, double progress) =>
    from + (to - from) * progress;
