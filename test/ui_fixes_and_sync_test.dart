import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jnova/core/network/network_info.dart';
import 'package:jnova/core/storage/secure_storage_service.dart';
import 'package:jnova/screens/account_security_page.dart';
import 'package:jnova/screens/all_products_screen.dart';
import 'package:jnova/screens/cart_screen.dart';
import 'package:jnova/screens/membership_settings_page.dart';
import 'package:jnova/screens/profile_screen.dart';
import 'package:jnova/models/product.dart';
import 'package:jnova/services/auth_service.dart';
import 'package:jnova/services/cart_service.dart';
import 'package:jnova/services/membership_service.dart';
import 'package:jnova/services/user_profile_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  });

  group('Perbaikan UI JNOVA MUSIC', () {
    testWidgets('1. CartScreen: Kartu Garansi Instrumen & Kayu Aman telah dihapus', (
      WidgetTester tester,
    ) async {
      MembershipService.instance.setPoints(1500);
      CartService.instance.addToCart(Product.allCatalog.first, quantity: 1);

      await tester.pumpWidget(const MaterialApp(home: CartScreen()));
      await tester.pump();

      // Pastikan kartu garansi TIDAK ada
      expect(find.text('Garansi Instrumen & Kayu Aman'), findsNothing);
      expect(
        find.text(
          'Kemasan packing kayu standar ekspor + asuransi 100% penggantian unit.',
        ),
        findsNothing,
      );

      // Pastikan elemen keranjang lainnya tetap utuh
      expect(find.text('Keranjang Saya'), findsOneWidget);
      expect(find.text('Pilih Semua'), findsOneWidget);
      expect(find.text('Silver Member Terdeteksi'), findsOneWidget);
      expect(find.text('Ringkasan Belanja'), findsOneWidget);
      expect(find.textContaining('Checkout'), findsWidgets);
    });

    testWidgets('2. AllProductsScreen: Banner Pengiriman Cepat & Aman telah dihapus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AllProductsScreen()));
      await tester.pump();

      // Pastikan banner pengiriman TIDAK ada
      expect(find.text('Pengiriman Cepat & Aman'), findsNothing);
      expect(
        find.text('Packing kayu & asuransi resmi ke seluruh Indonesia.'),
        findsNothing,
      );

      // Pastikan katalog, pencarian, dan navigasi tetap utuh
      expect(find.text('Semua Produk'), findsOneWidget);
      expect(find.text('Cari nama alat musik atau merek...'), findsOneWidget);
      expect(find.text('Fender Player II Stratocaster HSS'), findsOneWidget);
      expect(find.text('Kategori'), findsWidgets);
    });

    testWidgets('3. MembershipSettingsPage: Kartu Tukar Hadiah telah dihapus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MembershipSettingsPage()));
      await tester.pump();

      // Pastikan kartu Tukar Hadiah TIDAK ada
      expect(find.text('Tukar Hadiah'), findsNothing);
      expect(
        find.text('Jelajahi hadiah yang tersedia untuk ditukar'),
        findsNothing,
      );

      // Pastikan fitur Membership lainnya tetap utuh
      expect(find.text('Membership'), findsWidgets);
      expect(find.text('Tingkat Membership'), findsOneWidget);
      expect(find.text('Aktivitas Poin'), findsOneWidget);
      expect(find.text('Riwayat Poin'), findsOneWidget);
    });
  });

  group('Sinkronisasi Data Akun & Profil', () {
    testWidgets('4. AccountSecurityPage menampilkan data akun login sebenarnya & kondisi kosong yang jujur', (
      WidgetTester tester,
    ) async {
      // Kondisi 1: Profil awal/kosong (Belum ada data email/telepon)
      UserProfileService.instance.resetProfile();

      await tester.pumpWidget(const MaterialApp(home: AccountSecurityPage()));
      await tester.pump();

      // Jangan tampilkan email dummy 'b***.p******@email.com' atau nomor dummy '+62 812-****-7890'
      expect(find.text('b***.p******@email.com'), findsNothing);
      expect(find.text('+62 812-****-7890'), findsNothing);

      // Menampilkan kondisi kosong 'Belum tersedia' dan badge 'Belum Ada'
      expect(find.text('Belum tersedia'), findsWidgets);
      expect(find.text('Belum Ada'), findsWidgets);

      // Kondisi 2: Pengguna login dengan email dan nomor telepon nyata
      const testEmail = 'musisi.jnova@gmail.com';
      const testPhone = '+62 812-3456-7890';
      await UserProfileService.instance.loadProfileForUser(
        testEmail,
        fullName: 'Musisi JNOVA',
      );
      await UserProfileService.instance.updateProfile(
        phoneNumber: testPhone,
      );

      await tester.pump();

      // Email dan nomor telepon yang benar harus tampil di Keamanan Akun
      expect(find.text(testEmail), findsOneWidget);
      expect(find.text(testPhone), findsOneWidget);

      // Karena belum verifikasi OTP resmi, status tidak boleh menandai verifikasi palsu
      expect(find.text('Belum Terverifikasi'), findsWidgets);
    });

    testWidgets('5. Perubahan nomor telepon di Keamanan Akun tersinkron langsung ke Profil', (
      WidgetTester tester,
    ) async {
      const testEmail = 'rocker.jnova@gmail.com';
      await UserProfileService.instance.loadProfileForUser(
        testEmail,
        fullName: 'Rocker JNOVA',
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/security': (context) => const AccountSecurityPage(),
            '/profile': (context) => const ProfileScreen(),
          },
          home: const AccountSecurityPage(),
        ),
      );
      await tester.pump();

      // Buka dialog ubah nomor telepon
      expect(find.text('Ubah'), findsWidgets);
      await tester.tap(find.text('Ubah').first);
      await tester.pumpAndSettle();

      expect(find.text('Ubah Nomor Telepon'), findsOneWidget);

      // Masukkan nomor telepon baru
      const updatedPhone = '+62 877-9988-1122';
      await tester.enterText(find.byType(TextField).last, updatedPhone);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Pastikan di Keamanan Akun nomor terbaru sudah muncul
      expect(find.text(updatedPhone), findsOneWidget);

      // Buka halaman ProfileScreen dan pastikan nomor telepon konsisten
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pump();

      expect(find.text(updatedPhone), findsOneWidget);
      expect(find.text(testEmail), findsWidgets);
    });

    testWidgets('6. Data akun antar pengguna berbeda tetap terisolasi & tidak tertukar', (
      WidgetTester tester,
    ) async {
      // User 1
      await UserProfileService.instance.loadProfileForUser('user1@jnova.com', fullName: 'User Satu');
      await UserProfileService.instance.updateProfile(phoneNumber: '+62 811-1111-1111');

      expect(UserProfileService.instance.profile.email, 'user1@jnova.com');
      expect(UserProfileService.instance.profile.phoneNumber, '+62 811-1111-1111');

      // Logout
      await AuthService.instance.logout();
      expect(UserProfileService.instance.profile.email, '');
      expect(UserProfileService.instance.profile.phoneNumber, '');

      // User 2
      await UserProfileService.instance.loadProfileForUser('user2@jnova.com', fullName: 'User Dua');
      await UserProfileService.instance.updateProfile(phoneNumber: '+62 822-2222-2222');

      expect(UserProfileService.instance.profile.email, 'user2@jnova.com');
      expect(UserProfileService.instance.profile.phoneNumber, '+62 822-2222-2222');

      // Logout User 2, login kembali User 1
      await AuthService.instance.logout();
      await UserProfileService.instance.loadProfileForUser('user1@jnova.com');

      // Data User 1 pulih dari SecureStorage dengan nomornya sendiri
      expect(UserProfileService.instance.profile.email, 'user1@jnova.com');
      expect(UserProfileService.instance.profile.phoneNumber, '+62 811-1111-1111');
    });
  });
}
