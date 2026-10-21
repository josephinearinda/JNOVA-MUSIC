import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../core/config/app_config.dart';
import '../../core/network/network_info.dart';
import '../../models/product.dart';
import '../datasources/local/app_database.dart';
import '../datasources/remote/supabase_client_service.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  final AppDatabase _dbHelper = AppDatabase.instance;
  final SupabaseClientService _supabaseService = SupabaseClientService.instance;

  /// Mengambil semua produk katalog dengan strategi Cache-First (SQLite -> Supabase Sync)
  Future<List<Product>> getProducts() async {
    final db = await _dbHelper.database;

    // 1. Ambil dari SQLite Cache terlebih dahulu (respons instan)
    final localMaps = await db.query('cached_products');
    List<Product> products = [];

    if (localMaps.isNotEmpty) {
      products = localMaps.map((m) => Product.fromMap(m)).toList();
    } else {
      // Fallback jika database lokal belum ter-seed
      products = Product.allCatalog;
    }

    // 2. Sinkronkan dengan Supabase di background jika online
    _syncWithSupabaseInBackground();

    return products;
  }

  /// Sinkronisasi dengan Supabase jika online dan terkonfigurasi
  Future<void> _syncWithSupabaseInBackground() async {
    if (!AppConfig.isSupabaseConfigured || !_supabaseService.isInitialized) return;

    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline) return;

    try {
      final client = _supabaseService.client;
      if (client == null) return;

      final List<dynamic> response = await client
          .from('products')
          .select()
          .order('name');

      if (response.isNotEmpty) {
        final db = await _dbHelper.database;
        final batch = db.batch();
        final now = DateTime.now().millisecondsSinceEpoch;

        for (final item in response) {
          final map = Map<String, dynamic>.from(item);
          batch.insert(
            'cached_products',
            {
              'id': map['id']?.toString() ?? '',
              'brand': map['brand']?.toString() ?? '',
              'name': map['name']?.toString() ?? '',
              'price': (map['price'] as num?)?.toInt() ?? 0,
              'category': map['category']?.toString() ?? '',
              'variant': map['variant']?.toString() ?? '',
              'code': map['code']?.toString() ?? '',
              'stock': (map['stock'] as num?)?.toInt() ?? 0,
              'rating': (map['rating'] as num?)?.toDouble() ?? 5.0,
              'review_count': (map['review_count'] as num?)?.toInt() ?? 0,
              'is_original': (map['is_original'] == true || map['is_original'] == 1) ? 1 : 0,
              'is_best_seller': (map['is_best_seller'] == true || map['is_best_seller'] == 1) ? 1 : 0,
              'image_url': map['image_url']?.toString() ?? 'assets/images/fav_fender.png',
              'description': map['description']?.toString() ?? '',
              'specs_json': jsonEncode(map['specs'] ?? {}),
              'color_variants_json': jsonEncode(map['color_variants'] ?? []),
              'cached_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    } catch (_) {
      // Abaikan error background sync, tetap gunakan cache lokal
    }
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
        .where((p) =>
            p.name.toLowerCase().contains(clean) ||
            p.brand.toLowerCase().contains(clean) ||
            p.category.toLowerCase().contains(clean))
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
      await db.insert(
        'local_favorites',
        {
          'product_id': productId,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    return !isFav;
  }
}
