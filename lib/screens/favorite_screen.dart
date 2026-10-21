import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/currency_service.dart';
import '../services/favorite_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/product_favorite_card.dart';

/// Halaman Favorit Saya JNOVAMUSIC sesuai spesifikasi desain Figma
class FavoriteScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenCart;
  final VoidCallback? onOpenProfile;

  const FavoriteScreen({
    super.key,
    this.onBack,
    this.onOpenCart,
    this.onOpenProfile,
  });

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final FavoriteService _favService = FavoriteService.instance;
  final CartService _cartService = CartService.instance;
  final CurrencyService _currencyService = CurrencyService.instance;

  @override
  void initState() {
    super.initState();
    _favService.addListener(_onServiceUpdate);
    _cartService.addListener(_onServiceUpdate);
    _currencyService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _favService.removeListener(_onServiceUpdate);
    _cartService.removeListener(_onServiceUpdate);
    _currencyService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  /// Menambah produk ke keranjang & feedback
  void _addToCart(Product product) {
    _cartService.addToCart(product);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang.'),
        backgroundColor: AppColors.darkGrey,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Lihat',
          textColor: AppColors.primaryOrange,
          onPressed: () {
            widget.onOpenCart?.call();
          },
        ),
      ),
    );
  }

  /// Dialog konfirmasi Hapus Semua
  Future<void> _confirmClearAll() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Favorit?'),
        content: const Text(
          'Seluruh produk yang tersimpan di daftar favorit akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _favService.clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _favService.items;
    final int cartCount = _cartService.items.length;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // A. Header
            _buildHeader(cartCount),

            // Konten Scrollable
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          // B. Filter dan Aksi
                          _buildFilterBar(items.length),

                          const SizedBox(height: 14),

                          // C. Grid Produk Favorit (2 Kolom)
                          _buildProductGrid(items),

                          const SizedBox(height: 16),

                          // E. Informasi Pengiriman
                          _buildShippingInfoCard(),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),

            // Bottom Navigation
            AppBottomNav(
              currentIndex: 0,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else if (index == 1) {
                  Navigator.pushNamed(context, '/all-products');
                } else if (index == 2) {
                  Navigator.pushNamed(context, '/membership');
                } else if (index == 3) {
                  Navigator.pushNamed(context, '/order-detail');
                } else if (index == 4) {
                  if (widget.onOpenProfile != null) {
                    widget.onOpenProfile!();
                  } else {
                    Navigator.pushNamed(context, '/profile');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Header Favorit Saya
  Widget _buildHeader(int cartCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: Row(
        children: [
          // Tombol Kembali
          InkWell(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back,
                size: 22,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Judul dan Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text(
                  'Favorit Saya',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Produk pilihan yang kamu simpan.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondaryBrown,
                  ),
                ),
              ],
            ),
          ),

          // Ikon Keranjang dengan Badge
          GestureDetector(
            onTap: widget.onOpenCart,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 22,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 0,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$cartCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Ikon Profil Cokelat
          GestureDetector(
            onTap: () {
              if (widget.onOpenProfile != null) {
                widget.onOpenProfile!();
              } else {
                Navigator.pushNamed(context, '/profile');
              }
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF8D4315),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Baris filter & aksi
  Widget _buildFilterBar(int totalCount) {
    return Row(
      children: [
        // Badge jumlah produk
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$totalCount produk tersimpan',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Dropdown Pengurutan
        PopupMenuButton<String>(
          initialValue: _favService.currentSort,
          onSelected: (sort) => _favService.setSort(sort),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _favService.currentSort,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: AppColors.textPrimaryDark,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Terbaru', child: Text('Terbaru')),
            const PopupMenuItem(
              value: 'Harga Terendah',
              child: Text('Harga Terendah'),
            ),
            const PopupMenuItem(
              value: 'Harga Tertinggi',
              child: Text('Harga Tertinggi'),
            ),
            const PopupMenuItem(
              value: 'Rating Tertinggi',
              child: Text('Rating Tertinggi'),
            ),
          ],
        ),
        const SizedBox(width: 8),

        // Tombol Hapus Semua
        GestureDetector(
          onTap: _confirmClearAll,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Text(
              'Hapus Semua',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6E6560),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Grid 2 Kolom Produk Favorit
  Widget _buildProductGrid(List<Product> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        mainAxisExtent: 295,
      ),
      itemBuilder: (context, index) {
        final product = items[index];
        return ProductFavoriteCard(
          product: product,
          isFavorite: _favService.isFavorite(product.id),
          onTap: () {
            Navigator.pushNamed(context, '/product-detail', arguments: product);
          },
          onToggleFavorite: () => _favService.toggleFavorite(product),
          onAddToCart: () => _addToCart(product),
        );
      },
    );
  }

  /// Kartu Informasi Pengiriman Cepat & Aman
  Widget _buildShippingInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Ikon Truk Oranye dalam lingkaran krem
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFECE0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.primaryOrange,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),

          // Teks Pengiriman
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengiriman Cepat & Aman',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Packing kayu & asuransi resmi ke seluruh Indonesia.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7E756F),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state jika belum ada produk favorit
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 36,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Produk Favorit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Simpan produk alat musik yang kamu sukai agar mudah ditemukan kembali.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7E756F),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _favService.setSort('Terbaru');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Jelajahi Produk',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
