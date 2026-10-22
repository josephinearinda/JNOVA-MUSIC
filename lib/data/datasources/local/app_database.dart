import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../models/product.dart';

/// Database Helper SQLite untuk JNOVAMUSIC
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'jnova_music.db';
  static const int _dbVersion = 5;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _replaceCatalogWithCsvProducts(db);
    }
    if (oldVersion < 3) {
      await _createNotificationTables(db);
    }
    if (oldVersion < 4) {
      await _createPointHistoryTable(db);
    }
    if (oldVersion < 5) {
      await _removeUntouchedDefaultSelections(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Cache Katalog Produk
    await db.execute('''
      CREATE TABLE cached_products (
        id TEXT PRIMARY KEY,
        brand TEXT NOT NULL,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        category TEXT NOT NULL,
        variant TEXT,
        code TEXT,
        stock INTEGER NOT NULL,
        rating REAL DEFAULT 5.0,
        review_count INTEGER DEFAULT 0,
        is_original INTEGER DEFAULT 1,
        is_best_seller INTEGER DEFAULT 0,
        image_url TEXT NOT NULL,
        description TEXT NOT NULL,
        specs_json TEXT,
        color_variants_json TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');

    // 2. Keranjang Belanja Lokal
    await db.execute('''
      CREATE TABLE local_cart (
        product_id TEXT PRIMARY KEY,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        is_selected INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 3. Favorit Lokal
    await db.execute('''
      CREATE TABLE local_favorites (
        product_id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL
      )
    ''');

    // 4. Antrean Pesanan Offline (Pending Sync)
    await db.execute('''
      CREATE TABLE offline_pending_orders (
        client_temp_id TEXT PRIMARY KEY,
        idempotency_key TEXT UNIQUE NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT DEFAULT 'pending_sync',
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');

    // 5. Cache Riwayat Poin
    await db.execute('''
      CREATE TABLE cached_point_history (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        date_formatted TEXT NOT NULL,
        category TEXT NOT NULL,
        points INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        order_id TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');

    // 6. Cache Riwayat Pesanan
    await db.execute('''
      CREATE TABLE cached_orders (
        id TEXT PRIMARY KEY,
        order_number TEXT NOT NULL,
        date_formatted TEXT NOT NULL,
        fulfillment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        total_payment INTEGER NOT NULL,
        raw_json TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    await _createNotificationTables(db);
    await _createPointHistoryTable(db);

    // 7. Riwayat Obrolan AI Gemini Lokal
    await db.execute('''
      CREATE TABLE local_ai_chat_messages (
        id TEXT PRIMARY KEY,
        is_user INTEGER NOT NULL,
        text TEXT NOT NULL,
        time_formatted TEXT NOT NULL,
        recommended_product_id TEXT,
        badge TEXT,
        points_label TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Seed data katalog awal ke SQLite
    await _seedInitialProducts(db);
  }

  Future<void> _createNotificationTables(Database db) async {
    await db.execute('''
      CREATE TABLE notification_poll_state (
        user_id TEXT PRIMARY KEY,
        snapshot_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE notification_delivered_events (
        event_key TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createPointHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE user_point_history (
        user_email TEXT NOT NULL,
        id TEXT NOT NULL,
        title TEXT NOT NULL,
        date_formatted TEXT NOT NULL,
        category TEXT NOT NULL,
        points INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        order_id TEXT,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (user_email, id)
      )
    ''');
    await db.execute('''
      CREATE INDEX user_point_history_created_at
      ON user_point_history (user_email, created_at)
    ''');
  }

  Future<List<Map<String, Object?>>> getRecentPointHistory(
    String userEmail, {
    required int cutoff,
  }) async {
    final db = await database;
    final cleanEmail = userEmail.toLowerCase().trim();
    await db.delete(
      'user_point_history',
      where: 'created_at < ?',
      whereArgs: [cutoff],
    );
    return db.query(
      'user_point_history',
      where: 'user_email = ? AND created_at >= ?',
      whereArgs: [cleanEmail, cutoff],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> savePointHistory(
    String userEmail,
    Map<String, Object?> transaction,
  ) async {
    final cleanEmail = userEmail.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    final db = await database;
    await db.insert('user_point_history', {
      ...transaction,
      'user_email': cleanEmail,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getNotificationPollSnapshot(
    String userId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'notification_poll_state',
      columns: ['snapshot_json'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['snapshot_json'] as String)
        as Map<String, dynamic>;
  }

  Future<void> saveNotificationPollSnapshot(
    String userId,
    Map<String, dynamic> snapshot,
  ) async {
    final db = await database;
    await db.insert('notification_poll_state', {
      'user_id': userId,
      'snapshot_json': jsonEncode(snapshot),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> claimNotificationEvent(String eventKey) async {
    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'notification_delivered_events',
        columns: ['event_key'],
        where: 'event_key = ?',
        whereArgs: [eventKey],
        limit: 1,
      );
      if (existing.isNotEmpty) return false;

      await txn.insert('notification_delivered_events', {
        'event_key': eventKey,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      await txn.delete(
        'notification_delivered_events',
        where: 'created_at < ?',
        whereArgs: [
          DateTime.now()
              .subtract(const Duration(days: 90))
              .millisecondsSinceEpoch,
        ],
      );
      return true;
    });
  }

  Future<void> _seedInitialProducts(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();

    for (final prod in Product.allCatalog) {
      batch.insert(
        'cached_products',
        _productCacheMap(prod, now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> _removeUntouchedDefaultSelections(Database db) async {
    final initialCartIds = Product.allCatalog
        .take(3)
        .map((product) => product.id)
        .toSet();
    final cartRows = await db.query(
      'local_cart',
      columns: ['product_id', 'quantity', 'is_selected'],
    );
    if (cartRows.length == initialCartIds.length &&
        cartRows.every(
          (row) =>
              initialCartIds.contains(row['product_id']) &&
              row['quantity'] == 1 &&
              row['is_selected'] == 1,
        )) {
      await db.delete('local_cart');
    }

    final initialFavoriteIds = Product.initialProducts
        .map((product) => product.id)
        .toSet();
    final favoriteRows = await db.query(
      'local_favorites',
      columns: ['product_id'],
    );
    if (favoriteRows.length == initialFavoriteIds.length &&
        favoriteRows.every(
          (row) => initialFavoriteIds.contains(row['product_id']),
        )) {
      await db.delete('local_favorites');
    }
  }

  Future<void> _replaceCatalogWithCsvProducts(Database db) async {
    final previousProducts = await db.query(
      'cached_products',
      columns: ['id', 'brand', 'name'],
    );
    final catalogByName = {
      for (final product in Product.allCatalog)
        _productKey(product.brand, product.name): product,
    };

    for (final previous in previousProducts) {
      final previousId = previous['id']?.toString() ?? '';
      final product =
          catalogByName[_productKey(
            previous['brand']?.toString() ?? '',
            previous['name']?.toString() ?? '',
          )];
      if (product == null) {
        await db.delete(
          'local_cart',
          where: 'product_id = ?',
          whereArgs: [previousId],
        );
        await db.delete(
          'local_favorites',
          where: 'product_id = ?',
          whereArgs: [previousId],
        );
        await db.update(
          'local_ai_chat_messages',
          {'recommended_product_id': null},
          where: 'recommended_product_id = ?',
          whereArgs: [previousId],
        );
        continue;
      }

      await db.rawUpdate(
        'UPDATE OR REPLACE local_cart SET product_id = ? WHERE product_id = ?',
        [product.id, previousId],
      );
      await db.rawUpdate(
        'UPDATE OR REPLACE local_favorites SET product_id = ? WHERE product_id = ?',
        [product.id, previousId],
      );
      await db.update(
        'local_ai_chat_messages',
        {'recommended_product_id': product.id},
        where: 'recommended_product_id = ?',
        whereArgs: [previousId],
      );
    }

    await db.delete('cached_products');
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final product in Product.allCatalog) {
      batch.insert(
        'cached_products',
        _productCacheMap(product, now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Map<String, Object?> _productCacheMap(Product product, int cachedAt) => {
    'id': product.id,
    'brand': product.brand,
    'name': product.name,
    'price': product.price,
    'category': product.category,
    'variant': product.variant,
    'code': product.code,
    'stock': product.stock,
    'rating': product.rating,
    'review_count': product.reviewCount,
    'is_original': product.isOriginal ? 1 : 0,
    'is_best_seller': product.isBestSeller ? 1 : 0,
    'image_url': product.image,
    'description': product.description,
    'specs_json': jsonEncode(product.specs),
    'color_variants_json': jsonEncode(product.colorVariants),
    'cached_at': cachedAt,
  };

  String _productKey(String brand, String name) =>
      '${brand.trim().toLowerCase()}|${name.trim().toLowerCase()}';

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
