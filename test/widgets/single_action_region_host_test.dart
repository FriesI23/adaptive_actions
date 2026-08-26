import 'package:adaptive_actions/adaptive_actions.dart';
import 'package:adaptive_actions/src/widgets/action_region_slot.dart';
import 'package:adaptive_actions/src/widgets/single_action_region_host.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ActionRegionSlot<String> slot(
    String id, {
    double minimumExtent = 40,
    ActionRegionSlotRole role = ActionRegionSlotRole.action,
  }) => ActionRegionSlot<String>(
    id: id,
    layoutId: role == ActionRegionSlotRole.overflow
        ? const ActionRegionLayoutSlotId.overflow()
        : ActionRegionLayoutSlotId.action(ActionId(id)),
    variant: 'regular',
    role: role,
    minimumExtent: minimumExtent,
    data: id,
    child: SizedBox(key: ValueKey(id)),
  );

  Widget host({
    required SingleActionRegionSnapshotBuilder<String> snapshotBuilder,
    double primaryCapacity = 240,
    TextDirection textDirection = TextDirection.ltr,
    ActionRegionMainAxisDistribution distribution =
        ActionRegionMainAxisDistribution.compact,
    ActionRegionLayoutDelegate? layoutDelegate,
    Duration fadeDuration = Duration.zero,
    Duration resizeDuration = Duration.zero,
  }) => Directionality(
    textDirection: textDirection,
    child: Align(
      alignment: Alignment.centerLeft,
      child: SingleActionRegionHost<String>(
        snapshotBuilder: snapshotBuilder,
        primaryCapacity: primaryCapacity,
        actionIds: [ActionId('a'), ActionId('b')],
        height: 40,
        fadeDuration: fadeDuration,
        resizeDuration: resizeDuration,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        distribution: distribution,
        layoutDelegate: layoutDelegate,
      ),
    ),
  );

  testWidgets('builds one immutable snapshot from finite constraints', (
    tester,
  ) async {
    var buildCount = 0;
    BoxConstraints? receivedConstraints;
    final source = [slot('a'), slot('b', minimumExtent: 24)];

    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 240,
          child: host(
            snapshotBuilder: (context, constraints, primaryCapacity) {
              buildCount += 1;
              receivedConstraints = constraints;
              return SingleActionRegionSnapshot(slots: source);
            },
          ),
        ),
      ),
    );
    source.clear();

    expect(buildCount, 1);
    expect(receivedConstraints!.maxWidth, 240);
    expect(
      tester.getSize(find.byType(SingleActionRegionHost<String>)).width,
      64,
    );
    expect(find.byKey(const ValueKey('a')), findsOneWidget);
    expect(find.byKey(const ValueKey('b')), findsOneWidget);
  });

  testWidgets('forwards unbounded width without expanding compact slots', (
    tester,
  ) async {
    BoxConstraints? receivedConstraints;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: host(
            snapshotBuilder: (context, constraints, primaryCapacity) {
              receivedConstraints = constraints;
              return SingleActionRegionSnapshot(slots: [slot('a'), slot('b')]);
            },
          ),
        ),
      ),
    );

    expect(receivedConstraints!.maxWidth, double.infinity);
    expect(
      tester.getSize(find.byType(SingleActionRegionHost<String>)).width,
      80,
    );
  });

  testWidgets('places built-in distributions at exact finite positions', (
    tester,
  ) async {
    Future<List<double>> positions(
      ActionRegionMainAxisDistribution distribution, {
      TextDirection textDirection = TextDirection.ltr,
    }) async {
      await tester.pumpWidget(
        SizedBox(
          width: 240,
          child: host(
            textDirection: textDirection,
            distribution: distribution,
            snapshotBuilder: (context, constraints, primaryCapacity) =>
                SingleActionRegionSnapshot(
                  slots: [slot('a'), slot('b'), slot('c')],
                ),
          ),
        ),
      );
      return [
        for (final id in ['a', 'b', 'c'])
          tester.getTopLeft(find.byKey(ValueKey(id))).dx,
      ];
    }

    expect(await positions(ActionRegionMainAxisDistribution.spaceBetween), [
      0,
      100,
      200,
    ]);
    expect(await positions(ActionRegionMainAxisDistribution.spaceAround), [
      20,
      100,
      180,
    ]);
    expect(await positions(ActionRegionMainAxisDistribution.spaceEvenly), [
      30,
      100,
      170,
    ]);
    expect(
      await positions(
        ActionRegionMainAxisDistribution.spaceBetween,
        textDirection: TextDirection.rtl,
      ),
      [200, 100, 0],
    );
  });

  testWidgets('defines empty and single-slot distribution behavior', (
    tester,
  ) async {
    await tester.pumpWidget(
      SizedBox(
        width: 240,
        child: host(
          distribution: ActionRegionMainAxisDistribution.spaceEvenly,
          snapshotBuilder: (context, constraints, primaryCapacity) =>
              SingleActionRegionSnapshot(slots: const []),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(SingleActionRegionHost<String>)).width,
      0,
    );

    await tester.pumpWidget(
      SizedBox(
        width: 240,
        child: host(
          distribution: ActionRegionMainAxisDistribution.spaceAround,
          snapshotBuilder: (context, constraints, primaryCapacity) =>
              SingleActionRegionSnapshot(slots: [slot('a')]),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byKey(const ValueKey('a'))).dx, 100);

    await tester.pumpWidget(
      SizedBox(
        width: 240,
        child: host(
          distribution: ActionRegionMainAxisDistribution.spaceBetween,
          snapshotBuilder: (context, constraints, primaryCapacity) =>
              SingleActionRegionSnapshot(slots: [slot('a')]),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byKey(const ValueKey('a'))).dx, 0);
  });

  testWidgets('resize updates gaps without starting a slot transition', (
    tester,
  ) async {
    var width = 160.0;
    late StateSetter setState;
    var snapshotBuildCount = 0;
    Widget target() => Center(
      child: StatefulBuilder(
        builder: (context, setter) {
          setState = setter;
          return SizedBox(
            width: width,
            child: host(
              primaryCapacity: 240,
              distribution: ActionRegionMainAxisDistribution.spaceBetween,
              snapshotBuilder: (context, constraints, primaryCapacity) {
                snapshotBuildCount += 1;
                return SingleActionRegionSnapshot(
                  slots: [slot('a'), slot('b')],
                );
              },
            ),
          );
        },
      ),
    );

    await tester.pumpWidget(target());
    expect(tester.getTopLeft(find.byKey(const ValueKey('b'))).dx, 440);
    setState(() => width = 240);
    await tester.pump();

    expect(snapshotBuildCount, 2);
    expect(tester.getTopLeft(find.byKey(const ValueKey('b'))).dx, 480);
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('animated contraction stays within a shrinking flex viewport', (
    tester,
  ) async {
    var width = 160.0;
    late StateSetter setState;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setter) {
          setState = setter;
          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: width,
              child: host(
                primaryCapacity: 240,
                distribution: ActionRegionMainAxisDistribution.spaceEvenly,
                fadeDuration: const Duration(milliseconds: 400),
                resizeDuration: const Duration(milliseconds: 400),
                snapshotBuilder: (context, constraints, primaryCapacity) {
                  final isExtended = primaryCapacity >= 100;
                  return SingleActionRegionSnapshot(
                    slots: [
                      ActionRegionSlot<String>(
                        id: 'a',
                        layoutId: ActionRegionLayoutSlotId.action(
                          ActionId('a'),
                        ),
                        variant: isExtended ? 'extended' : 'iconOnly',
                        role: ActionRegionSlotRole.action,
                        minimumExtent: isExtended ? 100 : 40,
                        data: 'a',
                        child: const SizedBox(key: ValueKey('a')),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );

    setState(() => width = 80);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(tester.takeException(), isNull);
  });

  testWidgets('overflow replacement does not retain an outgoing flex gap', (
    tester,
  ) async {
    var overflow = false;
    late StateSetter setState;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setter) {
          setState = setter;
          return SizedBox(
            width: 240,
            child: host(
              distribution: ActionRegionMainAxisDistribution.spaceBetween,
              fadeDuration: const Duration(milliseconds: 400),
              resizeDuration: const Duration(milliseconds: 400),
              snapshotBuilder: (context, constraints, primaryCapacity) =>
                  SingleActionRegionSnapshot(
                    slots: [
                      slot('a'),
                      overflow
                          ? slot('more', role: ActionRegionSlotRole.overflow)
                          : slot('b'),
                    ],
                  ),
            ),
          );
        },
      ),
    );

    setState(() => overflow = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.getTopLeft(find.byKey(const ValueKey('b'))).dx, 200);
    expect(tester.getTopLeft(find.byKey(const ValueKey('more'))).dx, 200);
    expect(find.byType(Opacity), findsNWidgets(2));
  });

  testWidgets('reserves fixed gaps then allocates weighted tight flex', (
    tester,
  ) async {
    double? resolvedCapacity;
    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 200,
          child: host(
            layoutDelegate: _TestLayoutDelegate(
              fixedReservation: 8,
              entries: [
                ActionRegionLayoutEntry.slot(
                  ActionRegionLayoutSlotId.action(ActionId('a')),
                  extent: ActionRegionExtent.flex(),
                ),
                ActionRegionLayoutEntry.fixedGap(8),
                ActionRegionLayoutEntry.flexGap(),
                ActionRegionLayoutEntry.slot(
                  ActionRegionLayoutSlotId.action(ActionId('b')),
                ),
              ],
            ),
            snapshotBuilder: (context, constraints, primaryCapacity) {
              resolvedCapacity = primaryCapacity;
              return SingleActionRegionSnapshot(slots: [slot('a'), slot('b')]);
            },
          ),
        ),
      ),
    );

    expect(resolvedCapacity, 192);
    expect(tester.getSize(find.byKey(const ValueKey('a'))).width, 96);
    final hostLeft = tester
        .getTopLeft(find.byType(SingleActionRegionHost<String>))
        .dx;
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('b'))).dx - hostLeft,
      160,
    );
    expect(tester.getSize(find.byKey(const ValueKey('b'))).width, 40);
  });

  testWidgets('inserts Expanded-like and fixed gaps between fixed slots', (
    tester,
  ) async {
    Future<List<double>> positions({
      required bool expanded,
      bool alignFixedToEnd = false,
    }) async {
      await tester.pumpWidget(
        SizedBox(
          width: 240,
          child: host(
            layoutDelegate: _TestLayoutDelegate(
              fixedReservation: expanded ? 0 : 24,
              entries: [
                if (alignFixedToEnd) ActionRegionLayoutEntry.flexGap(),
                ActionRegionLayoutEntry.slot(
                  ActionRegionLayoutSlotId.action(ActionId('a')),
                ),
                ActionRegionLayoutEntry.slot(
                  ActionRegionLayoutSlotId.action(ActionId('b')),
                ),
                expanded
                    ? ActionRegionLayoutEntry.flexGap()
                    : ActionRegionLayoutEntry.fixedGap(24),
                ActionRegionLayoutEntry.slot(
                  ActionRegionLayoutSlotId.action(ActionId('c')),
                ),
              ],
            ),
            snapshotBuilder: (context, constraints, primaryCapacity) =>
                SingleActionRegionSnapshot(
                  slots: [slot('a'), slot('b'), slot('c')],
                ),
          ),
        ),
      );
      final hostLeft = tester
          .getTopLeft(find.byType(SingleActionRegionHost<String>))
          .dx;
      return [
        for (final id in ['a', 'b', 'c'])
          tester.getTopLeft(find.byKey(ValueKey(id))).dx - hostLeft,
      ];
    }

    expect(await positions(expanded: true), [0, 40, 200]);
    expect(await positions(expanded: false), [0, 40, 104]);
    expect(
      tester.getSize(find.byType(SingleActionRegionHost<String>)).width,
      144,
    );
    expect(await positions(expanded: false, alignFixedToEnd: true), [
      96,
      136,
      200,
    ]);
  });

  testWidgets('loose flex leaves its share unconsumed at logical end', (
    tester,
  ) async {
    await tester.pumpWidget(
      SizedBox(
        width: 240,
        child: host(
          layoutDelegate: _TestLayoutDelegate(
            entries: [
              ActionRegionLayoutEntry.slot(
                ActionRegionLayoutSlotId.action(ActionId('a')),
                extent: ActionRegionExtent.flex(fit: ActionRegionFlexFit.loose),
              ),
              ActionRegionLayoutEntry.slot(
                ActionRegionLayoutSlotId.action(ActionId('b')),
              ),
            ],
          ),
          snapshotBuilder: (context, constraints, primaryCapacity) =>
              SingleActionRegionSnapshot(slots: [slot('a'), slot('b')]),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('a'))).width, 40);
    expect(tester.getTopLeft(find.byKey(const ValueKey('b'))).dx, 40);
    expect(
      tester.getSize(find.byType(SingleActionRegionHost<String>)).width,
      240,
    );
  });

  testWidgets('does not expand flex under unbounded horizontal constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: host(
            layoutDelegate: _TestLayoutDelegate(
              fixedReservation: 8,
              entries: [
                ActionRegionLayoutEntry.slot(
                  ActionRegionLayoutSlotId.action(ActionId('a')),
                  extent: ActionRegionExtent.flex(),
                ),
                ActionRegionLayoutEntry.fixedGap(8),
                ActionRegionLayoutEntry.slot(
                  ActionRegionLayoutSlotId.action(ActionId('b')),
                ),
              ],
            ),
            snapshotBuilder: (context, constraints, primaryCapacity) =>
                SingleActionRegionSnapshot(slots: [slot('a'), slot('b')]),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('a'))).width, 40);
    expect(tester.getTopLeft(find.byKey(const ValueKey('b'))).dx, 48);
    expect(
      tester.getSize(find.byType(SingleActionRegionHost<String>)).width,
      88,
    );
  });

  testWidgets('rejects reordered, unreserved, or flexible overflow plans', (
    tester,
  ) async {
    Future<void> expectPlanFailure(_TestLayoutDelegate delegate) async {
      await tester.pumpWidget(
        SizedBox(
          width: 240,
          child: host(
            layoutDelegate: delegate,
            snapshotBuilder: (context, constraints, primaryCapacity) =>
                SingleActionRegionSnapshot(
                  slots: [
                    slot('a'),
                    slot('more', role: ActionRegionSlotRole.overflow),
                  ],
                ),
          ),
        ),
      );
      expect(tester.takeException(), isArgumentError);
    }

    await expectPlanFailure(
      _TestLayoutDelegate(
        entries: [
          const ActionRegionLayoutEntry.slot(
            ActionRegionLayoutSlotId.overflow(),
          ),
          ActionRegionLayoutEntry.slot(
            ActionRegionLayoutSlotId.action(ActionId('a')),
          ),
        ],
      ),
    );
    await expectPlanFailure(
      _TestLayoutDelegate(
        entries: [
          ActionRegionLayoutEntry.slot(
            ActionRegionLayoutSlotId.action(ActionId('a')),
          ),
          ActionRegionLayoutEntry.fixedGap(8),
          const ActionRegionLayoutEntry.slot(
            ActionRegionLayoutSlotId.overflow(),
          ),
        ],
      ),
    );
    await expectPlanFailure(
      _TestLayoutDelegate(
        entries: [
          ActionRegionLayoutEntry.slot(
            ActionRegionLayoutSlotId.action(ActionId('a')),
          ),
          ActionRegionLayoutEntry.slot(
            const ActionRegionLayoutSlotId.overflow(),
            extent: ActionRegionExtent.flex(),
          ),
        ],
      ),
    );
  });

  test('snapshot rejects duplicate or misplaced overflow slots', () {
    final overflow = slot('more', role: ActionRegionSlotRole.overflow);

    expect(
      () => SingleActionRegionSnapshot(slots: [overflow, slot('a')]),
      throwsArgumentError,
    );
    expect(
      () => SingleActionRegionSnapshot(slots: [overflow, overflow]),
      throwsArgumentError,
    );
  });

  test('slot rejects invalid minimum extents', () {
    expect(
      () => slot('infinite', minimumExtent: double.infinity),
      throwsArgumentError,
    );
    expect(() => slot('negative', minimumExtent: -1), throwsRangeError);
  });
}

final class _TestLayoutDelegate implements ActionRegionLayoutDelegate {
  _TestLayoutDelegate({this.fixedReservation = 0, required this.entries});

  final double fixedReservation;
  final List<ActionRegionLayoutEntry> entries;

  @override
  ActionRegionLayoutReservation reserve(
    ActionRegionLayoutReservationInput input,
  ) => ActionRegionLayoutReservation(fixedExtent: fixedReservation);

  @override
  ActionRegionLayoutPlan layout(ActionRegionLayoutInput input) =>
      ActionRegionLayoutPlan(entries: entries);
}
