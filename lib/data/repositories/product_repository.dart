import '../../core/config/app_config.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/product.dart';
import '../../services/product_stock_service.dart';
import '../datasources/local/app_database.dart';
import '../datasources/remote/supabase_client_service.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  final AppDatabase _dbHelper = AppDatabase.instance;
  final SupabaseClientService _supabaseService = SupabaseClientService.instance;

  /// Mengambil katalog CSV dari cache SQLite yang disegarkan saat migrasi.
  Future<List<Product>> getProducts() async {
    final db = await _dbHelper.database;

    final localMaps = await db.query('cached_products');
    if (localMaps.isNotEmpty) {
      return localMaps
          .map((m) => ProductStockService.instance.applyStock(Product.fromMap(m)))
          .toList();
    }

    return Product.allCatalog
        .map((p) => ProductStockService.instance.applyStock(p))
        .toList();
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
      return results
          .map((m) => ProductStockService.instance.applyStock(Product.fromMap(m)))
          .toList();
    }

    // Fallback jika query lokal kosong
    return Product.allCatalog
        .where(
          (p) =>
              p.name.toLowerCase().contains(clean) ||
              p.brand.toLowerCase().contains(clean) ||
              p.category.toLowerCase().contains(clean),
        )
        .map((p) => ProductStockService.instance.applyStock(p))
        .toList();
  }

  /// Memeriksa status favorit pengguna aktif
  Future<bool> isFavorite(String productId) async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      return isFavoriteForUser(email, productId);
    }
    return false;
  }

  /// Mengambil daftar produk favorit pengguna aktif
  Future<List<Product>> getFavoriteProducts() async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      return getFavoriteProductsForUser(email);
    }
    return [];
  }

  /// Ambil daftar produk favorit khusus per akun pengguna
  Future<List<Product>> getFavoriteProductsForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return [];

    final db = await _dbHelper.database;

    // 1. Sinkronisasi dari Supabase jika user aktif terhubung
    if (AppConfig.isSupabaseConfigured && _supabaseService.isInitialized) {
      final client = _supabaseService.client;
      final currentUser = client?.auth.currentUser;
      if (currentUser != null &&
          (currentUser.email?.toLowerCase().trim() == cleanEmail || cleanEmail.isNotEmpty)) {
        try {
          final remoteFavs = await client!
              .from('user_favorites')
              .select('product_id, created_at')
              .eq('user_id', currentUser.id);

          if (remoteFavs.isNotEmpty) {
            for (final f in remoteFavs) {
              final prodId = f['product_id']?.toString();
              if (prodId != null && prodId.isNotEmpty) {
                final createdAt = DateTime.tryParse(f['created_at']?.toString() ?? '')
                        ?.millisecondsSinceEpoch ??
                    DateTime.now().millisecondsSinceEpoch;
                await db.rawInsert('''
                  INSERT OR IGNORE INTO user_favorites (user_email, product_id, created_at)
                  VALUES (?, ?, ?)
                ''', [cleanEmail, prodId, createdAt]);
              }
            }
          }
        } catch (_) {
          // Offline / Supabase schema belum dibuat, fallback penuh ke SQLite lokal
        }
      }
    }

    // 2. Query SQLite user_favorites dengan LEFT JOIN dan fallback katalog lengkap
    final rows = await db.rawQuery('''
      SELECT 
        f.product_id,
        p.id, 
        p.brand, 
        p.name, 
        p.price, 
        p.category, 
        p.variant, 
        p.code, 
        p.stock, 
        p.rating, 
        p.review_count, 
        p.is_original, 
        p.is_best_seller, 
        p.image_url, 
        p.description
      FROM user_favorites f
      LEFT JOIN cached_products p ON p.id = f.product_id
      WHERE LOWER(f.user_email) = ?
      ORDER BY f.created_at DESC
    ''', [cleanEmail]);

    final List<Product> list = [];
    for (final row in rows) {
      final prodId = row['product_id']?.toString() ?? '';
      Product prod;
      if (row['id'] != null) {
        prod = Product.fromMap(row);
      } else {
        prod = Product.allCatalog.firstWhere(
          (p) => p.id == prodId,
          orElse: () => Product.allCatalog.first,
        );
      }
      list.add(ProductStockService.instance.applyStock(prod));
    }

    return list;
  }

  Future<void> setFavoriteForUser(
    String email,
    String productId, {
    required bool isFavorite,
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    final db = await _dbHelper.database;
    if (isFavorite) {
      await db.rawInsert('''
        INSERT OR REPLACE INTO user_favorites (user_email, product_id, created_at)
        VALUES (?, ?, ?)
      ''', [cleanEmail, productId, DateTime.now().millisecondsSinceEpoch]);
    } else {
      await db.delete(
        'user_favorites',
        where: 'LOWER(user_email) = ? AND product_id = ?',
        whereArgs: [cleanEmail, productId],
      );
    }

    // Sinkronkan ke Supabase jika aktif
    if (AppConfig.isSupabaseConfigured && _supabaseService.isInitialized) {
      final client = _supabaseService.client;
      final currentUser = client?.auth.currentUser;
      if (currentUser != null) {
        try {
          if (isFavorite) {
            await client!.from('user_favorites').upsert({
              'user_id': currentUser.id,
              'product_id': productId,
            });
          } else {
            await client!
                .from('user_favorites')
                .delete()
                .eq('user_id', currentUser.id)
                .eq('product_id', productId);
          }
        } catch (_) {}
      }
    }
  }

  Future<bool> isFavoriteForUser(String email, String productId) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return false;

    final db = await _dbHelper.database;
    final res = await db.query(
      'user_favorites',
      where: 'LOWER(user_email) = ? AND product_id = ?',
      whereArgs: [cleanEmail, productId],
    );
    return res.isNotEmpty;
  }

  Future<void> clearFavoritesForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    final db = await _dbHelper.database;
    await db.delete(
      'user_favorites',
      where: 'LOWER(user_email) = ?',
      whereArgs: [cleanEmail],
    );

    if (AppConfig.isSupabaseConfigured && _supabaseService.isInitialized) {
      final client = _supabaseService.client;
      final currentUser = client?.auth.currentUser;
      if (currentUser != null) {
        try {
          await client!.from('user_favorites').delete().eq('user_id', currentUser.id);
        } catch (_) {}
      }
    }
  }

  Future<void> setFavorite(String productId, {required bool isFavorite}) async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      await setFavoriteForUser(email, productId, isFavorite: isFavorite);
    }
  }

  Future<void> clearFavorites() async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      await clearFavoritesForUser(email);
    }
  }

  /// Toggle status favorit untuk pengguna aktif
  Future<bool> toggleFavorite(String productId) async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      final isFav = await isFavoriteForUser(email, productId);
      await setFavoriteForUser(email, productId, isFavorite: !isFav);
      return !isFav;
    }
    return false;
  }
}
