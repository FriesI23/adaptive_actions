import 'package:flutter/foundation.dart';

import '../../core.dart';

/// Dispatches an enabled action's non-null payload to its renderer host.
@internal
void invokeAdaptiveAction<T extends Object>(
  AdaptiveAction<T> action,
  ValueChanged<T> onInvoke,
) {
  if (!action.isEnabled) {
    return;
  }
  final payload = action.payload;
  if (payload != null) {
    onInvoke(payload);
  }
}
