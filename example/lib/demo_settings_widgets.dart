import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';

import 'demo_settings.dart';

const _finiteActionWidthDivisions = 17;
const _actionWidthSliderMaximum =
    maximumSimulatedActionWidth +
    (maximumSimulatedActionWidth - minimumActionWidth) /
        _finiteActionWidthDivisions;
const _actionWidthSliderDivisions = _finiteActionWidthDivisions + 1;

String _actionWidthLabel(double? width) =>
    width == null ? 'Unlimited' : '${width.toStringAsFixed(0)} px';

double? _actionWidthFromSlider(double value) =>
    value > maximumSimulatedActionWidth ? null : value;

final class DemoEnvironmentSummary extends StatelessWidget {
  const DemoEnvironmentSummary({
    super.key,
    required this.renderer,
    required this.windowWidth,
    required this.availableActionWidth,
    required this.simulatedMaxActionWidth,
    required this.parentActionHeight,
    required this.effectiveActionWidth,
    required this.centerTitle,
  });

  final DemoRenderer renderer;
  final double windowWidth;
  final double availableActionWidth;
  final double? simulatedMaxActionWidth;
  final double parentActionHeight;
  final double effectiveActionWidth;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 24,
    runSpacing: 8,
    children: [
      Text('Window width: ${windowWidth.toStringAsFixed(0)} px'),
      Text(
        '${renderer == DemoRenderer.material ? 'AppBar' : 'Bottom toolbar'} '
        'available action width: '
        '${availableActionWidth.toStringAsFixed(0)} px',
      ),
      Text('Simulated maximum: ${_actionWidthLabel(simulatedMaxActionWidth)}'),
      Text(
        'Effective action width: ${effectiveActionWidth.toStringAsFixed(0)} px',
      ),
      Text('Parent action height: ${parentActionHeight.toStringAsFixed(0)} px'),
      Text(
        'Title mode: ${renderer == DemoRenderer.apple
            ? 'Cupertino centered'
            : centerTitle
            ? 'Center'
            : 'Normal'}',
      ),
    ],
  );
}

final class DemoActionSettings extends StatelessWidget {
  const DemoActionSettings({
    super.key,
    required this.renderer,
    required this.simulatedMaxActionWidth,
    required this.parentActionHeight,
    required this.actionCount,
    required this.maxPrimaryActions,
    required this.enabled,
    required this.showAppBarActionFrame,
    required this.placement,
    required this.retention,
    required this.dividerVisibility,
    required this.onSimulatedMaxActionWidthChanged,
    required this.onParentActionHeightChanged,
    required this.onMaxPrimaryActionsChanged,
    required this.onEnabledChanged,
    required this.onShowAppBarActionFrameChanged,
    required this.onPlacementChanged,
    required this.onRetentionChanged,
    required this.onDividerVisibilityChanged,
  }) : assert(actionCount >= 0);

  final DemoRenderer renderer;
  final double? simulatedMaxActionWidth;
  final double parentActionHeight;
  final int actionCount;
  final int? maxPrimaryActions;
  final bool enabled;
  final bool showAppBarActionFrame;
  final DemoPlacement placement;
  final DemoRetention retention;
  final DemoDividerVisibility dividerVisibility;
  final ValueChanged<double?> onSimulatedMaxActionWidthChanged;
  final ValueChanged<double> onParentActionHeightChanged;
  final ValueChanged<int?> onMaxPrimaryActionsChanged;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onShowAppBarActionFrameChanged;
  final ValueChanged<DemoPlacement> onPlacementChanged;
  final ValueChanged<DemoRetention> onRetentionChanged;
  final ValueChanged<DemoDividerVisibility> onDividerVisibilityChanged;

