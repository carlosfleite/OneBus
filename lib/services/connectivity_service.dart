import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether the device has a network connection, so the UI can warn
/// the user when they go offline.
class ConnectivityService {
  ConnectivityService._();

  static final instance = ConnectivityService._();

  /// False while the device reports no network.
  final online = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> init() async {
    try {
      final connectivity = Connectivity();
      _apply(await connectivity.checkConnectivity());
      _sub = connectivity.onConnectivityChanged.listen(_apply);
    } catch (_) {
      // Plugin unavailable (tests, unsupported platform): assume online.
      online.value = true;
    }
  }

  /// Re-checks the connection; returns the new state.
  Future<bool> refresh() async {
    try {
      _apply(
        await Connectivity().checkConnectivity().timeout(
          const Duration(seconds: 3),
        ),
      );
    } catch (_) {}
    return online.value;
  }

  void _apply(List<ConnectivityResult> results) {
    online.value =
        results.isEmpty || results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() => _sub?.cancel();
}
