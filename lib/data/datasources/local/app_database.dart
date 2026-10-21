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
  static const int _dbVersion = 1;

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
    );
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

  Future<void> _seedInitialProducts(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();

    for (final prod in Product.allCatalog) {
      batch.insert(
        'cached_products',
        {
          'id': prod.id,
          'brand': prod.brand,
          'name': prod.name,
          'price': prod.price,
          'category': prod.category,
          'variant': prod.variant,
          'code': prod.code,
          'stock': prod.stock,
          'rating': prod.rating,
          'review_count': prod.reviewCount,
          'is_original': prod.isOriginal ? 1 : 0,
          'is_best_seller': prod.isBestSeller ? 1 : 0,
          'image_url': prod.image,
          'description': prod.description,
          'specs_json': jsonEncode(prod.specs),
          'color_variants_json': jsonEncode(prod.colorVariants),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Seed default cart items (3 produk teratas)
    final initialThree = Product.allCatalog.take(3).toList();
    for (final item in initialThree) {
      batch.insert(
        'local_cart',
        {
          'product_id': item.id,
          'quantity': 1,
          'is_selected': 1,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Seed default favorites (4 produk teratas)
    for (final fav in Product.initialProducts) {
      batch.insert(
        'local_favorites',
        {
          'product_id': fav.id,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