  @override
  Widget build(BuildContext context) => switch (renderer) {
    DemoRenderer.material => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simulated maximum action width: '
          '${_actionWidthLabel(simulatedMaxActionWidth)}',
        ),
        Slider(
          key: actionWidthSliderKey,
          min: minimumActionWidth,
          max: _actionWidthSliderMaximum,
          divisions: _actionWidthSliderDivisions,
          label: _actionWidthLabel(simulatedMaxActionWidth),
          value: simulatedMaxActionWidth ?? _actionWidthSliderMaximum,
          onChanged: (value) =>
              onSimulatedMaxActionWidthChanged(_actionWidthFromSlider(value)),
        ),
        SwitchListTile(
          key: appBarActionFrameSwitchKey,
          contentPadding: EdgeInsets.zero,
          title: const Text('Show AppBar action frame'),
          value: showAppBarActionFrame,
          onChanged: onShowAppBarActionFrameChanged,
        ),
        const SizedBox(height: 8),
        Text(
          'Parent action height: ${parentActionHeight.toStringAsFixed(0)} px',
        ),
        Slider(
          key: actionHeightSliderKey,
          min: minimumParentActionHeight,
          max: maximumParentActionHeight,
          divisions: 11,
          label: parentActionHeight.toStringAsFixed(0),
          value: parentActionHeight,
          onChanged: onParentActionHeightChanged,
        ),
        const SizedBox(height: 8),
        const Text('Maximum primary actions'),
        DropdownButton<int>(
          key: maxPrimaryActionsKey,
          value: maxPrimaryActions,
          hint: const Text('Unlimited'),
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('Unlimited')),
            for (var count = 0; count <= actionCount; count += 1)
              DropdownMenuItem(value: count, child: Text('$count')),
          ],
          onChanged: onMaxPrimaryActionsChanged,
        ),
        SwitchListTile(
          key: enabledSwitchKey,
          contentPadding: EdgeInsets.zero,
          title: const Text('Actions enabled'),
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        const Text('Top-level divider visibility'),
        DropdownButton<DemoDividerVisibility>(
          key: dividerVisibilitySelectorKey,
          value: dividerVisibility,
          isExpanded: true,
          items: [
            for (final value in DemoDividerVisibility.values)
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              onDividerVisibilityChanged(value);
            }
          },
        ),
        const Text('Save placement'),
        DropdownButton<DemoPlacement>(
          key: placementSelectorKey,
          value: placement,
          isExpanded: true,
          items: [
            for (final value in DemoPlacement.values)
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              onPlacementChanged(value);
            }
          },
        ),
        const SizedBox(height: 12),
        const Text('Save automatic retention'),
        DropdownButton<DemoRetention>(
          key: retentionSelectorKey,
          value: retention,
          isExpanded: true,
          items: [
            for (final value in DemoRetention.values)
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
          onChanged: placement == DemoPlacement.automatic
              ? (value) {
                  if (value != null) {
                    onRetentionChanged(value);
                  }
                }
              : null,
        ),
      ],
    ),
    DemoRenderer.apple => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simulated maximum action width: '
          '${_actionWidthLabel(simulatedMaxActionWidth)}',
        ),
        cupertino.CupertinoSlider(
          key: actionWidthSliderKey,
          min: minimumActionWidth,
          max: _actionWidthSliderMaximum,
          divisions: _actionWidthSliderDivisions,
          value: simulatedMaxActionWidth ?? _actionWidthSliderMaximum,
          onChanged: (value) =>
              onSimulatedMaxActionWidthChanged(_actionWidthFromSlider(value)),
        ),
        const SizedBox(height: 8),
        Text(
          'Parent action height: ${parentActionHeight.toStringAsFixed(0)} px',
        ),
        cupertino.CupertinoSlider(
          key: actionHeightSliderKey,
          min: minimumParentActionHeight,
          max: maximumParentActionHeight,
          divisions: 11,
          value: parentActionHeight,
          onChanged: onParentActionHeightChanged,
        ),
        _CupertinoSelectionField<int>(
          key: maxPrimaryActionsKey,
          title: 'Maximum primary actions',
          value: maxPrimaryActions,
          nullLabel: 'Unlimited',
          options: [
            for (var count = 0; count <= actionCount; count += 1) count,
          ],
          labelOf: (value) => '$value',
          onChanged: onMaxPrimaryActionsChanged,
        ),
        _CupertinoToggleRow(
          key: enabledSwitchKey,
          title: 'Actions enabled',
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        _CupertinoSelectionField<DemoDividerVisibility>(
          key: dividerVisibilitySelectorKey,
          title: 'Top-level divider visibility',
          value: dividerVisibility,
          options: DemoDividerVisibility.values,
          labelOf: (value) => value.label,
          onChanged: (value) {
            if (value != null) {
              onDividerVisibilityChanged(value);
            }
          },
        ),
        _CupertinoSelectionField<DemoPlacement>(
          key: placementSelectorKey,
          title: 'Save placement',
          value: placement,
          options: DemoPlacement.values,
          labelOf: (value) => value.label,
          onChanged: (value) {
            if (value != null) {
              onPlacementChanged(value);
            }
          },
        ),
        _CupertinoSelectionField<DemoRetention>(
          key: retentionSelectorKey,
          title: 'Save automatic retention',
          value: retention,
          options: DemoRetention.values,
          labelOf: (value) => value.label,
          onChanged: placement == DemoPlacement.automatic
              ? (value) {
                  if (value != null) {
                    onRetentionChanged(value);
                  }
                }
              : null,
        ),
      ],
    ),
  };
}

