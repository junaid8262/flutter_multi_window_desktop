// src/window_controller.dart

import 'dart:ui';
import 'Main_Window_Controller_Impl.dart';
import 'window_controller_impl.dart';

/// The [WindowController] instance used to control a window.
abstract class WindowController {
  WindowController();

  /// Factory constructor to create a [WindowController] from a window ID.
  factory WindowController.fromWindowId(int id) {
    if (id == 0) {
      return MainWindowController();
    }
    return WindowControllerMainImpl(id);
  }

  /// Factory constructor to create a [WindowController] for the main window.
  factory WindowController.main() {
    return MainWindowController();
  }

  /// The ID of the window.
  /// - `0` indicates the main window.
  int get windowId;

  /// Close the window.
  Future<void> close();

  /// Show the window.
  Future<void> show();

  /// Hide the window.
  Future<void> hide();

  /// Set the window's frame rectangle.
  Future<void> setFrame(Rect frame);

  /// Center the window on the screen.
  Future<void> center();

  /// Set the window's title.
  Future<void> setTitle(String title);

  /// Set whether the window is resizable. Only available on macOS.
  ///
  /// Most useful for ensuring windows cannot be resized. Windows are
  /// resizable by default, so there's no need to explicitly define a window
  /// as resizable unless you want to restrict it.
  Future<void> resizable(bool resizable);

  /// Set the frame autosave name. Available only on macOS.
  Future<void> setFrameAutosaveName(String name);

  /// Abstract method to invoke a method via the method channel.
  ///
  /// This method should be implemented by all subclasses to handle
  /// method channel invocations with appropriate request queueing.
  Future<dynamic> invokeMethod(String method, [dynamic arguments]);
}
