import 'package:flutter/services.dart';

import 'channels.dart';

typedef MessageHandler = Future<dynamic> Function(MethodCall call, int fromWindowId);

/// A client-side message channel for interacting with window isolates.
class ClientMessageChannel {
  const ClientMessageChannel();

  /// Invokes a method on the window event channel.
  ///
  /// [method]: The name of the method to invoke.
  /// [arguments]: The arguments to pass to the method.
  Future<dynamic> invokeMethod(String method, [dynamic arguments]) {
    return windowEventChannel.invokeMethod(method, arguments);
  }

  /// Sets a message handler for incoming method calls.
  ///
  /// [handler]: A function to handle incoming method calls.
  void setMessageHandler(MessageHandler? handler) {
    windowEventChannel.setMethodCallHandler((call) async {
      if (handler == null) return null;
      final fromWindowId = call.arguments['fromWindowId'] as int? ?? -1;
      final arguments = call.arguments['arguments'];
      return await handler(MethodCall(call.method, arguments), fromWindowId);
    });
  }
}
