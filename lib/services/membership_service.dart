import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';
import '../core/network/network_info.dart';
import '../data/datasources/remote/supabase_client_service.dart';

/// Layanan manajemen saldo poin dan tier membership JNOVAMUSIC
class MembershipService extends ChangeNotifier {
  MembershipService._();

  static final MembershipService instance = MembershipService._();
  final SupabaseClientService _supabaseService = SupabaseClientService.instance;

  // Saldo poin awal sesuai desain referensi Figma: 3.250 Poin
  int _currentPoints = 3250;
  final String _userTier = 'TIER 2';
  final String _tierName = 'Silver Member';

  int get currentPoints => _currentPoints;
  String get userTier => _userTier;
  String get tierName => _tierName;

  /// Menambahkan poin yang diperoleh dari sesi game yang valid
  void addGamePoints(int points) {
    if (points > 0) {
      _currentPoints += points;
      notifyListeners();
      _syncGamePointsToSupabase(points);
    }
  }

  Future<void> _syncGamePointsToSupabase(int points) async {
    if (!AppConfig.isSupabaseConfigured || !_supabaseService.isInitialized) {
      return;
    }
    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline) {
      return;
    }

    try {
      final client = _supabaseService.client;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('point_transactions').insert({
          'user_id': user.id,
          'title': 'Bonus JNova Beat Tilt - Skor S Rank',
          'category': 'Aktivitas Game',
          'points': points,
          'transaction_type': 'game_bonus',
        });
      }
    } catch (_) {}
  }

  /// Reset poin untuk keperluan pengujian
  void setPoints(int points) {
    _currentPoints = points;
    notifyListeners();
  }
}
