/// Tipe transaksi riwayat poin JNOVAMUSIC
enum PointTransactionType {
  purchase,
  game,
  bonus,
  jackpot,
}

/// Model data transaksi riwayat poin JNOVAMUSIC
class PointHistoryModel {
  final String id;
  final String title;
  final String date;
  final String category;
  final int points;
  final PointTransactionType type;
  final String? orderId;

  const PointHistoryModel({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    required this.points,
    required this.type,
    this.orderId,
  });

  /// Mengembalikan true jika transaksi berasal dari pembelian produk
  bool get isPurchase => type == PointTransactionType.purchase;

  /// Mengembalikan true jika transaksi berasal dari aktivitas game/event
  bool get isGame =>
      type == PointTransactionType.game ||
      type == PointTransactionType.bonus ||
      type == PointTransactionType.jackpot;

  /// Format teks jumlah poin sesuai regulasi Indonesia (+XXX Poin atau -XXX Poin)
  String get formattedPoints {
    final absPoints = points.abs();
    final formatted = absPoints.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    if (points >= 0) {
      return '+$formatted Poin';
    } else {
      return '-$formatted Poin';
    }
  }

  /// Factory untuk membuat dari JSON jika dihubungkan dengan API backend
  factory PointHistoryModel.fromJson(Map<String, dynamic> json) {
    return PointHistoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      category: json['category'] as String,
      points: json['points'] as int,
      type: PointTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PointTransactionType.purchase,
      ),
      orderId: json['order_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'category': category,
      'points': points,
      'type': type.name,
      'order_id': orderId,
    };
  }
}
