import 'package:flutter/foundation.dart';

import '../core/storage/secure_storage_service.dart';
import '../data/repositories/order_repository.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/store_branch.dart';
import 'cart_service.dart';
import 'membership_service.dart';
import 'notification_background_sync_service.dart';
import 'notification_service.dart';
import 'product_stock_service.dart';

/// Layanan manajemen pesanan dan transaksi JNOVAMUSIC dengan alur Pickup & Bayar di Toko
class OrderService extends ChangeNotifier {
  OrderService._() {
    _loadInitialOrders();
  }

  static final OrderService instance = OrderService._();
  final OrderRepository _repository = OrderRepository.instance;
  final SecureStorageService _storage = SecureStorageService.instance;

  OrderModel? _currentOrder;
  final List<OrderModel> _orders = [];

  OrderModel? get currentOrder => _currentOrder;
  List<OrderModel> get orders => List.unmodifiable(_orders);

  Future<void> _loadInitialOrders() async {
    try {
      final email = await _storage.getUserEmail();
      if (email != null && email.isNotEmpty) {
        await loadOrdersForUser(email);
      }
    } catch (_) {}
  }

  /// Memuat riwayat pesanan khusus untuk pengguna aktif
  Future<void> loadOrdersForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) {
      _orders.clear();
      _currentOrder = null;
      notifyListeners();
      return;
    }
    final list = await _repository.getOrdersForUser(cleanEmail);
    _orders.clear();
    _orders.addAll(list);
    _currentOrder = _orders.isNotEmpty ? _orders.first : null;
    notifyListeners();
  }

  /// Membuat pesanan baru Pickup & Bayar di Toko
  Future<OrderModel> checkout({
    required List<CartItem> items,
    required FulfillmentMethod fulfillment,
    String paymentMethod = 'Bayar di Toko (Pickup & Pay)',
    StoreBranch? store,
    String? recipientName,
    String? recipientPhone,
    String? recipientAddress,
    String? userEmail,
    double? discountRate,
  }) async {
    final activeEmail = userEmail ?? await _storage.getUserEmail() ?? '';
    final effectiveDiscountRate =
        discountRate ?? CartService.instance.discountRate;

    final order = await _repository.checkout(
      items: items.isNotEmpty
          ? items
          : [
              CartItem(
                product: Product.allCatalog.first,
                quantity: 1,
                isSelected: true,
              ),
            ],
      fulfillment: fulfillment,
      paymentMethod: paymentMethod,
      store: store ?? StoreBranch.branches.first,
      discountRate: effectiveDiscountRate,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      recipientAddress: recipientAddress,
      userEmail: activeEmail,
    );

    _currentOrder = order;
    _orders.insert(0, order);

    // Potong sisa stok produk secara permanen dan reaktif
    await ProductStockService.instance.deductStock(order.items);

    // Hapus item yang dibeli dari keranjang lokal
    CartService.instance.removeSelected();

    await NotificationService.instance.showOrderUpdate(
      title: 'Pesanan berhasil dibuat',
      message: 'Pesanan ${order.orderNumber} berhasil dibuat.',
      eventKey: 'order:${order.id}:menunggu_pembayaran',
    );
    await NotificationBackgroundSyncService.syncNow();

    notifyListeners();
    return order;
  }

  /// Menyelesaikan pesanan setelah pelanggan mengambil & membayar di toko
  /// Dilindungi mekanisme idempotensi agar poin hanya ditambahkan 1 kali
  Future<bool> completeOrder(OrderModel order) async {
    // 1. Cek proteksi idempotensi: jangan berikan poin ganda
    if (order.isCompleted || order.pointsAwarded) {
      return false;
    }

    final completedOrder = order.copyWith(
      isCompleted: true,
      pointsAwarded: true,
      status: 'Pesanan Selesai',
    );

    // 2. Perbarui list lokal & currentOrder
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _orders[index] = completedOrder;
    }
    if (_currentOrder?.id == order.id) {
      _currentOrder = completedOrder;
    }

    // 3. Simpan perubahan status secara permanen
    await _repository.updateOrder(completedOrder);

    // 4. Hitung poin transaksi sesuai aturan resmi (1 poin per Rp 10.000 belanja)
    final pointsEarned = (order.totalPayment / 10000).floor();
    final firstItemTitle = order.items.isNotEmpty
        ? order.items.first.product.name
        : 'Alat Musik';

    await MembershipService.instance.addPurchasePoints(
      pointsEarned,
      orderNumber: order.orderNumber,
      orderTitle: firstItemTitle,
    );

    await NotificationService.instance.showOrderUpdate(
      title: 'Pesanan selesai',
      message: 'Pesanan ${order.orderNumber} telah selesai.',
      eventKey: 'order:${order.id}:${completedOrder.status}',
    );
    await NotificationBackgroundSyncService.syncNow();

    notifyListeners();
    return true;
  }

  void setCurrentOrder(OrderModel order) {
    _currentOrder = order;
    notifyListeners();
  }

  /// Reset pesanan saat logout atau ganti akun
  void resetOrders() {
    _orders.clear();
    _currentOrder = null;
    notifyListeners();
  }
}
