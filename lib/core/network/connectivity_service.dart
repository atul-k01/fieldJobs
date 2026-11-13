import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor network connectivity status.
class ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  Stream<bool> get onConnectivityChanged => _controller.stream;

  void _init() {
    _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = _hasConnection(results);
      _controller.add(isOnline);
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  void dispose() {
    _controller.close();
  }
}
