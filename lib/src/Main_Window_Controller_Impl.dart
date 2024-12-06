// src/main_window_controller.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';

import '../desktop_multi_window.dart';
import 'channels.dart';
import 'window_controller.dart';
import 'request_queue.dart';

/// Controller for the main application window.
class MainWindowController extends WindowController {
  static final MethodChannel _channel = multiWindowChannel;
  final RequestQueue _requestQueue = RequestQueue(rateLimit: 5);

  // Singleton instance
  static final MainWindowController _instance = MainWindowController._internal();

  // Private constructor
  MainWindowController._internal();

  // Public factory constructor returning the singleton instance
  factory MainWindowController() => _instance;

  @override
  int get windowId => 0;

  /// Handles method channel invocations with queueing.
  @override
  Future<dynamic> invokeMethod(String method, [dynamic arguments]) {
    return _requestQueue.addRequest(() => _channel.invokeMethod(method, arguments));
  }

  @override
  Future<void> close() async {
    throw UnsupportedError('Cannot close the main application window.');
  }

  @override
  Future<void> hide() async {
    try {
      await invokeMethod('hide', windowId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> show() async {
    try {
      await invokeMethod('show', windowId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> center() async {
    try {
      await invokeMethod('center', windowId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> setFrame(Rect frame) async {
    try {
      await invokeMethod('setFrame', <String, dynamic>{
        'windowId': windowId,
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
        'windowId': windowId,
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
        'windowId': windowId,
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
        'windowId': windowId,
        'name': name,
      });
    } catch (e) {
      rethrow;
    }
  }
}
