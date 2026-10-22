import 'package:flutter_test/flutter_test.dart';
import 'package:jnova/core/storage/secure_storage_service.dart';
import 'package:jnova/data/repositories/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pengujian Pemulihan dan Ketahanan Biometrik (Sidik Jari)', () {
    late SecureStorageService storage;
    late AuthRepository authRepository;

    setUp(() async {
      storage = SecureStorageService.instance;
      authRepository = AuthRepository.instance;
      await storage.clearSession();
    });

    test('1. Akun dengan biometrik aktif dapat login sukses tanpa error kedaluwarsa', () async {
      const email = 'user.test@example.com';
      const password = 'Password123!';

      // Simpan kredensial biometrik & aktifkan
      await storage.saveBiometricCredentials(email: email, password: password);
      await storage.saveRegisteredUser(email: email, password: password, fullName: 'Test User');
      await storage.setBiometricEnabledForUser(email, true);
      await storage.saveBiometricAuthRecord(
        email: email,
        userId: 'test_uid_1',
        fullName: 'Test User',
        refreshToken: 'dummy_old_expired_token',
      );

      // Jalankan login biometrik
      final result = await authRepository.loginWithBiometrics(email: email);

      expect(result.isSuccess, isTrue);
      expect(result.message, contains('Selamat datang kembali'));

      // Verifikasi sesi terpasang
      final activeEmail = await storage.getUserEmail();
      expect(activeEmail, equals(email));
    });

    test('2. Biometrik dengan token kadaluwarsa tetap pulih dan login berhasil', () async {
      const email = 'expired.token@example.com';
      await storage.setBiometricEnabledForUser(email, true);
      await storage.saveBiometricAuthRecord(
        email: email,
        userId: 'test_uid_2',
        fullName: 'Expired User',
        refreshToken: 'invalid_expired_token_123',
      );

      final result = await authRepository.loginWithBiometrics(email: email);

      // Tidak boleh melempar atau memunculkan error "Sesi autentikasi telah kedaluwarsa"
      expect(result.isSuccess, isTrue);
      expect(result.message.contains('kedaluwarsa'), isFalse);
    });

    test('3. Biometrik tanpa email eksplisit otomatis mendeteksi pengguna terakhir', () async {
      const email = 'last.bio.user@example.com';
      await storage.setBiometricEnabledForUser(email, true);

      final lastUser = await storage.getLastBiometricUser();
      expect(lastUser, equals(email));

      final result = await authRepository.loginWithBiometrics();
      expect(result.isSuccess, isTrue);
      final sessionEmail = await storage.getUserEmail();
      expect(sessionEmail, equals(email));
    });
  });
}
