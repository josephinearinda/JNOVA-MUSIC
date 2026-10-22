import 'package:flutter/foundation.dart';
import '../data/repositories/product_repository.dart';
import '../models/product.dart';

/// Layanan state management Favorit Produk JNOVAMUSIC dengan penyimpanan SQLite
class FavoriteService extends ChangeNotifier {
  FavoriteService._() {
    _loadFuture = _loadFavorites();
  }

  static final FavoriteService instance = FavoriteService._();
  final ProductRepository _repository = ProductRepository.instance;

  final List<Product> _items = [];
  final List<Product> _newestFirstItems = [];
  late final Future<void> _loadFuture;
  String _currentSort = 'Terbaru';
  bool _isLoaded = false;

  List<Product> get items => List.unmodifiable(_items);
  String get currentSort => _currentSort;
  bool get isLoaded => _isLoaded;

  Future<void> _loadFavorites() async {
    try {
      final products = await _repository.getFavoriteProducts();
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
          context: ErrorDescription('while loading persisted favorites'),
        ),
      );
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  bool isFavorite(String productId) {
    return _items.any((item) => item.id == productId);
  }

  Future<void> toggleFavorite(Product product) async {
    await _loadFuture;
    final shouldFavorite = !isFavorite(product.id);
    await _repository.setFavorite(product.id, isFavorite: shouldFavorite);
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
    await _loadFuture;
    _items.removeWhere((item) => item.id == productId);
    _newestFirstItems.removeWhere((item) => item.id == productId);
    await _repository.setFavorite(productId, isFavorite: false);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _loadFuture;
    _items.clear();
    _newestFirstItems.clear();
    await _repository.clearFavorites();
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
