import 'package:adaptive_actions/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final textOption = ActionLayoutOptionId('text');

  AdaptiveAction<String> leaf(
    String id, {
    bool isEnabled = true,
    ActionPlacementPolicy? placementPolicy,
  }) => AdaptiveAction.action(
    id: ActionId(id),
    metadata: ActionMetadata(label: id),
    payload: '$id-command',
    isEnabled: isEnabled,
    placementPolicy: placementPolicy,
  );

  ActionLayoutProfile textCost(AdaptiveAction<String> action) =>
      ActionLayoutProfile(
        actionId: action.id,
        options: [ActionLayoutOption(id: textOption, cost: 10)],
      );

  test('custom text renderer consumes a complete ordered layout result', () {
    final save = leaf('save');
    final search = leaf(
      'search',
      placementPolicy: ActionPlacementPolicy(
        automaticPreference: AutomaticPlacementPreference(
          retentionPriority: PrimaryRetentionPriority.high,
        ),
      ),
    );
    final share = leaf(
      'share',
      placementPolicy: ActionPlacementPolicy(
        automaticPreference: AutomaticPlacementPreference(
          retentionPriority: PrimaryRetentionPriority.low,
        ),
      ),
    );
    final recent = leaf('recent');
    final open = AdaptiveAction<String>.composite(
      id: ActionId('open'),
      metadata: const ActionMetadata(label: 'open'),
      payload: 'open-command',
      children: [recent],
    );
    final reset = leaf('reset');
    final disabled = leaf('disabled', isEnabled: false);
    final advanced = AdaptiveAction<String>.menu(
      id: ActionId('advanced'),
      metadata: const ActionMetadata(label: 'advanced'),
      children: [reset, disabled],
    );
    final settings = AdaptiveAction<String>.menu(
      id: ActionId('settings'),
      metadata: const ActionMetadata(label: 'settings'),
      children: [advanced],
    );
    final tools = AdaptiveAction<String>.menu(
      id: ActionId('tools'),
      metadata: const ActionMetadata(label: 'tools'),
      children: [open, const AdaptiveMenuDivider<String>(), settings],
      placementPolicy: ActionPlacementPolicy(
        placement: ActionPlacement.overflowOnly,
      ),
    );
    final secret = leaf(
      'secret',
      placementPolicy: ActionPlacementPolicy(placement: ActionPlacement.hidden),
    );
    const capabilities = RendererCapabilities();
    final request = ActionLayoutRequest(
      actions: ActionCollection.withEntries(
        entries: [
          save,
          const AdaptiveMenuDivider<String>(),
          search,
          tools,
          share,
          secret,
        ],
      ),
      constraints: ActionLayoutConstraints(
        primaryCapacity: 20,
        profiles: [textCost(save), textCost(search), textCost(share)],
      ),
      capabilities: capabilities,
      primaryOrderOverride: [search.id, save.id],
      overflowOrderOverride: [share.id, tools.id],
    );
    final invoked = <String>[];
    final renderer = _TextRenderer<String>(
      capabilities: capabilities,
      primaryBuilders: {textOption: (action) => action.metadata.label},
      onInvoke: invoked.add,
    );

    final layout = const ActionLayoutResolver().resolve(request);
    final output = renderer.render(layout);

    expect(
      invoked,
      isEmpty,
      reason: 'resolving and rendering are side-effect free',
    );
    expect(output, [
      'primary:text:search [invoke]',
      'primary-divider',
      'primary:text:save [invoke]',
      'overflow:share [invoke]',
      'overflow:tools [menu]',
      '  child:open [invoke,submenu]',
      '    child:recent [invoke]',
      '  divider',
      '  child:settings [menu]',
      '    child:advanced [menu]',
      '      child:reset [invoke]',
      '      child:disabled [disabled]',
      'hidden:secret:forcedHidden',
      'diagnostic:forcedHidden:secret',
      'diagnostic:insufficientCapacity:share',
    ]);

    renderer.invoke(open);

    expect(invoked, ['open-command']);
  });

  test('custom resolver changes placement without changing the renderer', () {
    final save = leaf('save');
    final request = ActionLayoutRequest(
      actions: ActionCollection(roots: [save]),
      constraints: ActionLayoutConstraints(
        primaryCapacity: 10,
        profiles: [textCost(save)],
      ),
      capabilities: const RendererCapabilities(),
    );
    final renderer = _TextRenderer<String>(
      capabilities: const RendererCapabilities(),
      primaryBuilders: {textOption: (action) => action.metadata.label},
      onInvoke: (_) {},
    );

    final defaultLayout = const ActionLayoutResolver().resolve(request);
    final customLayout = const ActionLayoutResolver(
      placementDelegate: _OverflowPlacementDelegate(),
    ).resolve(request);

    expect(renderer.render(defaultLayout), ['primary:text:save [invoke]']);
    expect(renderer.render(customLayout), ['overflow:save [invoke]']);
  });

  test('fails clearly when a selected primary option has no builder', () {
    final action = leaf('save');
    final layout = ActionLayoutResult<String>(
      primary: [
        ResolvedPrimaryAction(
          action: action,
          optionId: ActionLayoutOptionId('unknown'),
        ),
      ],
    );
    final renderer = _TextRenderer<String>(
      capabilities: const RendererCapabilities(),
      primaryBuilders: const {},
      onInvoke: (_) {},
    );

    expect(
      () => renderer.render(layout),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('unknown'),
        ),
      ),
    );
  });
}

