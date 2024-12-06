// desktop_multi_window.dart

import 'dart:async';
import 'package:flutter/services.dart';

import 'src/channels.dart';
import 'src/window_controller.dart';
import 'src/window_controller_impl.dart';
import 'src/request_queue.dart';

export 'src/window_controller.dart';

class DesktopMultiWindow {
  // Registry to keep track of all window controllers
  static final Map<int, WindowController> _windowControllers = {};

  // Global RequestQueue for non-window-specific method channel invocations
  static final RequestQueue _globalRequestQueue = RequestQueue(rateLimit: 10); // Adjust as needed

  /// Create a new Window.
  static Future<WindowController> createWindow([String? arguments]) async {
    try {
      final windowId = await _globalRequestQueue.addRequest(() => multiWindowChannel.invokeMethod<int>(
        'createWindow',
        arguments,
      ));
      if (windowId == null || windowId <= 0) {
        throw Exception('Invalid window ID: $windowId');
      }
      final controller = WindowController.fromWindowId(windowId);
      _windowControllers[windowId] = controller;
      return controller;
    } catch (e) {
      // Handle or log the error appropriately
      rethrow;
    }
  }

  /// Invoke a method on the isolate of the specified window.
  static Future<dynamic> invokeMethod(
      int targetWindowId,
      String method, [
        dynamic arguments,
      ]) async {
    final controller = _windowControllers[targetWindowId];
    if (controller == null) {
      throw Exception('No window found with ID: $targetWindowId');
    }
    return controller.invokeMethod(method, arguments);
  }

  /// Set a method handler for incoming method calls on the window's isolate.
  ///
  /// **Note**: This handler is specific to this window's isolate.
  /// You cannot handle method calls targeting other windows in this handler.
  static void setMethodHandler(
      Future<dynamic> Function(MethodCall call, int fromWindowId)? handler,
      ) {
    windowEventChannel.setMethodCallHandler((call) async {
      if (handler == null) return null;
      final fromWindowId = call.arguments['fromWindowId'] as int? ?? -1;
      final arguments = call.arguments['arguments'];
      return await handler(MethodCall(call.method, arguments), fromWindowId);
    });
  }

  /// Retrieve all sub-window IDs.
  ///
  /// Excludes the main window (ID 0).
  static Future<List<int>> getAllSubWindowIds() async {
    try {
      final result = await _globalRequestQueue.addRequest(() => multiWindowChannel.invokeMethod<List<dynamic>>(
        'getAllSubWindowIds',
      ));
      final ids = result?.cast<int>() ?? [];
      if (ids.contains(0)) {
        throw Exception('IDs must not contain the main window ID (0).');
      }
      if (!ids.every((id) => id > 0)) {
        throw Exception('All window IDs must be greater than 0.');
      }
      return ids;
    } catch (e) {
      // Handle or log the error appropriately
      rethrow;
    }
  }

  /// Internal method to remove window controller from the registry
  static void removeWindowController(int windowId) {
    _windowControllers.remove(windowId);
  }
}
