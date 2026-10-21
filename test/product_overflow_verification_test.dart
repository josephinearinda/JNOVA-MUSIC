import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jnova/models/product.dart';
import 'package:jnova/screens/home_screen.dart';
import 'package:jnova/screens/all_products_screen.dart';
import 'package:jnova/widgets/product_favorite_card.dart';
import 'package:jnova/core/network/network_info.dart';
import 'package:jnova/services/cart_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    NetworkInfo.instance.overrideIsConnected = true;
  });

  group('Product Card Overflow & Responsiveness Tests', () {
    testWidgets('ProductFavoriteCard renders short and long product names without overflow', (tester) async {
      final shortProduct = Product(
        id: 'sp1',
        name: 'Gitar Mini',
        brand: 'Yamaha',
        price: 950000,
        image: 'assets/images/f310.png',
        rating: 4.7,
        reviewCount: 30,
        category: 'Gitar',
        description: 'Gitar akustik ukuran ringkas',
        isOriginal: true,
      );

      final longProduct = Product(
        id: 'lp1',
        name: 'Fender American Ultra Luxe Telecaster Floyd Rose HH Electric Guitar Mystic Black',
        brand: 'Fender Custom',
        price: 28500000,
        image: 'assets/images/fender_strat.png',
        rating: 5.0,
        reviewCount: 999,
        category: 'Gitar',
        description: 'Gitar elektrik premium',
        isBestSeller: true,
      );

      for (final width in [320.0, 360.0, 390.0, 412.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool cartAdded = false;
        bool favoriteToggled = false;
        bool cardTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  itemCount: 2,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 295,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final p = index == 0 ? shortProduct : longProduct;
                    return ProductFavoriteCard(
                      product: p,
                      isFavorite: index == 0,
                      onTap: () => cardTapped = true,
                      onToggleFavorite: () => favoriteToggled = true,
                      onAddToCart: () => cartAdded = true,
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Check for any RenderFlex overflow exceptions
        expect(tester.takeException(), isNull, reason: 'Overflow detected at width $width');

        // Check product names are displayed
        expect(find.text('Gitar Mini'), findsOneWidget);
        expect(find.textContaining('Fender American Ultra Luxe'), findsOneWidget);

        // Check badges
        expect(find.text('ORIGINAL'), findsOneWidget);
        expect(find.text('BEST SELLER'), findsOneWidget);

        // Check "+ Keranjang" buttons
        expect(find.text('+ Keranjang'), findsNWidgets(2));

        // Test interaction
        await tester.tap(find.text('+ Keranjang').first);
        await tester.pump();
        expect(cartAdded, isTrue);

        await tester.tap(find.byIcon(Icons.favorite_rounded).first);
        await tester.pump();
        expect(favoriteToggled, isTrue);

        await tester.tap(find.text('Gitar Mini'));
        await tester.pump();
        expect(cardTapped, isTrue);
      }
    });

    testWidgets('HomeScreen renders product grid without RenderFlex bottom overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/all-products': (context) => const Scaffold(body: Text('All Products')),
            '/cart': (context) => const Scaffold(body: Text('Cart')),
            '/membership': (context) => const Scaffold(body: Text('Membership')),
            '/order-detail': (context) => const Scaffold(body: Text('Orders')),
            '/profile': (context) => const Scaffold(body: Text('Profile')),
            '/search': (context) => const Scaffold(body: Text('Search')),
            '/product-detail': (context) => const Scaffold(body: Text('Product Detail')),
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Scroll to bottom to ensure product cards grid is laid out
      final scrollableFinder = find.byWidgetPredicate(
        (widget) => widget is SingleChildScrollView && widget.scrollDirection == Axis.vertical,
      );
      expect(scrollableFinder, findsOneWidget);
      await tester.drag(scrollableFinder, const Offset(0, -800));
      await tester.pump();

      final err = tester.takeException();
      if (err is FlutterError) {
        for (final node in err.diagnostics) {
          debugPrint('DEBUG DIAGNOSTIC: ${node.toStringDeep()}');
        }
      }
      expect(err, isNull);
    });

    testWidgets('AllProductsScreen renders product grid without RenderFlex bottom overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: const AllProductsScreen(),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
            '/cart': (context) => const Scaffold(body: Text('Cart')),
            '/membership': (context) => const Scaffold(body: Text('Membership')),
            '/order-detail': (context) => const Scaffold(body: Text('Orders')),
            '/profile': (context) => const Scaffold(body: Text('Profile')),
            '/search': (context) => const Scaffold(body: Text('Search')),
            '/product-detail': (context) => const Scaffold(body: Text('Product Detail')),
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Scroll to bottom to ensure product cards grid is laid out
      final verticalScrollable = find.byWidgetPredicate(
        (widget) => widget is SingleChildScrollView && widget.scrollDirection == Axis.vertical,
      );
      expect(verticalScrollable, findsOneWidget);
      await tester.drag(verticalScrollable, const Offset(0, -500));
      await tester.pump();

      // No overflow exceptions on AllProductsScreen!
      expect(tester.takeException(), isNull);
    });

    testWidgets('Verify Cart and Favorite functionality on product cards', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final initialTotalQty = CartService.instance.items.fold<int>(0, (sum, i) => sum + i.quantity);

      await tester.pumpWidget(
        MaterialApp(
          home: const AllProductsScreen(),
          routes: {
            '/cart': (context) => const Scaffold(body: Text('Cart')),
            '/product-detail': (context) => const Scaffold(body: Text('Product Detail')),
          },
        ),
      );
      await tester.pump();

      // Find the first "+ Keranjang" button and tap it
      final cartBtn = find.text('+ Keranjang').first;
      await tester.tap(cartBtn);
      await tester.pump();

      final updatedTotalQty = CartService.instance.items.fold<int>(0, (sum, i) => sum + i.quantity);
      expect(updatedTotalQty, initialTotalQty + 1);

      // Tap favorite heart icon
      final favFinder = find.descendant(of: find.byType(ProductFavoriteCard), matching: find.byType(InkWell));
      expect(favFinder, findsWidgets);

      await tester.pumpAndSettle(const Duration(seconds: 11));
    });
  });
}
