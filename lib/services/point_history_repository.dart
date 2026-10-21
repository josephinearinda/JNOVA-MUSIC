import 'dart:async';
import '../core/config/app_config.dart';
import '../core/network/network_info.dart';
import '../data/datasources/remote/supabase_client_service.dart';
import '../models/point_history_model.dart';

/// Repository untuk data riwayat poin JNOVAMUSIC
class PointHistoryRepository {
  PointHistoryRepository._();

  static final PointHistoryRepository instance = PointHistoryRepository._();
  final SupabaseClientService _supabaseService = SupabaseClientService.instance;

  // Dataset resmi riwayat transaksi poin sesuai screenshot Figma
  final List<PointHistoryModel> _defaultData = const [
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
    PointHistoryModel(
      id: 'tx_4',
      title: "Pembelian Senar D'Addario EXL110 Nickel",
      date: '09 Mei 2025 • 16:05 WIB',
      category: 'Pembelian Produk',
      points: 65,
      type: PointTransactionType.purchase,
      orderId: 'INV/2025/05/JNV-8712',
    ),
    PointHistoryModel(
      id: 'tx_5',
      title: 'Misi Harian JNova Beat Tilt - Mainkan 3 Lagu',
      date: '08 Apr 2025 • 20:15 WIB',
      category: 'Aktivitas Game',
      points: 50,
      type: PointTransactionType.game,
    ),
    PointHistoryModel(
      id: 'tx_6',
      title: 'Roland Cube-10GX Guitar Amplifier',
      date: '18 Apr 2025 • 11:20 WIB',
      category: 'Pembelian Produk',
      points: 195,
      type: PointTransactionType.purchase,
      orderId: 'INV/2025/04/JNV-8430',
    ),
    PointHistoryModel(
      id: 'tx_7',
      title: 'Audio-Technica ATH-M50x Professional Monitor',
      date: '14 Apr 2025 • 17:10 WIB',
      category: 'Pembelian Produk',
      points: 220,
      type: PointTransactionType.purchase,
      orderId: 'INV/2025/04/JNV-8319',
    ),
    PointHistoryModel(
      id: 'tx_8',
      title: 'Beat Master Challenge - Selesaikan Lagu Rock Tempo Tinggi',
      date: '03 Mei 2025 • 10:25 WIB',
      category: 'Aktivitas Game',
      points: 150,
      type: PointTransactionType.game,
    ),
    PointHistoryModel(
      id: 'tx_9',
      title: 'Kabel Jack Mogami 2524 Gold Custom 3m',
      date: '08 Apr 2025 • 10:15 WIB',
      category: 'Pembelian Produk',
      points: 45,
      type: PointTransactionType.purchase,
      orderId: 'INV/2025/04/JNV-8201',
    ),
    PointHistoryModel(
      id: 'tx_10',
      title: 'Misi Harian JNova Beat Tilt - Sempurna 100 Combo',
      date: '28 Apr 2025 • 20:10 WIB',
      category: 'Aktivitas Game',
      points: 50,
      type: PointTransactionType.game,
    ),
    PointHistoryModel(
      id: 'tx_11',
      title: 'Boss DS-1 Distortion Pedal Classic',
      date: '19 Feb 2025 • 13:18 WIB',
      category: 'Pembelian Produk',
      points: 390,
      type: PointTransactionType.purchase,
      orderId: 'INV/2025/02/JNV-7945',
    ),
    PointHistoryModel(
      id: 'tx_12',
      title: 'Jackpot Hujan Poin Promo Gajian',
      date: '25 Apr 2025 • 14:05 WIB',
      category: 'Aktivitas Game',
      points: 100,
      type: PointTransactionType.jackpot,
    ),
    PointHistoryModel(
      id: 'tx_13',
      title: 'Bonus Level Up JNova Beat Tilt Level 10',
      date: '19 Apr 2025 • 16:45 WIB',
      category: 'Aktivitas Game',
      points: 75,
      type: PointTransactionType.bonus,
    ),
  ];

  List<PointHistoryModel> get defaultData => List.unmodifiable(_defaultData);

  /// Mengambil riwayat poin secara asynchronous dari Supabase dengan fallback data resmi
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
            return response.map((item) {
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
          }
        }
      } catch (_) {
        // Fallback ke data visual resmi jika terjadi error koneksi
      }
    }

    return List.from(_defaultData);
  }
}
