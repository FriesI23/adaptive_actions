import 'package:adaptive_actions/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

final class DemoLayoutSnapshot {
  const DemoLayoutSnapshot({
    required this.primary,
    required this.overflow,
    required this.hidden,
    required this.diagnostics,
  });

  static DemoLayoutSnapshot fromResult<T extends Object>(
    ActionPlacementResult<T> result,
  ) => DemoLayoutSnapshot(
    primary: List.unmodifiable(
      result.primary.map((entry) => entry.action.metadata.label),
    ),
    overflow: List.unmodifiable(
      result.overflow.map((action) => action.metadata.label),
    ),
    hidden: List.unmodifiable(
      result.hidden.map(
        (entry) => '${entry.action.metadata.label} (${entry.reason.name})',
      ),
    ),
    diagnostics: List.unmodifiable(
      result.diagnostics.map(
        (diagnostic) =>
            '${diagnostic.code.name}: '
            '${diagnostic.actionIds.map((id) => id.value).join(', ')}',
      ),
    ),
  );

  final List<String> primary;
  final List<String> overflow;
  final List<String> hidden;
  final List<String> diagnostics;

  @override
  bool operator ==(Object other) =>
      other is DemoLayoutSnapshot &&
      listEquals(primary, other.primary) &&
      listEquals(overflow, other.overflow) &&
      listEquals(hidden, other.hidden) &&
      listEquals(diagnostics, other.diagnostics);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(primary),
    Object.hashAll(overflow),
    Object.hashAll(hidden),
    Object.hashAll(diagnostics),
  );
}

final class DemoLayoutReporter implements ActionPlacementDelegate {
  final snapshot = ValueNotifier<DemoLayoutSnapshot?>(null);
  final _delegate = const DefaultActionPlacementDelegate();

  DemoLayoutSnapshot? _scheduledSnapshot;
  bool _isDisposed = false;

  @override
  ActionPlacementResult<T> resolve<T extends Object>(
    ActionLayoutRequest<T> request,
  ) {
    final result = _delegate.resolve(request);
    final nextSnapshot = DemoLayoutSnapshot.fromResult(result);
    if (nextSnapshot != snapshot.value && nextSnapshot != _scheduledSnapshot) {
      _scheduledSnapshot = nextSnapshot;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed || _scheduledSnapshot != nextSnapshot) {
          return;
        }
        _scheduledSnapshot = null;
        snapshot.value = nextSnapshot;
      });
    }
    return result;
  }

  void dispose() {
    _isDisposed = true;
    snapshot.dispose();
  }
}
