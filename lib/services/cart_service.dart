import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/repositories/cart_repository.dart';
import '../models/product.dart';
import 'membership_service.dart';

/// Layanan state management Keranjang Belanja JNOVAMUSIC dengan isolasi per akun pengguna
class CartService extends ChangeNotifier {
  CartService._() {
    _membershipService.addListener(_handleMembershipChanged);
    _initCartForActiveUser();
  }

  static final CartService instance = CartService._();
  final CartRepository _repository = CartRepository.instance;
  final MembershipService _membershipService = MembershipService.instance;
  final SecureStorageService _storage = SecureStorageService.instance;

  final List<CartItem> _items = [];
  String _activeEmail = '';
  bool _isLoaded = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _isLoaded;
  String get activeEmail => _activeEmail;

  void _handleMembershipChanged() {
    notifyListeners();
  }

  // Data membership pengguna terhubung langsung dari sumber utama (MembershipService)
  bool get isMember => _membershipService.isMember;
  String get userTier => _membershipService.userTier;
  String get tierName => _membershipService.tierName;
  int get currentPoints => _membershipService.currentPoints;
  int get targetPoints => _membershipService.targetPoints;
  int get discountPercentage => _membershipService.discountPercentage;
  double get discountRate => _membershipService.discountRate;
  String get nextTierName => _membershipService.nextTierName;

  Future<void> _initCartForActiveUser() async {
    try {
      final email = await _storage.getUserEmail();
      if (email != null && email.isNotEmpty) {
        await loadCartForUser(email);
      } else {
        _isLoaded = true;
        notifyListeners();
      }
    } catch (_) {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Memuat keranjang khusus untuk pengguna aktif dari SQLite
  Future<void> loadCartForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    _activeEmail = cleanEmail;

    // Bersihkan memori seketika agar data akun lama tidak bocor
    _items.clear();

    if (cleanEmail.isEmpty) {
      _isLoaded = true;
      notifyListeners();
      return;
    }

    try {
      final dbItems = await _repository.getCartItemsForUser(cleanEmail);
      _items
        ..clear()
        ..addAll(dbItems);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'cart service',
          context: ErrorDescription('while loading persisted cart for user $cleanEmail'),
        ),
      );
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Mengosongkan memori keranjang saat logout / pergantian akun
  void resetCart() {
    _activeEmail = '';
    _items.clear();
    _isLoaded = true;
    notifyListeners();
  }

  Future<String> _ensureActiveEmail() async {
    if (_activeEmail.isNotEmpty) return _activeEmail;
    final email = await _storage.getUserEmail();
    _activeEmail = email?.toLowerCase().trim() ?? '';
    return _activeEmail;
  }

  /// Menambah produk ke keranjang untuk akun aktif
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final email = await _ensureActiveEmail();
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      _items[index].quantity += quantity;
      if (email.isNotEmpty) {
        unawaited(_repository.updateQuantityForUser(email, product.id, _items[index].quantity));
      }
    } else {
      _items.insert(0, CartItem(product: product, quantity: quantity, isSelected: true));
      if (email.isNotEmpty) {
        unawaited(_repository.addToCartForUser(email, product.id, quantity));
      }
    }
    notifyListeners();
  }

  /// Toggle centang semua produk
  void toggleSelectAll(bool selectAll) {
    for (final item in _items) {
      item.isSelected = selectAll;
    }
    if (_activeEmail.isNotEmpty) {
      _repository.toggleSelectAllForUser(_activeEmail, selectAll);
    }
    notifyListeners();
  }

  /// Toggle centang pada satu produk tertentu
  void toggleItemSelection(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _items[index].isSelected = !_items[index].isSelected;
      if (_activeEmail.isNotEmpty) {
        _repository.toggleSelectionForUser(_activeEmail, productId);
      }
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
        if (_activeEmail.isNotEmpty) {
          _repository.updateQuantityForUser(_activeEmail, productId, newQty);
        }
        notifyListeners();
      } else {
        removeItem(productId);
      }
    }
  }

  /// Menghapus 1 item dari keranjang
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    if (_activeEmail.isNotEmpty) {
      _repository.removeItemForUser(_activeEmail, productId);
    }
    notifyListeners();
  }

  /// Menghapus semua produk yang sedang dicentang
  void removeSelected() {
    _items.removeWhere((item) => item.isSelected);
    if (_activeEmail.isNotEmpty) {
      _repository.removeSelectedForUser(_activeEmail);
    }
    notifyListeners();
  }

  /// Mengosongkan seluruh keranjang untuk akun aktif
  void clearCart() {
    _items.clear();
    if (_activeEmail.isNotEmpty) {
      _repository.clearCartForUser(_activeEmail);
    }
    notifyListeners();
  }

  /// Reset atas permintaan eksplisit pengguna
  Future<void> reset() async {
    clearCart();
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

  /// Potongan diskon membership
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
