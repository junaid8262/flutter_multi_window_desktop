// src/request_queue.dart

import 'dart:async';
import 'dart:collection';
import 'dart:developer';

/// A class to manage and rate-limit method channel requests.
class RequestQueue {
  final int _rateLimit; // Maximum requests per second
  final Queue<_Request> _queue = Queue<_Request>();
  Timer? _timer;
  bool _isProcessing = false;

  /// Creates a [RequestQueue] with a specified [rateLimit].
  ///
  /// [rateLimit]: The maximum number of requests processed per second.
  RequestQueue({int rateLimit = 5}) : _rateLimit = rateLimit;

  /// Adds a new request to the queue.
  ///
  /// [request]: A function that returns a [Future] representing the method channel call.
  Future<dynamic> addRequest(Future<dynamic> Function() request) {
    final completer = Completer<dynamic>();
    _queue.add(_Request(request, completer));
    log('Request added. Queue length: ${_queue.length}');

    // Start processing if not already
    if (!_isProcessing) {
      log('Starting queue processing.');
      _processQueue();
    }

    return completer.future;
  }

  /// Processes the request queue based on the rate limit.
  void _processQueue() {
    _isProcessing = true;
    final interval = Duration(milliseconds: 1000 ~/ _rateLimit);
    log('Processing queue with interval: ${interval.inMilliseconds}ms');

    _timer = Timer.periodic(interval, (timer) async {
      if (_queue.isEmpty) {
        log('Queue is empty. Stopping processing.');
        _stopProcessing();
        return;
      }

      final currentRequest = _queue.removeFirst();
      log('Processing request. Remaining queue: ${_queue.length}');
      try {
        final result = await currentRequest.call();
        currentRequest.completer.complete(result);
        log('Request completed successfully.');
      } catch (e) {
        log('Request failed with error: $e');
        if (currentRequest.retryCount < currentRequest.maxRetries) {
          currentRequest.retryCount++;
          final delay = Duration(milliseconds: 500 * (1 << currentRequest.retryCount));
          log('Retrying request in ${delay.inMilliseconds}ms. Retry count: ${currentRequest.retryCount}');
          Timer(delay, () {
            _queue.add(currentRequest); // Requeue with exponential backoff
            log('Request requeued. New queue length: ${_queue.length}');
          });
        } else {
          log('Max retries reached. Completing with error.');
          currentRequest.completer.completeError(e);
        }
      }
    });
  }

  /// Stops the queue processing.
  void _stopProcessing() {
    _isProcessing = false;
    _timer?.cancel();
    _timer = null;
    log('Queue processing stopped.');
  }

  /// Disposes the RequestQueue by stopping processing and clearing the queue.
  void dispose() {
    _stopProcessing();
    _queue.clear();
    log('RequestQueue disposed.');
  }
}

/// Represents a single request in the [RequestQueue].
class _Request {
  final Future<dynamic> Function() call;
  final Completer<dynamic> completer;
  int retryCount = 0;
  final int maxRetries;

  _Request(this.call, this.completer, {this.maxRetries = 3});
}
