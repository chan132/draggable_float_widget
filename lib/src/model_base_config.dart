import 'package:flutter/material.dart';

/// The default value of the width of the component boundary.
const double defaultBorderWidth = 3.0;

/// The default value of the width of the exposed part when the component is
/// hidden.
const double defaultExposedPartWidthWhenHidden = 5.0;

/// The base config of [DraggableFloatWidget].
class DraggableFloatWidgetBaseConfig {
  /// Whether full screen.
  ///
  /// true: Overlay + OverlayEntry
  /// false: Used inside stack
  final bool isFullScreen;

  /// The height of [AppBar].
  /// The default value is [kToolbarHeight].
  final double appBarHeight;

  /// Whether the initial position of the component on the x-axis is on the
  /// left side of the screen.
  ///
  /// true: on the left side of the screen
  /// false: on the right side of the screen
  final bool initPositionXInLeft;

  /// Whether the initial position of the component on the y-axis is on the
  /// top side of the screen.
  ///
  /// true: on the top side of the screen
  /// false: on the bottom side of the screen
  final bool initPositionYInTop;

  /// The distance between the initial position of the component on the y-axis.
  /// The default value is zero.
  final double initPositionYMarginBorder;

  /// The distance from the left side of the component to the boundary.
  final double borderLeft;

  /// The distance from the right side of the component to the boundary.
  final double borderRight;

  /// The distance from the top side of the component to the boundary.
  final double borderTop;

  /// Whether [borderTop] contains the height of all Bars at the top.
  /// The default value is false.
  ///
  /// If [isFullScreen] is false, [borderTopContainTopBar] is invalid.
  final bool borderTopContainTopBar;

  /// The distance from the bottom side of the component to the boundary.
  final double borderBottom;

  /// The width of the exposed part when the component is hidden.
  final double exposedPartWidthWhenHidden;

  /// The length of time this animation should last.
  final Duration animDuration;

  /// The length of time this delay display timer.
  final Duration delayShowDuration;

  /// Whether to debug mode.
  final bool debug;

  const DraggableFloatWidgetBaseConfig({
    this.isFullScreen = true,
    this.appBarHeight = kToolbarHeight,
    this.initPositionXInLeft = true,
    this.initPositionYInTop = true,
    this.initPositionYMarginBorder = 0,
    this.borderLeft = defaultBorderWidth,
    this.borderRight = defaultBorderWidth,
    this.borderTop = defaultBorderWidth,
    this.borderTopContainTopBar = false,
    this.borderBottom = defaultBorderWidth,
    this.exposedPartWidthWhenHidden = defaultExposedPartWidthWhenHidden,
    this.animDuration = const Duration(milliseconds: 300),
    this.delayShowDuration = const Duration(milliseconds: 500),
    this.debug = false,
  });
}
