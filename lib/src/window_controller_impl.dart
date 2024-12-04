import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';

import '../desktop_multi_window.dart';
import 'channels.dart';
import 'window_controller.dart';
import 'request_queue.dart';

class WindowControllerMainImpl extends WindowController {
  static final MethodChannel _channel = multiWindowChannel;

  // The ID of this window
  final int _id;

  // Each window has its own RequestQueue
  final RequestQueue _requestQueue;

  // Constructor
  WindowControllerMainImpl(this._id)
      : _requestQueue = RequestQueue(rateLimit: 5); // Adjust as needed

  @override
  int get windowId => _id;

  // Helper method to handle method channel invocation with queueing
  Future<dynamic> invokeMethod(String method, [dynamic arguments]) {
    return _requestQueue.addRequest(() => _channel.invokeMethod(method, arguments));
  }

  @override
  Future<void> close() async {
    try {
      await invokeMethod('close', _id);
      DesktopMultiWindow.removeWindowController(_id);
    } catch (e) {
      // Handle or log the error appropriately
      rethrow;
    }
  }

  @override
  Future<void> hide() async {
    try {
      await invokeMethod('hide', _id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> show() async {
    try {
      await invokeMethod('show', _id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> center() async {
    try {
      await invokeMethod('center', _id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> setFrame(Rect frame) async {
    try {
      await invokeMethod('setFrame', <String, dynamic>{
        'windowId': _id,
        'left': frame.left,
        'top': frame.top,
        'width': frame.width,
        'height': frame.height,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> setTitle(String title) async {
    try {
      await invokeMethod('setTitle', <String, dynamic>{
        'windowId': _id,
        'title': title,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resizable(bool resizable) async {
    if (!Platform.isMacOS) {
      throw MissingPluginException(
        'The resizable functionality is only available on macOS.',
      );
    }
    try {
      await invokeMethod('resizable', <String, dynamic>{
        'windowId': _id,
        'resizable': resizable,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> setFrameAutosaveName(String name) async {
    try {
      await invokeMethod('setFrameAutosaveName', <String, dynamic>{
        'windowId': _id,
        'name': name,
      });
    } catch (e) {
      rethrow;
    }
  }
}
