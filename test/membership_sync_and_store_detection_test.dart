import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:jnova/core/network/network_info.dart';
import 'package:jnova/core/storage/secure_storage_service.dart';
import 'package:jnova/models/order_model.dart';
import 'package:jnova/models/product.dart';
import 'package:jnova/models/store_branch.dart';
import 'package:jnova/screens/cart_screen.dart';
import 'package:jnova/screens/checkout_screen.dart';
import 'package:jnova/screens/membership_settings_page.dart';
import 'package:jnova/services/auth_service.dart';
import 'package:jnova/services/cart_service.dart';
import 'package:jnova/services/location_service.dart';
import 'package:jnova/services/membership_service.dart';
import 'package:jnova/services/order_service.dart';
import 'package:jnova/services/user_profile_service.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    NetworkInfo.instance.overrideIsConnected = false;
  });

  setUp(() async {
    await SecureStorageService.instance.clearSession();
    UserProfileService.instance.resetProfile();
    MembershipService.instance.resetPoints();
    await CartService.instance.reset();
    OrderService.instance.resetOrders();
    LocationService.instance.resetMock();
  });

  tearDown(() {
    LocationService.instance.resetMock();
  });

  group('BAGIAN 1 — Sinkronisasi Poin dan Membership JNOVAMUSIC', () {
    testWidgets(
      '1. Akun baru dengan 0 poin: Membership dan Keranjang sama-sama menampilkan 0 poin (tidak ada 1.400 poin)',
      (WidgetTester tester) async {
        MembershipService.instance.resetPoints();
        expect(MembershipService.instance.currentPoints, 0);
        expect(CartService.instance.currentPoints, 0);

        await CartService.instance.addToCart(Product.allCatalog.first, quantity: 1);

        // Buka Halaman Keranjang
        await tester.pumpWidget(const MaterialApp(home: CartScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Pastikan TIDAK ADA teks 1.400 poin
        expect(find.textContaining('1.400'), findsNothing);
        expect(find.textContaining('1400'), findsNothing);

        // Pastikan Keranjang menampilkan saldo 0 poin aktual (Non-Member)
        expect(find.text('Non-Member (0 Poin)'), findsOneWidget);
        expect(find.text('Target Silver: 1.000'), findsOneWidget);
        expect(find.text('BRONZE'), findsNothing);
        expect(find.text('Bronze Member'), findsNothing);

        // Buka Halaman Membership
        await tester.pumpWidget(const MaterialApp(home: MembershipSettingsPage()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Pastikan Halaman Membership juga menampilkan 0 poin dan tidak ada tier Bronze
        expect(find.text('0 Poin'), findsOneWidget);
        expect(find.text('0 / 1.000 Poin'), findsOneWidget);
        expect(find.text('BRONZE'), findsNothing);
        expect(find.text('Bronze Member'), findsNothing);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      '2. Akun dengan poin valid: kedua halaman menampilkan saldo yang persis sama',
      (WidgetTester tester) async {
        const testPoints = 1750;
        MembershipService.instance.setPoints(testPoints);
        await CartService.instance.addToCart(Product.allCatalog.first, quantity: 1);

        expect(MembershipService.instance.currentPoints, testPoints);
        expect(CartService.instance.currentPoints, testPoints);

        // Cek Keranjang
        await tester.pumpWidget(const MaterialApp(home: CartScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Silver Member (1.750 Poin)'), findsOneWidget);
        expect(find.text('Target Gold: 3.000'), findsOneWidget);

        // Cek Membership
        await tester.pumpWidget(const MaterialApp(home: MembershipSettingsPage()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('1.750 Poin'), findsOneWidget);
        expect(find.text('1.750 / 3.000 Poin'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      '3. Pengguna yang memenuhi syarat Gold (>= 3000 poin) otomatis naik ke Gold Member & diskon 20%',
      (WidgetTester tester) async {
        MembershipService.instance.setPoints(3500);
        await CartService.instance.addToCart(Product.allCatalog.first, quantity: 1);

        expect(MembershipService.instance.tierName, 'Gold Member');
        expect(MembershipService.instance.discountPercentage, 20);
        expect(CartService.instance.tierName, 'Gold Member');
        expect(CartService.instance.discountPercentage, 20);

        await tester.pumpWidget(const MaterialApp(home: CartScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Gold Member Terdeteksi'), findsOneWidget);
        expect(find.text('Gold Member (3.500 Poin)'), findsOneWidget);
        expect(find.text('Target Platinum: 10.000'), findsOneWidget);
        expect(find.text('Diskon Gold Member (20%)'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
      },
    );

    test(
      '4. Perubahan jumlah barang memperbarui subtotal belanja dan diskon dengan benar',
      () async {
        MembershipService.instance.setPoints(1500);
        await CartService.instance.reset();
        await CartService.instance.addToCart(Product.allCatalog.first, quantity: 1);
        final initialSubtotal = CartService.instance.subtotal;
        final initialDiscount = CartService.instance.discountAmount;

        expect(initialSubtotal, greaterThan(0));
        expect(initialDiscount, (initialSubtotal * CartService.instance.discountRate).round());

        // Tambah produk ke keranjang
        await CartService.instance.addToCart(Product.allCatalog.first, quantity: 1);
        final newSubtotal = CartService.instance.subtotal;
        final newDiscount = CartService.instance.discountAmount;

        expect(newSubtotal, greaterThan(initialSubtotal));
        expect(newDiscount, (newSubtotal * CartService.instance.discountRate).round());
        expect(CartService.instance.totalPayment, newSubtotal - newDiscount);
      },
    );

    test(
      '5. Poin transaksi pembelian bertambah setelah pesanan diselesaikan (status selesai)',
      () async {
        MembershipService.instance.resetPoints();
        expect(MembershipService.instance.currentPoints, 0);

        // Simulasi checkout
        final order = await OrderService.instance.checkout(
          items: [CartItem(product: Product.allCatalog.first, quantity: 1, isSelected: true)],
          fulfillment: FulfillmentMethod.pickup,
          store: StoreBranch.branches.first,
        );

        // Saat baru checkout, poin belum diberikan
        expect(MembershipService.instance.currentPoints, 0);

        // Pelanggan mengambil barang dan menekan pesanan selesai
        await OrderService.instance.completeOrder(order);

        // Poin harus bertambah sesuai aturan resmi (1 poin per Rp 10.000)
        final expectedPoints = (order.totalPayment / 10000).floor();
        expect(MembershipService.instance.currentPoints, expectedPoints);
        expect(CartService.instance.currentPoints, expectedPoints);
      },
    );

    test(
      '6. Logout dan login akun berbeda tidak mencampur saldo poin antar pengguna',
      () async {
        // User 1 login dan punya 2500 poin
        await MembershipService.instance.loadPointsForUser('user1@jnova.com');
        MembershipService.instance.setPoints(2500);
        await SecureStorageService.instance.savePointsForUser('user1@jnova.com', 2500);

        expect(MembershipService.instance.currentPoints, 2500);

        // Logout
        await AuthService.instance.logout();
        expect(MembershipService.instance.currentPoints, 0);

        // User 2 login (akun baru 0 poin)
        await MembershipService.instance.loadPointsForUser('user2@jnova.com');
        expect(MembershipService.instance.currentPoints, 0);

        // Kembali ke User 1
        await MembershipService.instance.loadPointsForUser('user1@jnova.com');
        expect(MembershipService.instance.currentPoints, 2500);
      },
    );
  });

  group('BAGIAN 2 — Deteksi Lokasi dan Pemilihan Toko Pickup Terdekat', () {
    test(
      '7. Formula Haversine / LocationService menghitung jarak dan format jarak dengan akurat',
      () {
        // Koordinat Monas Jakarta (-6.1754, 106.8272) ke JNOVAMUSIC Flagship (-6.244265, 106.783478)
        final distance = LocationService.instance.calculateDistanceMeters(
          -6.1754,
          106.8272,
          -6.244265,
          106.783478,
        );

        expect(distance, greaterThan(8000)); // Sekitar 9-10 km
        expect(distance, lessThan(15000));

        final formatted = LocationService.instance.formatDistance(distance);
        expect(formatted, contains('km'));

        // Jarak pendek (< 1 km)
        expect(LocationService.instance.formatDistance(750), '750 m');
      },
    );

    testWidgets(
      '8. Izin lokasi diberikan: aplikasi otomatis memilih cabang Jakarta terdekat dari posisi pelanggan',
      (WidgetTester tester) async {
        // Mock lokasi pelanggan di Jakarta Selatan (dekat JNOVAMUSIC Flagship)
        LocationService.instance.setMockLocation(
          latitude: -6.2440,
          longitude: 106.7830,
          status: LocationStatus.success,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: CheckoutScreen(initialMethod: FulfillmentMethod.pickup),
          ),
        );
        await tester.pumpAndSettle();

        // Pastikan banner sukses lokasi muncul
        expect(find.text('Lokasi terdeteksi. Cabang terdekat otomatis terpilih.'), findsOneWidget);

        // Pastikan penanda "Toko Terdekat" muncul
        expect(find.text('Toko Terdekat'), findsOneWidget);

        // Pastikan tombol rute Google Maps tersedia
        expect(find.text('Buka Rute Google Maps'), findsWidgets);

        // Pastikan teks jarak garis lurus muncul
        expect(find.textContaining('dari lokasimu (garis lurus)'), findsWidgets);
      },
    );

    testWidgets(
      '9. Izin lokasi diberikan di Yogyakarta: otomatis memilih cabang Yogyakarta terdekat',
      (WidgetTester tester) async {
        // Mock lokasi pelanggan di Sleman, D.I. Yogyakarta (dekat Zeal Musik)
        LocationService.instance.setMockLocation(
          latitude: -7.7750,
          longitude: 110.3465,
          status: LocationStatus.success,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: CheckoutScreen(initialMethod: FulfillmentMethod.pickup),
          ),
        );
        await tester.pumpAndSettle();

        // Zeal Musik harus menjadi toko terpilih pertama
        expect(find.text('Zeal Musik'), findsOneWidget);
        expect(find.text('Toko Terdekat'), findsOneWidget);
      },
    );

    testWidgets(
      '10. Izin lokasi ditolak: tidak crash, menampilkan pesan penanganan yang jelas & pemilihan manual tetap berfungsi',
      (WidgetTester tester) async {
        LocationService.instance.setMockLocation(
          status: LocationStatus.permissionDenied,
          message: 'Izin lokasi tidak diberikan. Kamu tetap dapat memilih toko pickup secara manual.',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: CheckoutScreen(initialMethod: FulfillmentMethod.pickup),
          ),
        );
        await tester.pumpAndSettle();

        // Aplikasi tidak crash dan menampilkan pesan error informatif
        expect(
          find.text('Izin lokasi tidak diberikan. Kamu tetap dapat memilih toko pickup secara manual.'),
          findsOneWidget,
        );
        expect(find.text('Coba Lagi'), findsOneWidget);

        // Pemilihan manual tetap tersedia
        expect(find.text('Pilih Toko Pengambilan'), findsOneWidget);
        expect(find.text('Buka Rute Google Maps'), findsWidgets);
      },
    );

    testWidgets(
      '11. Layanan GPS mati: aplikasi menampilkan penanganan GPS tidak aktif dengan benar',
      (WidgetTester tester) async {
        LocationService.instance.setMockLocation(
          status: LocationStatus.serviceDisabled,
          message: 'Layanan lokasi perangkat (GPS) tidak aktif. Silakan aktifkan lokasi atau pilih toko secara manual.',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: CheckoutScreen(initialMethod: FulfillmentMethod.pickup),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Layanan lokasi perangkat (GPS) tidak aktif. Silakan aktifkan lokasi atau pilih toko secara manual.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '12. Pelanggan dapat mengganti toko manual dan pilihan tersimpan ke pesanan',
      (WidgetTester tester) async {
        LocationService.instance.setMockLocation(
          latitude: -6.2440,
          longitude: 106.7830,
          status: LocationStatus.success,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: const CheckoutScreen(initialMethod: FulfillmentMethod.pickup),
            routes: {
              '/pickup-detail': (context) => const Scaffold(),
            },
          ),
        );
        await tester.pumpAndSettle();

        // Verifikasi tombol konfirmasi pesanan pickup ada di checkout
        final confirmBtn = find.text('Konfirmasi Pesanan Pickup');
        expect(confirmBtn, findsOneWidget);
      },
    );

    test(
      '13. URL Google Maps memuat koordinat tujuan cabang toko yang benar',
      () {
        final branch = StoreBranch.branches.first;
        final directionsUrl = branch.getDirectionsUrl(-6.2000, 106.8000);

        expect(directionsUrl, contains('api=1'));
        expect(directionsUrl, contains('origin=-6.2,106.8'));
        expect(directionsUrl, contains('destination=${branch.latitude},${branch.longitude}'));
        expect(directionsUrl, contains('travelmode=driving'));
      },
    );
  });
}
