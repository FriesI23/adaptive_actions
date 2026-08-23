import 'dart:math' as math;

import 'package:adaptive_actions/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cupertino_demo.dart';
import 'demo_layout_reporter.dart';
import 'demo_settings.dart';
import 'demo_settings_widgets.dart';
import 'demo_widgets.dart';

const _kAppTitle = 'Adaptive Actions Renderer Example';
const _kToolbarTitle = 'Adaptive Actions';
const _kAppBarLeadingWidth = 56.0;
const _kAppBarTitleSpacing = 16.0;
const _kAppBarEndPadding = 8.0;
const _kActionsAnimationDuration = Duration(milliseconds: 400);
final _primaryOrderOverride = [ActionId('share'), ActionId('open')];
final _overflowOrderOverride = [ActionId('delete'), ActionId('share')];

void main() {
  runApp(const AdaptiveActionsExampleApp());
}

final class AdaptiveActionsExampleApp extends StatefulWidget {
  const AdaptiveActionsExampleApp({super.key});

  @override
  State<AdaptiveActionsExampleApp> createState() =>
      _AdaptiveActionsExampleAppState();
}

final class _AdaptiveActionsExampleAppState
    extends State<AdaptiveActionsExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: _kAppTitle,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    themeMode: _themeMode,
    home: AdaptiveActionsDemoPage(
      brightness: _themeMode == ThemeMode.light
          ? Brightness.light
          : Brightness.dark,
      onThemeToggle: _toggleTheme,
    ),
  );

  void _toggleTheme() => setState(
    () => _themeMode = switch (_themeMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark || ThemeMode.system => ThemeMode.light,
    },
  );
}

enum DemoCommand {
  save,
  open,
  recentDocument,
  browse,
  shareLink,
  shareEmail,
  delete,
  help,
  toggleRenderer,
  toggleTheme,
  toggleTextDirection,
}

extension DemoCommandLabel on DemoCommand {
  String get label => switch (this) {
    DemoCommand.save => 'Save',
    DemoCommand.open => 'Open',
    DemoCommand.recentDocument => 'Recent document',
    DemoCommand.browse => 'Browse files',
    DemoCommand.shareLink => 'Copy share link',
    DemoCommand.shareEmail => 'Share by email',
    DemoCommand.delete => 'Delete',
    DemoCommand.help => 'Help',
    DemoCommand.toggleRenderer => 'Toggle renderer',
    DemoCommand.toggleTheme => 'Toggle theme',
    DemoCommand.toggleTextDirection => 'Toggle text direction',
  };
}

final class AdaptiveActionsDemoPage extends StatefulWidget {
  const AdaptiveActionsDemoPage({
    super.key,
    required this.brightness,
    required this.onThemeToggle,
  });

  final Brightness brightness;
  final VoidCallback onThemeToggle;

  @override
  State<AdaptiveActionsDemoPage> createState() =>
      _AdaptiveActionsDemoPageState();
}

