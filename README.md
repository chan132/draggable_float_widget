# draggable_float_widget

This is a draggable and floating Flutter widget, which can control its visibility through the scrolling event of ScrollView.



## Usage

To use this plugin, add `draggable_float_widget` as a dependency in your pubspec.yaml file.

#### constructor

* the constructor of component

  ``` dart
  DraggableFloatWidget({
    Key? key,
    this.width = defaultWidgetWidth,
    this.height = defaultWidgetHeight,
    this.eventStreamController,
    this.config = const DraggableFloatWidgetBaseConfig(),
    required this.child,
    this.onTap,
  }) : super(key: key);
  ```

* special field instructions

  | property         | description                               | default                          |
  | ---------------- | ----------------------------------------- | -------------------------------- |
  | eventStreamController | The [StreamController] of [OperateEvent]                | null                             |
  | config           | the base config of [DraggableFloatWidget] | DraggableFloatWidgetBaseConfig() |

* the base config of component

  ``` dart
  DraggableFloatWidgetBaseConfig({
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
  ```

#### example

* the first, add scroll listener

  ⚠️Ignore this step if the component is not affected by ScrollView scrolling, and you don't need to pass an StreamController instance into the instance.

  ``` dart
  NotificationListener(
    onNotification: (notification) {
      if (notification is ScrollStartNotification) {
        eventStreamController.add(OperateEvent.OPERATE_HIDE);
      } else if (notification is ScrollEndNotification) {
        eventStreamController.add(OperateEvent.OPERATE_SHOW);
      }
      return true;
    },
    child: ListView(...),
  )
  ```

* the first way: stack mode

  ```dart
  Stack(
    children: [
      listView,
      DraggableFloatWidget(
        child: child,
        eventStreamController: eventStreamController,
        config: DraggableFloatWidgetBaseConfig(
          isFullScreen: false,
          initPositionYInTop: false,
          initPositionYMarginBorder: 50,
          borderBottom: navigatorBarHeight + defaultBorderWidth,
        ),
        onTap: () => print("Drag onTap!"),
      )
    ],
  )
  ```

  ![stack mode](https://raw.githubusercontent.com/chan132/draggable_float_widget/master/images/stack_mode.gif)

* the second way: overlay mode

  ```dart
  _overlayEntry = OverlayEntry(builder: (context) {
    return DraggableFloatWidget(
      child: widget.child,
      eventStreamController: widget.eventStreamController,
      config: DraggableFloatWidgetBaseConfig(
        initPositionYInTop: false,
        initPositionYMarginBorder: 50,
        borderTopContainTopBar: true,
        borderBottom: widget.navigatorBarHeight + defaultBorderWidth,
      ),
      onTap: () => print("Drag onTap!"),
    );
  });
  
  /// Warning: context cannot be the context of MaterialApp
  Overlay.of(context)?.insert(_overlayEntry!);
  ```
  
  ![overlay mode](https://raw.githubusercontent.com/chan132/draggable_float_widget/master/images/overlay_mode.gif)



## Contributions

If you encounter any problem or the library is missing a feature feel free to open an issue. Feel free to fork, improve the package and make pull request.



## License

[MIT](https://choosealicense.com/licenses/mit/)

