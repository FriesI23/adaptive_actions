import 'package:adaptive_actions/adaptive_actions.dart';
import 'package:adaptive_actions/src/widgets/action_region_slot.dart';
import 'package:adaptive_actions/src/widgets/animated_action_region.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const duration = Duration(milliseconds: 400);

  ActionRegionSlot<String> item(
    String id, {
    String variant = 'regular',
    double width = 40,
    ActionRegionSlotRole role = ActionRegionSlotRole.action,
  }) => ActionRegionSlot<String>(
    id: id,
    layoutId: role == ActionRegionSlotRole.overflow
        ? const ActionRegionLayoutSlotId.overflow()
        : ActionRegionLayoutSlotId.action(ActionId(id)),
    variant: variant,
    role: role,
    minimumExtent: width,
    data: '$id-$variant',
    child: SizedBox(key: ValueKey('$id-$variant')),
  );

  Widget target(
    List<ActionRegionSlot<String>> items, {
    Duration fadeDuration = duration,
    Duration resizeDuration = duration,
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.centerLeft,
      child: AnimatedActionRegion<String>(
        items: items,
        height: 40,
        fadeDuration: fadeDuration,
        resizeDuration: resizeDuration,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        variantBuilder: (context, from, to, fadeProgress, resizeProgress) =>
            AnimatedBuilder(
              animation: resizeProgress,
              builder: (context, child) => SizedBox(
                key: const ValueKey('variant-frame'),
                width:
                    from.minimumExtent +
                    (to.minimumExtent - from.minimumExtent) *
                        resizeProgress.value,
              ),
            ),
      ),
    ),
  );

  testWidgets('animates only the last changed action slot', (tester) async {
    await tester.pumpWidget(
      target([item('a'), item('b'), item('c'), item('d')]),
    );
    await tester.pumpWidget(
      target([
        item('a'),
        item('b'),
        item('overflow', role: ActionRegionSlotRole.overflow),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('d-regular')), findsNothing);
    expect(find.byKey(const ValueKey('c-regular')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('c-regular')),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('a-regular')),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(find.byType(Opacity), findsOneWidget);
  });

  testWidgets('uses complementary opacity for an overflow replacement', (
    tester,
  ) async {
    await tester.pumpWidget(target([item('save')]));
    await tester.pumpWidget(
      target([item('overflow', role: ActionRegionSlotRole.overflow)]),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final outgoing = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('save-regular')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    final incoming = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('overflow-regular')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(outgoing.opacity + incoming.opacity, 1);
    expect(find.byType(Opacity), findsNWidgets(2));
  });

  testWidgets('keeps interrupted transitions flat and width-continuous', (
    tester,
  ) async {
    await tester.pumpWidget(
      target([item('save', variant: 'label', width: 100)]),
    );
    await tester.pumpWidget(target([item('save', variant: 'icon')]));
    await tester.pump(const Duration(milliseconds: 100));
    final widthBeforeInterruption = tester
        .getSize(find.byType(AnimatedActionRegion<String>))
        .width;

    await tester.pumpWidget(
      target([item('overflow', role: ActionRegionSlotRole.overflow)]),
    );
    expect(
      tester.getSize(find.byType(AnimatedActionRegion<String>)).width,
      closeTo(widthBeforeInterruption, 0.0001),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Opacity), findsNWidgets(2));

    await tester.pumpWidget(
      target([item('save', variant: 'label', width: 100)]),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Opacity), findsNWidgets(2));
  });

  testWidgets('disables fades while retaining boundary resize', (tester) async {
    await tester.pumpWidget(
      target([item('save', width: 80)], fadeDuration: Duration.zero),
    );
    await tester.pumpWidget(target([], fadeDuration: Duration.zero));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      tester.getSize(find.byType(AnimatedActionRegion<String>)).width,
      inExclusiveRange(0, 80),
    );
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
  });

  testWidgets('disables boundary resize while retaining fades', (tester) async {
    await tester.pumpWidget(
      target([item('save', width: 80)], resizeDuration: Duration.zero),
    );
    await tester.pumpWidget(target([], resizeDuration: Duration.zero));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.getSize(find.byType(AnimatedActionRegion<String>)).width, 80);
    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      inExclusiveRange(0, 1),
    );
  });

  testWidgets('zero durations complete layout changes immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      target(
        [item('save', width: 80)],
        fadeDuration: Duration.zero,
        resizeDuration: Duration.zero,
      ),
    );
    await tester.pumpWidget(
      target([], fadeDuration: Duration.zero, resizeDuration: Duration.zero),
    );

    expect(find.byKey(const ValueKey('save-regular')), findsNothing);
    expect(find.byType(Opacity), findsNothing);
    expect(tester.getSize(find.byType(AnimatedActionRegion<String>)).width, 0);
  });

  testWidgets('runs fade and resize on independent timelines', (tester) async {
    await tester.pumpWidget(
      target([
        item('save', width: 80),
      ], fadeDuration: const Duration(milliseconds: 100)),
    );
    await tester.pumpWidget(
      target([], fadeDuration: const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    expect(
      tester.getSize(find.byType(AnimatedActionRegion<String>)).width,
      inExclusiveRange(0, 80),
    );
  });
}
