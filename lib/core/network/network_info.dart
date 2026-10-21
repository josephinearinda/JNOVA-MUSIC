import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service untuk memantau status koneksi online / offline
class NetworkInfo {
  NetworkInfo._();
  static final NetworkInfo instance = NetworkInfo._();

  final Connectivity _connectivity = Connectivity();
  bool? _overrideIsConnected;

  /// Override status koneksi untuk keperluan automated testing
  set overrideIsConnected(bool? value) => _overrideIsConnected = value;

  Future<bool> get isConnected async {
    if (_overrideIsConnected != null) return _overrideIsConnected!;
    try {
      final results = await _connectivity.checkConnectivity().timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => [ConnectivityResult.none],
      );
      return _hasActiveConnection(results);
    } catch (_) {
      return false;
    }
  }

  /// Stream perubahan status jaringan (true = online, false = offline)
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_hasActiveConnection);
  }

  bool _hasActiveConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    for (final result in results) {
      if (result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn) {
        return true;
      }
    }
    return false;
  }
}
