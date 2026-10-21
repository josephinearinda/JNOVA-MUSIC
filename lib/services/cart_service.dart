import 'package:flutter/foundation.dart';
import '../data/repositories/cart_repository.dart';
import '../models/product.dart';
import 'membership_service.dart';

/// Layanan state management Keranjang Belanja JNOVAMUSIC dengan penyimpanan SQLite
class CartService extends ChangeNotifier {
  CartService._() {
    _membershipService.addListener(_handleMembershipChanged);
    _initializeDefaultItems();
    _loadFromDatabase();
  }

  static final CartService instance = CartService._();
  final CartRepository _repository = CartRepository.instance;
  final MembershipService _membershipService = MembershipService.instance;

  final List<CartItem> _items = [];
  bool _isLoaded = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _isLoaded;

  void _handleMembershipChanged() {
    notifyListeners();
  }

  // Data membership pengguna terhubung langsung dari sumber utama (MembershipService)
  String get userTier => _membershipService.userTier;
  String get tierName => _membershipService.tierName;
  int get currentPoints => _membershipService.currentPoints;
  int get targetPoints => _membershipService.targetPoints;
  int get discountPercentage => _membershipService.discountPercentage;
  double get discountRate => _membershipService.discountRate;
  String get nextTierName => _membershipService.nextTierName;

  Future<void> _loadFromDatabase() async {
    try {
      final dbItems = await _repository.getCartItems();
      if (dbItems.isNotEmpty) {
        _items.clear();
        _items.addAll(dbItems);
      } else {
        _initializeDefaultItems();
      }
    } catch (_) {
      _initializeDefaultItems();
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  void _initializeDefaultItems() {
    final products = Product.initialProducts;
    if (products.length >= 3 && _items.isEmpty) {
      _items.addAll([
        CartItem(product: products[0], quantity: 1, isSelected: true),
        CartItem(product: products[1], quantity: 1, isSelected: true),
        CartItem(product: products[2], quantity: 1, isSelected: true),
      ]);
    }
  }

  /// Mengembalikan isi keranjang ke kondisi awal
  Future<void> reset() async {
    _items.clear();
    _initializeDefaultItems();
    notifyListeners();
    try {
      await _repository.clearCart();
      for (final it in _items) {
        await _repository.addToCart(it.product.id, it.quantity);
      }
    } catch (_) {}
  }

  /// Menambah produk ke keranjang
  void addToCart(Product product, {int quantity = 1}) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity += quantity;
      _repository.updateQuantity(product.id, _items[index].quantity);
    } else {
      _items.insert(0, CartItem(product: product, quantity: quantity, isSelected: true));
      _repository.addToCart(product.id, quantity);
    }
    notifyListeners();
  }

  /// Toggle centang semua produk
  void toggleSelectAll(bool selectAll) {
    for (final item in _items) {
      item.isSelected = selectAll;
    }
    _repository.toggleSelectAll(selectAll);
    notifyListeners();
  }

  /// Toggle centang pada satu produk tertentu
  void toggleItemSelection(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _items[index].isSelected = !_items[index].isSelected;
      _repository.toggleSelection(productId);
      notifyListeners();
    }
  }

  /// Mengubah kuantitas item (+1 atau -1)
  void updateQuantity(String productId, int delta) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      final newQty = _items[index].quantity + delta;
      if (newQty > 0) {
        _items[index].quantity = newQty;
        _repository.updateQuantity(productId, newQty);
        notifyListeners();
      } else {
        removeItem(productId);
      }
    }
  }

  /// Menghapus 1 item dari keranjang
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _repository.removeItem(productId);
    notifyListeners();
  }

  /// Menghapus semua produk yang sedang dicentang
  void removeSelected() {
    _items.removeWhere((item) => item.isSelected);
    _repository.removeSelected();
    notifyListeners();
  }

  /// Mengosongkan seluruh keranjang
  void clearCart() {
    _items.clear();
    _repository.clearCart();
    notifyListeners();
  }

  /// Memeriksa apakah semua item yang ada telah dicentang
  bool get isAllSelected =>
      _items.isNotEmpty && _items.every((item) => item.isSelected);

  /// Jumlah item yang sedang dicentang
  int get selectedCount =>
      _items.where((item) => item.isSelected).length;

  /// Total harga kotor (sebelum diskon) dari item yang dicentang
  int get subtotal => _items
      .where((item) => item.isSelected)
      .fold(0, (sum, item) => sum + item.itemTotal);

  /// Potongan diskon membership (10% untuk Silver Member)
  int get discountAmount {
    if (subtotal <= 0) return 0;
    return (subtotal * discountRate).round();
  }

  /// Total akhir pembayaran yang harus dibayar
  int get totalPayment {
    final total = subtotal - discountAmount;
    return total > 0 ? total : 0;
  }
}
