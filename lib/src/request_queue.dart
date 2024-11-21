import 'dart:async';
import 'package:collection/collection.dart';

class RequestQueue {
  final _queue = HeapPriorityQueue<_Request>((a, b) => a.priority.compareTo(b.priority));
  final int _baseRateLimit;
  int _dynamicRateLimit;
  Timer? _timer;
  bool _isProcessing = false;

  RequestQueue({int baseRateLimit = 5, int initialWindows = 1})
      : _baseRateLimit = baseRateLimit,
        _dynamicRateLimit = baseRateLimit ~/ initialWindows;

  void updateRateLimit(int activeWindows) {
    _dynamicRateLimit = (activeWindows > 0) ? _baseRateLimit ~/ activeWindows : _baseRateLimit;
  }

  void addRequest(Future<dynamic> Function() request, {int priority = 0}) {
    final completer = Completer();
    _queue.add(_Request(request, completer, priority));

    if (!_isProcessing) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isProcessing = true;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      int processedRequests = 0;

      while (_queue.isNotEmpty && processedRequests < _dynamicRateLimit) {
        final request = _queue.removeFirst();
        try {
          final result = await request.call();
          request.completer.complete(result);
        } catch (e) {
          if (request.retryCount < request.maxRetries) {
            request.retryCount++;
            final delay = Duration(milliseconds: 500 * (1 << request.retryCount));
            await Future.delayed(delay);
            _queue.add(request);
          } else {
            request.completer.completeError(e);
          }
        }
        processedRequests++;
      }

      if (_queue.isEmpty) {
        _isProcessing = false;
        _timer?.cancel();
      }
    });
  }
}

class _Request {
  final Future<dynamic> Function() call;
  final Completer completer;
  final int priority;
  int retryCount = 0;
  final int maxRetries = 3;

  _Request(this.call, this.completer, this.priority);
}
