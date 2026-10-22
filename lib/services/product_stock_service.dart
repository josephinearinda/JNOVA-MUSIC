import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../data/datasources/local/app_database.dart';
import '../models/order_model.dart';
import '../models/product.dart';

/// Layanan manajemen stok produk terpusat dan reaktif JNOVAMUSIC
class ProductStockService extends ChangeNotifier {
  ProductStockService._() {
    _initStock();
  }

  static final ProductStockService instance = ProductStockService._();
  final AppDatabase _dbHelper = AppDatabase.instance;

  final Map<String, int> _stockMap = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> _initStock() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _isInitialized = true;
      return;
    }
    try {
      final db = await _dbHelper.database;

      // 1. Ambil stok awal dari cached_products
      final productRows = await db.query(
        'cached_products',
        columns: ['id', 'stock'],
      );

      for (final row in productRows) {
        final id = row['id']?.toString() ?? '';
        final stock = (row['stock'] as num?)?.toInt() ?? 5;
        if (id.isNotEmpty) {
          _stockMap[id] = stock;
        }
      }

      // 2. Hitung total produk yang sudah pernah di-checkout dari cached_orders
      // Memastikan order yang sebelumnya pernah dibuat langsung memotong stok!
      final orderRows = await db.query('cached_orders', columns: ['raw_json']);
      final Map<String, int> orderedQuantities = {};

      for (final row in orderRows) {
        final raw = row['raw_json'] as String?;
        if (raw != null && raw.isNotEmpty) {
          try {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            final order = OrderModel.fromMap(map);
            for (final item in order.items) {
              final pid = item.product.id;
              orderedQuantities[pid] = (orderedQuantities[pid] ?? 0) + item.quantity;
            }
          } catch (_) {}
        }
      }

      // 3. Sesuaikan stok berdasarkan total pesanan yang sudah tercatat
      final batch = db.batch();
      var hasChanges = false;

      for (final entry in orderedQuantities.entries) {
        final pid = entry.key;
        final orderedQty = entry.value;
        const baseStock = 5;
        final effectiveStock = (baseStock - orderedQty).clamp(0, baseStock);

        _stockMap[pid] = effectiveStock;
        batch.update(
          'cached_products',
          {'stock': effectiveStock},
          where: 'id = ?',
          whereArgs: [pid],
        );
        hasChanges = true;
      }

      if (hasChanges) {
        await batch.commit(noResult: true);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ProductStockService: $e');
    }
  }

  /// Mengambil sisa stok produk aktif
  int getStock(String productId, {int defaultStock = 5}) {
    return _stockMap[productId] ?? defaultStock;
  }

  /// Memeriksa apakah stok produk telah habis
  bool isOutOfStock(String productId) {
    return getStock(productId) <= 0;
  }

  /// Menerapkan sisa stok terkini ke model Product
  Product applyStock(Product product) {
    final current = getStock(product.id, defaultStock: product.stock);
    return product.copyWith(stock: current);
  }

  /// Mengurangi stok saat checkout berhasil dibuat
  Future<void> deductStock(List<CartItem> items) async {
    for (final item in items) {
      final pid = item.product.id;
      final current = getStock(pid, defaultStock: item.product.stock);
      final newStock = (current - item.quantity).clamp(0, 9999);
      _stockMap[pid] = newStock;
    }
    notifyListeners();

    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final item in items) {
        final pid = item.product.id;
        final newStock = _stockMap[pid] ?? 0;

        batch.update(
          'cached_products',
          {'stock': newStock},
          where: 'id = ?',
          whereArgs: [pid],
        );
      }

      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error deducting stock: $e');
    }
  }

  /// Mengembalikan stok bila diperlukan
  Future<void> restoreStock(List<CartItem> items) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final item in items) {
        final pid = item.product.id;
        final current = getStock(pid, defaultStock: item.product.stock);
        final newStock = (current + item.quantity).clamp(0, 9999);
        _stockMap[pid] = newStock;

        batch.update(
          'cached_products',
          {'stock': newStock},
          where: 'id = ?',
          whereArgs: [pid],
        );
      }

      await batch.commit(noResult: true);
      notifyListeners();
    } catch (_) {}
  }
}
