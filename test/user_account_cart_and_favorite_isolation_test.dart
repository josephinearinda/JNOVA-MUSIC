import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:jnova/core/network/network_info.dart';
import 'package:jnova/core/storage/secure_storage_service.dart';
import 'package:jnova/models/product.dart';
import 'package:jnova/services/auth_service.dart';
import 'package:jnova/services/cart_service.dart';
import 'package:jnova/services/favorite_service.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    NetworkInfo.instance.overrideIsConnected = false;
  });

  setUp(() async {
    CartService.instance.resetCart();
    FavoriteService.instance.resetFavorites();
    await SecureStorageService.instance.clearSession();
  });

  tearDown(() async {
    CartService.instance.resetCart();
    FavoriteService.instance.resetFavorites();
    await SecureStorageService.instance.clearSession();
  });

  group('Isolasi Penuh Antar Akun untuk Keranjang dan Favorit', () {
    test('Keranjang Belanja (Cart) terpisah sempurna antar akun yang berbeda', () async {
      final userA = 'arinda_a@gmail.com';
      final userB = 'budi_b@gmail.com';

      final product1 = Product.allCatalog[0];
      final product2 = Product.allCatalog[1];

      // 1. Akun A login dan menambahkan product1 ke keranjang
      await SecureStorageService.instance.saveSession(
        accessToken: 'local_token_a',
        refreshToken: 'refresh_a',
        userId: 'user_a',
        email: userA,
      );
      await CartService.instance.loadCartForUser(userA);
      expect(CartService.instance.items.isEmpty, isTrue);

      await CartService.instance.addToCart(product1, quantity: 2);
      expect(CartService.instance.items.length, equals(1));
      expect(CartService.instance.items.first.product.id, equals(product1.id));
      expect(CartService.instance.items.first.quantity, equals(2));

      // 2. Akun A logout
      await AuthService.instance.logout();
      expect(CartService.instance.items.isEmpty, isTrue);

      // 3. Akun B login: Keranjang Akun B HARUS bersih (kosong), tidak ada barang akun A!
      await SecureStorageService.instance.saveSession(
        accessToken: 'local_token_b',
        refreshToken: 'refresh_b',
        userId: 'user_b',
        email: userB,
      );
      await CartService.instance.loadCartForUser(userB);
      expect(CartService.instance.items.isEmpty, isTrue);

      // 4. Akun B menambahkan product2 ke keranjangnya
      await CartService.instance.addToCart(product2, quantity: 1);
      expect(CartService.instance.items.length, equals(1));
      expect(CartService.instance.items.first.product.id, equals(product2.id));
      expect(CartService.instance.items.first.quantity, equals(1));

      // 5. Akun B logout
      await AuthService.instance.logout();
      expect(CartService.instance.items.isEmpty, isTrue);

      // 6. Akun A login kembali: Keranjang Akun A harus tetap memuat product1 miliknya!
      await SecureStorageService.instance.saveSession(
        accessToken: 'local_token_a',
        refreshToken: 'refresh_a',
        userId: 'user_a',
        email: userA,
      );
      await CartService.instance.loadCartForUser(userA);
      expect(CartService.instance.items.length, equals(1));
      expect(CartService.instance.items.first.product.id, equals(product1.id));
      expect(CartService.instance.items.first.quantity, equals(2));
    });

    test('Daftar Favorit terpisah sempurna antar akun yang berbeda', () async {
      final userA = 'arinda_a@gmail.com';
      final userB = 'budi_b@gmail.com';

      final product1 = Product.allCatalog[0];
      final product2 = Product.allCatalog[1];

      // 1. Akun A login dan menambahkan product1 ke favorit
      await SecureStorageService.instance.saveSession(
        accessToken: 'local_token_a',
        refreshToken: 'refresh_a',
        userId: 'user_a',
        email: userA,
      );
      await FavoriteService.instance.loadFavoritesForUser(userA);
      expect(FavoriteService.instance.items.isEmpty, isTrue);

      await FavoriteService.instance.toggleFavorite(product1);
      expect(FavoriteService.instance.isFavorite(product1.id), isTrue);
      expect(FavoriteService.instance.isFavorite(product2.id), isFalse);
      expect(FavoriteService.instance.items.length, equals(1));

      // 2. Akun A logout
      await AuthService.instance.logout();
      expect(FavoriteService.instance.items.isEmpty, isTrue);
      expect(FavoriteService.instance.isFavorite(product1.id), isFalse);

      // 3. Akun B login: Favorit Akun B HARUS bersih (kosong), tidak ada favorit akun A!
      await SecureStorageService.instance.saveSession(
        accessToken: 'local_token_b',
        refreshToken: 'refresh_b',
        userId: 'user_b',
        email: userB,
      );
      await FavoriteService.instance.loadFavoritesForUser(userB);
      expect(FavoriteService.instance.items.isEmpty, isTrue);
      expect(FavoriteService.instance.isFavorite(product1.id), isFalse);

      // 4. Akun B memfavoritkan product2
      await FavoriteService.instance.toggleFavorite(product2);
      expect(FavoriteService.instance.isFavorite(product2.id), isTrue);
      expect(FavoriteService.instance.isFavorite(product1.id), isFalse);
      expect(FavoriteService.instance.items.length, equals(1));

      // 5. Akun B logout
      await AuthService.instance.logout();
      expect(FavoriteService.instance.items.isEmpty, isTrue);

      // 6. Akun A login kembali: Favorit Akun A harus tetap memuat product1, dan tidak ada product2!
      await SecureStorageService.instance.saveSession(
        accessToken: 'local_token_a',
        refreshToken: 'refresh_a',
        userId: 'user_a',
        email: userA,
      );
      await FavoriteService.instance.loadFavoritesForUser(userA);
      expect(FavoriteService.instance.isFavorite(product1.id), isTrue);
      expect(FavoriteService.instance.isFavorite(product2.id), isFalse);
      expect(FavoriteService.instance.items.length, equals(1));
    });
  });
}
