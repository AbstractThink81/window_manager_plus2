import 'package:flutter/material.dart';
import 'package:window_manager_plus/src/window_manager.dart';

/// A widget for drag to move window.
///
/// When you have hidden the title bar, you can add this widget to move the window position.
///
/// {@tool snippet}
///
/// The sample creates a red box, drag the box to move the window.
///
/// ```dart
/// DragToMoveArea(
///   child: Container(
///     width: 300,
///     height: 32,
///     color: Colors.red,
///   ),
/// )
/// ```
/// {@end-tool}
class DragToMoveArea extends StatefulWidget {
  const DragToMoveArea({
    super.key,
    required this.child,
    this.targetWindow,
  });

  final Widget child;

  /// Window to move when this area is dragged.
  ///
  /// If null, [WindowManagerPlus.current] will be used instead.
  final WindowManagerPlus? targetWindow;

  @override
  State<DragToMoveArea> createState() => _DragToMoveAreaState();
}

class _DragToMoveAreaState extends State<DragToMoveArea> {
  Offset hoverPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final currentTargetWindow =
        widget.targetWindow ?? WindowManagerPlus.current;
    return MouseRegion(
        hitTestBehavior: HitTestBehavior.translucent,
        onHover: (event) {
          hoverPosition = event.position;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            currentTargetWindow.startDragging(
                initialOffset: details.globalPosition - hoverPosition);
          },
          onDoubleTap: () async {
            bool isMaximized = await currentTargetWindow.isMaximized();
            if (!isMaximized) {
              currentTargetWindow.maximize();
            } else {
              currentTargetWindow.unmaximize();
            }
          },
          child: widget.child,
        ));
  }
}
