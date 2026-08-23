import 'package:adaptive_actions/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AdaptiveAction<String> leaf(String id, {bool isEnabled = true}) =>
      AdaptiveAction.action(
        id: ActionId(id),
        metadata: ActionMetadata(label: id),
        payload: '$id-command',
        isEnabled: isEnabled,
      );

  group('renderer interaction contract', () {
    test(
      'hands an enabled leaf payload to the host only after interaction',
      () {
        final invoked = <String>[];
        final action = leaf('save');
        final renderer = _InteractionProbe<String>(
          capabilities: const RendererCapabilities(),
          onInvoke: invoked.add,
        );

        expect(renderer.affordancesFor(action), ['invoke:save']);
        expect(
          invoked,
          isEmpty,
          reason: 'layout consumption has no side effect',
        );

        renderer.invoke(action);

        expect(invoked, ['save-command']);
      },
    );

    test('suppresses invocation and child navigation while disabled', () {
      final invoked = <String>[];
      final child = leaf('child');
      final disabled = AdaptiveAction.composite(
        id: ActionId('disabled'),
        metadata: const ActionMetadata(label: 'disabled'),
        payload: 'disabled-command',
        children: [child],
        isEnabled: false,
      );
      final renderer = _InteractionProbe<String>(
        capabilities: const RendererCapabilities(),
        onInvoke: invoked.add,
      );

      expect(renderer.affordancesFor(disabled), isEmpty);
      renderer.invoke(disabled);

      expect(renderer.open(disabled), isEmpty);
      expect(invoked, isEmpty);
    });

    test('opens menu children in declaration order without invoking', () {
      final invoked = <String>[];
      final first = leaf('first');
      final second = leaf('second');
      final menu = AdaptiveAction<String>.menu(
        id: ActionId('more'),
        metadata: const ActionMetadata(label: 'more'),
        children: [first, second],
      );
      final renderer = _InteractionProbe<String>(
        capabilities: const RendererCapabilities(),
        onInvoke: invoked.add,
      );

      expect(renderer.affordancesFor(menu), ['menu:more']);
      expect(renderer.open(menu), [first, second]);
      expect(invoked, isEmpty);
    });

    test('preserves both composite behaviors for native and split UI', () {
      final child = leaf('recent');
      final composite = AdaptiveAction<String>.composite(
        id: ActionId('open'),
        metadata: const ActionMetadata(label: 'open'),
        payload: 'open-command',
        children: [child],
      );

      for (final testCase in [
        (
          capabilities: const RendererCapabilities(
            supportsCompositeActions: true,
          ),
          expected: ['composite:open'],
        ),
        (
          capabilities: const RendererCapabilities(),
          expected: ['invoke:open', 'submenu:open'],
        ),
      ]) {
        final invoked = <String>[];
        final renderer = _InteractionProbe<String>(
          capabilities: testCase.capabilities,
          onInvoke: invoked.add,
        );

        expect(renderer.affordancesFor(composite), testCase.expected);
        renderer.invoke(composite);

        expect(invoked, ['open-command']);
        expect(renderer.open(composite), [child]);
      }
    });
  });
}

final class _InteractionProbe<T extends Object> {
  const _InteractionProbe({required this.capabilities, required this.onInvoke});

  final RendererCapabilities capabilities;
  final void Function(T payload) onInvoke;

  List<String> affordancesFor(AdaptiveAction<T> action) {
    if (!action.isEnabled) {
      return const [];
    }
    if (action.payload != null) {
      if (action.children.isEmpty) {
        return ['invoke:${action.id}'];
      }
      if (capabilities.supportsCompositeActions) {
        return ['composite:${action.id}'];
      }
      return ['invoke:${action.id}', 'submenu:${action.id}'];
    }
    return ['menu:${action.id}'];
  }

  void invoke(AdaptiveAction<T> action) {
    if (!action.isEnabled) {
      return;
    }
    final payload = action.payload;
    if (payload != null) {
      onInvoke(payload);
    }
  }

  List<AdaptiveAction<T>> open(AdaptiveAction<T> action) =>
      action.isEnabled ? action.children : const [];
}