final class DemoPresentationSettings extends StatelessWidget {
  const DemoPresentationSettings({
    super.key,
    required this.renderer,
    required this.materialPresentation,
    required this.cupertinoPresentation,
    required this.onMaterialChanged,
    required this.onCupertinoChanged,
  });

  final DemoRenderer renderer;
  final DemoPresentation materialPresentation;
  final DemoPresentation cupertinoPresentation;
  final ValueChanged<DemoPresentation?> onMaterialChanged;
  final ValueChanged<DemoPresentation?> onCupertinoChanged;

  @override
  Widget build(BuildContext context) => switch (renderer) {
    DemoRenderer.material => DropdownButton<DemoPresentation>(
      key: materialPresentationSelectorKey,
      value: materialPresentation,
      isExpanded: true,
      items: [
        for (final value in DemoPresentation.values)
          DropdownMenuItem(value: value, child: Text(value.label)),
      ],
      onChanged: onMaterialChanged,
    ),
    DemoRenderer.apple => _CupertinoSelectionField<DemoPresentation>(
      key: cupertinoPresentationSelectorKey,
      title: 'Primary action presentation',
      value: cupertinoPresentation,
      options: DemoPresentation.values,
      labelOf: (value) => value.label,
      onChanged: onCupertinoChanged,
    ),
  };
}

final class DemoAnimationSettings extends StatelessWidget {
  const DemoAnimationSettings({
    super.key,
    required this.renderer,
    required this.fadeDuration,
    required this.resizeDuration,
    required this.onAllChanged,
    required this.onFadeChanged,
    required this.onResizeChanged,
  });

  final DemoRenderer renderer;
  final Duration fadeDuration;
  final Duration resizeDuration;
  final ValueChanged<bool> onAllChanged;
  final ValueChanged<bool> onFadeChanged;
  final ValueChanged<bool> onResizeChanged;

