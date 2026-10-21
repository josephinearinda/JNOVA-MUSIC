import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

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
        const Duration(seconds: 3),
        onTimeout: () => [ConnectivityResult.none],
      );
      if (_hasActiveConnection(results)) return true;

      // Fallback socket lookup jika connectivity_plus menghasilkan false-negative (umum di Windows desktop)
      if (!kIsWeb) {
        try {
          final lookup = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 2));
          return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
        } catch (_) {}
      }
      return false;
    } catch (_) {
      if (!kIsWeb) {
        try {
          final lookup = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 2));
          return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
        } catch (_) {}
      }
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
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.other) {
        return true;
      }
    }
    return false;
  }
}