final class _AdaptiveActionsDemoPageState
    extends State<AdaptiveActionsDemoPage> {
  final _layoutReporter = DemoLayoutReporter();

  late final ActionLayoutResolver _resolver;
  late DemoRenderer _renderer;
  DemoPlacement _placement = DemoPlacement.automatic;
  DemoRetention _retention = DemoRetention.normal;
  DemoDividerVisibility _dividerVisibility = DemoDividerVisibility.menuOnly;
  final _presentations = DemoPresentationValues();
  double? _simulatedMaxActionWidth = defaultSimulatedMaxActionWidth;
  double _parentActionHeight = defaultParentActionHeight;
  int? _maxPrimaryActions = defaultMaxPrimaryActions;
  bool _enabled = true;
  bool _showAppBarActionFrame = true;
  bool _customOverflowButton = false;
  Duration _fadeDuration = _kActionsAnimationDuration;
  Duration _resizeDuration = _kActionsAnimationDuration;
  bool _centerTitle = false;
  bool _rightToLeft = false;
  String _lastInvocation = 'None';

  @override
  void initState() {
    super.initState();
    _renderer = defaultDemoRenderer(defaultTargetPlatform);
    _resolver = ActionLayoutResolver(placementDelegate: _layoutReporter);
  }

  @override
  void dispose() {
    _layoutReporter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final windowWidth = MediaQuery.sizeOf(context).width;
    final availableActionWidth = switch (_renderer) {
      DemoRenderer.material => _maximumMaterialAppBarActionWidth(
        context,
        windowWidth: windowWidth,
        centerTitle: _centerTitle,
      ),
      DemoRenderer.apple => maximumCupertinoDemoActionWidth(windowWidth),
    };
    final simulatedMaxActionWidth = _simulatedMaxActionWidth;
    final effectiveActionWidth = simulatedMaxActionWidth == null
        ? availableActionWidth
        : math.min(availableActionWidth, simulatedMaxActionWidth);
    final actions = ActionCollection<DemoCommand>.withEntries(
      entries: _buildActionEntries(),
    );
    final showDesktopMenu = isDesktopTarget(defaultTargetPlatform);
    final body = _buildDemoBody(
      context,
      windowWidth: windowWidth,
      availableActionWidth: availableActionWidth,
      effectiveActionWidth: effectiveActionWidth,
      actions: actions,
      showDesktopMenu: showDesktopMenu,
    );

    return Directionality(
      textDirection: _rightToLeft ? TextDirection.rtl : TextDirection.ltr,
      child: switch (_renderer) {
        DemoRenderer.material => _buildMaterialPage(
          body: body,
          actions: actions,
          effectiveActionWidth: effectiveActionWidth,
        ),
        DemoRenderer.apple => CupertinoDemoPage<DemoCommand>(
          title: _kToolbarTitle,
          body: body,
          actions: actions,
          resolver: _resolver,
          primaryOrderOverride: _primaryOrderOverride,
          overflowOrderOverride: _overflowOrderOverride,
          actionWidth: effectiveActionWidth,
          actionHeight: _parentActionHeight,
          maxPrimaryActions: _maxPrimaryActions,
          presentationOverride: _presentations.cupertino,
          fadeDuration: _fadeDuration,
          resizeDuration: _resizeDuration,
          brightness: widget.brightness,
          onInvoke: _onInvoke,
          customOverflowButton: _customOverflowButton,
        ),
      },
    );
  }

  Widget _buildDemoBody(
    BuildContext context, {
    required double windowWidth,
    required double availableActionWidth,
    required double effectiveActionWidth,
    required ActionCollection<DemoCommand> actions,
    required bool showDesktopMenu,
  }) {
    final useCupertino = _renderer == DemoRenderer.apple;
    return ListView(
      key: previewListKey,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _kAppTitle,
          style: useCupertino
              ? const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)
              : Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Resize a desktop window or change the simulated maximum action '
          'width and parent action height. Every setting rebuilds the same '
          'action configuration used by the navigation bar and preview. '
          'Material desktop targets also expose the same tree through '
          'MenuAnchor.',
        ),
        const SizedBox(height: 12),
        DemoSection(
          title: 'Environment',
          useCupertino: useCupertino,
          child: DemoEnvironmentSummary(
            renderer: _renderer,
            windowWidth: windowWidth,
            availableActionWidth: availableActionWidth,
            simulatedMaxActionWidth: _simulatedMaxActionWidth,
            parentActionHeight: _parentActionHeight,
            effectiveActionWidth: effectiveActionWidth,
            centerTitle: _centerTitle,
          ),
        ),
        DemoSection(
          title: 'Action settings',
          useCupertino: useCupertino,
          child: DemoActionSettings(
            renderer: _renderer,
            simulatedMaxActionWidth: _simulatedMaxActionWidth,
            parentActionHeight: _parentActionHeight,
            actionCount: actions.roots.length,
            maxPrimaryActions: _maxPrimaryActions,
            enabled: _enabled,
            showAppBarActionFrame: _showAppBarActionFrame,
            placement: _placement,
            retention: _retention,
            dividerVisibility: _dividerVisibility,
            onSimulatedMaxActionWidthChanged: (width) =>
                setState(() => _simulatedMaxActionWidth = width),
            onParentActionHeightChanged: (height) =>
                setState(() => _parentActionHeight = height),
            onMaxPrimaryActionsChanged: (count) =>
                setState(() => _maxPrimaryActions = count),
            onEnabledChanged: (enabled) => setState(() => _enabled = enabled),
            onShowAppBarActionFrameChanged: (show) =>
                setState(() => _showAppBarActionFrame = show),
            onPlacementChanged: (placement) =>
                setState(() => _placement = placement),
            onRetentionChanged: (retention) =>
                setState(() => _retention = retention),
            onDividerVisibilityChanged: (visibility) =>
                setState(() => _dividerVisibility = visibility),
          ),
        ),
        DemoSection(
          title: '${_renderer.label} presentation',
          useCupertino: useCupertino,
          child: DemoPresentationSettings(
            renderer: _renderer,
            materialPresentation: _presentations.material,
            cupertinoPresentation: _presentations.cupertino,
            onMaterialChanged: (presentation) =>
                setState(() => _presentations.material = presentation),
            onCupertinoChanged: (presentation) =>
                setState(() => _presentations.cupertino = presentation),
          ),
        ),
        DemoSection(
          title: 'Custom button builders',
          useCupertino: useCupertino,
          child: DemoBuilderSettings(
            renderer: _renderer,
            customOverflowButton: _customOverflowButton,
            onCustomOverflowButtonChanged: (enabled) =>
                setState(() => _customOverflowButton = enabled),
          ),
        ),
        DemoSection(
          title: 'Animation',
          useCupertino: useCupertino,
          child: DemoAnimationSettings(
            renderer: _renderer,
            fadeDuration: _fadeDuration,
            resizeDuration: _resizeDuration,
            onAllChanged: (enabled) => setState(() {
              _fadeDuration = enabled
                  ? _kActionsAnimationDuration
                  : Duration.zero;
              _resizeDuration = enabled
                  ? _kActionsAnimationDuration
                  : Duration.zero;
            }),
            onFadeChanged: (enabled) => setState(
              () => _fadeDuration = enabled
                  ? _kActionsAnimationDuration
                  : Duration.zero,
            ),
            onResizeChanged: (enabled) => setState(
              () => _resizeDuration = enabled
                  ? _kActionsAnimationDuration
                  : Duration.zero,
            ),
          ),
        ),
        DemoSection(
          title: 'Adaptive action preview',
          useCupertino: useCupertino,
          child: SimulatedActionFrame(
            useCupertino: useCupertino,
            width: effectiveActionWidth,
            height: _parentActionHeight,
            child: _actionRegion(
              key: previewActionsKey,
              actions: actions,
              actionWidth: effectiveActionWidth,
            ),
          ),
        ),
        DemoSection(
          title: 'Resolved layout',
          useCupertino: useCupertino,
          child: ValueListenableBuilder<DemoLayoutSnapshot?>(
            valueListenable: _layoutReporter.snapshot,
            builder: (context, snapshot, child) => LayoutResultPanel(
              snapshot: snapshot,
              lastInvocation: _lastInvocation,
            ),
          ),
        ),
        if (showDesktopMenu && !useCupertino)
          DemoSection(
            title: 'Desktop MenuAnchor',
            child: DesktopActionMenu<DemoCommand>(
              actions: actions,
              onInvoke: _onInvoke,
              iconBuilder: _materialIconBuilder,
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMaterialPage({
    required Widget body,
    required ActionCollection<DemoCommand> actions,
    required double effectiveActionWidth,
  }) => Scaffold(
    appBar: AppBar(
      centerTitle: _centerTitle,
      leadingWidth: _kAppBarLeadingWidth,
      leading: IconButton(
        key: titleAlignmentToggleKey,
        tooltip: _centerTitle ? 'Align title left' : 'Center title',
        icon: Icon(
          _centerTitle ? Icons.format_align_left : Icons.format_align_center,
        ),
        onPressed: () => setState(() => _centerTitle = !_centerTitle),
      ),
      title: const Text(_kToolbarTitle, overflow: TextOverflow.ellipsis),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: AppBarActionFrame(
            key: appBarActionFrameKey,
            showBorder: _showAppBarActionFrame,
            child: SizedBox(
              height: _parentActionHeight,
              child: _actionRegion(
                key: appBarActionsKey,
                actions: actions,
                actionWidth: effectiveActionWidth,
              ),
            ),
          ),
        ),
      ],
    ),
    body: body,
  );

  Widget _actionRegion({
    required Key key,
    required ActionCollection<DemoCommand> actions,
    required double actionWidth,
  }) => switch (_renderer) {
    DemoRenderer.material => MaterialAdaptiveActions<DemoCommand>.moreAction(
      key: key,
      actions: actions,
      resolver: _resolver,
      primaryOrderOverride: _primaryOrderOverride,
      overflowOrderOverride: _overflowOrderOverride,
      primaryCapacity: actionWidth,
      maxPrimaryActions: _maxPrimaryActions,
      presentationOverride: _presentations.material,
      onInvoke: _onInvoke,
      iconBuilder: _materialIconBuilder,
      actionButtonBuilder: _materialActionButtonBuilder,
      overflowButtonBuilder: _customOverflowButton
          ? _materialOverflowButtonBuilder
          : null,
      overflowTooltip: 'More actions',
      fadeDuration: _fadeDuration,
      resizeDuration: _resizeDuration,
    ),
    DemoRenderer.apple => CupertinoDemoActions<DemoCommand>(
      key: key,
      actions: actions,
      resolver: _resolver,
      primaryOrderOverride: _primaryOrderOverride,
      overflowOrderOverride: _overflowOrderOverride,
      actionWidth: actionWidth,
      maxPrimaryActions: _maxPrimaryActions,
      presentationOverride: _presentations.cupertino,
      fadeDuration: _fadeDuration,
      resizeDuration: _resizeDuration,
      onInvoke: _onInvoke,
      customOverflowButton: _customOverflowButton,
    ),
  };

  List<AdaptiveMenuEntry<DemoCommand>> _buildActionEntries() {
    final savePolicy = switch (_placement) {
      DemoPlacement.automatic => ActionPlacementPolicy(
        automaticPreference: AutomaticPlacementPreference(
          retentionPriority: _retention.priority,
        ),
      ),
      _ => ActionPlacementPolicy(placement: _placement.placement),
    };
    final highRetention = ActionPlacementPolicy(
      automaticPreference: AutomaticPlacementPreference(
        retentionPriority: PrimaryRetentionPriority.high,
      ),
    );
    final lowRetention = ActionPlacementPolicy(
      automaticPreference: AutomaticPlacementPreference(
        retentionPriority: PrimaryRetentionPriority.low,
        allowsHiding: true,
      ),
    );
    final overflowOnly = ActionPlacementPolicy(
      placement: ActionPlacement.overflowOnly,
    );
    final divider = switch (_dividerVisibility) {
      DemoDividerVisibility.both => const AdaptiveMenuDivider<DemoCommand>(),
      DemoDividerVisibility.menuOnly =>
        const AdaptiveMenuDivider<DemoCommand>.menuOnly(),
      DemoDividerVisibility.primaryOnly =>
        const AdaptiveMenuDivider<DemoCommand>.primaryOnly(),
      DemoDividerVisibility.hidden =>
        const AdaptiveMenuDivider<DemoCommand>.hidden(),
    };

    return [
      AdaptiveAction.action(
        id: ActionId('save'),
        metadata: const ActionMetadata(
          label: 'Save',
          tooltip: 'Save document',
          iconKey: 'save',
        ),
        payload: DemoCommand.save,
        isEnabled: _enabled,
        placementPolicy: savePolicy,
      ),
      divider,
      AdaptiveAction.composite(
        id: ActionId('open'),
        metadata: const ActionMetadata(label: 'Open', iconKey: 'open'),
        payload: DemoCommand.open,
        isEnabled: _enabled,
        placementPolicy: highRetention,
        children: [
          AdaptiveAction.action(
            id: ActionId('recent-document'),
            metadata: const ActionMetadata(
              label: 'Recent document',
              iconKey: 'history',
            ),
            payload: DemoCommand.recentDocument,
            isEnabled: _enabled,
          ),
          const AdaptiveMenuDivider<DemoCommand>(),
          AdaptiveAction.action(
            id: ActionId('browse'),
            metadata: const ActionMetadata(
              label: 'Browse files',
              iconKey: 'browse',
            ),
            payload: DemoCommand.browse,
            isEnabled: _enabled,
          ),
        ],
      ),
      divider,
      AdaptiveAction.menu(
        id: ActionId('share'),
        metadata: const ActionMetadata(label: 'Share', iconKey: 'share'),
        isEnabled: _enabled,
        children: [
          AdaptiveAction.action(
            id: ActionId('share-link'),
            metadata: const ActionMetadata(
              label: 'Copy share link',
              iconKey: 'link',
            ),
            payload: DemoCommand.shareLink,
            isEnabled: _enabled,
          ),
          AdaptiveAction.action(
            id: ActionId('share-email'),
            metadata: const ActionMetadata(
              label: 'Share by email',
              iconKey: 'email',
            ),
            payload: DemoCommand.shareEmail,
            isEnabled: _enabled,
          ),
        ],
      ),
      divider,
      AdaptiveAction.action(
        id: ActionId('delete'),
        metadata: const ActionMetadata(
          label: 'Delete',
          tooltip: 'Delete document',
          iconKey: 'delete',
          isDestructive: true,
        ),
        payload: DemoCommand.delete,
        isEnabled: _enabled,
        placementPolicy: lowRetention,
      ),
      AdaptiveAction.action(
        id: ActionId('help'),
        metadata: const ActionMetadata(label: 'Help', iconKey: 'help'),
        payload: DemoCommand.help,
        isEnabled: _enabled,
      ),
      AdaptiveAction.action(
        id: ActionId('toggle-renderer'),
        metadata: ActionMetadata(
          label: switch (_renderer) {
            DemoRenderer.material => 'Switch to Apple',
            DemoRenderer.apple => 'Switch to Material',
          },
          subtitle: switch (_renderer) {
            DemoRenderer.material => 'Currently using Material UI',
            DemoRenderer.apple => 'Currently using Apple UI',
          },
          iconKey: 'renderer',
        ),
        payload: DemoCommand.toggleRenderer,
        placementPolicy: overflowOnly,
      ),
      AdaptiveAction.action(
        id: ActionId('toggle-theme'),
        metadata: ActionMetadata(
          label: widget.brightness == Brightness.light
              ? 'Switch to dark theme'
              : 'Switch to light theme',
          iconKey: widget.brightness == Brightness.light
              ? 'theme-dark'
              : 'theme-light',
        ),
        payload: DemoCommand.toggleTheme,
        placementPolicy: overflowOnly,
      ),
      AdaptiveAction.action(
        id: ActionId('toggle-text-direction'),
        metadata: ActionMetadata(
          label: _rightToLeft ? 'Use LTR' : 'Use RTL',
          iconKey: 'text-direction',
        ),
        payload: DemoCommand.toggleTextDirection,
        placementPolicy: overflowOnly,
      ),
    ];
  }

  void _onInvoke(DemoCommand command) {
    setState(() {
      _lastInvocation = command.label;
      switch (command) {
        case DemoCommand.toggleRenderer:
          _renderer = switch (_renderer) {
            DemoRenderer.material => DemoRenderer.apple,
            DemoRenderer.apple => DemoRenderer.material,
          };
          break;
        case DemoCommand.toggleTextDirection:
          _rightToLeft = !_rightToLeft;
          break;
        case DemoCommand.toggleTheme ||
            DemoCommand.save ||
            DemoCommand.open ||
            DemoCommand.recentDocument ||
            DemoCommand.browse ||
            DemoCommand.shareLink ||
            DemoCommand.shareEmail ||
            DemoCommand.delete ||
            DemoCommand.help:
          break;
      }
    });
    if (command == DemoCommand.toggleTheme) {
      widget.onThemeToggle();
    }
  }

  double _maximumMaterialAppBarActionWidth(
    BuildContext context, {
    required double windowWidth,
    required bool centerTitle,
  }) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: _kToolbarTitle,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final availableWidth = centerTitle
        ? (windowWidth - titlePainter.width) / 2 - _kAppBarEndPadding
        : windowWidth -
              _kAppBarLeadingWidth -
              _kAppBarTitleSpacing -
              titlePainter.width -
              _kAppBarEndPadding;
    return math.max(minimumActionWidth, availableWidth);
  }
}

