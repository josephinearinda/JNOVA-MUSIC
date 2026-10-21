import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../storage/secure_storage_service.dart';

/// Konfigurasi terpusat aplikasi JNOVAMUSIC
class AppConfig {
  AppConfig._();

  static String? _customApiKey;
  static String? _customModel;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env', mergeWith: Platform.environment);
    } catch (_) {
      // Jika file .env tidak ditemukan di asset bundle (misal belum di-bundle),
      // coba baca langsung dari file lokal jika pada lingkungan desktop/lokal
      if (!kIsWeb) {
        try {
          final localFile = File('.env');
          if (localFile.existsSync()) {
            final lines = await localFile.readAsLines();
            final map = <String, String>{};
            for (final line in lines) {
              final trimmed = line.trim();
              if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
              final idx = trimmed.indexOf('=');
              if (idx > 0) {
                final k = trimmed.substring(0, idx).trim();
                final v = trimmed.substring(idx + 1).trim();
                map[k] = v;
              }
            }
            await dotenv.load(mergeWith: {...Platform.environment, ...map});
          }
        } catch (_) {}
      }
    }

    // Muat API key dan model kustom dari Secure Storage jika telah dikonfigurasi pengguna
    try {
      final storedKey = await SecureStorageService.instance.getGeminiApiKey();
      if (storedKey != null && storedKey.isNotEmpty) {
        _customApiKey = storedKey;
      }
      final storedModel = await SecureStorageService.instance.getGeminiModel();
      if (storedModel != null && storedModel.isNotEmpty) {
        _customModel = storedModel;
      }
    } catch (_) {}
  }

  // Supabase Configuration
  static String get supabaseUrl {
    if (!dotenv.isInitialized) return '';
    return _cleanEnvVal(dotenv.env['SUPABASE_URL']);
  }

  static String get supabaseAnonKey {
    if (!dotenv.isInitialized) return '';
    return _cleanEnvVal(dotenv.env['SUPABASE_ANON_KEY']);
  }

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-id');

  // Google Gemini AI Configuration
  /// Mengambil Gemini API Key dari urutan prioritas:
  /// 1. Kunci kustom di Secure Storage (disimpan via dialog aplikasi)
  /// 2. Compile-time --dart-define=GEMINI_API_KEY=...
  /// 3. OS / System Environment (Platform.environment: GEMINI_API_KEY / gemini_api_key / GOOGLE_API_KEY)
  /// 4. File .env (GEMINI_API_KEY / gemini_api_key / GOOGLE_API_KEY / google_api_key / GEMINI_KEY)
  static String get geminiApiKey {
    if (_customApiKey != null && _customApiKey!.isNotEmpty) {
      return _customApiKey!;
    }

    const compileTimeKey = String.fromEnvironment('GEMINI_API_KEY');
    if (compileTimeKey.isNotEmpty) {
      return compileTimeKey.trim();
    }

    if (!kIsWeb) {
      try {
        final sysEnv = Platform.environment['GEMINI_API_KEY'] ??
            Platform.environment['gemini_api_key'] ??
            Platform.environment['GOOGLE_API_KEY'] ??
            Platform.environment['google_api_key'] ??
            Platform.environment['GEMINI_KEY'] ??
            Platform.environment['gemini_key'];
        if (sysEnv != null && sysEnv.trim().isNotEmpty) {
          final cleaned = _cleanEnvVal(sysEnv);
          if (cleaned.isNotEmpty) return cleaned;
        }
      } catch (_) {}
    }

    if (!dotenv.isInitialized) return '';

    final candidate = dotenv.env['GEMINI_API_KEY'] ??
        dotenv.env['gemini_api_key'] ??
        dotenv.env['GOOGLE_API_KEY'] ??
        dotenv.env['google_api_key'] ??
        dotenv.env['GEMINI_KEY'] ??
        dotenv.env['gemini_key'] ??
        '';

    return _cleanEnvVal(candidate);
  }

  /// Mengambil Gemini Model dari:
  /// 1. Model kustom di Secure Storage (disimpan via dialog aplikasi)
  /// 2. Compile-time --dart-define=GEMINI_MODEL=...
  /// 3. OS / System Environment (Platform.environment: GEMINI_MODEL / gemini_model)
  /// 4. File .env (GEMINI_MODEL / gemini_model / GOOGLE_MODEL)
  /// Default: gemini-1.5-flash
  static String get geminiModel {
    if (_customModel != null && _customModel!.isNotEmpty) {
      return _customModel!;
    }

    const compileTimeModel = String.fromEnvironment('GEMINI_MODEL');
    if (compileTimeModel.isNotEmpty) {
      return compileTimeModel.trim();
    }

    if (!kIsWeb) {
      try {
        final sysEnv = Platform.environment['GEMINI_MODEL'] ??
            Platform.environment['gemini_model'] ??
            Platform.environment['GOOGLE_MODEL'];
        if (sysEnv != null && sysEnv.trim().isNotEmpty) {
          final cleaned = _cleanEnvVal(sysEnv);
          if (cleaned.isNotEmpty) return cleaned;
        }
      } catch (_) {}
    }

    if (!dotenv.isInitialized) return 'gemini-1.5-flash';

    final candidate = dotenv.env['GEMINI_MODEL'] ??
        dotenv.env['gemini_model'] ??
        dotenv.env['GOOGLE_MODEL'] ??
        '';

    final cleaned = _cleanEnvVal(candidate);
    return cleaned.isNotEmpty ? cleaned : 'gemini-1.5-flash';
  }

  /// Memeriksa apakah Gemini API Key valid dan bukan placeholder
  static bool get isGeminiConfigured {
    final key = geminiApiKey;
    if (key.isEmpty) return false;
    final lower = key.toLowerCase();
    if (lower.contains('your-gemini-api-key') ||
        lower.contains('your_gemini_api_key') ||
        lower.contains('your-api-key') ||
        lower.contains('insert-key-here') ||
        lower.contains('your_api_key') ||
        lower.contains('ganti_dengan_api_key')) {
      return false;
    }
    return key.length >= 10;
  }

  /// Simpan API key baru ke memori & Secure Storage
  static Future<void> saveGeminiApiKey(String key) async {
    final clean = key.trim();
    _customApiKey = clean;
    await SecureStorageService.instance.saveGeminiApiKey(clean);
  }

  /// Hapus API key kustom (kembali ke .env / unconfigured)
  static Future<void> clearCustomGeminiApiKey() async {
    _customApiKey = null;
    await SecureStorageService.instance.clearGeminiApiKey();
  }

  /// Simpan model baru ke memori & Secure Storage
  static Future<void> saveGeminiModel(String model) async {
    final clean = model.trim();
    _customModel = clean;
    await SecureStorageService.instance.saveGeminiModel(clean);
  }

  /// Hapus model kustom
  static Future<void> clearCustomGeminiModel() async {
    _customModel = null;
    await SecureStorageService.instance.saveGeminiModel('gemini-1.5-flash');
  }

  /// Helper untuk membersihkan tanda kutip dan spasi dari nilai env
  static String _cleanEnvVal(String? val) {
    if (val == null) return '';
    var s = val.trim();
    if ((s.startsWith('"') && s.endsWith('"')) ||
        (s.startsWith("'") && s.endsWith("'"))) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s;
  }

  // Rekening Resmi Transfer Bank JNOVAMUSIC
  static const String bcaAccountNumber = '8841-0922-1100';
  static const String bcaAccountName = 'PT JNOVA MUSIK INDONESIA';

  static const String mandiriAccountNumber = '137-00-8841922-1';
  static const String mandiriAccountName = 'PT JNOVA MUSIK INDONESIA';
}
