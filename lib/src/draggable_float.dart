import 'dart:async';
import 'dart:ui';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';

import 'enum_state_event.dart';
import 'event_operate.dart';
import 'model_base_config.dart';

/// The default value of [DraggableFloatWidget.width].
const double defaultWidgetWidth = 60;

/// The default value of [DraggableFloatWidget.height].
const double defaultWidgetHeight = 60;

/// This is a draggable and floating Flutter widget.
///
/// 1. How to use:
/// ```dart
/// // the first way
/// OverlayEntry _overlayEntry = OverlayEntry(
///   builder: (context) {
///     return DraggableFloatWidget(
///       width: 60,
///       height: 60,
///       config: OptimizeDragPositionConfig(
///         initPositionY: 100,
///       ),
///       onTap: () => print("Draggable float widget onTap!"),
///     );
///   },
/// );
/// Overlay.of(context).insert(_overlayEntry);
///
/// // the second way (Not recommended)
/// Stack(
///   children: [
///     DraggableFloatWidget(
///       width: 60,
///       height: 60,
///       config: OptimizeDragPositionConfig(
///         isFullScreen: false,
///         initPositionY: 100,
///       ),
///       onTap: () => print("Draggable float widget onTap!"),
///     ),
///   ],
/// )
/// ```
///
/// 2. How to send events externally:
/// ```dart
/// EventBus _eventBus = EventBus();
/// NotificationListener(
///   onNotification: (notification) {
///     if (notification is ScrollStartNotification) {
///       _eventBus.fire(OperateHideEvent());
///     } else if (notification is ScrollEndNotification) {
///       _eventBus.fire(OperateShowEvent());
///     }
///     return true;
///   },
///   child: ScrollView(),
/// )
/// ```
class DraggableFloatWidget extends StatefulWidget {
  /// The width of [DraggableFloatWidget].
  final double width;

  /// The height of [DraggableFloatWidget].
  final double height;

  /// The instance of [EventBus].
  final EventBus? eventBusInstance;

  /// The base config of [DraggableFloatWidget].
  final DraggableFloatWidgetBaseConfig config;

  /// The [child] contained by the [DraggableFloatWidget].
  final Widget? child;

  /// The click callback of [DraggableFloatWidget].
  ///
  /// See [GestureDetector.onTap] for details.
  final GestureTapCallback? onTap;