  @override
  Widget build(BuildContext context) => switch (renderer) {
    DemoRenderer.material => Column(
      children: [
        SwitchListTile(
          key: animationEnabledSwitchKey,
          contentPadding: EdgeInsets.zero,
          title: const Text('Animations'),
          subtitle: const Text('Master switch'),
          value:
              fadeDuration != Duration.zero || resizeDuration != Duration.zero,
          onChanged: onAllChanged,
        ),
        SwitchListTile(
          key: animationFadeSwitchKey,
          contentPadding: EdgeInsets.zero,
          title: const Text('Action fade'),
          subtitle: const Text('Fade changing actions and labels'),
          value: fadeDuration != Duration.zero,
          onChanged: onFadeChanged,
        ),
        SwitchListTile(
          key: animationResizeSwitchKey,
          contentPadding: EdgeInsets.zero,
          title: const Text('Boundary resize'),
          subtitle: const Text('Animate the changing boundary width'),
          value: resizeDuration != Duration.zero,
          onChanged: onResizeChanged,
        ),
      ],
    ),
    DemoRenderer.apple => Column(
      children: [
        _CupertinoToggleRow(
          key: animationEnabledSwitchKey,
          title: 'Animations',
          subtitle: 'Master switch',
          value:
              fadeDuration != Duration.zero || resizeDuration != Duration.zero,
          onChanged: onAllChanged,
        ),
        _CupertinoToggleRow(
          key: animationFadeSwitchKey,
          title: 'Action fade',
          subtitle: 'Fade changing actions and labels',
          value: fadeDuration != Duration.zero,
          onChanged: onFadeChanged,
        ),
        _CupertinoToggleRow(
          key: animationResizeSwitchKey,
          title: 'Boundary resize',
          subtitle: 'Animate the changing boundary width',
          value: resizeDuration != Duration.zero,
          onChanged: onResizeChanged,
        ),
      ],
    ),
  };
}

final class DemoBuilderSettings extends StatelessWidget {
  const DemoBuilderSettings({
    super.key,
    required this.renderer,
    required this.customOverflowButton,
    required this.onCustomOverflowButtonChanged,
  });

  final DemoRenderer renderer;
  final bool customOverflowButton;
  final ValueChanged<bool> onCustomOverflowButtonChanged;

  @override
  Widget build(BuildContext context) => switch (renderer) {
    DemoRenderer.material => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Save, Open, and Delete demonstrate selective primary button '
          'builders.',
        ),
        SwitchListTile(
          key: customOverflowButtonSwitchKey,
          contentPadding: EdgeInsets.zero,
          title: const Text('Custom More button'),
          subtitle: const Text('Replace only the overflow menu trigger'),
          value: customOverflowButton,
          onChanged: onCustomOverflowButtonChanged,
        ),
      ],
    ),
    DemoRenderer.apple => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Save, Open, and Delete demonstrate selective primary button '
          'builders.',
        ),
        _CupertinoToggleRow(
          key: customOverflowButtonSwitchKey,
          title: 'Custom More button',
          subtitle: 'Replace only the overflow menu trigger',
          value: customOverflowButton,
          onChanged: onCustomOverflowButtonChanged,
        ),
      ],
    ),
  };
}

final class _CupertinoToggleRow extends StatelessWidget {
  const _CupertinoToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => onChanged(!value),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: cupertino.CupertinoColors.secondaryLabel
                          .resolveFrom(context),
                    ),
                  ),
              ],
            ),
          ),
          cupertino.CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    ),
  );
}

final class _CupertinoSelectionField<T extends Object> extends StatelessWidget {
  const _CupertinoSelectionField({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.nullLabel,
  });

  final String title;
  final T? value;
  final List<T> options;
  final String Function(T value) labelOf;
  final ValueChanged<T?>? onChanged;
  final String? nullLabel;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onChanged == null ? null : () => _showOptions(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(value == null ? nullLabel! : labelOf(value as T)),
          const SizedBox(width: 6),
          const Icon(cupertino.CupertinoIcons.chevron_down, size: 14),
        ],
      ),
    ),
  );

  Future<void> _showOptions(BuildContext context) =>
      cupertino.showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => cupertino.CupertinoActionSheet(
          title: Text(title),
          actions: [
            if (nullLabel != null)
              cupertino.CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  onChanged!(null);
                },
                child: Text(nullLabel!),
              ),
            for (final option in options)
              cupertino.CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  onChanged!(option);
                },
                child: Text(labelOf(option)),
              ),
          ],
          cancelButton: cupertino.CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
}
