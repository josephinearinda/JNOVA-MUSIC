import '../data/repositories/auth_repository.dart';

export '../data/repositories/auth_repository.dart' show AuthResult;

/// Service autentikasi JNOVAMUSIC terhubung ke Supabase Auth & Secure Storage
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final AuthRepository _repository = AuthRepository.instance;

  /// Melakukan proses masuk akun melalui Supabase Auth
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return await _repository.login(email: email, password: password);
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
      message:
          'Integrasi Google Sign-In memerlukan konfigurasi OAuth Client ID pada Supabase Dashboard.',
    );
  }

  /// Melakukan proses keluar dari akun dan menghapus sesi autentikasi pengguna
  Future<void> logout() async {
    await _repository.logout();
  }
}
