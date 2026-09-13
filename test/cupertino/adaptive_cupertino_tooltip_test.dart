import 'package:adaptive_actions/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('positions below the child with a clear vertical gap', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 100),
              child: AdaptiveCupertinoTooltip(
                message: 'Save document',
                child: SizedBox(key: ValueKey('target'), width: 44, height: 44),
              ),
            ),
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(
      tester.getCenter(find.byKey(const ValueKey('target'))),
    );
    await tester.pumpAndSettle();

    final target = tester.getRect(find.byKey(const ValueKey('target')));
    final tooltip = tester.getRect(find.byType(CupertinoPopupSurface));
    expect(tooltip.top, greaterThanOrEqualTo(target.bottom + 4));

    await pointer.removePointer();
  });

  testWidgets('automatically moves above a child near the bottom edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: AdaptiveCupertinoTooltip(
                message: 'Save document',
                child: SizedBox(key: ValueKey('target'), width: 44, height: 44),
              ),
            ),
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    await pointer.moveTo(
      tester.getCenter(find.byKey(const ValueKey('target'))),
    );
    await tester.pumpAndSettle();

    final target = tester.getRect(find.byKey(const ValueKey('target')));
    final tooltip = tester.getRect(find.byType(CupertinoPopupSurface));
    expect(tooltip.bottom, lessThanOrEqualTo(target.top - 4));

    await pointer.removePointer();
  });
}
