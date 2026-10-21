import 'package:sqflite/sqflite.dart';
import '../../models/product.dart';
import '../datasources/local/app_database.dart';

class CartRepository {
  CartRepository._();
  static final CartRepository instance = CartRepository._();

  final AppDatabase _dbHelper = AppDatabase.instance;

  /// Mengambil semua item keranjang belanja dari SQLite
  Future<List<CartItem>> getCartItems() async {
    final db = await _dbHelper.database;

    final results = await db.rawQuery('''
      SELECT 
        c.product_id, 
        c.quantity, 
        c.is_selected,
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
      FROM local_cart c
      LEFT JOIN cached_products p ON c.product_id = p.id
    ''');

    final List<CartItem> items = [];
    for (final row in results) {
      Product prod;
      if (row['id'] != null) {
        prod = Product.fromMap(row);
      } else {
        // Fallback jika belum tersinkron di tabel produk
        prod = Product.allCatalog.firstWhere(
          (p) => p.id == row['product_id'],
          orElse: () => Product.allCatalog.first,
        );
      }

      items.add(
        CartItem(
          product: prod,
          quantity: (row['quantity'] as num?)?.toInt() ?? 1,
          isSelected: row['is_selected'] == 1,
        ),
      );
    }

    return items;
  }

  /// Menambah atau mengupdate jumlah item di keranjang
  Future<void> addToCart(String productId, int quantity) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      'local_cart',
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    if (existing.isNotEmpty) {
      final currentQty = (existing.first['quantity'] as num).toInt();
      await db.update(
        'local_cart',
        {
          'quantity': currentQty + quantity,
          'updated_at': now,
        },
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    } else {
      await db.insert(
        'local_cart',
        {
          'product_id': productId,
          'quantity': quantity,
          'is_selected': 1,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Memperbarui kuantitas produk tertentu
  Future<void> updateQuantity(String productId, int quantity) async {
    final db = await _dbHelper.database;
    if (quantity <= 0) {
      await removeItem(productId);
    } else {
      await db.update(
        'local_cart',
        {
          'quantity': quantity,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    }
  }

  /// Toggle centang pada satu produk
  Future<void> toggleSelection(String productId) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      'local_cart',
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    if (existing.isNotEmpty) {
      final current = existing.first['is_selected'] == 1;
      await db.update(
        'local_cart',
        {'is_selected': current ? 0 : 1},
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    }
  }

  /// Toggle centang semua produk
  Future<void> toggleSelectAll(bool selectAll) async {
    final db = await _dbHelper.database;
    await db.update('local_cart', {'is_selected': selectAll ? 1 : 0});
  }

  /// Hapus produk dari keranjang
  Future<void> removeItem(String productId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'local_cart',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  /// Hapus produk yang sedang dicentang
  Future<void> removeSelected() async {
    final db = await _dbHelper.database;
    await db.delete(
      'local_cart',
      where: 'is_selected = ?',
      whereArgs: [1],
    );
  }

  /// Mengosongkan keranjang
  Future<void> clearCart() async {
    final db = await _dbHelper.database;
    await db.delete('local_cart');
  }
}
