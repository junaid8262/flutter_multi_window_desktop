import 'dart:async';

class RequestQueue {
  final _queue = <_Request>[];
  final int _rateLimit; // Maximum requests per second
  Timer? _timer;
  bool _isProcessing = false;

  RequestQueue({int rateLimit = 2}) : _rateLimit = rateLimit;

  void addRequest(Future<dynamic> Function() request) {
    final completer = Completer();
    _queue.add(_Request(request, completer));

    if (!_isProcessing) {
      _processQueue();
    }
  }

  Future<dynamic> _processQueue() async {
    _isProcessing = true;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      int processedRequests = 0;

      while (_queue.isNotEmpty && processedRequests < _rateLimit) {
        final request = _queue.removeAt(0);
        try {
          final result = await request.call();
          request.completer.complete(result);
        } catch (e) {
          if (request.retryCount < request.maxRetries) {
            request.retryCount++;
            final delay = Duration(milliseconds: 500 * (1 << request.retryCount));
            await Future.delayed(delay);
            _queue.add(request); // Requeue with backoff delay
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

/*class _Request {
  final Future<dynamic> Function() call;
  final Completer completer;

  _Request(this.call, this.completer);
}*/
class _Request {
  final Future<dynamic> Function() call;
  final Completer completer;
  int retryCount = 0;
  final int maxRetries = 3;

  _Request(this.call, this.completer);
}
