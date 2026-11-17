import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Finds standalone Material tooltips, including semantics-excluded tooltips.
///
/// Flutter 3.47's `find.byTooltip` checks the SDK Material tooltip type when
/// semantics are excluded, so it cannot find these tooltips by their message.
Finder findMaterialTooltip(String message) => find.byWidgetPredicate(
  (widget) =>
      widget is Tooltip &&
      (widget.message ?? widget.richMessage?.toPlainText()) == message,
  description: 'Material tooltip with message "$message"',
);
