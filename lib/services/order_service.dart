import 'package:flutter/foundation.dart';
import '../data/repositories/order_repository.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/store_branch.dart';
import 'cart_service.dart';

/// Layanan manajemen pesanan dan transaksi JNOVAMUSIC dengan integrasi Server & SQLite
class OrderService extends ChangeNotifier {
  OrderService._() {
    _initializeDefaultOrder();
  }

  static final OrderService instance = OrderService._();
  final OrderRepository _repository = OrderRepository.instance;

  OrderModel? _currentOrder;
  final List<OrderModel> _orders = [];

  OrderModel? get currentOrder => _currentOrder;
  List<OrderModel> get orders => List.unmodifiable(_orders);

  void _initializeDefaultOrder() {
    final fender = Product.allCatalog.first;
    final item = CartItem(product: fender, quantity: 1, isSelected: true);

    _currentOrder = OrderModel.createFromCart(
      cartItems: [item],
      fulfillment: FulfillmentMethod.pickup,
      paymentMethod: 'Transfer Bank BCA (Otomatis / Manual)',
      store: StoreBranch.branches.first,
    );
    _orders.add(_currentOrder!);
  }

  /// Membuat pesanan baru dengan validasi server-authoritative & proteksi idempotensi
  Future<OrderModel> checkout({
    required List<CartItem> items,
    required FulfillmentMethod fulfillment,
    required String paymentMethod,
    StoreBranch? store,
    int shippingCost = 0,
    int packingCost = 0,
    String? recipientName,
    String? recipientPhone,
    String? recipientAddress,
  }) async {
    final order = await _repository.checkout(
      items: items.isNotEmpty
          ? items
          : [CartItem(product: Product.allCatalog.first, quantity: 1, isSelected: true)],
      fulfillment: fulfillment,
      paymentMethod: paymentMethod,
      store: store ?? StoreBranch.branches.first,
      shippingCost: shippingCost,
      packingCost: packingCost,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      recipientAddress: recipientAddress,
    );

    _currentOrder = order;
    _orders.insert(0, order);

    // Hapus item yang dibeli dari keranjang lokal
    CartService.instance.removeSelected();

    notifyListeners();
    return order;
  }

  void setCurrentOrder(OrderModel order) {
    _currentOrder = order;
    notifyListeners();
  }
}
