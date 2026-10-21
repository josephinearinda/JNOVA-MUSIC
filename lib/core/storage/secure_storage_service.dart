import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Layanan penyimpanan aman terenkripsi (Android Keystore / iOS Keychain)
/// Dilengkapi in-memory fallback untuk stabilitas test & error recovery.
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final Map<String, String> _memoryFallback = {};

  static const String _keyAccessToken = 'supabase_access_token';
  static const String _keyRefreshToken = 'supabase_refresh_token';
  static const String _keyUserId = 'current_user_id';
  static const String _keyUserEmail = 'current_user_email';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
  }) async {
    _memoryFallback[_keyAccessToken] = accessToken;
    _memoryFallback[_keyRefreshToken] = refreshToken;
    _memoryFallback[_keyUserId] = userId;
    _memoryFallback[_keyUserEmail] = email;

    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
      await _storage.write(key: _keyUserId, value: userId);
      await _storage.write(key: _keyUserEmail, value: email);
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    try {
      final val = await _storage.read(key: _keyAccessToken);
      if (val != null) return val;
    } catch (_) {}
    return _memoryFallback[_keyAccessToken];
  }

  Future<String?> getRefreshToken() async {
    try {
      final val = await _storage.read(key: _keyRefreshToken);
      if (val != null) return val;
    } catch (_) {}
    return _memoryFallback[_keyRefreshToken];
  }

  Future<String?> getUserId() async {
    try {
      final val = await _storage.read(key: _keyUserId);
      if (val != null) return val;
    } catch (_) {}
    return _memoryFallback[_keyUserId];
  }

  Future<String?> getUserEmail() async {
    try {
      final val = await _storage.read(key: _keyUserEmail);
      if (val != null) return val;
    } catch (_) {}
    return _memoryFallback[_keyUserEmail];
  }

  static const String _keyPreferredCurrency = 'preferred_currency';

  Future<void> saveCurrency(String currency) async {
    _memoryFallback[_keyPreferredCurrency] = currency;
    try {
      await _storage.write(key: _keyPreferredCurrency, value: currency);
    } catch (_) {}
  }

  Future<String?> getCurrency() async {
    try {
      final val = await _storage.read(key: _keyPreferredCurrency);
      if (val != null) return val;
    } catch (_) {}
    return _memoryFallback[_keyPreferredCurrency];
  }

  static const String _keyProfileData = 'user_profile_data';

  Future<void> saveProfile(Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    _memoryFallback[_keyProfileData] = jsonStr;
    try {
      await _storage.write(key: _keyProfileData, value: jsonStr);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final str = await _storage.read(key: _keyProfileData);
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    final fallback = _memoryFallback[_keyProfileData];
    if (fallback != null && fallback.isNotEmpty) {
      try {
        return jsonDecode(fallback) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearSession() async {
    _memoryFallback.clear();
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUserEmail);
    } catch (_) {}
  }
}
