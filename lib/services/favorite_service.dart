import 'package:flutter/foundation.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/repositories/product_repository.dart';
import '../models/product.dart';

/// Layanan state management Favorit Produk JNOVAMUSIC
/// Terisolasi penuh per akun pengguna (tidak tercampur antar akun yang berbeda)
class FavoriteService extends ChangeNotifier {
  FavoriteService._() {
    _initUserFavorites();
  }

  static final FavoriteService instance = FavoriteService._();
  final ProductRepository _repository = ProductRepository.instance;
  final SecureStorageService _storage = SecureStorageService.instance;

  final List<Product> _items = [];
  final List<Product> _newestFirstItems = [];
  String _activeEmail = '';
  String _currentSort = 'Terbaru';
  bool _isLoaded = false;

  List<Product> get items => List.unmodifiable(_items);
  String get currentSort => _currentSort;
  bool get isLoaded => _isLoaded;
  String get activeEmail => _activeEmail;

  Future<void> _initUserFavorites() async {
    try {
      final email = await _storage.getUserEmail();
      if (email != null && email.isNotEmpty) {
        await loadFavoritesForUser(email);
      } else {
        _isLoaded = true;
        notifyListeners();
      }
    } catch (_) {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Memuat daftar favorit khusus untuk pengguna aktif
  Future<void> loadFavoritesForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    _activeEmail = cleanEmail;

    // Bersihkan memori seketika agar akun berikutnya tidak menampilkan favorit akun sebelumnya
    _items.clear();
    _newestFirstItems.clear();

    if (cleanEmail.isEmpty) {
      _isLoaded = true;
      notifyListeners();
      return;
    }

    try {
      final products = await _repository.getFavoriteProductsForUser(cleanEmail);
      _newestFirstItems
        ..clear()
        ..addAll(products);
      _applySort();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'favorite service',
          context: ErrorDescription('while loading persisted favorites for user $cleanEmail'),
        ),
      );
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Mengosongkan daftar favorit saat logout agar tidak tertaut ke akun berikutnya
  void resetFavorites() {
    _activeEmail = '';
    _items.clear();
    _newestFirstItems.clear();
    _isLoaded = true;
    notifyListeners();
  }

  bool isFavorite(String productId) {
    return _items.any((item) => item.id == productId);
  }

  Future<String> _ensureActiveEmail() async {
    if (_activeEmail.isNotEmpty) return _activeEmail;
    final email = await _storage.getUserEmail();
    _activeEmail = email?.toLowerCase().trim() ?? '';
    return _activeEmail;
  }

  Future<void> toggleFavorite(Product product) async {
    final email = await _ensureActiveEmail();
    final shouldFavorite = !isFavorite(product.id);

    if (email.isNotEmpty) {
      await _repository.setFavoriteForUser(email, product.id, isFavorite: shouldFavorite);
    }

    if (shouldFavorite) {
      _items.insert(0, product);
      _newestFirstItems.insert(0, product);
    } else {
      _items.removeWhere((item) => item.id == product.id);
      _newestFirstItems.removeWhere((item) => item.id == product.id);
    }
    _applySort();
    notifyListeners();
  }

  Future<void> removeFavorite(String productId) async {
    final email = await _ensureActiveEmail();
    _items.removeWhere((item) => item.id == productId);
    _newestFirstItems.removeWhere((item) => item.id == productId);

    if (email.isNotEmpty) {
      await _repository.setFavoriteForUser(email, productId, isFavorite: false);
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    final email = await _ensureActiveEmail();
    _items.clear();
    _newestFirstItems.clear();

    if (email.isNotEmpty) {
      await _repository.clearFavoritesForUser(email);
    }
    notifyListeners();
  }

  void setSort(String sort) {
    _currentSort = sort;
    _applySort();
    notifyListeners();
  }

  void _applySort() {
    _items
      ..clear()
      ..addAll(_newestFirstItems);
    switch (_currentSort) {
      case 'Harga Terendah':
        _items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Harga Tertinggi':
        _items.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating Tertinggi':
        _items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Terbaru':
      default:
        break;
    }
  }
}
