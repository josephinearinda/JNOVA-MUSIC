import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../services/biometric_service.dart';
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
      final registeredUsers = await _secureStorage.getRegisteredUsers();
      if (registeredUsers.containsKey(cleanEmail)) {
        final savedPassword = registeredUsers[cleanEmail]?['password'];
        if (savedPassword != null && savedPassword != password) {
          return const AuthResult(
            isSuccess: false,
            message: 'Kata sandi salah. Silakan periksa kembali kata sandi Anda.',
          );
        }
      }

      await _secureStorage.saveSession(
        accessToken: 'local_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'local_refresh',
        userId: 'local_user_${cleanEmail.hashCode}',
        email: cleanEmail,
      );

      final isBioEnabled =
          await _secureStorage.isBiometricEnabledForUser(cleanEmail);
      if (isBioEnabled) {
        final existingRecord =
            await _secureStorage.getBiometricAuthRecord(cleanEmail);
        await _secureStorage.saveBiometricAuthRecord(
          email: cleanEmail,
          userId: 'local_user_${cleanEmail.hashCode}',
          fullName: existingRecord?['fullName'] as String?,
          refreshToken: 'local_refresh',
        );
        await _secureStorage.setBiometricEnabledForUser(cleanEmail, true);
      }

      return const AuthResult(
        isSuccess: true,
        message: 'Berhasil masuk ke akun JNOVAMUSIC.',
      );
    }

    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline) {
      final registeredUsers = await _secureStorage.getRegisteredUsers();
      if (registeredUsers.containsKey(cleanEmail)) {
        final savedPassword = registeredUsers[cleanEmail]?['password'];
        if (savedPassword != null && savedPassword != password) {
          return const AuthResult(
            isSuccess: false,
            message: 'Kata sandi salah. Silakan periksa kembali kata sandi Anda.',
          );
        }
      }

      await _secureStorage.saveSession(
        accessToken: 'offline_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'offline_refresh',
        userId: 'offline_user_${cleanEmail.hashCode}',
        email: cleanEmail,
      );

      final isBioEnabled =
          await _secureStorage.isBiometricEnabledForUser(cleanEmail);
      if (isBioEnabled) {
        final existingRecord =
            await _secureStorage.getBiometricAuthRecord(cleanEmail);
        await _secureStorage.saveBiometricAuthRecord(
          email: cleanEmail,
          userId: 'offline_user_${cleanEmail.hashCode}',
          fullName: existingRecord?['fullName'] as String?,
          refreshToken: 'offline_refresh',
        );
        await _secureStorage.setBiometricEnabledForUser(cleanEmail, true);
      }

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

        if (session.refreshToken != null && session.refreshToken!.isNotEmpty) {
          await _secureStorage.saveBiometricRefreshToken(
            cleanEmail,
            session.refreshToken!,
          );
        }

        final isBioEnabled =
            await _secureStorage.isBiometricEnabledForUser(cleanEmail);
        if (isBioEnabled) {
          final existingRecord =
              await _secureStorage.getBiometricAuthRecord(cleanEmail);
          await _secureStorage.saveBiometricAuthRecord(
            email: cleanEmail,
            userId: user.id,
            fullName: existingRecord?['fullName'] as String?,
            refreshToken: session.refreshToken,
          );
          await _secureStorage.setBiometricEnabledForUser(cleanEmail, true);
        }

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

  /// Registrasi akun baru (tanpa otomatis login ke dashboard)
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
      // Simpan akun ke penyimpanan terenkripsi agar bisa digunakan login
      await _secureStorage.saveRegisteredUser(
        email: cleanEmail,
        password: password,
        fullName: fullName,
      );
      // Pastikan tidak ada sesi aktif (jangan auto-login)
      await _secureStorage.clearSession();

      return const AuthResult(
        isSuccess: true,
        message: 'Pendaftaran berhasil! Silakan masuk dengan akun yang baru Anda buat.',
      );
    }

    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline) {
      await _secureStorage.saveRegisteredUser(
        email: cleanEmail,
        password: password,
        fullName: fullName,
      );
      await _secureStorage.clearSession();

      return const AuthResult(
        isSuccess: true,
        message: 'Mode Offline: Pendaftaran berhasil disimpan! Silakan masuk.',
      );
    }

    try {
      final client = _supabaseService.client!;
      final response = await client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user == null) {
        return const AuthResult(
          isSuccess: false,
          message: 'Pendaftaran gagal: Server tidak mengembalikan data pengguna.',
        );
      }

      // Pastikan tidak ada sesi login otomatis dari Supabase
      try {
        await client.auth.signOut();
      } catch (_) {}
      await _secureStorage.clearSession();

      return AuthResult(
        isSuccess: true,
        message: 'Pendaftaran berhasil! Silakan masuk menggunakan akun baru Anda.',
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

  /// Login menggunakan biometrik sidik jari dengan pemulihan sesi aman
  Future<AuthResult> loginWithBiometrics() async {
    final lastUser = await _secureStorage.getLastBiometricUser();
    if (lastUser == null || lastUser.isEmpty) {
      return const AuthResult(
        isSuccess: false,
        message:
            'Belum ada akun yang dihubungkan dengan login sidik jari. Silakan masuk dengan kata sandi dan aktifkan fitur di Pengaturan Akun.',
      );
    }

    final isEnabled = await _secureStorage.isBiometricEnabledForUser(lastUser);
    if (!isEnabled) {
      return const AuthResult(
        isSuccess: false,
        message: 'Fitur login sidik jari dinonaktifkan untuk akun ini.',
      );
    }

    final biometricRecord = await _secureStorage.getBiometricAuthRecord(lastUser);

    // 1. Jika Supabase dikonfigurasi & online
    if (AppConfig.isSupabaseConfigured && _supabaseService.isInitialized) {
      final isOnline = await NetworkInfo.instance.isConnected;
      if (isOnline) {
        try {
          final client = _supabaseService.client;
          if (client != null) {
            final currentSession = client.auth.currentSession;
            final currentUser = currentSession?.user;
            if (currentSession != null &&
                !currentSession.isExpired &&
                currentUser != null &&
                currentUser.email?.toLowerCase().trim() ==
                    lastUser.toLowerCase().trim()) {
              await _secureStorage.saveSession(
                accessToken: currentSession.accessToken,
                refreshToken: currentSession.refreshToken ?? '',
                userId: currentUser.id,
                email: currentUser.email ?? lastUser,
              );
              return AuthResult(
                isSuccess: true,
                message:
                    'Selamat datang kembali! Masuk berhasil dengan sidik jari.',
                user: currentUser,
                token: currentSession.accessToken,
              );
            }

            final savedRefreshToken =
                biometricRecord?['refreshToken'] as String? ??
                await _secureStorage.getBiometricRefreshToken(lastUser) ??
                await _secureStorage.getRefreshToken();

            if (savedRefreshToken != null &&
                savedRefreshToken.isNotEmpty &&
                savedRefreshToken != 'offline_refresh' &&
                savedRefreshToken != 'local_refresh') {
              final refreshResponse =
                  await client.auth.setSession(savedRefreshToken);
              final session = refreshResponse.session;
              final user = refreshResponse.user;
              if (session != null && user != null) {
                if (user.email?.toLowerCase().trim() !=
                    lastUser.toLowerCase().trim()) {
                  await logout();
                  return const AuthResult(
                    isSuccess: false,
                    message:
                        'Kredensial sesi tidak sesuai dengan akun sidik jari yang aktif.',
                  );
                }

                await _secureStorage.saveSession(
                  accessToken: session.accessToken,
                  refreshToken: session.refreshToken ?? savedRefreshToken,
                  userId: user.id,
                  email: user.email ?? lastUser,
                );
                if (session.refreshToken != null &&
                    session.refreshToken!.isNotEmpty) {
                  await _secureStorage.saveBiometricRefreshToken(
                    lastUser,
                    session.refreshToken!,
                  );
                  await _secureStorage.saveBiometricAuthRecord(
                    email: lastUser,
                    userId: user.id,
                    fullName: biometricRecord?['fullName'] as String?,
                    refreshToken: session.refreshToken!,
                  );
                }
                return AuthResult(
                  isSuccess: true,
                  message:
                      'Selamat datang kembali! Sesi berhasil dipulihkan dengan sidik jari.',
                  user: user,
                  token: session.accessToken,
                );
              }
            } else {
              return const AuthResult(
                isSuccess: false,
                message:
                    'Kredensial sesi akun tidak ditemukan. Silakan masuk menggunakan kata sandi.',
              );
            }
          }
        } on AuthException catch (e) {
          return AuthResult(
            isSuccess: false,
            message:
                'Sesi autentikasi telah kedaluwarsa (${e.message}). Silakan masuk menggunakan kata sandi.',
          );
        } catch (e) {
          return const AuthResult(
            isSuccess: false,
            message:
                'Sesi autentikasi Anda telah kedaluwarsa. Silakan masuk menggunakan kata sandi.',
          );
        }
      }
    }

    // 2. Mode lokal / offline: periksa data otorisasi biometrik aman
    if (biometricRecord != null) {
      final recordEmail =
          (biometricRecord['email'] as String? ?? lastUser).toLowerCase().trim();
      final recordUserId =
          biometricRecord['userId'] as String? ?? 'user_${recordEmail.hashCode}';
      final recordRefreshToken =
          biometricRecord['refreshToken'] as String? ?? 'biometric_refresh';

      await _secureStorage.saveSession(
        accessToken: 'biometric_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: recordRefreshToken,
        userId: recordUserId,
        email: recordEmail,
      );
      return const AuthResult(
        isSuccess: true,
        message: 'Selamat datang kembali! Berhasil masuk dengan sidik jari.',
      );
    }

    final registeredUsers = await _secureStorage.getRegisteredUsers();
    final cleanLastUser = lastUser.toLowerCase().trim();
    if (registeredUsers.containsKey(cleanLastUser)) {
      final userData = registeredUsers[cleanLastUser];
      final recordUserId = 'local_user_${cleanLastUser.hashCode}';
      await _secureStorage.saveSession(
        accessToken: 'biometric_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'biometric_refresh',
        userId: recordUserId,
        email: cleanLastUser,
      );
      await _secureStorage.saveBiometricAuthRecord(
        email: cleanLastUser,
        userId: recordUserId,
        fullName: userData?['fullName'] as String?,
        refreshToken: 'biometric_refresh',
      );
      return const AuthResult(
        isSuccess: true,
        message: 'Selamat datang kembali! Berhasil masuk dengan sidik jari.',
      );
    }

    return const AuthResult(
      isSuccess: false,
      message:
          'Kredensial akun aman tidak ditemukan. Silakan masuk menggunakan kata sandi.',
    );
  }

  /// Mengaktifkan login biometrik untuk pengguna yang sedang aktif dengan verifikasi aman
  Future<AuthResult> enableBiometricsForUser({
    required String email,
    String? fullName,
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) {
      return const AuthResult(
        isSuccess: false,
        message: 'Email pengguna tidak valid.',
      );
    }

    // 1. Periksa dukungan hardware
    final isSupported = await BiometricService.instance.isDeviceSupported();
    if (!isSupported) {
      return const AuthResult(
        isSuccess: false,
        message:
            'Perangkat Anda tidak memiliki sensor biometrik atau hardware tidak didukung.',
      );
    }

    // 2. Periksa apakah sidik jari sudah terdaftar di OS
    final hasEnrolled = await BiometricService.instance.hasEnrolledBiometrics();
    if (!hasEnrolled) {
      return const AuthResult(
        isSuccess: false,
        message:
            'Belum ada sidik jari yang terdaftar pada perangkat ini. Silakan atur sidik jari di pengaturan sistem Android.',
      );
    }

    // 3. Autentikasi lokal melalui API biometrik
    final bioResult = await BiometricService.instance.authenticate(
      localizedReason:
          'Pindai sidik jari Anda untuk mengonfirmasi aktivasi Login Biometrik JNOVAMUSIC',
    );
    if (!bioResult.isSuccess) {
      return AuthResult(
        isSuccess: false,
        message: bioResult.message,
      );
    }

    // 4. Siapkan kredensial pemulihan sesi yang aman
    String userId = '';
    String refreshToken = '';

    if (AppConfig.isSupabaseConfigured && _supabaseService.isInitialized) {
      final client = _supabaseService.client;
      final session = client?.auth.currentSession;
      final user = client?.auth.currentUser;

      if (session != null && !session.isExpired && user != null) {
        userId = user.id;
        refreshToken = session.refreshToken ?? '';
      } else {
        final savedToken = await _secureStorage.getRefreshToken();
        final savedUserId = await _secureStorage.getUserId();
        if (savedToken != null && savedToken.isNotEmpty) {
          refreshToken = savedToken;
          userId = savedUserId ?? 'user_${cleanEmail.hashCode}';
        } else {
          return const AuthResult(
            isSuccess: false,
            message:
                'Sesi autentikasi server tidak ditemukan. Silakan masuk ulang dengan kata sandi sebelum mengaktifkan biometrik.',
          );
        }
      }
    } else {
      userId =
          await _secureStorage.getUserId() ?? 'local_user_${cleanEmail.hashCode}';
      refreshToken =
          await _secureStorage.getRefreshToken() ?? 'local_refresh';
    }

    // 5. Simpan kredensial aman di Android Keystore
    try {
      await _secureStorage.saveBiometricAuthRecord(
        email: cleanEmail,
        userId: userId,
        fullName: fullName,
        refreshToken: refreshToken,
      );
      if (refreshToken.isNotEmpty) {
        await _secureStorage.saveBiometricRefreshToken(cleanEmail, refreshToken);
      }
      await _secureStorage.setBiometricEnabledForUser(cleanEmail, true);

      // Verifikasi penulisan secure storage berhasil
      final isEnabled =
          await _secureStorage.isBiometricEnabledForUser(cleanEmail);
      final record = await _secureStorage.getBiometricAuthRecord(cleanEmail);
      if (!isEnabled || record == null) {
        throw Exception('Penyimpanan kredensial biometrik gagal diverifikasi.');
      }

      return AuthResult(
        isSuccess: true,
        message:
            'Login dengan Sidik Jari berhasil diaktifkan untuk akun $cleanEmail.',
      );
    } catch (e) {
      // Rollback jika terjadi kegagalan penulisan
      await _secureStorage.clearBiometricForUser(cleanEmail);
      return AuthResult(
        isSuccess: false,
        message: 'Gagal mengaktifkan biometrik: ${e.toString()}',
      );
    }
  }

  /// Menonaktifkan login biometrik untuk pengguna
  Future<AuthResult> disableBiometricsForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    try {
      await _secureStorage.clearBiometricForUser(cleanEmail);
      return const AuthResult(
        isSuccess: true,
        message: 'Login biometrik dinonaktifkan.',
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Gagal menonaktifkan biometrik: ${e.toString()}',
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
