import 'package:adaptive_actions/adaptive_actions.dart';
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
const actionRegionLayoutSelectorKey = ValueKey('action-region-layout-selector');
const materialPresentationSelectorKey = ValueKey(
  'material-presentation-selector',
);
const cupertinoPresentationSelectorKey = ValueKey(
  'cupertino-presentation-selector',
);
const actionLanguageSelectorKey = ValueKey('action-language-selector');
const textScaleSliderKey = ValueKey('text-scale-slider');
const previewListKey = ValueKey('preview-list');
const appBarActionFrameKey = ValueKey('app-bar-action-frame');
const appBarActionsKey = ValueKey('app-bar-actions');
const previewActionsKey = ValueKey('preview-actions');
const localizedComparisonActionsKey = ValueKey('localized-comparison-actions');

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
  DemoPresentation material = DemoPresentation.automatic;
  DemoPresentation cupertino = DemoPresentation.automatic;
}

enum DemoPresentation { automatic, extended, iconOnly, mixed }

enum DemoActionLanguage { english, chinese }

extension DemoActionLanguageValue on DemoActionLanguage {
  String get label => switch (this) {
    DemoActionLanguage.english => 'English',
    DemoActionLanguage.chinese => '中文',
  };

  String get languageCode => switch (this) {
    DemoActionLanguage.english => 'en',
    DemoActionLanguage.chinese => 'zh',
  };
}

enum DemoActionRegionLayout {
  compact,
  spaceBetween,
  spaceAround,
  spaceEvenly,
  insertedExpandedGap,
  insertedFixedGap,
}

extension DemoActionRegionLayoutValue on DemoActionRegionLayout {
  bool get usesFiniteTarget => this != DemoActionRegionLayout.compact;

  String get label => switch (this) {
    DemoActionRegionLayout.compact => 'Compact',
    DemoActionRegionLayout.spaceBetween => 'Space between',
    DemoActionRegionLayout.spaceAround => 'Space around',
    DemoActionRegionLayout.spaceEvenly => 'Space evenly',
    DemoActionRegionLayout.insertedExpandedGap =>
      'Expanded gap after second slot',
    DemoActionRegionLayout.insertedFixedGap =>
      'Fixed 48 px gap after second slot',
  };

  ActionRegionMainAxisDistribution get distribution => switch (this) {
    DemoActionRegionLayout.compact ||
    DemoActionRegionLayout.insertedExpandedGap ||
    DemoActionRegionLayout.insertedFixedGap =>
      ActionRegionMainAxisDistribution.compact,
    DemoActionRegionLayout.spaceBetween =>
      ActionRegionMainAxisDistribution.spaceBetween,
    DemoActionRegionLayout.spaceAround =>
      ActionRegionMainAxisDistribution.spaceAround,
    DemoActionRegionLayout.spaceEvenly =>
      ActionRegionMainAxisDistribution.spaceEvenly,
  };

  ActionRegionLayoutDelegate? get layoutDelegate => switch (this) {
    DemoActionRegionLayout.insertedExpandedGap =>
      const _DemoInsertedGapLayoutDelegate.expanded(),
    DemoActionRegionLayout.insertedFixedGap =>
      const _DemoInsertedGapLayoutDelegate.fixed(48),
    _ => null,
  };
}

final class _DemoInsertedGapLayoutDelegate
    implements ActionRegionLayoutDelegate {
  const _DemoInsertedGapLayoutDelegate.expanded() : _fixedExtent = null;

  const _DemoInsertedGapLayoutDelegate.fixed(double extent)
    : _fixedExtent = extent;

  final double? _fixedExtent;

  @override
  ActionRegionLayoutReservation reserve(
    ActionRegionLayoutReservationInput input,
  ) => ActionRegionLayoutReservation(
    fixedExtent: input.actionIds.isEmpty ? 0 : _fixedExtent ?? 0,
  );

  @override
  ActionRegionLayoutPlan layout(ActionRegionLayoutInput input) {
    final entries = <ActionRegionLayoutEntry>[];
    var gapInserted = false;
    for (final (index, slot) in input.slots.indexed) {
      if (index == 2) {
        entries.add(_gap(input.reservation));
        gapInserted = true;
      }
      entries.add(ActionRegionLayoutEntry.slot(slot.id));
    }
    if (!gapInserted && input.reservation.fixedExtent > 0) {
      entries.add(_gap(input.reservation));
    }
    return ActionRegionLayoutPlan(entries: entries);
  }

  ActionRegionLayoutEntry _gap(ActionRegionLayoutReservation reservation) =>
      _fixedExtent == null
      ? ActionRegionLayoutEntry.flexGap()
      : ActionRegionLayoutEntry.fixedGap(reservation.fixedExtent);
}

extension DemoPresentationLabel on DemoPresentation {
  String get label => switch (this) {
    DemoPresentation.automatic => 'Automatic',
    DemoPresentation.extended => 'Force icon + label',
    DemoPresentation.iconOnly => 'Force icon only',
    DemoPresentation.mixed => 'Mixed per action',
  };
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
}