  const DraggableFloatWidget({
    Key? key,
    this.width = defaultWidgetWidth,
    this.height = defaultWidgetHeight,
    this.eventBusInstance,
    this.config = const DraggableFloatWidgetBaseConfig(),
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CustomDraggableFloatState();
}

class _CustomDraggableFloatState extends State<DraggableFloatWidget>
    with TickerProviderStateMixin<DraggableFloatWidget> {
  /// Parameters related to the component boundary.
  late double _screenWidth,
      _screenHeight,
      _halfScreenW,
      _statusBarHeight,
      _bottomBarHeight; // screen size
  late double _variableTop, _top, _bottom, _left, _right; // widget boundary

  /// The current location and status of component.
  late double positionX, positionY;
  late DraggableFloatWidgetState currentState;

  /// Parameters related to component events.
  StreamSubscription? eventSubscription;
  List<OperateEvent> receivedEventList = [];

  /// Parameters related to component animation.
  late AnimationController animationController;
  late Animation<double> animation;
  late double animStartPx, animStartPy; // animation start location
  late double animEndPx, animEndPy; // animation end location
  Timer? delayShowTimer; // delayed display of Timer

  @override
  void initState() {
    /// 0. Initialize the component location, boundaries, and status.
    _initBorderSize();

    /// 1. Add event subscription.
    _initEventSubscription();

    /// 2. Initialize animation.
    _initAnimation();
    super.initState();
  }

  /// Initialize data related to component locations.
  _initBorderSize() {
    // 1. Relevant data of the screen.
    var _mediaQueryData = MediaQueryData.fromWindow(window);
    _screenWidth = _mediaQueryData.size.width;
    _screenHeight = _mediaQueryData.size.height;
    _halfScreenW = _screenWidth / 2;
    _statusBarHeight = _mediaQueryData.padding.top; // SafeArea top
    _bottomBarHeight = _mediaQueryData.padding.bottom; // SafeArea bottom
    // 2. Determine the boundary.
    _variableTop = _statusBarHeight + widget.config.appBarHeight;
    _top = widget.config.borderTop +
        (widget.config.isFullScreen && widget.config.borderTopContainTopBar
            ? _variableTop
            : 0);
    _bottom = _screenHeight -
        widget.height -
        widget.config.borderBottom -
        _bottomBarHeight -
        (widget.config.isFullScreen ? 0 : _variableTop); // 需要减去全面屏的bottom bar高度
    _left = widget.config.borderLeft;
    _right = _screenWidth - widget.width - widget.config.borderRight;
    // 3. Determine the location.
    currentState = DraggableFloatWidgetState.SHOW;
    positionX = widget.config.initPositionXInLeft ? _left : _right;
    positionY = widget.config.initPositionYInTop
        ? _top + widget.config.initPositionYMarginBorder
        : _bottom - widget.config.initPositionYMarginBorder;
  }

  /// Initialize event subscription.
  _initEventSubscription() {
    if (widget.eventBusInstance == null) return;
    eventSubscription = widget.eventBusInstance!.on().listen((event) {
      // 1. When an event is received, DraggableFloatWidget's current state is
      // the case of DRAG_IN_PROGRESS or AUTO_ATTACH_IN_PROGRESS, and the event
      // will not be handled.
      if (currentState == DraggableFloatWidgetState.DRAG_IN_PROGRESS ||
          currentState == DraggableFloatWidgetState.AUTO_ATTACH_IN_PROGRESS)
        return;
      // 2. Handle the event.
      if (event.runtimeType == OperateHideEvent) {
        _print("OperateHideEvent received!");
        _handleReceivedEvent(OperateEvent.OPERATE_HIDE);
      } else if (event.runtimeType == OperateShowEvent) {
        _print("OperateShowEvent received!");
        _handleReceivedEvent(OperateEvent.OPERATE_SHOW);
      }
    });
  }

  /// Initialize animation.
  ///
  /// The principle is to execute only one animation at a time.
  _initAnimation() {
    /// 1. Complete the initialization of the animation.
    animationController = AnimationController(
      duration: widget.config.animDuration,
      vsync: this,
    );
    animation = Tween(begin: 0.0, end: 1.0).animate(animationController);

    /// 2. Add status listener.
    animation.addStatusListener((status) {
      // 0. Only handle the status of animation playback, other states do not
      // handle.
      if (status != AnimationStatus.completed) return;
      // 1. After the animation, refresh the page should be in the status.
      var _tempAnimEndState =
          currentState == DraggableFloatWidgetState.ANIM_HIDE_IN_PROGRESS
              ? DraggableFloatWidgetState.HIDE
              : DraggableFloatWidgetState.SHOW;
      _refreshDragState(_tempAnimEndState);
      // 2. There are no new events in the current list.
      if (receivedEventList.isEmpty) return;
      // 3. Take out the last event in the list and empty the list.
      OperateEvent _event = receivedEventList.last;
      receivedEventList.clear();
      // 4.If the component state after the last event is consistent with the
      // component state after the current animation, refresh directly,
      // otherwise perform the component animation of the last event.
      var _tempNextState = _event == OperateEvent.OPERATE_HIDE
          ? DraggableFloatWidgetState.HIDE
          : DraggableFloatWidgetState.SHOW;
      if (_tempAnimEndState == _tempNextState) return;
      _handleScrollEvent(_event);
    });

    /// 3. Add value change listener to the animation.
    animation.addListener(_handleAnimValueChange);
  }

  _handleAnimValueChange() {
    double _value = animation.value;
    double _tempAbsX = (animStartPx - animEndPx).abs();
    double _tempAbsY = (animStartPy - animEndPy).abs();
    // The current status of the component is AUTO_ATTACH_IN_PROGRESS.
    if (currentState == DraggableFloatWidgetState.AUTO_ATTACH_IN_PROGRESS) {
      double _tempX = animEndPx <= _halfScreenW
          ? (animStartPx < _left
              ? animStartPx + _tempAbsX * _value
              : animEndPx + _tempAbsX * (1 - _value))
          : (animStartPx < _right
              ? animStartPx + _tempAbsX * _value
              : animEndPx + _tempAbsX * (1 - _value));
      double _tempY = animEndPy;
      if (animStartPy < _top) {
        _tempY = animStartPy + _tempAbsY * _value;
      } else if (animStartPy > _bottom) {
        _tempY = animEndPy + _tempAbsY * (1 - _value);
      }
      positionX = _tempX;
      positionY = _tempY;
      _safeSetState();
      return;
    }
    // The current status of the component is ANIM_SHOW_IN_PROGRESS.
    if (currentState == DraggableFloatWidgetState.ANIM_SHOW_IN_PROGRESS) {
      positionX = animEndPx <= _halfScreenW
          ? animStartPx + _tempAbsX * _value
          : animEndPx + _tempAbsX * (1 - _value);
      _safeSetState();
      return;
    }
    // The current status of the component is ANIM_HIDE_IN_PROGRESS.
    if (currentState == DraggableFloatWidgetState.ANIM_HIDE_IN_PROGRESS) {
      positionX = animEndPx <= _halfScreenW
          ? animEndPx + _tempAbsX * (1 - _value)
          : animStartPx + _tempAbsX * _value;
      _safeSetState();
      return;
    }
  }

  @override
  void dispose() {
    eventSubscription?.cancel();
    animationController.dispose();
    _cancelDelayShowTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// 1. Build a dragged component.
    var _dragWidget = _buildDragWidget();

    /// 2. Build a draggable float component.
    return Positioned(
      left: positionX,
      top: positionY,
      child: currentState != DraggableFloatWidgetState.SHOW &&
              currentState != DraggableFloatWidgetState.DRAG_IN_PROGRESS
          ? _dragWidget
          : Draggable(
              child: _dragWidget,
              childWhenDragging: Container(),
              feedback: _dragWidget,
              onDragStarted: () {
                _print("drag Start!");
                _refreshDragState(DraggableFloatWidgetState.DRAG_IN_PROGRESS);
              },
              onDragEnd: (details) {
                _print(
                    "drag End! DraggableDetails(wasAccepted: ${details.wasAccepted}, velocity: ${details.velocity.toString()}, offset: ${details.offset.toString()})");
                _handleDragEnd(details.offset);
              },
              onDragCompleted: () => _print("drag Completed!"),
              onDraggableCanceled: (velocity, offset) => _print(
                  "drag Canceled! {velocity: ${velocity.toString()}, offset: ${offset.toString()}}"),
            ),
    );
  }

  _buildDragWidget() => Container(
        width: widget.width,
        height: widget.height,
        child: GestureDetector(
          onTap: () => widget.onTap?.call(),
          child: widget.child,
        ),
      );

  _handleDragEnd(Offset _offset) {
    // 0. Assign the position at which the animation begins.
    animStartPx = _offset.dx;
    animStartPy = _offset.dy - (widget.config.isFullScreen ? 0 : _variableTop);
    // 1. Calculate the position at the end of the animation.
    animEndPx = _offset.dx + widget.width / 2 <= _halfScreenW ? _left : _right;
    if (animStartPy <= _top) {
      animEndPy = _top;
    } else if (animStartPy > _top && animStartPy <= _bottom) {
      animEndPy = animStartPy;
    } else {
      animEndPy = _bottom;
    }
    // 2. Start animation.
    _startAnimation(DraggableFloatWidgetState.AUTO_ATTACH_IN_PROGRESS);
  }

  /// Handle the event.
  _handleReceivedEvent(OperateEvent event) {
    // If the animation is being performed, add the event to the event queue.
    if (currentState == DraggableFloatWidgetState.ANIM_SHOW_IN_PROGRESS ||
        currentState == DraggableFloatWidgetState.ANIM_HIDE_IN_PROGRESS) {
      receivedEventList.add(event);
      return;
    }
    // Handle the event.
    _handleScrollEvent(event);
  }

  _handleScrollEvent(OperateEvent event) {
    // 0-1. Empty the list of events and cancel the previous delay display of
    // Timer.
    receivedEventList.clear();
    _cancelDelayShowTimer();
    // 0-2. The component state after handling the received event is not
    // processed when it is consistent with the current component status.
    if ((currentState == DraggableFloatWidgetState.SHOW &&
            event == OperateEvent.OPERATE_SHOW) ||
        (currentState == DraggableFloatWidgetState.HIDE &&
            event == OperateEvent.OPERATE_HIDE)) return;
    // 1. Assign the position at which the animation begins.
    animStartPx = positionX;
    animStartPy = positionY;
    // 2. Calculate the position at the end of the animation.
    if (event == OperateEvent.OPERATE_HIDE) {
      animEndPx = positionX <= _halfScreenW
          ? widget.config.exposedPartWidthWhenHidden - widget.width
          : _screenWidth - widget.config.exposedPartWidthWhenHidden;
    } else {
      animEndPx = positionX <= _halfScreenW ? _left : _right;
    }
    animEndPy = positionY;
    // 3. Start animation.
    if (currentState == DraggableFloatWidgetState.SHOW &&
        event == OperateEvent.OPERATE_HIDE) {
      _startAnimation(DraggableFloatWidgetState.ANIM_HIDE_IN_PROGRESS);
    } else if (currentState == DraggableFloatWidgetState.HIDE &&
        event == OperateEvent.OPERATE_SHOW) {
      _startDelayShowTimer();
    }
  }

  _startDelayShowTimer() {
    delayShowTimer = Timer(widget.config.delayShowDuration, () {
      _startAnimation(DraggableFloatWidgetState.ANIM_SHOW_IN_PROGRESS);
    });
  }

  _cancelDelayShowTimer() {
    delayShowTimer?.cancel();
    delayShowTimer = null;
  }

  _startAnimation(DraggableFloatWidgetState state) {
    // Refresh the current state of the component.
    _refreshDragState(state);
    // Start animation.
    animationController.reset();
    animationController.forward();
  }

  _refreshDragState(DraggableFloatWidgetState state) {
    currentState = state;
    _print("current state: ${state.toString().split(".").last}");
    _safeSetState();
  }

  _safeSetState() {
    if (mounted) setState(() {});
  }

  _print(String message) {
    if (widget.config.debug) print("[CDF] Widget $message");
  }
}
