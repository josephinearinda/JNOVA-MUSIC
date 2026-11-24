import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models/order_model.dart';
import 'models/product.dart';
import 'screens/screens.dart';
import 'models/blockchain_certificate.dart';
import 'models/store_branch.dart';
import 'core/config/app_config.dart';
import 'data/datasources/local/app_database.dart';
import 'data/datasources/remote/supabase_client_service.dart';
import 'services/notification_background_sync_service.dart';
import 'services/notification_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/favorite_service.dart';
import 'services/membership_service.dart';
import 'services/order_service.dart';
import 'services/user_profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Database Factory SQLite untuk desktop (Windows / Linux)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Product.loadCatalogFromAssets();

  // 1. Inisialisasi Environment Variables (.env)
  await AppConfig.initialize();

  // 2. Inisialisasi Supabase SDK jika kredensial tersedia
  await SupabaseClientService.instance.initialize();

  // 3. Inisialisasi Database SQLite Lokal
  await AppDatabase.instance.database;

  // 4. Siapkan notifikasi perangkat sebelum layar aplikasi dimulai.
  await NotificationService.instance.initialize();
  await NotificationBackgroundSyncService.initialize();
  if (SupabaseClientService.instance.isAuthenticated) {
    await NotificationBackgroundSyncService.enable();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'JNOVAMUSIC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF58A45)),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(
          onAnimationFinished: () async {
            final hasSession = await AuthService.instance.hasActiveSession();

            if (hasSession) {
              // Ambil email dari sesi Supabase terlebih dahulu.
              final email =
                  SupabaseClientService.instance.currentUser?.email ??
                  await SecureStorageService.instance.getUserEmail();

              if (email != null && email.isNotEmpty) {
                await UserProfileService.instance.loadProfileForUser(email);
                await MembershipService.instance.loadPointsForUser(email);
                await OrderService.instance.loadOrdersForUser(email);
                await FavoriteService.instance.loadFavoritesForUser(email);
                await CartService.instance.loadCartForUser(email);
              }
            } else {
              UserProfileService.instance.resetProfile();
              MembershipService.instance.resetPoints();
              OrderService.instance.resetOrders();
              FavoriteService.instance.resetFavorites();
              CartService.instance.resetCart();
            }

            if (!context.mounted) return;

            // Arahkan sesuai status autentikasi.
            Navigator.of(context)
                .pushReplacementNamed(hasSession ? '/home' : '/login');

            // Jika aplikasi dibuka dari ketukan notifikasi (misal: pengingat game)
            if (NotificationService.pendingRoute != null) {
              final route = NotificationService.pendingRoute!;
              NotificationService.pendingRoute = null;
              Navigator.of(context).pushNamed(route);
            }
          },
        ),

        '/login': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final initialEmail = args is String ? args : null;
          return LoginScreen(
            initialEmail: initialEmail,
            onLoginSuccess: () {
              Navigator.of(context).pushReplacementNamed('/home');
            },
            onRegisterPressed: () {
              Navigator.of(context).pushNamed('/register');
            },
          );
        },
        '/register': (context) => RegisterScreen(
          onRegisterSuccess: (result) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              result.token != null ? '/home' : '/login',
              (route) => false,
              arguments: result.token == null ? result.email : null,
            );
          },
          onLoginPressed: () {
            Navigator.of(context).pop();
          },
        ),
        '/home': (context) => const HomeScreen(),
        '/favorite': (context) => FavoriteScreen(
          onBack: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
          onOpenCart: () {
            Navigator.pushNamed(context, '/cart');
          },
          onOpenProfile: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        '/cart': (context) => CartScreen(
          onBack: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
          onOpenProfile: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        '/membership': (context) => const MembershipSettingsPage(),
        '/all-products': (context) {
          final category = ModalRoute.of(context)?.settings.arguments;
          return AllProductsScreen(
            initialCategory: category is String && category.trim().isNotEmpty
                ? category
                : 'Semua',
          );
        },
        '/search': (context) => const SearchScreen(),
        '/product-detail': (context) {
          final product =
              ModalRoute.of(context)?.settings.arguments as Product? ??
              Product.allCatalog.first;
          return ProductDetailScreen(product: product);
        },
        '/checkout': (context) {
          final method =
              ModalRoute.of(context)?.settings.arguments
                  as FulfillmentMethod? ??
              FulfillmentMethod.pickup;
          return CheckoutScreen(initialMethod: method);
        },
        '/pickup-detail': (context) => const PickupDetailScreen(),
        '/select-pickup-store': (context) {
          final branch =
              ModalRoute.of(context)?.settings.arguments as StoreBranch? ??
              StoreBranch.branches.first;
          return SelectPickupStorePage(selectedBranch: branch);
        },
        '/order-detail': (context) {
          final order =
              ModalRoute.of(context)?.settings.arguments as OrderModel?;
          if (order != null) {
            return OrderDetailScreen(order: order);
          }
          return const OrderHistoryScreen();
        },
        '/order-history': (context) => const OrderHistoryScreen(),
        '/tracking': (context) => const TrackingScreen(),
        '/games': (context) => const GameSelectionPage(),
        '/game-permission': (context) => const MotionPermissionPage(),
        '/game-home': (context) => const JNovaRhythmHomePage(),
        '/game-play': (context) => const JNovaRhythmGameplayPage(),
        '/game2': (context) => const JNovaDodgeGamePage(),
        '/game-result': (context) {
          final result =
              ModalRoute.of(context)?.settings.arguments as GameResultData?;
          return JNovaRhythmResultPage(resultData: result);
        },
        '/profile': (context) => const ProfileScreen(),
        '/profile-edit': (context) => const EditProfilePage(),
        '/address-edit': (context) => const AddressEditPage(),
        '/notifications': (context) => const NotificationSettingsPage(),
        '/account-security': (context) => const AccountSecurityPage(),
        '/currency-preferences': (context) => const CurrencyPreferencesPage(),
        '/music-preferences': (context) => const MusicPreferencesPage(),
        '/world-clock': (context) => const WorldClockPage(),
        '/membership-settings': (context) => const MembershipSettingsPage(),
        '/point-history': (context) => const PointHistoryPage(),
        '/suggestion-review': (context) => const SuggestionReviewPage(),
        '/ai-chat': (context) => const AIChatPage(),
        '/ai-scanner': (context) => const AIScannerPage(),
        '/blockchain-certificates': (context) => const MyCertificatesScreen(),
        '/blockchain-certificate-detail': (context) {
          final cert =
              ModalRoute.of(context)?.settings.arguments
                  as BlockchainCertificate?;
          if (cert == null) return const MyCertificatesScreen();
          return BlockchainCertificatePage(
            certificate: cert,
            isPreview: !cert.isClaimed,
          );
        },
      },
    );
  }
}

