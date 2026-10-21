import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi terpusat aplikasi JNOVAMUSIC
class AppConfig {
  AppConfig._();

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Jika file .env tidak ditemukan, fallback ke mode aman/tanpa env
    }
  }

  // Supabase Configuration
  static String get supabaseUrl {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['SUPABASE_URL']?.trim() ?? '';
  }

  static String get supabaseAnonKey {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  }

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-id');

  // Google Gemini AI Configuration
  static String get geminiApiKey {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
  }

  static String get geminiModel {
    if (!dotenv.isInitialized) return 'gemini-1.5-flash';
    return dotenv.env['GEMINI_MODEL']?.trim() ?? 'gemini-1.5-flash';
  }

  static bool get isGeminiConfigured =>
      geminiApiKey.isNotEmpty && !geminiApiKey.contains('your-gemini-api-key');

  // Rekening Resmi Transfer Bank JNOVAMUSIC
  static const String bcaAccountNumber = '8841-0922-1100';
  static const String bcaAccountName = 'PT JNOVA MUSIK INDONESIA';

  static const String mandiriAccountNumber = '137-00-8841922-1';
  static const String mandiriAccountName = 'PT JNOVA MUSIK INDONESIA';
}
