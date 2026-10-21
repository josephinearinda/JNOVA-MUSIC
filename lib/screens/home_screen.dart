import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/currency_service.dart';
import '../services/favorite_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/product_favorite_card.dart';

/// Halaman Beranda (Dashboard) JNOVAMUSIC
/// Sesuai referensi visual resmi JNOVAMUSIC dengan Banner JNOVA GAMES,
/// Banner Membership, Kategori, Produk Pilihan, dan Bottom Navigasi.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CartService _cartService = CartService.instance;
  final FavoriteService _favService = FavoriteService.instance;
  final CurrencyService _currencyService = CurrencyService.instance;

  final List<_CategoryItem> _categories = const [
    _CategoryItem(name: 'Gitar', icon: Icons.music_note_rounded),
    _CategoryItem(name: 'Drum', icon: Icons.album_rounded),
    _CategoryItem(name: 'Bass', icon: Icons.straighten_rounded),
    _CategoryItem(name: 'Piano', icon: Icons.grid_view_rounded),
    _CategoryItem(name: 'Audio', icon: Icons.headphones_rounded),
    _CategoryItem(name: 'Aksesoris', icon: Icons.build_rounded),
    _CategoryItem(name: 'Biola', icon: Icons.gesture_rounded),
    _CategoryItem(name: 'Saxophone', icon: Icons.air_rounded),
    _CategoryItem(name: 'Amplifier', icon: Icons.speaker_rounded),
    _CategoryItem(name: 'Kabel Jack', icon: Icons.cable_rounded),
    _CategoryItem(name: 'Efek & Pedal', icon: Icons.tune_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_onServiceUpdate);
    _favService.addListener(_onServiceUpdate);
    _currencyService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _cartService.removeListener(_onServiceUpdate);
    _favService.removeListener(_onServiceUpdate);
    _currencyService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _addToCart(Product product) {
    _cartService.addToCart(product);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang.'),
        backgroundColor: const Color(0xFF2E2E2E),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Lihat',
          textColor: const Color(0xFFFF5500),
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = _cartService.items.length;
    final favCount = _favService.items.length;
    final products = Product.initialProducts;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Utama Beranda
            _buildHeader(cartCount, favCount),

            // 2. Konten Scrollable Beranda
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Banner VIP Member
                    _buildMembershipBanner(),

                    const SizedBox(height: 14),

                    // Search Bar
                    _buildSearchBar(),

                    const SizedBox(height: 18),

                    // Jelajahi Kategori
                    _buildCategorySection(),

                    const SizedBox(height: 18),

                    // Banner Game JNOVA GAMES
                    _buildGamesBanner(),

                    const SizedBox(height: 20),

                    // Produk Pilihan
                    _buildProductsSection(products),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0, // Beranda aktif
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/all-products');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/membership');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/order-detail');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

  /// Header Beranda dengan Logo dan Badge Favorit & Keranjang
  Widget _buildHeader(int cartCount, int favCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F0ED), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Logo Orange Equalizer
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5500),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildWaveBar(height: 6),
                  const SizedBox(width: 2),
                  _buildWaveBar(height: 12),
                  const SizedBox(width: 2),
                  _buildWaveBar(height: 18),
                  const SizedBox(width: 2),
                  _buildWaveBar(height: 12),
                  const SizedBox(width: 2),
                  _buildWaveBar(height: 6),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Teks Brand
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'JNÓVAMUSIC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'TOKO ALAT MUSIK RESMI',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF757575),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Ikon Favorit dengan Badge
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/favorite'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(7.0),
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    size: 22,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
                if (favCount > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5500),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: Text(
                        '$favCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Ikon Keranjang dengan Badge
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/cart'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(7.0),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 22,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
                if (cartCount > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5500),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: Text(
                        '$cartCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Banner VIP Membership Promo
  Widget _buildMembershipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9F5), Color(0xFFFDEEE3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE2CF), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text('👑', style: TextStyle(fontSize: 9.5)),
                    SizedBox(width: 4),
                    Text(
                      'VIP MEMBER',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF5500),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: Color(0xFFFF5500)),
                  SizedBox(width: 3),
                  Text(
                    'Eksklusif',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF5500),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'JNOVAMUSIC Membership',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Nikmati keuntungan khusus untuk member.',
            style: TextStyle(fontSize: 11, color: Color(0xFF7E7E7E)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/membership'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Lihat Keuntungan Member',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF5500),
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Color(0xFFFF5500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/membership'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8D8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Daftar Gratis',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF5500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Search Bar interaktif
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/search'),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEBEBEB), width: 1.0),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, size: 19, color: Color(0xFF9E9E9E)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cari alat musik favoritmu...',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Color(0xFFA8A8A8)),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.tune_rounded, size: 17, color: Color(0xFF757575)),
          ],
        ),
      ),
    );
  }

  /// Bagian Kategori Alat Musik
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jelajahi Kategori',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Pilihan lengkap instrumen & perlengkapan audio',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/all-products'),
              child: const Text(
                'Lihat Semua >',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF5500),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Grid Kategori (3 & 4 kolom rapi)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/all-products'),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF2F0ED),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF4EC),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        cat.icon,
                        color: const Color(0xFFFF5500),
                        size: 19,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Banner Game Resmi: JNOVA GAMES (Navigasi langsung ke Game)
  Widget _buildGamesBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1612), Color(0xFF2E1F18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5500),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_esports_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'GAME RITME RESMI',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 11, color: Color(0xFFFFB088)),
                  SizedBox(width: 3),
                  Text(
                    'Audio Beats',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFB088),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JNOVA GAMES',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ikuti irama. Pecahkan skor\ntertinggi!',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFFD6CBC4),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Main Sekarang
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/games'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5500),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44FF5500),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'MAIN SEKARANG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bagian Produk Pilihan (2 Kolom)
  Widget _buildProductsSection(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produk Pilihan',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Instrumen original bergaransi resmi distributor',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/all-products'),
              child: const Text(
                'Semua Produk >',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF5500),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            mainAxisExtent: 295,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            final isFav = _favService.isFavorite(product.id);

            return ProductFavoriteCard(
              product: product,
              isFavorite: isFav,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/product-detail',
                  arguments: product,
                );
              },
              onToggleFavorite: () => _favService.toggleFavorite(product),
              onAddToCart: () => _addToCart(product),
            );
          },
        ),
      ],
    );
  }

  /// Satu batang equalizer logo soundwave
  Widget _buildWaveBar({required double height}) {
    return Container(
      width: 2.0,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

class _CategoryItem {
  final String name;
  final IconData icon;

  const _CategoryItem({required this.name, required this.icon});
}