final class _OverflowPlacementDelegate implements ActionPlacementDelegate {
  const _OverflowPlacementDelegate();

  @override
  ActionPlacementResult<T> resolve<T extends Object>(
    ActionLayoutRequest<T> request,
  ) => ActionPlacementResult(overflow: request.actions.roots);
}

final class _TextRenderer<T extends Object> {
  const _TextRenderer({
    required this.capabilities,
    required this.primaryBuilders,
    required this.onInvoke,
  });

  final RendererCapabilities capabilities;
  final Map<ActionLayoutOptionId, String Function(AdaptiveAction<T> action)>
  primaryBuilders;
  final void Function(T payload) onInvoke;

  List<String> render(ActionLayoutResult<T> layout) {
    final lines = <String>[];
    for (final entry in layout.primary) {
      if (layout.primaryDividerBeforeActionIds.contains(entry.action.id)) {
        lines.add('primary-divider');
      }
      final builder = primaryBuilders[entry.optionId];
      if (builder == null) {
        throw StateError(
          'No primary builder registered for ${entry.optionId}.',
        );
      }
      lines.add(
        'primary:${entry.optionId}:${builder(entry.action)} '
        '[${_affordances(entry.action)}]',
      );
      _renderChildren(lines, entry.action.children, depth: 1);
    }
    for (final action in layout.overflow) {
      if (layout.overflowDividerBeforeActionIds.contains(action.id)) {
        lines.add('overflow-divider');
      }
      lines.add('overflow:${action.id} [${_affordances(action)}]');
      _renderChildren(lines, action.children, depth: 1);
    }
    for (final entry in layout.hidden) {
      lines.add('hidden:${entry.action.id}:${entry.reason.name}');
    }
    for (final diagnostic in layout.diagnostics) {
      lines.add(
        'diagnostic:${diagnostic.code.name}:'
        '${diagnostic.actionIds.join(',')}',
      );
    }
    return lines;
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

  void _renderChildren(
    List<String> lines,
    List<AdaptiveMenuEntry<T>> children, {
    required int depth,
  }) {
    for (final child in children) {
      if (child is AdaptiveMenuDivider<T>) {
        lines.add('${'  ' * depth}divider');
        continue;
      }
      final action = child as AdaptiveAction<T>;
      lines.add('${'  ' * depth}child:${action.id} [${_affordances(action)}]');
      _renderChildren(lines, action.children, depth: depth + 1);
    }
  }

  String _affordances(AdaptiveAction<T> action) {
    if (!action.isEnabled) {
      return 'disabled';
    }
    if (action.payload == null) {
      return 'menu';
    }
    if (!action.hasMenu) {
      return 'invoke';
    }
    return capabilities.supportsCompositeActions
        ? 'composite'
        : 'invoke,submenu';
  }
}
