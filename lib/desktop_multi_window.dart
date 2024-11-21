import 'dart:async';
import 'package:flutter/services.dart';
import 'src/channels.dart';
import 'src/window_controller.dart';
import 'src/window_controller_impl.dart';
import 'src/request_queue.dart';
export 'src/window_controller.dart';

class DesktopMultiWindow {
  static final RequestQueue _requestQueue = RequestQueue();
  static final Set<int> _activeWindows = {}; // Track active window IDs

  /// Create a new Window.
  /// The new window instance will call `main` method in your `main.dart` file in
  /// a new flutter engine instance with some additional arguments.
  /// You can use [WindowController] to control the window.
  static Future<WindowController> createWindow([String? arguments]) async {
    final request = () => multiWindowChannel.invokeMethod<int>(
      'createWindow',
      arguments,
    );

    // Add the request to the queue with high priority
    final completer = Completer<WindowController>();
    _requestQueue.addRequest(() async {
      final windowId = await request();
      if (windowId == null || windowId <= 0) {
        throw Exception('Failed to create a valid window');
      }
      completer.complete(WindowControllerMainImpl(windowId));
    }, priority: 0);

    return completer.future;
  }

  /// Invoke a method on the isolate of the window.
  /// [targetWindowId] specifies the window to invoke the method on.
  static Future<dynamic> invokeMethod(int targetWindowId, String method,
      [dynamic arguments]) async {
    final request = () => windowEventChannel.invokeMethod(
      method,
      <String, dynamic>{
        'targetWindowId': targetWindowId,
        'arguments': arguments,
      },
    );

    // Assign priority based on method type
    final priority = (method == 'close' || method == 'show') ? 0 : 1;
    final completer = Completer();

    _requestQueue.addRequest(() async {
      try {
        final result = await request();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      }
    }, priority: priority);

    return completer.future;
  }

  /// Add a method handler to the isolate of the window.
  static void setMethodHandler(
      Future<dynamic> Function(MethodCall call, int fromWindowId)? handler) {
    if (handler == null) {
      windowEventChannel.setMethodCallHandler(null);
      return;
    }
    windowEventChannel.setMethodCallHandler((call) async {
      final fromWindowId = call.arguments['fromWindowId'] as int;
      final arguments = call.arguments['arguments'];
      return await handler(MethodCall(call.method, arguments), fromWindowId);
    });
  }

  /// Get all sub window id.
  static Future<List<int>> getAllSubWindowIds() async {
    final result = await multiWindowChannel
        .invokeMethod<List<dynamic>>('getAllSubWindowIds');
    final ids = result?.cast<int>() ?? const [];
    assert(!ids.contains(0), 'ids must not contains main window id');
    assert(ids.every((id) => id > 0), 'id must be greater than 0');
    return ids;
  }
}
