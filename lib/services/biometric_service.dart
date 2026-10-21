import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

/// Status hasil autentikasi biometrik
enum BiometricStatus {
  success,
  failed,
  canceled,
  notAvailable,
  notEnrolled,
  lockedOut,
  error,
}

/// Model hasil autentikasi biometrik
class BiometricResult {
  final bool isSuccess;
  final String message;
  final BiometricStatus status;

  const BiometricResult({
    required this.isSuccess,
    required this.message,
    required this.status,
  });

  factory BiometricResult.success([String message = 'Autentikasi sidik jari berhasil.']) {
    return BiometricResult(
      isSuccess: true,
      message: message,
      status: BiometricStatus.success,
    );
  }

  factory BiometricResult.failed([String message = 'Sidik jari tidak cocok. Silakan coba lagi.']) {
    return BiometricResult(
      isSuccess: false,
      message: message,
      status: BiometricStatus.failed,
    );
  }

  factory BiometricResult.canceled([String message = 'Autentikasi sidik jari dibatalkan.']) {
    return BiometricResult(
      isSuccess: false,
      message: message,
      status: BiometricStatus.canceled,
    );
  }

  factory BiometricResult.notAvailable([String message = 'Perangkat tidak mendukung autentikasi sidik jari.']) {
    return BiometricResult(
      isSuccess: false,
      message: message,
      status: BiometricStatus.notAvailable,
    );
  }

  factory BiometricResult.notEnrolled([String message = 'Belum ada sidik jari yang terdaftar pada perangkat ini. Silakan daftarkan sidik jari di pengaturan perangkat.']) {
    return BiometricResult(
      isSuccess: false,
      message: message,
      status: BiometricStatus.notEnrolled,
    );
  }

  factory BiometricResult.lockedOut([String message = 'Sensor biometrik terkunci sementara karena terlalu banyak percobaan salah. Silakan coba lagi beberapa saat.']) {
    return BiometricResult(
      isSuccess: false,
      message: message,
      status: BiometricStatus.lockedOut,
    );
  }

  factory BiometricResult.error(String message) {
    return BiometricResult(
      isSuccess: false,
      message: message,
      status: BiometricStatus.error,
    );
  }
}

/// Service resmi penanganan autentikasi biometrik (Fingerprint) JNOVAMUSIC
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Memeriksa apakah perangkat fisik mendukung hardware biometrik
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa apakah ada biometrik yang didaftarkan (enrolled) oleh pengguna di OS
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Mendapatkan daftar biometrik yang tersedia di perangkat
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// Meminta pengguna memindai sidik jari dengan dialog resmi platform
  Future<BiometricResult> authenticate({
    required String localizedReason,
    String cancelButtonText = 'Batal / Gunakan Sandi',
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return BiometricResult.notAvailable();
      }

      final hasEnrolled = await hasEnrolledBiometrics();
      if (!hasEnrolled) {
        return BiometricResult.notEnrolled();
      }

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
        authMessages: <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Masuk dengan Sidik Jari',
            signInHint: 'Tempelkan jari Anda pada sensor sidik jari',
            cancelButton: cancelButtonText,
          ),
          IOSAuthMessages(
            cancelButton: cancelButtonText,
          ),
        ],
      );

      if (authenticated) {
        return BiometricResult.success();
      } else {
        return BiometricResult.canceled();
      }
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return BiometricResult.notAvailable();
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
          return BiometricResult.notEnrolled();
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return BiometricResult.lockedOut();
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
          return BiometricResult.canceled();
        default:
          return BiometricResult.error('Gagal autentikasi biometrik: ${e.description ?? e.code.name}');
      }
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        return BiometricResult.notAvailable();
      } else if (e.code == 'NotEnrolled') {
        return BiometricResult.notEnrolled();
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return BiometricResult.lockedOut();
      } else if (e.code == 'UserCancel' || e.code == 'SystemCancel') {
        return BiometricResult.canceled();
      }
      return BiometricResult.error('Gagal autentikasi biometrik: ${e.message ?? e.code}');
    } catch (e) {
      return BiometricResult.error('Terjadi kesalahan pada sensor biometrik: $e');
    }
  }

  /// Menghentikan proses autentikasi biometrik jika sedang berlangsung
  Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}
