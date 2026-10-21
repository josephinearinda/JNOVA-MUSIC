import 'dart:async';
import '../core/config/app_config.dart';
import '../core/network/network_info.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/datasources/remote/supabase_client_service.dart';
import '../models/point_history_model.dart';

/// Repository untuk data riwayat poin JNOVAMUSIC
/// Memisahkan data riwayat per akun, pengguna baru mulai dengan riwayat kosong
class PointHistoryRepository {
  PointHistoryRepository._();

  static final PointHistoryRepository instance = PointHistoryRepository._();
  final SupabaseClientService _supabaseService = SupabaseClientService.instance;
  final SecureStorageService _storage = SecureStorageService.instance;

  // In-memory cache transaksi poin per email pengguna
  final Map<String, List<PointHistoryModel>> _userTransactions = {};

  // Dataset referensi Figma (hanya untuk preview atau fallback dokumentasi)
  static const List<PointHistoryModel> _figmaReferenceData = [
    PointHistoryModel(
      id: 'tx_1',
      title: 'Pembelian Fender Player II Stratocaster HSS',
      date: '10 Mei 2025 • 14:35 WIB',
      category: 'Pembelian Produk',
      points: 1485,
      type: PointTransactionType.purchase,
      orderId: 'INV/2025/05/JNV-8821',
    ),
    PointHistoryModel(
      id: 'tx_2',
      title: 'Bonus JNova Beat Tilt - Skor S Rank Mingguan',
      date: '10 Mei 2025 • 19:40 WIB',
      category: 'Aktivitas Game',
      points: 250,
      type: PointTransactionType.bonus,
    ),
    PointHistoryModel(
      id: 'tx_3',
      title: 'Jackpot Hujan Poin Spesial Weekend',
      date: '10 Mei 2025 • 09:15 WIB',
      category: 'Aktivitas Game',
      points: 100,
      type: PointTransactionType.jackpot,
    ),
  ];

  List<PointHistoryModel> get defaultData => const [];
  List<PointHistoryModel> get referenceData => List.unmodifiable(_figmaReferenceData);

  /// Menambahkan transaksi poin baru ke akun pengguna aktif
  void addTransaction(PointHistoryModel item, {String? userEmail}) {
    final email = (userEmail ?? '').toLowerCase().trim();
    final key = email.isNotEmpty ? email : 'guest';
    _userTransactions.putIfAbsent(key, () => []);
    // Cegah duplikasi transaksi dengan ID yang sama
    _userTransactions[key]!.removeWhere((tx) => tx.id == item.id);
    _userTransactions[key]!.insert(0, item);
  }

  /// Mengambil riwayat poin secara asynchronous khusus untuk pengguna aktif
  Future<List<PointHistoryModel>> getPointHistory({
    bool forceError = false,
    bool forceEmpty = false,
  }) async {
    if (forceError) {
      throw Exception('Tidak dapat mengambil data riwayat poin. Silakan coba lagi.');
    }

    if (forceEmpty) {
      return [];
    }

    final email = (await _storage.getUserEmail())?.toLowerCase().trim();

    final isOnline = await NetworkInfo.instance.isConnected;
    if (isOnline && AppConfig.isSupabaseConfigured && _supabaseService.isInitialized) {
      try {
        final client = _supabaseService.client;
        final user = client?.auth.currentUser;
        if (client != null && user != null) {
          final List<dynamic> response = await client
              .from('point_transactions')
              .select()
              .eq('user_id', user.id)
              .order('created_at', ascending: false);

          if (response.isNotEmpty) {
            final remoteList = response.map((item) {
              final map = Map<String, dynamic>.from(item);
              final typeStr = map['transaction_type']?.toString().toLowerCase() ?? '';
              PointTransactionType type = PointTransactionType.purchase;
              if (typeStr.contains('bonus')) type = PointTransactionType.bonus;
              if (typeStr.contains('jackpot')) type = PointTransactionType.jackpot;
              if (typeStr.contains('game')) type = PointTransactionType.game;

              return PointHistoryModel(
                id: map['id']?.toString() ?? '',
                title: map['title']?.toString() ?? '',
                date: map['created_at']?.toString() ?? '',
                category: map['category']?.toString() ?? 'Pembelian Produk',
                points: (map['points'] as num?)?.toInt() ?? 0,
                type: type,
                orderId: map['order_id']?.toString(),
              );
            }).toList();

            // Gabungkan dengan transaksi lokal terbaru
            final localKey = email ?? 'guest';
            final local = _userTransactions[localKey] ?? [];
            for (final tx in local) {
              if (!remoteList.any((r) => r.id == tx.id)) {
                remoteList.insert(0, tx);
              }
            }
            return remoteList;
          }
        }
      } catch (_) {}
    }

    // Jika offline atau belum ada di Supabase, kembalikan transaksi lokal untuk akun ini
    final key = email ?? 'guest';
    final userList = _userTransactions[key];
    if (userList != null && userList.isNotEmpty) {
      return List.from(userList);
    }

    // Pengguna baru selalu memiliki riwayat kosong (0 transaksi)
    return [];
  }

  /// Menghapus cache transaksi saat logout
  void clearCache() {
    _userTransactions.clear();
  }
}