Widget? _materialIconBuilder(
  BuildContext context,
  AdaptiveAction<DemoCommand> action,
) => switch (action.metadata.iconKey) {
  'save' => const Icon(Icons.save),
  'open' => const Icon(Icons.folder_open),
  'history' => const Icon(Icons.history),
  'browse' => const Icon(Icons.folder),
  'share' => const Icon(Icons.share),
  'link' => const Icon(Icons.link),
  'email' => const Icon(Icons.email),
  'delete' => const Icon(Icons.delete),
  'help' => const Icon(Icons.help_outline),
  'renderer' => const Icon(Icons.widgets_outlined),
  'theme-dark' => const Icon(Icons.dark_mode_outlined),
  'theme-light' => const Icon(Icons.light_mode_outlined),
  'text-direction' => const Icon(Icons.format_textdirection_l_to_r),
  _ => null,
};

Widget _materialActionButtonBuilder(
  BuildContext context,
  AdaptiveAction<DemoCommand> action,
  VoidCallback? onPressed,
  MaterialActionButtonDefaultBuilder<DemoCommand> defaultBuilder,
) => switch (action.id.value) {
  'save' => KeyedSubtree(
    key: customSaveButtonKey,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: defaultBuilder(context, action, onPressed),
    ),
  ),
  'open' => KeyedSubtree(
    key: customOpenButtonKey,
    child: Badge(
      alignment: AlignmentDirectional.topEnd,
      child: defaultBuilder(context, action, onPressed),
    ),
  ),
  'delete' => KeyedSubtree(
    key: customDeleteButtonKey,
    child: IconButton(
      tooltip: action.metadata.tooltip ?? action.metadata.label,
      color: Theme.of(context).colorScheme.error,
      iconSize: const MaterialAdaptiveActionsStyle().iconSize,
      onPressed: onPressed,
      icon: const Icon(Icons.delete_forever_outlined),
    ),
  ),
  _ => defaultBuilder(context, action, onPressed),
};

Widget _materialOverflowButtonBuilder(
  BuildContext context,
  VoidCallback onPressed,
  MaterialOverflowButtonDefaultBuilder defaultBuilder,
) => IconButton.filledTonal(
  key: customOverflowButtonKey,
  tooltip: 'Custom More actions',
  onPressed: onPressed,
  icon: const Icon(Icons.apps),
);
