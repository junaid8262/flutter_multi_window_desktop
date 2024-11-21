import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'channels.dart';
import 'request_queue.dart';
import 'window_controller.dart';

class WindowControllerMainImpl extends WindowController {
  final MethodChannel _channel = multiWindowChannel;

  // The ID of this window
  final int _id;

  // Request queue for rate-limited operations
  static final RequestQueue _requestQueue = RequestQueue();

  WindowControllerMainImpl(this._id);

  @override
  int get windowId => _id;

  @override
  Future<void> close() async {
    await _enqueueRequest(() => _channel.invokeMethod('close', _id), priority: 0);
  }

  @override
  Future<void> hide() async {
    await _enqueueRequest(() => _channel.invokeMethod('hide', _id), priority: 1);
  }

  @override
  Future<void> show() async {
    await _enqueueRequest(() => _channel.invokeMethod('show', _id), priority: 0);
  }

  @override
  Future<void> center() async {
    await _enqueueRequest(() => _channel.invokeMethod('center', _id), priority: 1);
  }

  @override
  Future<void> setFrame(Rect frame) async {
    await _enqueueRequest(() {
      return _channel.invokeMethod('setFrame', <String, dynamic>{
        'windowId': _id,
        'left': frame.left,
        'top': frame.top,
        'width': frame.width,
        'height': frame.height,
      });
    }, priority: 1);
  }

  @override
  Future<void> setTitle(String title) async {
    await _enqueueRequest(() {
      return _channel.invokeMethod('setTitle', <String, dynamic>{
        'windowId': _id,
        'title': title,
      });
    }, priority: 1);
  }

  @override
  Future<void> resizable(bool resizable) async {
    if (Platform.isMacOS) {
      await _enqueueRequest(() {
        return _channel.invokeMethod('resizable', <String, dynamic>{
          'windowId': _id,
          'resizable': resizable,
        });
      }, priority: 1);
    } else {
      throw MissingPluginException(
        'This functionality is only available on macOS',
      );
    }
  }

  @override
  Future<void> setFrameAutosaveName(String name) async {
    await _enqueueRequest(() {
      return _channel.invokeMethod('setFrameAutosaveName', <String, dynamic>{
        'windowId': _id,
        'name': name,
      });
    }, priority: 1);
  }

  /// Helper method to enqueue requests into the rate-limited queue
  Future<void> _enqueueRequest(Future<dynamic> Function() request, {int priority = 1}) async {
    final completer = Completer<void>();

    _requestQueue.addRequest(() async {
      try {
        await request();
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      }
    }, priority: priority);

    return completer.future;
  }
}
