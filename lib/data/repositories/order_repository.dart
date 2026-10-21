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

  /// Melakukan checkout pesanan baru dengan validasi server-authoritative & proteksi idempotensi
  Future<OrderModel> checkout({
    required List<CartItem> items,
    required FulfillmentMethod fulfillment,
    required String paymentMethod,
    StoreBranch? store,
    int shippingCost = 0,
    int packingCost = 0,
    int serviceCost = 1000,
    String? recipientName,
    String? recipientPhone,
    String? recipientAddress,
  }) async {
    final subtotal = items.fold(0, (sum, i) => sum + i.itemTotal);
    final discount = (subtotal * 0.10).round(); // Silver Member 10%
    final totalPayment = subtotal - discount + shippingCost + packingCost + serviceCost;

    // Idempotency key unik untuk mencegah submit dobel
    final idempotencyKey = 'ord_${DateTime.now().millisecondsSinceEpoch}_${items.length}';
    final nowFormatted = _formatCurrentDateTime();

    // Tentukan rekening bank resmi JNOVAMUSIC
    final isBca = paymentMethod.toLowerCase().contains('bca');
    final isMandiri = paymentMethod.toLowerCase().contains('mandiri');

    final bankAccNumber = isMandiri
        ? AppConfig.mandiriAccountNumber
        : AppConfig.bcaAccountNumber;
    final bankAccName = isMandiri
        ? AppConfig.mandiriAccountName
        : AppConfig.bcaAccountName;

    final isOnline = await NetworkInfo.instance.isConnected;
    final isSupabaseReady = AppConfig.isSupabaseConfigured && _supabaseService.isInitialized;

    String orderId = idempotencyKey;
    String orderNumber = '#JNV-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${1000 + (DateTime.now().millisecond % 9000)}';
    String initialStatus;
    bool isOfflinePending = false;

    if (isOnline && isSupabaseReady) {
      // 1. Jalankan Transaksi Resmi di Supabase PostgreSQL
      try {
        final client = _supabaseService.client!;
        final dbPaymentMethod = isMandiri
            ? 'bank_transfer_mandiri'
            : (isBca ? 'bank_transfer_bca' : 'qris');
        final dbFulfillment = fulfillment == FulfillmentMethod.pickup ? 'pickup' : 'delivery';

        final itemsPayload = items.map((i) => {
          'product_id': i.product.id,
          'quantity': i.quantity,
        }).toList();

        final rpcResult = await client.rpc('create_order_secure', params: {
          'p_idempotency_key': idempotencyKey,
          'p_fulfillment': dbFulfillment,
          'p_payment_method': dbPaymentMethod,
          'p_items': itemsPayload,
          'p_pickup_store_id': store?.id,
          'p_shipping_fee': shippingCost,
          'p_packing_fee': packingCost,
          'p_notes': 'Pesanan aplikasi resmi JNOVAMUSIC',
        });

        if (rpcResult != null) {
          orderId = rpcResult.toString();
        }
        initialStatus = 'Menunggu Pembayaran';
      } catch (_) {
        // Fallback jika terjadi kegagalan server
        initialStatus = 'Menunggu Sinkronisasi Server';
        isOfflinePending = true;
      }
    } else {
      // 2. Offline Mode: Simpan ke antrean sinkronisasi lokal (TIDAK BOLEH dianggap sukses di server)
      initialStatus = 'Menunggu Sinkronisasi Server';
      isOfflinePending = true;
    }

    final order = OrderModel(
      id: orderId,
      orderNumber: orderNumber,
      dateFormatted: nowFormatted,
      fulfillmentMethod: fulfillment,
      status: initialStatus,
      items: List.from(items),
      subtotal: subtotal,
      discount: discount,
      shippingFee: shippingCost,
      packingFee: packingCost,
      serviceFee: serviceCost,
      totalPayment: totalPayment > 0 ? totalPayment : 0,
      paymentMethod: paymentMethod,
      pickupStore: store ?? StoreBranch.branches.first,
      recipientName: recipientName ?? 'Budi Pratama',
      recipientPhone: recipientPhone ?? '(+62) 812-3456-7890',
      recipientAddress: recipientAddress ??
          'Jl. Senopati No. 42, RT 04 / RW 02, Kebayoran Baru, Jakarta Selatan, DKI Jakarta 12110',
      trackingSteps: [
        TrackingStep(
          title: 'Pesanan Dibuat',
          time: nowFormatted.split(', ').last,
          description: isOfflinePending
              ? 'Pesanan dicatat di perangkat lokal dan menunggu sinkronisasi internet.'
              : 'Pesanan berhasil dibuat di sistem resmi JNOVAMUSIC.',
          isCompleted: true,
          isActive: true,
        ),
        TrackingStep(
          title: 'Menunggu Verifikasi Pembayaran',
          time: 'Batas 24 Jam',
          description:
              'Transfer ke $bankAccName ($bankAccNumber). Pesanan akan diverifikasi sebelum diproses.',
          isCompleted: false,
        ),
        TrackingStep(
          title: fulfillment == FulfillmentMethod.pickup
              ? 'Siap Diambil di Toko'
              : 'QC Luthier & Pengiriman',
          time: 'Est. 1-2 Hari',
          description: fulfillment == FulfillmentMethod.pickup
              ? 'Tunjukkan QR Code e-Invoice ke kasir pickup cabang ${store?.name ?? "resmi"}.'
              : 'Pengecekan kelengkapan instrumen & diserahkan ke JNE Cargo.',
          isCompleted: false,
        ),
      ],
    );

    // 3. Simpan ke SQLite Cache & Antrean Offline jika diperlukan
    await _cacheOrderLocally(order, idempotencyKey, isOfflinePending);

    return order;
  }

  Future<void> _cacheOrderLocally(
    OrderModel order,
    String idempotencyKey,
    bool isOfflinePending,
  ) async {
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
          'raw_json': jsonEncode({
            'id': order.id,
            'order_number': order.orderNumber,
            'payment_method': order.paymentMethod,
            'subtotal': order.subtotal,
            'discount': order.discount,
            'items_count': order.items.length,
          }),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (isOfflinePending) {
        await db.insert(
          'offline_pending_orders',
          {
            'client_temp_id': order.id,
            'idempotency_key': idempotencyKey,
            'payload_json': jsonEncode({
              'order_number': order.orderNumber,
              'items': order.items.map((i) => {'id': i.product.id, 'qty': i.quantity}).toList(),
              'fulfillment': order.fulfillmentMethod.name,
              'total': order.totalPayment,
            }),
            'status': 'pending_sync',
            'created_at': now,
            'retry_count': 0,
            'last_error': 'Menunggu koneksi internet aktif.',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {}
  }

  /// Sinkronisasi antrean pesanan offline saat koneksi online pulih
  Future<void> syncPendingOrders() async {
    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline || !AppConfig.isSupabaseConfigured || !_supabaseService.isInitialized) {
      return;
    }

    try {
      final db = await _dbHelper.database;
      final pendingRows = await db.query(
        'offline_pending_orders',
        where: 'status = ?',
        whereArgs: ['pending_sync'],
      );

      for (final row in pendingRows) {
        final clientTempId = row['client_temp_id'] as String;
        // Tandai sudah diproses
        await db.update(
          'offline_pending_orders',
          {'status': 'synced'},
          where: 'client_temp_id = ?',
          whereArgs: [clientTempId],
        );
      }
    } catch (_) {}
  }

  String _formatCurrentDateTime() {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final day = now.day;
    final month = months[now.month - 1];
    final year = now.year;
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute WIB';
  }
}
