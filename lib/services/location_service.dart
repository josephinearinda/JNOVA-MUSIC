import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/store_branch.dart';

/// Status pendeteksian lokasi perangkat pelanggan
enum LocationStatus {
  idle,
  loading,
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  error,
}

/// Hasil dari operasi pendeteksian lokasi
class LocationResult {
  final double? latitude;
  final double? longitude;
  final LocationStatus status;
  final String message;

  const LocationResult({
    this.latitude,
    this.longitude,
    required this.status,
    required this.message,
  });

  bool get isSuccess =>
      status == LocationStatus.success &&
      latitude != null &&
      longitude != null;
}

/// Layanan deteksi lokasi GPS dan penentuan toko terdekat JNOVAMUSIC
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // Hook untuk pengujian unit & simulasi koordinat
  LocationResult? _mockLocationResult;
  bool _useMock = false;

  void setMockLocation({
    double? latitude,
    double? longitude,
    LocationStatus status = LocationStatus.success,
    String message = 'Lokasi mock berhasil diatur.',
  }) {
    _useMock = true;
    _mockLocationResult = LocationResult(
      latitude: latitude,
      longitude: longitude,
      status: status,
      message: message,
    );
  }

  void resetMock() {
    _useMock = false;
    _mockLocationResult = null;
  }

  /// Mendeteksi koordinat aktual pelanggan dengan validasi izin dan kesiapan GPS
  Future<LocationResult> getCurrentLocation({
    bool requestPermission = true,
  }) async {
    if (_useMock && _mockLocationResult != null) {
      return _mockLocationResult!;
    }

    try {
      // 1. Cek apakah layanan GPS pada perangkat aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          status: LocationStatus.serviceDisabled,
          message:
              'Layanan lokasi perangkat (GPS) tidak aktif. Silakan aktifkan lokasi atau pilih toko secara manual.',
        );
      }

      // 2. Cek status izin lokasi saat ini
      LocationPermission permission = await Geolocator.checkPermission();

      // Minta izin hanya jika belum ditolak permanen
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult(
          status: LocationStatus.permissionDenied,
          message:
              'Izin lokasi tidak diberikan. Kamu tetap dapat memilih toko pickup secara manual.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          status: LocationStatus.permissionDeniedForever,
          message:
              'Izin lokasi ditolak permanen pada perangkat. Kamu dapat memilih toko secara manual di bawah.',
        );
      }

      // 3. Ambil posisi koordinat aktual dengan batas waktu (timeout) 8 detik
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        status: LocationStatus.success,
        message: 'Lokasimu berhasil dideteksi.',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocationService Error: $e');
      }
      return LocationResult(
        status: LocationStatus.error,
        message: 'Gagal mendeteksi lokasi pelanggan. Silakan gunakan pemilihan toko manual.',
      );
    }
  }

  /// Menghitung jarak garis lurus (dalam meter) antar koordinat
  double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    try {
      return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    } catch (_) {
      // Fallback formula Haversine murni
      const earthRadius = 6371000.0; // Radius bumi dalam meter
      final dLat = _degToRad(lat2 - lat1);
      final dLon = _degToRad(lon2 - lon1);
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(_degToRad(lat1)) *
              math.cos(_degToRad(lat2)) *
              math.sin(dLon / 2) *
              math.sin(dLon / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      return earthRadius * c;
    }
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Format jarak yang mudah dibaca (m atau km)
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Mengurutkan seluruh cabang toko berdasarkan jarak dari lokasi pelanggan
  List<StoreBranchWithDistance> sortStoresByDistance(
    double userLat,
    double userLng,
    List<StoreBranch> branches,
  ) {
    final list = branches.map((b) {
      final distance = calculateDistanceMeters(
        userLat,
        userLng,
        b.latitude,
        b.longitude,
      );
      return StoreBranchWithDistance(
        branch: b,
        distanceMeters: distance,
      );
    }).toList();

    list.sort((a, b) => (a.distanceMeters ?? double.infinity)
        .compareTo(b.distanceMeters ?? double.infinity));

    if (list.isNotEmpty) {
      list[0] = StoreBranchWithDistance(
        branch: list[0].branch,
        distanceMeters: list[0].distanceMeters,
        isNearest: true,
      );
    }

    return list;
  }

  /// Mencari toko terdekat dari koordinat pengguna
  StoreBranch? findNearestStore(
    double userLat,
    double userLng,
    List<StoreBranch> branches,
  ) {
    if (branches.isEmpty) return null;
    final sorted = sortStoresByDistance(userLat, userLng, branches);
    return sorted.first.branch;
  }
}
