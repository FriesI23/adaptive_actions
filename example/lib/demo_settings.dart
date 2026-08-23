import 'package:adaptive_actions/core.dart';
import 'package:adaptive_actions/cupertino.dart'
    show CupertinoActionPresentation;
import 'package:adaptive_actions/material.dart' show MaterialActionPresentation;
import 'package:flutter/foundation.dart';

const titleAlignmentToggleKey = ValueKey('title-alignment-toggle');
const actionWidthSliderKey = ValueKey('action-width-slider');
const actionHeightSliderKey = ValueKey('action-height-slider');
const maxPrimaryActionsKey = ValueKey('max-primary-actions');
const enabledSwitchKey = ValueKey('enabled-switch');
const appBarActionFrameSwitchKey = ValueKey('app-bar-action-frame-switch');
const animationEnabledSwitchKey = ValueKey('animation-enabled-switch');
const animationFadeSwitchKey = ValueKey('animation-fade-switch');
const animationResizeSwitchKey = ValueKey('animation-resize-switch');
const customOverflowButtonSwitchKey = ValueKey('custom-overflow-button-switch');
const customOverflowButtonKey = ValueKey('custom-overflow-button');
const customSaveButtonKey = ValueKey('custom-save-button');
const customOpenButtonKey = ValueKey('custom-open-button');
const customDeleteButtonKey = ValueKey('custom-delete-button');
const placementSelectorKey = ValueKey('placement-selector');
const retentionSelectorKey = ValueKey('retention-selector');
const dividerVisibilitySelectorKey = ValueKey('divider-visibility-selector');
const materialPresentationSelectorKey = ValueKey(
  'material-presentation-selector',
);
const cupertinoPresentationSelectorKey = ValueKey(
  'cupertino-presentation-selector',
);
const previewListKey = ValueKey('preview-list');
const appBarActionFrameKey = ValueKey('app-bar-action-frame');
const appBarActionsKey = ValueKey('app-bar-actions');
const previewActionsKey = ValueKey('preview-actions');

const double? defaultSimulatedMaxActionWidth = null;
const minimumActionWidth = 48.0;
const maximumSimulatedActionWidth = 640.0;
const defaultParentActionHeight = 48.0;
const minimumParentActionHeight = 20.0;
const maximumParentActionHeight = 64.0;
const int? defaultMaxPrimaryActions = null;

enum DemoRenderer { material, apple }

DemoRenderer defaultDemoRenderer(TargetPlatform platform) => switch (platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => DemoRenderer.apple,
  _ => DemoRenderer.material,
};

final class DemoPresentationValues {
  MaterialActionPresentation? material;
  CupertinoActionPresentation? cupertino;
}

extension DemoRendererValue on DemoRenderer {
  String get label => switch (this) {
    DemoRenderer.material => 'Material',
    DemoRenderer.apple => 'Apple',
  };
}

enum DemoPlacement { automatic, pinned, overflowOnly, hidden }

extension DemoPlacementValue on DemoPlacement {
  String get label => switch (this) {
    DemoPlacement.automatic => 'Automatic',
    DemoPlacement.pinned => 'Pinned',
    DemoPlacement.overflowOnly => 'Overflow only',
    DemoPlacement.hidden => 'Hidden',
  };

  ActionPlacement get placement => switch (this) {
    DemoPlacement.automatic => ActionPlacement.automatic,
    DemoPlacement.pinned => ActionPlacement.pinned,
    DemoPlacement.overflowOnly => ActionPlacement.overflowOnly,
    DemoPlacement.hidden => ActionPlacement.hidden,
  };
}

enum DemoRetention { low, normal, high }

extension DemoRetentionValue on DemoRetention {
  String get label => switch (this) {
    DemoRetention.low => 'Low',
    DemoRetention.normal => 'Normal',
    DemoRetention.high => 'High',
  };

  PrimaryRetentionPriority get priority => switch (this) {
    DemoRetention.low => PrimaryRetentionPriority.low,
    DemoRetention.normal => PrimaryRetentionPriority.normal,
    DemoRetention.high => PrimaryRetentionPriority.high,
  };
}

enum DemoDividerVisibility { both, menuOnly, primaryOnly, hidden }

extension DemoDividerVisibilityValue on DemoDividerVisibility {
  String get label => switch (this) {
    DemoDividerVisibility.both => 'Both (true / true)',
    DemoDividerVisibility.menuOnly => 'Menu only (false / true)',
    DemoDividerVisibility.primaryOnly => 'Primary only (true / false)',
    DemoDividerVisibility.hidden => 'Hidden (false / false)',
  };

  bool get showInPrimary => switch (this) {
    DemoDividerVisibility.both || DemoDividerVisibility.primaryOnly => true,
    DemoDividerVisibility.menuOnly || DemoDividerVisibility.hidden => false,
  };

  bool get showInMenu => switch (this) {
    DemoDividerVisibility.both || DemoDividerVisibility.menuOnly => true,
    DemoDividerVisibility.primaryOnly || DemoDividerVisibility.hidden => false,
  };
}

extension MaterialActionPresentationLabel on MaterialActionPresentation {
  String get demoLabel => switch (this) {
    MaterialActionPresentation.extended => 'Force icon + label',
    MaterialActionPresentation.iconOnly => 'Force icon only',
  };
}

extension CupertinoActionPresentationLabel on CupertinoActionPresentation {
  String get demoLabel => switch (this) {
    CupertinoActionPresentation.extended => 'Force icon + label',
    CupertinoActionPresentation.iconOnly => 'Force icon only',
  };
}
