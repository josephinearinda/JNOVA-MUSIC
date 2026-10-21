// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jnova/main.dart';
import 'package:jnova/models/order_model.dart';
import 'package:jnova/models/product.dart';
import 'package:jnova/screens/splash_screen.dart';
import 'package:jnova/screens/login_screen.dart';
import 'package:jnova/screens/register_screen.dart';
import 'package:jnova/screens/favorite_screen.dart';
import 'package:jnova/screens/cart_screen.dart';
import 'package:jnova/screens/all_products_screen.dart';
import 'package:jnova/screens/search_screen.dart';
import 'package:jnova/screens/product_detail_screen.dart';
import 'package:jnova/screens/checkout_screen.dart';
import 'package:jnova/screens/pickup_detail_screen.dart';
import 'package:jnova/screens/order_detail_screen.dart';
import 'package:jnova/screens/tracking_screen.dart';
import 'package:jnova/services/currency_service.dart';
import 'package:jnova/screens/game/motion_permission_page.dart';
import 'package:jnova/screens/game/beat_tilt_home_page.dart';
import 'package:jnova/screens/game/beat_tilt_result_page.dart';
import 'package:jnova/screens/game_selection_page.dart';
import 'package:jnova/screens/profile_screen.dart';
import 'package:jnova/screens/edit_profile_page.dart';
import 'package:jnova/screens/address_edit_page.dart';
import 'package:jnova/screens/notification_settings_page.dart';
import 'package:jnova/screens/account_security_page.dart';
import 'package:jnova/screens/currency_preferences_page.dart';
import 'package:jnova/screens/music_preferences_page.dart';
import 'package:jnova/screens/world_clock_page.dart';
import 'package:jnova/screens/membership_settings_page.dart';
import 'package:jnova/screens/point_history_page.dart';
import 'package:jnova/screens/suggestion_review_page.dart';
import 'package:jnova/screens/ai_chat_page.dart';
import 'package:jnova/widgets/logout_confirmation_dialog.dart';
import 'package:jnova/services/cart_service.dart';
import 'package:jnova/core/network/network_info.dart';
import 'package:jnova/core/storage/secure_storage_service.dart';
import 'package:jnova/data/repositories/auth_repository.dart';
import 'package:jnova/services/auth_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    NetworkInfo.instance.overrideIsConnected = true;
  });

  testWidgets('SplashScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that SplashScreen is displayed.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Temukan Nada, Ciptakan Karya'), findsOneWidget);
    expect(find.text('TOKO ALAT MUSIK & AUDIO STUDIO RESMI'), findsOneWidget);
    expect(find.text('v2.4.0 \u2022 Karya Musik Indonesia'), findsOneWidget);
  });

  testWidgets('LoginScreen smoke test and form validation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Verify UI elements
    expect(find.text('Selamat Datang!'), findsOneWidget);
    expect(
      find.text('Temukan alat musik yang tepat untuk menemani kreativitasmu.'),
      findsOneWidget,
    );
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
    expect(find.text('Masuk \u2192'), findsOneWidget);
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    expect(find.text('Gitar & Bass'), findsOneWidget);
    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Audio & Studio'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Transaksi Aman & Bergaransi Resmi Toko'), findsOneWidget);

    // Test empty validation
    await tester.tap(find.text('Masuk \u2192'));
    await tester.pump();

    expect(find.text('Alamat email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);

    // Enter invalid email
    await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
    await tester.enterText(find.byType(TextFormField).last, '12345');
    await tester.tap(find.text('Masuk \u2192'));
    await tester.pump();

    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
  });

  testWidgets('LoginScreen displays register prompt', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    final daftarFinder = find.text('Daftar');
    expect(daftarFinder, findsOneWidget);
  });

  testWidgets('RegisterScreen smoke test and form validation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    expect(find.text('Buat Akun'), findsOneWidget);
    expect(find.text('Data Diri'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Tanggal Lahir'), findsOneWidget);
    expect(find.text('Nomor HP'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);
    expect(find.text('Alamat Lengkap'), findsOneWidget);
    expect(find.text('Kelurahan'), findsOneWidget);
    expect(find.text('Kecamatan'), findsOneWidget);
    expect(find.text('Kota/Kabupaten'), findsOneWidget);
    expect(find.text('Provinsi'), findsOneWidget);
    expect(find.text('Kode Pos'), findsOneWidget);
    expect(find.text('Alamat Pengiriman'), findsNothing);
    expect(find.text('Tujuan Kirim'), findsNothing);
    expect(find.text('Daftar'), findsOneWidget);

    // Test empty validation
    final submitBtn = find.text('Daftar');
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn);
    await tester.pump();

    expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
    expect(find.text('Username wajib diisi'), findsOneWidget);
    expect(find.text('Nomor HP wajib diisi'), findsOneWidget);
    expect(find.text('Alamat email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(find.text('Alamat lengkap wajib diisi'), findsOneWidget);
    expect(find.text('Kelurahan wajib diisi'), findsOneWidget);
    expect(find.text('Kecamatan wajib diisi'), findsOneWidget);
    expect(find.text('Kota/Kabupaten wajib diisi'), findsOneWidget);
    expect(find.text('Provinsi wajib dipilih'), findsOneWidget);
    expect(find.text('Kode Pos wajib diisi'), findsOneWidget);
  });

  testWidgets('FavoriteScreen smoke test and interaction', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FavoriteScreen()));

    expect(find.text('Favorit Saya'), findsOneWidget);
    expect(find.text('Produk pilihan yang kamu simpan.'), findsOneWidget);
    expect(find.text('Pengiriman Cepat & Aman'), findsOneWidget);
    expect(find.text('Fender Player II Stratocaster HSS'), findsOneWidget);
    expect(find.text('Yamaha P-125 Digital Piano 88-Key'), findsOneWidget);

    // Tap + Keranjang
    await tester.tap(find.text('+ Keranjang').first);
    await tester.pump();
  });

  testWidgets('CartScreen smoke test and price calculation', (
    WidgetTester tester,
  ) async {
    await CartService.instance.reset();

    await tester.pumpWidget(const MaterialApp(home: CartScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Keranjang Saya'), findsOneWidget);
    expect(find.text('Pilih Semua'), findsOneWidget);
    expect(find.text('Silver Member Terdeteksi'), findsOneWidget);
    expect(find.text('Garansi Instrumen & Kayu Aman'), findsNothing);
    expect(find.text('Ringkasan Belanja'), findsOneWidget);
    expect(find.text('Rp 28.890.000'), findsOneWidget);
    expect(find.text('-Rp 2.889.000'), findsOneWidget);
    expect(find.text('Rp 26.001.000'), findsWidgets);
  });

  testWidgets('AllProductsScreen smoke test and filtering', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AllProductsScreen()));

    expect(find.text('Semua Produk'), findsOneWidget);
    expect(find.text('Temukan alat musik yang cocok...'), findsOneWidget);
    expect(find.text('Cari nama alat musik atau merek...'), findsOneWidget);
    expect(find.text('Menampilkan 12 Produk'), findsOneWidget);
    expect(find.text('Pengiriman Cepat & Aman'), findsNothing);
    expect(find.text('Fender Player II Stratocaster HSS'), findsOneWidget);

    // Tap category "Drum"
    await tester.tap(find.text('Drum'));
    await tester.pump();

    expect(find.text('Roland TD-07KV V-Drums Electronic'), findsOneWidget);
  });

  testWidgets('SearchScreen smoke test and UX empty state simulation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));

    expect(find.text('Semua Produk'), findsWidgets);
    expect(find.text('Pencarian Terakhir'), findsNothing);
    expect(find.text('Kategori Populer'), findsOneWidget);

    // Cari produk untuk menguji kemunculan Hasil Pencarian & Pencarian Terakhir
    await tester.enterText(find.byType(TextField), 'Fender');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Hasil Pencarian'), findsOneWidget);
    expect(find.text('Pencarian Terakhir'), findsOneWidget);
    final simFinder = find.text('Simulasikan "Tidak Ada Hasil"');
    await tester.ensureVisible(simFinder);
    await tester.pumpAndSettle();
    await tester.tap(simFinder);
    await tester.pumpAndSettle();

    expect(find.text('Produk Tidak Ditemukan'), findsOneWidget);
    expect(
      find.text(
        'Coba kata kunci lain atau periksa ejaanmu untuk menemukan alat musik yang kamu cari.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('ProductDetailScreen smoke test and quantity interaction', (
    WidgetTester tester,
  ) async {
    final product = Product.allCatalog.first;

    await tester.pumpWidget(
      MaterialApp(home: ProductDetailScreen(product: product)),
    );

    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Kode : 0140512500'), findsOneWidget);
    expect(find.text('+ Keranjang'), findsOneWidget);
    expect(find.text('Beli Sekarang'), findsOneWidget);

    final addFinder = find.byIcon(Icons.add);
    await tester.ensureVisible(addFinder);
    await tester.pumpAndSettle();

    // Initial quantity is 1
    expect(find.text('1'), findsWidgets);

    // Tap + to increment quantity
    await tester.tap(addFinder);
    await tester.pumpAndSettle();
    expect(find.text('2'), findsWidgets);

    // Tap - to decrement quantity back to 1
    final removeFinder = find.byIcon(Icons.remove);
    await tester.tap(removeFinder);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets);
  });

  testWidgets(
    'CheckoutScreen smoke test for pure Store Pickup flow',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CheckoutScreen(initialMethod: FulfillmentMethod.pickup),
        ),
      );

      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('Ambil di Toko (Store Pickup)'), findsOneWidget);
      expect(find.text('Produk yang Dipesan'), findsOneWidget);
      expect(find.text('Ambil di Toko'), findsWidgets);
      expect(find.text('Gratis Sound Check & Luthier Setup'), findsOneWidget);
      expect(find.text('Pilih Toko Pengambilan'), findsOneWidget);
      expect(find.text('JNOVAMUSIC Flagship Jakarta'), findsOneWidget);
      expect(find.text('Buka Peta & Rute'), findsOneWidget);
      expect(find.text('Member Silver'), findsOneWidget);
      expect(find.text('Ringkasan Biaya'), findsOneWidget);
      expect(find.text('Bayar Sekarang'), findsOneWidget);

      // Verify that home delivery is not present
      expect(find.text('Pengiriman ke Rumah'), findsNothing);
      expect(find.text('Pengiriman Rumah'), findsNothing);
    },
  );

  testWidgets('PickupDetailScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PickupDetailScreen()));

    expect(find.text('Detail Pengambilan'), findsOneWidget);
    expect(find.text('AMBIL DI TOKO'), findsOneWidget);
    expect(find.text('Siap Diambil di Toko'), findsOneWidget);
    expect(find.text('Kode Pengambilan Resmi'), findsOneWidget);
    expect(find.text('PKP-8841-JNV'), findsOneWidget);
    expect(find.text('Lokasi Pengambilan'), findsOneWidget);
    expect(find.text('Petunjuk Singkat'), findsOneWidget);
    expect(find.text('Lihat Detail Pesanan'), findsOneWidget);
  });

  testWidgets(
    'OrderDetailScreen smoke test with store pickup and verification',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: OrderDetailScreen()));

      expect(find.text('Detail Pesanan'), findsOneWidget);
      expect(find.text('PEMBAYARAN TERVERIFIKASI'), findsOneWidget);
      expect(find.text('Status Pesanan'), findsOneWidget);
      expect(find.text('Metode: Ambil di Toko Resmi (Store Pickup)'), findsOneWidget);
      expect(find.text('SIAP DIAMBIL'), findsOneWidget);
      expect(find.text('Informasi Toko Pengambilan'), findsOneWidget);
      expect(find.text('Tampilkan QR Code'), findsOneWidget);
      expect(find.text('Petunjuk Arah'), findsOneWidget);
      expect(find.text('Unduh E-Invoice (PDF)'), findsOneWidget);

      // Verify that "Pengiriman Rumah" is completely removed
      expect(find.text('Pengiriman Rumah'), findsNothing);
      expect(find.text('Pengiriman ke Rumah'), findsNothing);
    },
  );

  testWidgets('TrackingScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrackingScreen()));

    expect(find.text('Jnovamusic Lacak Pengiriman'), findsOneWidget);
    expect(find.text('Dalam Pengiriman'), findsOneWidget);
    expect(find.text('ESTIMASI TIBA'), findsOneWidget);
    expect(find.text('Riwayat Perjalanan Paket'), findsOneWidget);
    expect(find.text('Alamat Tujuan'), findsOneWidget);
    expect(find.text('Kembali ke Detail Pesanan'), findsOneWidget);
  });

  testWidgets('MotionPermissionPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MotionPermissionPage()));

    expect(find.text('Izin Sensor Gerak'), findsOneWidget);
    expect(find.text('Siap Mengumpulkan Poin?'), findsOneWidget);
    expect(find.text('Sensor Akselerometer HP'), findsOneWidget);
    expect(find.text('Panduan Keamanan'), findsOneWidget);
    expect(find.text('Validasi Studio Cerdas'), findsOneWidget);
    expect(find.text('IZINKAN & MULAI'), findsOneWidget);
    expect(find.text('Kembali ke Beranda JNOVAMUSIC'), findsOneWidget);
  });

  testWidgets('BeatTiltHomePage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BeatTiltHomePage()));

    expect(find.text('JNova Beat Tilt'), findsNWidgets(2));
    expect(find.text('Kembali ke JNOVAMUSIC'), findsOneWidget);
    expect(find.text('MINI-GAME MEMBERSHIP'), findsOneWidget);
    expect(find.text('Sensor Siap Digunakan'), findsOneWidget);
    expect(find.text('LAGU TANTANGAN HARI INI'), findsOneWidget);
    expect(find.text('Mine Mine'), findsOneWidget);
    expect(find.text('MULAI GOYANG'), findsOneWidget);
  });

  testWidgets('GameSelectionPage offers both games', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GameSelectionPage()));

    expect(find.text('Pilih Game'), findsOneWidget);
    expect(find.text('JNova Beat Tilt'), findsOneWidget);
    expect(find.text('JNova Dodge'), findsOneWidget);
  });

  testWidgets('GameSelectionPage opens JNova Dodge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const GameSelectionPage(),
        routes: {
          '/game2': (_) => const Scaffold(body: Text('Dodge game opened')),
        },
      ),
    );

    await tester.tap(find.text('JNova Dodge'));
    await tester.pumpAndSettle();

    expect(find.text('Dodge game opened'), findsOneWidget);
  });

  testWidgets('BeatTiltResultPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BeatTiltResultPage(
          resultData: GameResultData(
            validShakes: 32,
            pointsEarned: 65,
            shakeRate: 3.2,
            durationSeconds: 10,
          ),
        ),
      ),
    );

    expect(find.text('Hasil Permainan'), findsOneWidget);
    expect(find.text('SESI 10 DETIK SELESAI'), findsOneWidget);
    expect(find.text('WAKTU HABIS!'), findsOneWidget);
    expect(find.text('+65 POIN'), findsOneWidget);
    expect(find.text('METRIK RITME'), findsOneWidget);
    expect(find.text('32 Goyangan'), findsOneWidget);
    expect(find.text('MAIN LAGI'), findsOneWidget);
    expect(find.text('KEMBALI KE BERANDA JNOVAMUSIC'), findsOneWidget);
  });

  testWidgets('ProfileScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    expect(find.text('Profil'), findsWidgets);
    expect(find.text('Budi Pratama'), findsWidgets);
    expect(find.text('Informasi Pribadi'), findsOneWidget);
    expect(find.text('Alamat Saya'), findsOneWidget);
    expect(find.text('Aktivitas Saya'), findsOneWidget);
    expect(find.text('Pengaturan Aplikasi'), findsOneWidget);
  });

  testWidgets('EditProfilePage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: EditProfilePage()));

    expect(find.text('Edit Profil'), findsWidgets);
    expect(find.text('Informasi Akun & Kontak'), findsOneWidget);
    expect(find.text('Alamat Pengiriman Utama'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);
  });

  testWidgets('AddressEditPage smoke test and interaction', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AddressEditPage(
        onSaved: () {},
        onBack: () {},
      ),
      routes: {
        '/profile': (context) => const Scaffold(),
      },
    ));

    expect(find.text('Ubah Alamat'), findsOneWidget);
    expect(find.text('TIPE LOKASI'), findsOneWidget);
    expect(find.text('Rumah'), findsOneWidget);
    expect(find.text('Kantor'), findsOneWidget);
    expect(find.text('Studio/Kost'), findsOneWidget);
    expect(find.text('Nama Penerima'), findsOneWidget);
    expect(find.text('WILAYAH ADMINISTRATIF'), findsOneWidget);
    expect(find.text('Jadikan Alamat Utama'), findsOneWidget);
    expect(find.text('Simpan Perubahan Alamat'), findsOneWidget);
    expect(find.text('Hapus Alamat Ini'), findsOneWidget);

    // Tap "Kantor"
    await tester.tap(find.text('Kantor'));
    await tester.pumpAndSettle();

    // Tap "Studio/Kost"
    await tester.tap(find.text('Studio/Kost'));
    await tester.pumpAndSettle();

    // Tap "Rumah"
    await tester.tap(find.text('Rumah'));
    await tester.pumpAndSettle();

    // Tap "Simpan Perubahan Alamat"
    final saveBtn = find.text('Simpan Perubahan Alamat');
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn);
    await tester.pump();
  });

  testWidgets('NotificationSettingsPage smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationSettingsPage()),
    );

    expect(find.text('Notifikasi'), findsWidgets);
    expect(find.text('Preferensi Notifikasi'), findsOneWidget);
    expect(find.text('Riwayat Notifikasi'), findsOneWidget);
  });

  testWidgets('AccountSecurityPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountSecurityPage()));

    expect(find.text('Keamanan Akun'), findsWidgets);
    expect(find.text('Akun Terlindungi Penuh'), findsOneWidget);
    expect(find.text('Metode Pemulihan & Verifikasi'), findsOneWidget);
    expect(find.text('Login dengan Sidik Jari'), findsOneWidget);
  });

  testWidgets('CurrencyPreferencesPage smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CurrencyPreferencesPage()));

    expect(find.text('Preferensi Mata Uang'), findsWidgets);
    expect(find.text('Rupiah Indonesia (Rp)'), findsOneWidget);
    expect(find.text('Simpan Preferensi'), findsOneWidget);

    // Ubah ke USD dan periksa CurrencyService
    await tester.tap(find.text('Dolar Amerika (\$)'));
    await tester.pumpAndSettle();
    expect(CurrencyService.instance.selectedCurrency, 'USD');

    // Kembalikan ke IDR
    await tester.tap(find.text('Rupiah Indonesia (Rp)'));
    await tester.pumpAndSettle();
    expect(CurrencyService.instance.selectedCurrency, 'IDR');
  });

  testWidgets('MusicPreferencesPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MusicPreferencesPage()));

    expect(find.text('Preferensi Musik & Lagu'), findsWidgets);
    expect(find.text('Simpan Preferensi Musik'), findsOneWidget);
  });

  testWidgets('WorldClockPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WorldClockPage()));

    expect(find.text('Jam Dunia'), findsWidgets);
    expect(find.text('Zona Waktu Utama'), findsOneWidget);
    expect(find.text('Zona Terdistribusi'), findsOneWidget);
  });

  testWidgets('MembershipSettingsPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MembershipSettingsPage()));

    expect(find.text('Membership'), findsWidgets);
    expect(find.text('Tingkat Membership'), findsOneWidget);
    expect(find.text('Aktivitas Poin'), findsOneWidget);
    expect(find.text('Tukar Hadiah'), findsNothing);
  });

  testWidgets('PointHistoryPage smoke test and tab switching', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PointHistoryPage()));

    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Riwayat Poin'), findsWidgets);
    expect(find.text('Poin Membership'), findsOneWidget);
    expect(find.text('ACOUSTIC TIER'), findsOneWidget);
    expect(find.text('Lihat Membership >'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Pembelian'), findsWidgets);
    expect(find.text('Aktivitas Game'), findsWidgets);

    // Switch to "Pembelian"
    await tester.tap(find.text('Pembelian').first);
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Poin Pembelian'), findsOneWidget);

    // Switch to "Aktivitas Game"
    await tester.tap(find.text('Aktivitas Game').first);
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Poin Aktivitas Game'), findsOneWidget);
  });

  testWidgets('SuggestionReviewPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SuggestionReviewPage()));

    expect(find.text('Saran dan Kesan'), findsWidgets);
    expect(find.text('Suara Anda Berarti Bagi Kami'), findsOneWidget);
    expect(find.text('Kirim Masukan'), findsOneWidget);
  });

  testWidgets('AIChatPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AIChatPage()));

    expect(find.text('Jnova AI'), findsWidgets);
    expect(find.text('Yamaha F310 Natural'), findsOneWidget);
    expect(find.text('Lihat Produk'), findsOneWidget);
  });

  testWidgets(
      'AIChatPage interaction test: sending question displays user message and configuration prompt',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: AIChatPage()));
    await tester.pumpAndSettle();

    final inputFinder = find.byType(TextField);
    expect(inputFinder, findsOneWidget);

    await tester.enterText(
        inputFinder, 'Carikan rekomendasi bass harga Rp1.000.000');
    await tester.pump();

    final sendButton = find.byIcon(Icons.arrow_upward_rounded);
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pump();

    expect(
        find.text('Carikan rekomendasi bass harga Rp1.000.000'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));

    expect(
        find.textContaining('Google Gemini API belum dikonfigurasi'), findsOneWidget);
    expect(find.text('Konfigurasi Gemini API Key Sekarang'), findsOneWidget);
  });

  testWidgets('LogoutConfirmationDialog smoke test and behavior', (
    WidgetTester tester,
  ) async {
    bool isLoggedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                LogoutConfirmationDialog.show(
                  context,
                  onConfirmLogout: () {
                    isLoggedOut = true;
                  },
                );
              },
              child: const Text('Buka Dialog Logout'),
            ),
          ),
        ),
      ),
    );

    // Tap button to open dialog
    await tester.tap(find.text('Buka Dialog Logout'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Yakin ingin keluar?'), findsOneWidget);
    expect(
      find.text(
        'Kamu yakin ingin keluar dari akun JNOVAMUSIC? Keranjang dan wishlist kamu akan tersimpan dengan aman.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ya, Keluar →'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Sesi belanja terenkripsi aman.'), findsOneWidget);

    // Test "Batal"
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Yakin ingin keluar?'), findsNothing);
    expect(isLoggedOut, isFalse);

    // Open dialog again to test "Ya, Keluar →"
    await tester.tap(find.text('Buka Dialog Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Yakin ingin keluar?'), findsOneWidget);

    await tester.tap(find.text('Ya, Keluar →'));
    await tester.pumpAndSettle();
    expect(isLoggedOut, isTrue);
  });

  group('Login Biometrik & Secure Storage Test Suite', () {
    final storage = SecureStorageService.instance;
    final authRepo = AuthRepository.instance;

    setUp(() async {
      await storage.clearSession();
      await storage.clearBiometricForUser('budi.pratama@email.com');
      await storage.clearBiometricForUser('other.user@email.com');
    });

    test('1. Menyimpan dan membaca biometric auth record tanpa plaintext password', () async {
      const email = 'budi.pratama@email.com';
      await storage.saveBiometricAuthRecord(
        email: email,
        userId: 'user_123',
        fullName: 'Budi Pratama',
        refreshToken: 'refresh_token_test_123',
      );

      final record = await storage.getBiometricAuthRecord(email);
      expect(record, isNotNull);
      expect(record!['email'], equals(email));
      expect(record['userId'], equals('user_123'));
      expect(record['fullName'], equals('Budi Pratama'));
      expect(record['refreshToken'], equals('refresh_token_test_123'));
      expect(record.containsKey('password'), isFalse);
    });

    test('2. Logout / clearSession tidak menghapus record biometrik yang sah', () async {
      const email = 'budi.pratama@email.com';
      await storage.saveSession(
        accessToken: 'temp_access',
        refreshToken: 'temp_refresh',
        userId: 'temp_user',
        email: email,
      );

      await storage.saveBiometricAuthRecord(
        email: email,
        userId: 'user_123',
        fullName: 'Budi Pratama',
        refreshToken: 'refresh_token_test_123',
      );
      await storage.setBiometricEnabledForUser(email, true);

      // Pastikan session ada sebelum logout
      expect(await storage.getUserEmail(), equals(email));

      // Logout
      await authRepo.logout();

      // Session sementara bersih
      expect(await storage.getUserEmail(), isNull);
      expect(await storage.getAccessToken(), isNull);

      // Record biometrik tetap persisten di secure storage
      expect(await storage.getLastBiometricUser(), equals(email));
      expect(await storage.isBiometricEnabledForUser(email), isTrue);
      expect(await storage.getBiometricAuthRecord(email), isNotNull);
    });

    test('3. Alur login biometrik sukses memulihkan sesi akun yang sah', () async {
      const email = 'budi.pratama@email.com';
      const password = 'Password123!';

      // Simulasikan pendaftaran / akun terdaftar
      await storage.saveRegisteredUser(
        email: email,
        password: password,
        fullName: 'Budi Pratama',
      );

      // Login dengan password
      final loginRes = await authRepo.login(email: email, password: password);
      expect(loginRes.isSuccess, isTrue);

      // Aktifkan biometrik & simpan kredensial aman
      await storage.saveBiometricAuthRecord(
        email: email,
        userId: 'local_user_${email.hashCode}',
        fullName: 'Budi Pratama',
        refreshToken: 'local_refresh',
      );
      await storage.setBiometricEnabledForUser(email, true);

      // Logout
      await authRepo.logout();
      expect(await storage.getUserEmail(), isNull);

      // Login kembali dengan sidik jari
      final bioResult = await authRepo.loginWithBiometrics();
      expect(bioResult.isSuccess, isTrue);
      expect(bioResult.message, contains('Selamat datang kembali'));

      // Sesi aktif pulih
      expect(await storage.getUserEmail(), equals(email));
    });

    test('4. Login biometrik gagal dengan pesan jelas jika belum ada akun dihubungkan', () async {
      final res = await authRepo.loginWithBiometrics();
      expect(res.isSuccess, isFalse);
      expect(res.message, contains('Belum ada akun yang dihubungkan'));
    });

    test('5. Login biometrik gagal jika fitur dinonaktifkan untuk akun tersebut', () async {
      const email = 'budi.pratama@email.com';
      await storage.saveBiometricAuthRecord(
        email: email,
        userId: 'user_123',
        fullName: 'Budi Pratama',
        refreshToken: 'refresh_123',
      );
      await storage.setBiometricEnabledForUser(email, true);
      // Nonaktifkan
      await storage.setBiometricEnabledForUser(email, false);

      final res = await authRepo.loginWithBiometrics();
      expect(res.isSuccess, isFalse);
    });

    test('6. Pergantian akun tidak tertukar kredensial biometriknya', () async {
      const userA = 'budi.pratama@email.com';
      const userB = 'other.user@email.com';

      // User A aktifkan biometrik
      await storage.saveBiometricAuthRecord(
        email: userA,
        userId: 'user_a_id',
        fullName: 'User A',
        refreshToken: 'refresh_a',
      );
      await storage.setBiometricEnabledForUser(userA, true);

      // User B login dengan kata sandi
      await authRepo.login(email: userB, password: 'Password456!');
      await authRepo.logout();

      // Cek bahwa last biometric user tetap User A
      expect(await storage.getLastBiometricUser(), equals(userA));
      final res = await authRepo.loginWithBiometrics();
      expect(res.isSuccess, isTrue);
      expect(await storage.getUserEmail(), equals(userA));
      expect(await storage.getUserEmail(), isNot(equals(userB)));
    });

    test('7. Login dengan kata sandi tetap berfungsi normal', () async {
      const email = 'budi.pratama@email.com';
      const password = 'Password123!';

      await storage.saveRegisteredUser(
        email: email,
        password: password,
        fullName: 'Budi Pratama',
      );

      final wrongPassRes = await AuthService.instance.login(
        email: email,
        password: 'SalahPassword123',
      );
      expect(wrongPassRes.isSuccess, isFalse);

      final correctPassRes = await AuthService.instance.login(
        email: email,
        password: password,
      );
      expect(correctPassRes.isSuccess, isTrue);
    });
  });
}
