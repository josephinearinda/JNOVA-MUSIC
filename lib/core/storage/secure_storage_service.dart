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
  static const String _keyPrefixProfileUser = 'profile_data_';
  static const String _keyPrefixPointsUser = 'points_balance_';
  static const String _keyPrefixNotificationPreferences =
      'notification_preferences_';

  Future<void> saveNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    final email = (await getUserEmail())?.toLowerCase().trim();
    final key = '$_keyPrefixNotificationPreferences${email ?? 'guest'}';
    final jsonStr = jsonEncode(preferences);
    _memoryFallback[key] = jsonStr;
    try {
      await _storage.write(key: key, value: jsonStr);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getNotificationPreferences() async {
    final email = (await getUserEmail())?.toLowerCase().trim();
    final key = '$_keyPrefixNotificationPreferences${email ?? 'guest'}';
    try {
      final value = await _storage.read(key: key);
      if (value != null && value.isNotEmpty) {
        return jsonDecode(value) as Map<String, dynamic>;
      }
    } catch (_) {}
    final fallback = _memoryFallback[key];
    if (fallback == null || fallback.isEmpty) return null;
    try {
      return jsonDecode(fallback) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    _memoryFallback[_keyProfileData] = jsonStr;
    try {
      await _storage.write(key: _keyProfileData, value: jsonStr);
    } catch (_) {}
    final email = data['email']?.toString().toLowerCase().trim();
    if (email != null && email.isNotEmpty) {
      await saveProfileForUser(email, data);
    }
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

  Future<void> saveProfileForUser(
    String email,
    Map<String, dynamic> data,
  ) async {
    final cleanEmail = email.toLowerCase().trim();
    final key = '$_keyPrefixProfileUser$cleanEmail';
    final jsonStr = jsonEncode(data);
    _memoryFallback[key] = jsonStr;
    try {
      await _storage.write(key: key, value: jsonStr);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getProfileForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return null;
    final key = '$_keyPrefixProfileUser$cleanEmail';
    try {
      final str = await _storage.read(key: key);
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    final fallback = _memoryFallback[key];
    if (fallback != null && fallback.isNotEmpty) {
      try {
        return jsonDecode(fallback) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<void> savePointsForUser(String email, int points) async {
    final cleanEmail = email.toLowerCase().trim();
    final key = '$_keyPrefixPointsUser$cleanEmail';
    final valStr = points.toString();
    _memoryFallback[key] = valStr;
    try {
      await _storage.write(key: key, value: valStr);
    } catch (_) {}
  }

  Future<int?> getPointsForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return null;
    final key = '$_keyPrefixPointsUser$cleanEmail';
    try {
      final str = await _storage.read(key: key);
      if (str != null && str.isNotEmpty) {
        return int.tryParse(str);
      }
    } catch (_) {}
    final fallback = _memoryFallback[key];
    if (fallback != null && fallback.isNotEmpty) {
      return int.tryParse(fallback);
    }
    return null;
  }

  static const String _keyRegisteredUsers = 'registered_users_map';

  Future<void> saveRegisteredUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final users = await getRegisteredUsers();
    users[email.toLowerCase().trim()] = {
      'email': email.toLowerCase().trim(),
      'password': password,
      'fullName': fullName,
    };
    final jsonStr = jsonEncode(users);
    _memoryFallback[_keyRegisteredUsers] = jsonStr;
    try {
      await _storage.write(key: _keyRegisteredUsers, value: jsonStr);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getRegisteredUsers() async {
    try {
      final str = await _storage.read(key: _keyRegisteredUsers);
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    final fallback = _memoryFallback[_keyRegisteredUsers];
    if (fallback != null && fallback.isNotEmpty) {
      try {
        return jsonDecode(fallback) as Map<String, dynamic>;
      } catch (_) {}
    }
    return {};
  }

  Future<void> clearSession() async {
    _memoryFallback.remove(_keyAccessToken);
    _memoryFallback.remove(_keyRefreshToken);
    _memoryFallback.remove(_keyUserId);
    _memoryFallback.remove(_keyUserEmail);
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUserEmail);
    } catch (_) {}
  }

  // --- Dukungan Autentikasi Biometrik ---
  static const String _keyPrefixBiometricEnabled = 'biometric_enabled_';
  static const String _keyLastBiometricUser = 'last_biometric_user';
  static const String _keyPrefixBiometricRefreshToken =
      'biometric_refresh_token_';

  Future<void> setBiometricEnabledForUser(String email, bool enabled) async {
    final cleanEmail = email.toLowerCase().trim();
    final key = '$_keyPrefixBiometricEnabled$cleanEmail';
    final valStr = enabled.toString();
    _memoryFallback[key] = valStr;
    try {
      await _storage.write(key: key, value: valStr);
      if (enabled) {
        _memoryFallback[_keyLastBiometricUser] = cleanEmail;
        await _storage.write(key: _keyLastBiometricUser, value: cleanEmail);
      } else {
        if (_memoryFallback[_keyLastBiometricUser] == cleanEmail) {
          _memoryFallback.remove(_keyLastBiometricUser);
        }
        final last = await getLastBiometricUser();
        if (last == cleanEmail) {
          await _storage.delete(key: _keyLastBiometricUser);
        }
      }
    } catch (_) {}
  }

  Future<bool> isBiometricEnabledForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return false;
    final key = '$_keyPrefixBiometricEnabled$cleanEmail';
    try {
      final val = await _storage.read(key: key);
      if (val != null) return val == 'true';
    } catch (_) {}
    return _memoryFallback[key] == 'true';
  }

  Future<String?> getLastBiometricUser() async {
    try {
      final val = await _storage.read(key: _keyLastBiometricUser);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    return _memoryFallback[_keyLastBiometricUser];
  }

  Future<void> saveBiometricRefreshToken(
    String email,
    String refreshToken,
  ) async {
    final cleanEmail = email.toLowerCase().trim();
    final key = '$_keyPrefixBiometricRefreshToken$cleanEmail';
    _memoryFallback[key] = refreshToken;
    try {
      await _storage.write(key: key, value: refreshToken);
    } catch (_) {}
  }

  Future<String?> getBiometricRefreshToken(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    final key = '$_keyPrefixBiometricRefreshToken$cleanEmail';
    try {
      final val = await _storage.read(key: key);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    return _memoryFallback[key];
  }

  static const String _keyPrefixBiometricRecord = 'biometric_record_';

  Future<void> saveBiometricAuthRecord({
    required String email,
    required String userId,
    String? fullName,
    String? refreshToken,
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    final key = '$_keyPrefixBiometricRecord$cleanEmail';
    final data = {
      'email': cleanEmail,
      'userId': userId,
      'fullName': fullName ?? '',
      'refreshToken': refreshToken ?? '',
      'updatedAt': DateTime.now().toIso8601String(),
    };
    final jsonStr = jsonEncode(data);
    _memoryFallback[key] = jsonStr;
    try {
      await _storage.write(key: key, value: jsonStr);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getBiometricAuthRecord(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    final key = '$_keyPrefixBiometricRecord$cleanEmail';
    try {
      final str = await _storage.read(key: key);
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    final fallback = _memoryFallback[key];
    if (fallback != null && fallback.isNotEmpty) {
      try {
        return jsonDecode(fallback) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearBiometricForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    final key = '$_keyPrefixBiometricEnabled$cleanEmail';
    final tokenKey = '$_keyPrefixBiometricRefreshToken$cleanEmail';
    final recordKey = '$_keyPrefixBiometricRecord$cleanEmail';
    _memoryFallback[key] = 'false';
    _memoryFallback.remove(tokenKey);
    _memoryFallback.remove(recordKey);
    try {
      await _storage.write(key: key, value: 'false');
      await _storage.delete(key: tokenKey);
      await _storage.delete(key: recordKey);
      if (_memoryFallback[_keyLastBiometricUser] == cleanEmail) {
        _memoryFallback.remove(_keyLastBiometricUser);
        await _storage.delete(key: _keyLastBiometricUser);
      }
    } catch (_) {}
  }

  // Remove Gemini keys saved by older app versions.
  static const String _keyGeminiApiKey = 'gemini_api_key';

  Future<void> clearGeminiApiKey() async {
    _memoryFallback.remove(_keyGeminiApiKey);
    try {
      await _storage.delete(key: _keyGeminiApiKey);
    } catch (_) {}
  }
}
