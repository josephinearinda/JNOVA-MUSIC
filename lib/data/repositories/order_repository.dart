import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../core/config/app_config.dart';
import '../../core/network/network_info.dart';
import '../../models/order_model.dart';
import '../../models/product.dart';
import '../../models/store_branch.dart';
import '../datasources/local/app_database.dart';
import '../datasources/remote/supabase_client_service.dart';

class OrderRepository {
  OrderRepository._();
  static final OrderRepository instance = OrderRepository._();

  final AppDatabase _dbHelper = AppDatabase.instance;
  final SupabaseClientService _supabaseService = SupabaseClientService.instance;

  /// Melakukan checkout pesanan baru dengan alur Pickup & Bayar di Toko
  Future<OrderModel> checkout({
    required List<CartItem> items,
    required FulfillmentMethod fulfillment,
    String paymentMethod = 'Bayar di Toko (Pickup & Pay)',
    StoreBranch? store,
    int serviceCost = 1000,
    String? recipientName,
    String? recipientPhone,
    String? recipientAddress,
    String? userEmail,
    double? discountRate,
  }) async {
    final subtotal = items.fold(0, (sum, i) => sum + i.itemTotal);
    final effectiveDiscountRate = discountRate ?? 0.10;
    final discount = (subtotal * effectiveDiscountRate).round();
    final totalPayment = subtotal - discount + serviceCost;

    final idempotencyKey = 'ord_${DateTime.now().millisecondsSinceEpoch}_${items.length}';
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dateFormatted =
        '${now.day} ${months[now.month - 1]} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
    final randomSuffix = 1000 + (now.millisecondsSinceEpoch % 9000);
    final orderNumber = '#JNV-${now.year}${now.month.toString().padLeft(2, '0')}-$randomSuffix';
    final pickupCode = 'PKP-$randomSuffix-JNV';

    String orderId = idempotencyKey;
    final isOnline = await NetworkInfo.instance.isConnected;
    final isSupabaseReady = AppConfig.isSupabaseConfigured && _supabaseService.isInitialized;

    if (isOnline && isSupabaseReady) {
      try {
        final client = _supabaseService.client!;
        final itemsPayload = items.map((i) => {
          'product_id': i.product.id,
          'quantity': i.quantity,
        }).toList();

        final rpcResult = await client.rpc('create_order_secure', params: {
          'p_idempotency_key': idempotencyKey,
          'p_fulfillment': 'pickup',
          'p_payment_method': 'store_pickup_pay',
          'p_items': itemsPayload,
          'p_pickup_store_id': store?.id,
          'p_shipping_fee': 0,
          'p_packing_fee': 0,
          'p_notes': 'Pesanan Pickup & Bayar di Toko JNOVAMUSIC',
        });

        if (rpcResult != null) {
          orderId = rpcResult.toString();
        }
      } catch (_) {}
    }

    final order = OrderModel(
      id: orderId,
      orderNumber: orderNumber,
      dateFormatted: dateFormatted,
      fulfillmentMethod: FulfillmentMethod.pickup,
      status: 'Menunggu Pengambilan & Pembayaran di Toko',
      items: List.from(items),
      subtotal: subtotal,
      discount: discount,
      shippingFee: 0,
      packingFee: 0,
      serviceFee: serviceCost,
      totalPayment: totalPayment > 0 ? totalPayment : 0,
      paymentMethod: paymentMethod,
      pickupStore: store ?? StoreBranch.branches.first,
      pickupCode: pickupCode,
      recipientName: (recipientName != null && recipientName.trim().isNotEmpty)
          ? recipientName.trim()
          : (userEmail != null && userEmail.contains('@')
              ? userEmail.split('@').first
              : 'Pelanggan JNOVAMUSIC'),
      recipientPhone: recipientPhone ?? '',
      recipientAddress: recipientAddress ?? '',
      isCompleted: false,
      pointsAwarded: false,
      userEmail: userEmail ?? '',
    );

    await _cacheOrderLocally(order);

    return order;
  }

  Future<void> _cacheOrderLocally(OrderModel order) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        'cached_orders',
        {
          'id': order.id,
          'order_number': order.orderNumber,
          'date_formatted': order.dateFormatted,
          'fulfillment_method': order.fulfillmentMethod.name,
          'status': order.status,
          'total_payment': order.totalPayment,
          'raw_json': jsonEncode(order.toMap()),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Mengambil pesanan yang tersimpan untuk email tertentu
  Future<List<OrderModel>> getOrdersForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return [];

    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'cached_orders',
        orderBy: 'cached_at DESC',
      );

      final list = <OrderModel>[];

      for (final r in rows) {
        final raw = r['raw_json'] as String?;
        final orderId = r['id'] as String?;
        if (raw != null && raw.isNotEmpty) {
          try {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            final order = OrderModel.fromMap(map);

            // Bersihkan pesanan rusak yang kosong atau tanpa email pengguna
            if (order.items.isEmpty || order.userEmail.trim().isEmpty) {
              if (orderId != null) {
                await db.delete('cached_orders', where: 'id = ?', whereArgs: [orderId]);
              }
              continue;
            }

            // Hanya sertakan pesanan yang cocok persis dengan akun aktif
            if (order.userEmail.toLowerCase().trim() == cleanEmail) {
              list.add(order);
            }
          } catch (_) {}
        }
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  /// Memperbarui pesanan saat status berubah (misalnya diselesaikan)
  Future<void> updateOrder(OrderModel order) async {
    await _cacheOrderLocally(order);

    // Sinkronkan ke Supabase jika online
    final isOnline = await NetworkInfo.instance.isConnected;
    if (isOnline && AppConfig.isSupabaseConfigured && _supabaseService.isInitialized) {
      try {
        final client = _supabaseService.client;
        if (client != null) {
          await client
              .from('orders')
              .update({'status': order.status})
              .eq('id', order.id);
        }
      } catch (_) {}
    }
  }
}
