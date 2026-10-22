import 'package:sqflite/sqflite.dart';

import '../../models/product.dart';
import '../datasources/local/app_database.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  final AppDatabase _dbHelper = AppDatabase.instance;

  /// Mengambil katalog CSV dari cache SQLite yang disegarkan saat migrasi.
  Future<List<Product>> getProducts() async {
    final db = await _dbHelper.database;

    final localMaps = await db.query('cached_products');
    if (localMaps.isNotEmpty) {
      return localMaps.map((m) => Product.fromMap(m)).toList();
    }

    return Product.allCatalog;
  }

  /// Mencari produk berdasarkan kata kunci di SQLite
  Future<List<Product>> searchProducts(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return getProducts();

    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      'SELECT * FROM cached_products WHERE LOWER(name) LIKE ? OR LOWER(brand) LIKE ? OR LOWER(category) LIKE ?',
      ['%$clean%', '%$clean%', '%$clean%'],
    );

    if (results.isNotEmpty) {
      return results.map((m) => Product.fromMap(m)).toList();
    }

    // Fallback jika query lokal kosong
    return Product.allCatalog
        .where(
          (p) =>
              p.name.toLowerCase().contains(clean) ||
              p.brand.toLowerCase().contains(clean) ||
              p.category.toLowerCase().contains(clean),
        )
        .toList();
  }

  /// Memeriksa status favorit
  Future<bool> isFavorite(String productId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'local_favorites',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return res.isNotEmpty;
  }

  /// Toggle status favorit
  Future<bool> toggleFavorite(String productId) async {
    final db = await _dbHelper.database;
    final isFav = await isFavorite(productId);

    if (isFav) {
      await db.delete(
        'local_favorites',
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    } else {
      await db.insert('local_favorites', {
        'product_id': productId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    return !isFav;
  }
}
