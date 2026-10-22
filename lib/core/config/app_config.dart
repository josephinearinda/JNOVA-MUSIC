import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../storage/secure_storage_service.dart';

/// Konfigurasi terpusat aplikasi JNOVAMUSIC
class AppConfig {
  AppConfig._();

  static Future<void> initialize({bool clearLegacyGeminiApiKey = true}) async {
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

    if (clearLegacyGeminiApiKey) {
      await SecureStorageService.instance.clearGeminiApiKey();
    }
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

  static bool get isAiBackendConfigured => isSupabaseConfigured;

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
