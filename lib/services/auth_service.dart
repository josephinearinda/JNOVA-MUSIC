import '../data/repositories/auth_repository.dart';
import 'membership_service.dart';
import 'notification_background_sync_service.dart';
import 'order_service.dart';
import 'user_profile_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/datasources/remote/supabase_client_service.dart';

export '../data/repositories/auth_repository.dart' show AuthResult;

/// Service autentikasi JNOVAMUSIC terhubung ke Supabase Auth & Secure Storage
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final AuthRepository _repository = AuthRepository.instance;

  Future<bool> hasActiveSession() async {
    if (SupabaseClientService.instance.isAuthenticated) return true;

    final storage = SecureStorageService.instance;
    final accessToken = await storage.getAccessToken();
    final email = await storage.getUserEmail();
    return email != null &&
        email.isNotEmpty &&
        (accessToken?.startsWith('local_token_') == true ||
            accessToken?.startsWith('offline_token_') == true);
  }

  /// Melakukan proses masuk akun melalui Supabase Auth
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _repository.login(email: email, password: password);
    if (result.isSuccess) {
      await NotificationBackgroundSyncService.enable();
    }
    return result;
  }

  /// Pendaftaran akun baru
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _repository.register(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  /// Autentikasi menggunakan Google OAuth
  Future<AuthResult> loginWithGoogle() async {
    return const AuthResult(
      isSuccess: false,
      message: 'Integrasi Google Sign-In memerlukan konfigurasi OAuth Client ID pada Supabase Dashboard.',
    );
  }

  /// Login menggunakan biometrik sidik jari dengan pemulihan sesi aman
  Future<AuthResult> loginWithBiometrics() async {
    final result = await _repository.loginWithBiometrics();
    if (result.isSuccess) {
      await NotificationBackgroundSyncService.enable();
    }
    return result;
  }

  /// Mengaktifkan login biometrik untuk pengguna yang sedang aktif dengan verifikasi aman
  Future<AuthResult> enableBiometricsForUser({
    required String email,
    String? fullName,
  }) async {
    return await _repository.enableBiometricsForUser(
      email: email,
      fullName: fullName,
    );
  }

  /// Menonaktifkan login biometrik untuk pengguna
  Future<AuthResult> disableBiometricsForUser(String email) async {
    return await _repository.disableBiometricsForUser(email);
  }

  /// Melakukan proses keluar dari akun dan menghapus sesi autentikasi pengguna
  Future<void> logout() async {
    await NotificationBackgroundSyncService.disable();
    await _repository.logout();
    UserProfileService.instance.resetProfile();
    MembershipService.instance.resetPoints();
    OrderService.instance.resetOrders();
  }
}
