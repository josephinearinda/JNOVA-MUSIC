import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/secure_storage_service.dart';
import '../datasources/remote/supabase_client_service.dart';

class AuthResult {
  final bool isSuccess;
  final String message;
  final String? token;
  final User? user;

  const AuthResult({
    required this.isSuccess,
    required this.message,
    this.token,
    this.user,
  });
}

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final SupabaseClientService _supabaseService = SupabaseClientService.instance;
  final SecureStorageService _secureStorage = SecureStorageService.instance;

  /// Login email & password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.isEmpty) {
      return const AuthResult(
        isSuccess: false,
        message: 'Alamat email dan kata sandi wajib diisi.',
      );
    }

    if (!AppConfig.isSupabaseConfigured || !_supabaseService.isInitialized) {
      await _secureStorage.saveSession(
        accessToken: 'local_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'local_refresh',
        userId: 'local_user_${cleanEmail.hashCode}',
        email: cleanEmail,
      );
      return const AuthResult(
        isSuccess: true,
        message: 'Berhasil masuk ke akun JNOVAMUSIC (Sesi Lokal).',
      );
    }

    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline) {
      await _secureStorage.saveSession(
        accessToken: 'offline_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'offline_refresh',
        userId: 'offline_user_${cleanEmail.hashCode}',
        email: cleanEmail,
      );
      return const AuthResult(
        isSuccess: true,
        message: 'Mode Offline: Berhasil masuk ke sesi lokal.',
      );
    }

    try {
      final client = _supabaseService.client;
      if (client == null) {
        return const AuthResult(
          isSuccess: false,
          message: 'Klien Supabase belum siap.',
        );
      }

      final response = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      final session = response.session;
      final user = response.user;

      if (session != null && user != null) {
        await _secureStorage.saveSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken ?? '',
          userId: user.id,
          email: user.email ?? cleanEmail,
        );

        return AuthResult(
          isSuccess: true,
          message: 'Berhasil masuk ke akun JNOVAMUSIC.',
          token: session.accessToken,
          user: user,
        );
      }

      return const AuthResult(
        isSuccess: false,
        message: 'Gagal mendapatkan sesi autentikasi dari server.',
      );
    } on AuthException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Autentikasi gagal: ${e.message}',
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Terjadi kesalahan sistem: ${e.toString()}',
      );
    }
  }

  /// Registrasi akun baru
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.isEmpty) {
      return const AuthResult(
        isSuccess: false,
        message: 'Email dan kata sandi wajib diisi.',
      );
    }

    if (!AppConfig.isSupabaseConfigured || !_supabaseService.isInitialized) {
      await _secureStorage.saveSession(
        accessToken: 'local_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'local_refresh',
        userId: 'local_user_${cleanEmail.hashCode}',
        email: cleanEmail,
      );
      return const AuthResult(
        isSuccess: true,
        message: 'Pendaftaran berhasil (Sesi Lokal). Selamat datang di JNOVAMUSIC.',
      );
    }

    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline) {
      await _secureStorage.saveSession(
        accessToken: 'offline_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'offline_refresh',
        userId: 'offline_user_${cleanEmail.hashCode}',
        email: cleanEmail,
      );
      return const AuthResult(
        isSuccess: true,
        message: 'Mode Offline: Pendaftaran berhasil disimpan secara lokal.',
      );
    }

    try {
      final client = _supabaseService.client!;
      final response = await client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'full_name': fullName},
      );

      return AuthResult(
        isSuccess: true,
        message: 'Pendaftaran berhasil. Silakan periksa email untuk verifikasi.',
        user: response.user,
      );
    } on AuthException catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Pendaftaran gagal: ${e.message}',
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  /// Sign out dan bersihkan secure storage
  Future<void> logout() async {
    try {
      await _supabaseService.client?.auth.signOut();
    } catch (_) {}
    await _secureStorage.clearSession();
  }
}
