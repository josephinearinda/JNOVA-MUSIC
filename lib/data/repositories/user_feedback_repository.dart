import 'package:sqflite/sqflite.dart';

import '../datasources/local/app_database.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/user_feedback.dart';

abstract interface class UserFeedbackRepository {
  Future<List<UserFeedback>> getMyFeedback();

  Future<UserFeedback> submitFeedback({
    required String message,
    required String type,
    required String sender,
    required int rating,
  });
}

class LocalUserFeedbackRepository implements UserFeedbackRepository {
  LocalUserFeedbackRepository({
    AppDatabase? database,
    SecureStorageService? storage,
  }) : _database = database ?? AppDatabase.instance,
       _storage = storage ?? SecureStorageService.instance;

  final AppDatabase _database;
  final SecureStorageService _storage;

  Future<String> _requireUserEmail() async {
    final email = (await _storage.getUserEmail())?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      throw const UserFeedbackException(
        'Silakan login untuk melihat atau mengirim saran dan kesan.',
      );
    }
    return email;
  }

  @override
  Future<List<UserFeedback>> getMyFeedback() async {
    final email = await _requireUserEmail();
    final db = await _database.database;
    final rows = await db.query(
      'user_feedback',
      where: 'user_email = ?',
      whereArgs: [email],
      orderBy: 'created_at DESC, id DESC',
    );

    return rows.map((row) => UserFeedback.fromMap(row)).toList();
  }

  @override
  Future<UserFeedback> submitFeedback({
    required String message,
    required String type,
    required String sender,
    required int rating,
  }) async {
    final email = await _requireUserEmail();
    final submittedAt = DateTime.now();
    final db = await _database.database;
    await db.insert('user_feedback', {
      'user_email': email,
      'message': message,
      'type': type,
      'sender_name': sender,
      'rating': rating,
      'created_at': submittedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);

    return UserFeedback(
      message: message,
      type: type,
      sender: sender,
      rating: rating,
      submittedAt: submittedAt,
    );
  }
}

class UserFeedbackException implements Exception {
  final String message;

  const UserFeedbackException(this.message);

  @override
  String toString() => message;
}
