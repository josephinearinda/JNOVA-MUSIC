import 'package:flutter/foundation.dart';
import '../data/repositories/product_repository.dart';
import '../models/product.dart';

/// Layanan state management Favorit Produk JNOVAMUSIC dengan penyimpanan SQLite
class FavoriteService extends ChangeNotifier {
  FavoriteService._() {
    _initializeDefaultItems();
  }

  static final FavoriteService instance = FavoriteService._();
  final ProductRepository _repository = ProductRepository.instance;

  final List<Product> _items = [];
  String _currentSort = 'Terbaru';

  List<Product> get items => List.unmodifiable(_items);
  String get currentSort => _currentSort;

  void _initializeDefaultItems() {
    _items.addAll(Product.initialProducts);
  }

  bool isFavorite(String productId) {
    return _items.any((item) => item.id == productId);
  }

  void toggleFavorite(Product product) {
    if (isFavorite(product.id)) {
      _items.removeWhere((item) => item.id == product.id);
    } else {
      _items.insert(0, product);
    }
    _repository.toggleFavorite(product.id);
    notifyListeners();
  }

  void removeFavorite(String productId) {
    _items.removeWhere((item) => item.id == productId);
    _repository.toggleFavorite(productId);
    notifyListeners();
  }

  void clearAll() {
    for (final it in _items) {
      _repository.toggleFavorite(it.id);
    }
    _items.clear();
    notifyListeners();
  }

  void setSort(String sort) {
    _currentSort = sort;
    switch (sort) {
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
        _items.clear();
        _initializeDefaultItems();
        break;
    }
    notifyListeners();
  }
}
