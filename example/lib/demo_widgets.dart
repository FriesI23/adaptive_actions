import 'package:adaptive_actions/material.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';

import 'demo_layout_reporter.dart';

typedef DemoActionIconBuilder<T extends Object> =
    Widget? Function(BuildContext context, AdaptiveAction<T> action);

bool isDesktopTarget(TargetPlatform platform) => switch (platform) {
  TargetPlatform.linux ||
  TargetPlatform.macOS ||
  TargetPlatform.windows => true,
  _ => false,
};

final class AppBarActionFrame extends StatelessWidget {
  const AppBarActionFrame({
    super.key,
    required this.child,
    this.showBorder = true,
  });

  final Widget child;
  final bool showBorder;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: showBorder
          ? Border.all(color: Theme.of(context).colorScheme.outline)
          : null,
      borderRadius: BorderRadius.circular(4),
    ),
    child: child,
  );
}

final class DemoSection extends StatelessWidget {
  const DemoSection({
    super.key,
    required this.title,
    required this.child,
    this.useCupertino = false,
  });

  final String title;
  final Widget child;
  final bool useCupertino;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: useCupertino
                ? cupertino.CupertinoTheme.of(
                    context,
                  ).textTheme.navTitleTextStyle
                : Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
    if (!useCupertino) {
      return Card(child: content);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cupertino.CupertinoColors.secondarySystemGroupedBackground
              .resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      ),
    );
  }
}

final class SimulatedActionFrame extends StatelessWidget {
  const SimulatedActionFrame({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.useCupertino = false,
  });

  final double width;
  final double height;
  final Widget child;
  final bool useCupertino;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: useCupertino
              ? cupertino.CupertinoColors.separator.resolveFrom(context)
              : Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRect(
          child: OverflowBox(
            alignment: AlignmentDirectional.centerStart,
            minWidth: 0,
            maxWidth: double.infinity,
            child: child,
          ),
        ),
      ),
    ),
  );
}

final class LayoutResultPanel extends StatelessWidget {
  const LayoutResultPanel({
    super.key,
    required this.snapshot,
    required this.lastInvocation,
  });

  final DemoLayoutSnapshot? snapshot;
  final String lastInvocation;

  @override
  Widget build(BuildContext context) {
    final result = snapshot;
    if (result == null) {
      return const Text('Resolving layout…');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResultRow(label: 'Primary', values: result.primary),
        _ResultRow(label: 'Overflow', values: result.overflow),
        _ResultRow(label: 'Hidden', values: result.hidden),
        _ResultRow(label: 'Diagnostics', values: result.diagnostics),
        _ResultRow(label: 'Last invocation', values: [lastInvocation]),
      ],
    );
  }
}

final class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 112, child: Text('$label:')),
        Expanded(child: Text(values.isEmpty ? '—' : values.join(', '))),
      ],
    ),
  );
}

final class DesktopActionMenu<T extends Object> extends StatelessWidget {
  const DesktopActionMenu({
    super.key,
    required this.actions,
    required this.onInvoke,
    required this.iconBuilder,
  });

  final ActionCollection<T> actions;
  final ValueChanged<T> onInvoke;
  final DemoActionIconBuilder<T> iconBuilder;

  @override
  Widget build(BuildContext context) {
    final visibleRoots = actions.roots
        .where(
          (action) =>
              action.placementPolicy.placement != ActionPlacement.hidden,
        )
        .toList(growable: false);
    if (visibleRoots.isEmpty) {
      return const OutlinedButton(
        onPressed: null,
        child: Text('Desktop action menu'),
      );
    }
    return MenuAnchor(
      menuChildren: [
        for (final action in visibleRoots)
          _DesktopMenuEntry<T>(
            entry: action,
            onInvoke: onInvoke,
            iconBuilder: iconBuilder,
          ),
      ],
      builder: (context, controller, child) => OutlinedButton.icon(
        onPressed: controller.isOpen ? controller.close : controller.open,
        icon: const Icon(Icons.menu),
        label: const Text('Desktop action menu'),
      ),
    );
  }
}

final class _DesktopMenuEntry<T extends Object> extends StatelessWidget {
  const _DesktopMenuEntry({
    required this.entry,
    required this.onInvoke,
    required this.iconBuilder,
  });

  final AdaptiveMenuEntry<T> entry;
  final ValueChanged<T> onInvoke;
  final DemoActionIconBuilder<T> iconBuilder;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    if (entry is AdaptiveMenuDivider<T>) {
      return const PopupMenuDivider();
    }
    final action = entry as AdaptiveAction<T>;
    if (action.children.isEmpty || !action.isEnabled) {
      return _DesktopInvokeItem<T>(
        action: action,
        onInvoke: onInvoke,
        iconBuilder: iconBuilder,
      );
    }
    return SubmenuButton(
      leadingIcon: iconBuilder(context, action),
      menuChildren: [
        if (action.payload != null)
          _DesktopInvokeItem<T>(
            action: action,
            onInvoke: onInvoke,
            iconBuilder: iconBuilder,
          ),
        for (final child in action.children)
          _DesktopMenuEntry<T>(
            entry: child,
            onInvoke: onInvoke,
            iconBuilder: iconBuilder,
          ),
      ],
      child: Text(action.metadata.label),
    );
  }
}

final class _DesktopInvokeItem<T extends Object> extends StatelessWidget {
  const _DesktopInvokeItem({
    required this.action,
    required this.onInvoke,
    required this.iconBuilder,
  });

  final AdaptiveAction<T> action;
  final ValueChanged<T> onInvoke;
  final DemoActionIconBuilder<T> iconBuilder;

  @override
  Widget build(BuildContext context) => MenuItemButton(
    leadingIcon: iconBuilder(context, action),
    onPressed: action.isEnabled && action.payload != null
        ? () => onInvoke(action.payload as T)
        : null,
    child: Text(action.metadata.label),
  );
}
