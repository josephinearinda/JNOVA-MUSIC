import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';

/// Service inisialisasi & pembungkus klien Supabase
class SupabaseClientService {
  SupabaseClientService._();
  static final SupabaseClientService instance = SupabaseClientService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Inisialisasi Supabase SDK
  Future<void> initialize() async {
    if (!AppConfig.isSupabaseConfigured) {
      _isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
    }
  }

  // Session & User helpers
  User? get currentUser => client?.auth.currentUser;
  Session? get currentSession => client?.auth.currentSession;
  bool get isAuthenticated => currentUser != null;
}
