import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jnova/core/storage/secure_storage_service.dart';
import 'package:jnova/data/repositories/user_feedback_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('feedback remains available after repository recreation', () async {
    await SecureStorageService.instance.saveSession(
      accessToken: 'local_token_user_a',
      refreshToken: 'local_refresh_user_a',
      userId: 'user-a',
      email: 'user.a@example.com',
    );
    final firstRepository = LocalUserFeedbackRepository();

    await firstRepository.submitFeedback(
      message: 'Materi Flutter mudah dipahami.',
      type: 'Kesan',
      sender: 'Pengguna A',
      rating: 5,
    );

    final reopenedRepository = LocalUserFeedbackRepository();
    final feedback = await reopenedRepository.getMyFeedback();

    expect(feedback, hasLength(1));
    expect(feedback.single.message, 'Materi Flutter mudah dipahami.');
    expect(feedback.single.type, 'Kesan');
    expect(feedback.single.sender, 'Pengguna A');
    expect(feedback.single.rating, 5);
  });

  test('feedback is isolated by signed-in account email', () async {
    final storage = SecureStorageService.instance;
    await storage.saveSession(
      accessToken: 'local_token_user_a',
      refreshToken: 'local_refresh_user_a',
      userId: 'user-a',
      email: 'user.a@example.com',
    );
    final repository = LocalUserFeedbackRepository();
    await repository.submitFeedback(
      message: 'Masukan akun A',
      type: 'Saran',
      sender: 'Pengguna A',
      rating: 0,
    );

    await storage.saveSession(
      accessToken: 'local_token_user_b',
      refreshToken: 'local_refresh_user_b',
      userId: 'user-b',
      email: 'user.b@example.com',
    );

    expect(await repository.getMyFeedback(), isEmpty);
  });
}
