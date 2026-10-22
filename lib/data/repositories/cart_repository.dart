import 'package:sqflite/sqflite.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/product.dart';
import '../../services/product_stock_service.dart';
import '../datasources/local/app_database.dart';

class CartRepository {
  CartRepository._();
  static final CartRepository instance = CartRepository._();

  final AppDatabase _dbHelper = AppDatabase.instance;

  // ==============================================================================
  // METODE KERANJANG TERISOLASI PER AKUN PENGGUNA (user_cart)
  // ==============================================================================

  /// Mengambil semua item keranjang belanja khusus untuk akun pengguna tertentu
  Future<List<CartItem>> getCartItemsForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return [];

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
      FROM user_cart c
      LEFT JOIN cached_products p ON c.product_id = p.id
      WHERE LOWER(c.user_email) = ?
      ORDER BY c.updated_at DESC
    ''', [cleanEmail]);

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

      // Pastikan stok terupdate secara reaktif
      prod = ProductStockService.instance.applyStock(prod);

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

  /// Menambah atau mengupdate kuantitas item di keranjang pengguna
  Future<void> addToCartForUser(String email, String productId, int quantity) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    final db = await _dbHelper.database;
    final existing = await db.query(
      'user_cart',
      where: 'LOWER(user_email) = ? AND product_id = ?',
      whereArgs: [cleanEmail, productId],
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    if (existing.isNotEmpty) {
      final currentQty = (existing.first['quantity'] as num).toInt();
      await db.update(
        'user_cart',
        {
          'quantity': currentQty + quantity,
          'updated_at': now,
        },
        where: 'LOWER(user_email) = ? AND product_id = ?',
        whereArgs: [cleanEmail, productId],
      );
    } else {
      await db.insert(
        'user_cart',
        {
          'user_email': cleanEmail,
          'product_id': productId,
          'quantity': quantity,
          'is_selected': 1,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Memperbarui kuantitas produk tertentu untuk pengguna
  Future<void> updateQuantityForUser(String email, String productId, int quantity) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    final db = await _dbHelper.database;
    if (quantity <= 0) {
      await removeItemForUser(cleanEmail, productId);
    } else {
      await db.update(
        'user_cart',
        {
          'quantity': quantity,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'LOWER(user_email) = ? AND product_id = ?',
        whereArgs: [cleanEmail, productId],
      );
    }
  }

  /// Toggle centang pada satu produk untuk pengguna
  Future<void> toggleSelectionForUser(String email, String productId) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    final db = await _dbHelper.database;
    final existing = await db.query(
      'user_cart',
      where: 'LOWER(user_email) = ? AND product_id = ?',
      whereArgs: [cleanEmail, productId],
    );

    if (existing.isNotEmpty) {
      final current = existing.first['is_selected'] == 1;
      await db.update(
        'user_cart',
        {'is_selected': current ? 0 : 1},
        where: 'LOWER(user_email) = ? AND product_id = ?',
        whereArgs: [cleanEmail, productId],
      );
    }
  }

  /// Toggle centang semua produk untuk pengguna
  Future<void> toggleSelectAllForUser(String email, bool selectAll) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    final db = await _dbHelper.database;
    await db.update(
      'user_cart',
      {'is_selected': selectAll ? 1 : 0},
      where: 'LOWER(user_email) = ?',
      whereArgs: [cleanEmail],
    );
  }

  /// Hapus produk dari keranjang pengguna
  Future<void> removeItemForUser(String email, String productId) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    final db = await _dbHelper.database;
    await db.delete(
      'user_cart',
      where: 'LOWER(user_email) = ? AND product_id = ?',
      whereArgs: [cleanEmail, productId],
    );
  }

  /// Hapus produk yang sedang dicentang dari keranjang pengguna
  Future<void> removeSelectedForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    final db = await _dbHelper.database;
    await db.delete(
      'user_cart',
      where: 'LOWER(user_email) = ? AND is_selected = ?',
      whereArgs: [cleanEmail, 1],
    );
  }

  /// Mengosongkan keranjang pengguna
  Future<void> clearCartForUser(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    final db = await _dbHelper.database;
    await db.delete(
      'user_cart',
      where: 'LOWER(user_email) = ?',
      whereArgs: [cleanEmail],
    );
  }

  // ==============================================================================
  // METODE LEGACY (Mendelegasikan ke akun pengguna aktif)
  // ==============================================================================

  Future<List<CartItem>> getCartItems() async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      return getCartItemsForUser(email);
    }
    return [];
  }

  Future<void> addToCart(String productId, int quantity) async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      await addToCartForUser(email, productId, quantity);
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      await updateQuantityForUser(email, productId, quantity);
    }
  }

  Future<void> toggleSelection(String productId) async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      await toggleSelectionForUser(email, productId);
    }
  }

  Future<void> toggleSelectAll(bool selectAll) async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      await toggleSelectAllForUser(email, selectAll);
    }
  }

  Future<void> removeItem(String productId) async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      await removeItemForUser(email, productId);
    }
  }

  Future<void> removeSelected() async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      await removeSelectedForUser(email);
    }
  }

  Future<void> clearCart() async {
    final email = await SecureStorageService.instance.getUserEmail();
    if (email != null && email.isNotEmpty) {
      await clearCartForUser(email);
    }
  }
}

