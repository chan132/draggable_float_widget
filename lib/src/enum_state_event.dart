/// The State of [DraggableFloatWidget].
enum DraggableFloatWidgetState {
  /// Normal Display.
  SHOW,

  /// Dragging.
  DRAG_IN_PROGRESS,

  /// Complete the drag.
  ///
  /// Auto attach to the boundary.
  AUTO_ATTACH_IN_PROGRESS,

  /// Received 'show' event.
  ///
  ///
  /// The animation of the 'show' event is under execution.
  ANIM_SHOW_IN_PROGRESS,

  /// Received 'hide' event.
  ///
  ///
  /// The animation of the 'hide' event is under execution.
  ANIM_HIDE_IN_PROGRESS,

  /// Hide.
  HIDE,
}

/// Operation event
enum OperateEvent {
  /// Hide.
  OPERATE_HIDE,

  /// Show.
  OPERATE_SHOW,
}
