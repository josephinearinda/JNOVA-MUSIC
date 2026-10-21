import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';
import '../core/network/network_info.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/datasources/remote/supabase_client_service.dart';
import '../models/point_history_model.dart';
import 'point_history_repository.dart';
import 'user_profile_service.dart';

/// Layanan manajemen saldo poin dan tier membership JNOVAMUSIC
/// Pengguna baru mulai dari 0 poin, konsisten antar sesi dan terisolasi per akun
class MembershipService extends ChangeNotifier {
  MembershipService._() {
    _initializePoints();
  }

  static final MembershipService instance = MembershipService._();
  final SupabaseClientService _supabaseService = SupabaseClientService.instance;
  final SecureStorageService _storage = SecureStorageService.instance;

  // Pengguna baru selalu mulai dari 0 poin
  int _currentPoints = 0;

  int get currentPoints => _currentPoints;
  String get userTier =>
      _currentPoints >= 10000 ? 'TIER 4' : (_currentPoints >= 3000 ? 'TIER 3' : 'TIER 2');
  String get tierName =>
      _currentPoints >= 10000 ? 'Platinum Member' : (_currentPoints >= 3000 ? 'Gold Member' : 'Silver Member');
  int get discountPercentage =>
      _currentPoints >= 10000 ? 35 : (_currentPoints >= 3000 ? 20 : 10);
  double get discountRate => discountPercentage / 100.0;
  int get targetPoints =>
      _currentPoints >= 10000 ? 10000 : (_currentPoints >= 3000 ? 10000 : 3000);
  String get nextTierName =>
      _currentPoints >= 10000 ? 'Maksimal' : (_currentPoints >= 3000 ? 'Platinum' : 'Gold');

  Future<void> _initializePoints() async {
    try {
      final email = await _storage.getUserEmail();
      if (email != null && email.isNotEmpty) {
        await loadPointsForUser(email);
      }
    } catch (_) {}
  }

  /// Memuat saldo poin khusus untuk pengguna aktif
  Future<void> loadPointsForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    try {
      final savedPoints = await _storage.getPointsForUser(cleanEmail);
      _currentPoints = savedPoints ?? 0;
      notifyListeners();

      // Sinkronkan ke UserProfileService
      UserProfileService.instance.updateProfile(
        points: _currentPoints,
        tier: tierName,
      );

      // Sinkronkan dari Supabase jika online
      _loadPointsFromSupabase(cleanEmail);
    } catch (_) {}
  }

  Future<void> _loadPointsFromSupabase(String email) async {
    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline ||
        !AppConfig.isSupabaseConfigured ||
        !_supabaseService.isInitialized) {
      return;
    }

    try {
      final client = _supabaseService.client;
      final user = client?.auth.currentUser;
      if (client != null && user != null && user.email == email) {
        final List<dynamic> records = await client
            .from('point_transactions')
            .select('points')
            .eq('user_id', user.id);

        if (records.isNotEmpty) {
          int totalFromRemote = 0;
          for (final r in records) {
            totalFromRemote += (r['points'] as num?)?.toInt() ?? 0;
          }
          if (totalFromRemote > _currentPoints) {
            _currentPoints = totalFromRemote;
            await _storage.savePointsForUser(email, _currentPoints);
            notifyListeners();
            UserProfileService.instance.updateProfile(
              points: _currentPoints,
              tier: tierName,
            );
          }
        }
      }
    } catch (_) {}
  }

  /// Menambahkan poin dari pembelian produk resmi
  Future<void> addPurchasePoints(
    int points, {
    required String orderNumber,
    required String orderTitle,
  }) async {
    if (points <= 0) return;

    _currentPoints += points;
    notifyListeners();

    final email = await _storage.getUserEmail();
    if (email != null && email.isNotEmpty) {
      await _storage.savePointsForUser(email, _currentPoints);
    }

    UserProfileService.instance.updateProfile(
      points: _currentPoints,
      tier: tierName,
    );

    // Catat ke PointHistoryRepository
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dateStr =
        '${now.day} ${months[now.month - 1]} ${now.year} • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    PointHistoryRepository.instance.addTransaction(
      PointHistoryModel(
        id: 'tx_${now.millisecondsSinceEpoch}',
        title: 'Pembelian $orderTitle',
        date: dateStr,
        category: 'Pembelian Produk',
        points: points,
        type: PointTransactionType.purchase,
        orderId: orderNumber,
      ),
      userEmail: email,
    );

    _syncPointTransactionToSupabase(
      points: points,
      title: 'Pembelian $orderTitle',
      category: 'Pembelian Produk',
      type: 'purchase',
      orderId: orderNumber,
    );
  }

  /// Menambahkan poin yang diperoleh dari sesi game yang valid
  Future<void> addGamePoints(int points, {String? gameTitle}) async {
    if (points <= 0) return;

    _currentPoints += points;
    notifyListeners();

    final email = await _storage.getUserEmail();
    if (email != null && email.isNotEmpty) {
      await _storage.savePointsForUser(email, _currentPoints);
    }

    UserProfileService.instance.updateProfile(
      points: _currentPoints,
      tier: tierName,
    );

    final title = gameTitle ?? 'Bonus JNova Beat Tilt - Skor Ritme';
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dateStr =
        '${now.day} ${months[now.month - 1]} ${now.year} • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    PointHistoryRepository.instance.addTransaction(
      PointHistoryModel(
        id: 'tx_game_${now.millisecondsSinceEpoch}',
        title: title,
        date: dateStr,
        category: 'Aktivitas Game',
        points: points,
        type: PointTransactionType.game,
      ),
      userEmail: email,
    );

    _syncPointTransactionToSupabase(
      points: points,
      title: title,
      category: 'Aktivitas Game',
      type: 'game_bonus',
    );
  }

  Future<void> _syncPointTransactionToSupabase({
    required int points,
    required String title,
    required String category,
    required String type,
    String? orderId,
  }) async {
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
          'title': title,
          'category': category,
          'points': points,
          'transaction_type': type,
          'order_id': ?orderId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  /// Reset poin untuk keperluan logout atau pergantian akun
  void resetPoints() {
    _currentPoints = 0;
    notifyListeners();
  }

  /// Set poin manual (untuk testing / migrasi)
  void setPoints(int points) {
    _currentPoints = points;
    notifyListeners();
  }
}
