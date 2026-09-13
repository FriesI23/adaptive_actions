import 'package:flutter/cupertino.dart';

/// Builds a Cupertino tooltip wrapper for [child].
///
/// The adaptive-actions renderer resolves tooltip visibility and text before
/// calling this builder. Implementations should avoid adding duplicate tooltip
/// semantics when the wrapped control already owns them.
typedef AdaptiveCupertinoTooltipBuilder =
    Widget Function(BuildContext context, String message, Widget child);

/// A Cupertino-styled tooltip backed by Flutter's [RawTooltip] interaction.
///
/// The tooltip prefers the space below [child] and automatically moves above
/// it when the lower side cannot fit.
final class AdaptiveCupertinoTooltip extends StatelessWidget {
  /// Creates a Cupertino-styled tooltip.
  const AdaptiveCupertinoTooltip({
    super.key,
    required this.message,
    required this.child,
    this.visible = true,
    this.excludeFromSemantics = false,
    this.verticalGap = 4,
    this.preferBelow = true,
    this.screenMargin = 10,
    this.positionDelegate,
  }) : assert(verticalGap >= 0 && verticalGap < double.infinity),
       assert(screenMargin >= 0 && screenMargin < double.infinity);

  /// The text displayed in the tooltip.
  final String message;

  /// The widget that triggers the tooltip.
  final Widget child;

  /// Whether the tooltip interaction is installed around [child].
  final bool visible;

  /// Whether [message] is omitted from tooltip semantics.
  final bool excludeFromSemantics;

  /// The empty vertical space between the tooltip and [child].
  final double verticalGap;

  /// Whether the tooltip prefers the space below [child].
  final bool preferBelow;

  /// The minimum distance from the overlay's edges.
  final double screenMargin;

  /// An optional override for the tooltip's overlay position.
  ///
  /// When supplied, [verticalGap], [preferBelow], and [screenMargin] do not
  /// affect positioning.
  final TooltipPositionDelegate? positionDelegate;

  Offset _defaultPosition(TooltipPositionContext context) =>
      positionDependentBox(
        size: context.overlaySize,
        childSize: context.tooltipSize,
        target: context.target,
        verticalOffset: context.targetSize.height / 2 + verticalGap,
        preferBelow: preferBelow,
        margin: screenMargin,
      );

  @override
  Widget build(BuildContext context) => !visible || message.isEmpty
      ? child
      : RawTooltip(
          semanticsTooltip: excludeFromSemantics ? null : message,
          ignorePointer: true,
          positionDelegate: positionDelegate ?? _defaultPosition,
          tooltipBuilder: (context, animation) => FadeTransition(
            opacity: animation,
            child: CupertinoPopupSurface(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  message,
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(
                        color: CupertinoColors.label.resolveFrom(context),
                        fontSize: 12,
                      ),
                ),
              ),
            ),
          ),
          child: child,
        );
}
