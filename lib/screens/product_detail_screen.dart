import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/currency_service.dart';
import '../services/favorite_service.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman DETAIL PRODUK JNOVAMUSIC sesuai desain Figma 6
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final VoidCallback? onBack;
  final VoidCallback? onOpenCart;
  final VoidCallback? onOpenSearch;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.onBack,
    this.onOpenCart,
    this.onOpenSearch,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = CartService.instance;
  final FavoriteService _favoriteService = FavoriteService.instance;
  final CurrencyService _currencyService = CurrencyService.instance;

  int _selectedThumbIndex = 0;
  int _quantity = 1;
  late String _selectedColor;
  bool _isDescriptionExpanded = false;

  final List<Map<String, String>> _thumbnails = [
    {'title': 'FRONT', 'image': 'assets/images/thumb_front.png'},
    {'title': 'BACK', 'image': 'assets/images/thumb_back.png'},
    {'title': 'HEADSTOCK', 'image': 'assets/images/thumb_headstock.png'},
    {'title': 'PICKUPS', 'image': 'assets/images/thumb_pickups.png'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.product.colorVariants.isNotEmpty
        ? widget.product.colorVariants.first
        : '3-Color Sunburst';
    _cartService.addListener(_handleStateChanged);
    _favoriteService.addListener(_handleStateChanged);
    _currencyService.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    _cartService.removeListener(_handleStateChanged);
    _favoriteService.removeListener(_handleStateChanged);
    _currencyService.removeListener(_handleStateChanged);
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

  void _incrementQuantity() {
    if (_quantity < widget.product.stock) {
      setState(() {
        _quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Batas maksimum pembelian adalah ${widget.product.stock} unit.',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _handleAddToCart() {
    _cartService.addToCart(widget.product, quantity: _quantity);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$_quantity unit ${widget.product.name} berhasil ditambahkan ke keranjang.',
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: AppColors.textPrimaryDark,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Buka Keranjang',
          textColor: AppColors.primaryOrange,
          onPressed: _handleOpenCart,
        ),
      ),
    );
  }

  void _handleBuyNow() {
    _cartService.addToCart(widget.product, quantity: _quantity);
    _handleOpenCart();
  }

  void _handleOpenCart() {
    if (widget.onOpenCart != null) {
      widget.onOpenCart!();
    } else {
      Navigator.pushNamed(context, '/cart');
    }
  }

  void _handleOpenSearch() {
    if (widget.onOpenSearch != null) {
      widget.onOpenSearch!();
    } else {
      Navigator.pushNamed(context, '/search');
    }
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/all-products');
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isFav = _favoriteService.isFavorite(product.id);
    final discountAmount = (product.price * _cartService.discountRate).round();
    final rewardPoints = (product.price / 100000).round();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, Beranda, Search, Cart, Avatar
            _buildHeader(context),

            // Konten Detail Produk yang dapat di-scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subheader: Breadcrumb & Official Store Badge
                    _buildSubHeader(),

                    // Hero Image Gallery
                    _buildHeroGallery(product, isFav),

                    const SizedBox(height: 14),

                    // Thumbnails Selector (FRONT, BACK, HEADSTOCK, PICKUPS)
                    _buildThumbnailsRow(),

                    const SizedBox(height: 14),

                    // Brand & Kode
                    _buildBrandAndCode(product),

                    const SizedBox(height: 6),

                    // Judul Produk
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '${product.name} - ${product.variant}',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                          height: 1.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Harga Produk Utama
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        formatCurrency(product.price),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryOrange,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Rating & Review & Penjualan
                    _buildRatingAndSales(product),

                    const SizedBox(height: 12),

                    // Tombol Aksi (+ Keranjang & Beli Sekarang)
                    _buildActionButtons(),

                    const SizedBox(height: 10),

                    // Status Stok
                    _buildStockAlert(product.stock),

                    const SizedBox(height: 14),

                    // Keuntungan Membership (Silver Member 10%)
                    _buildMembershipCard(discountAmount, rewardPoints),

                    const SizedBox(height: 16),

                    // Pilihan Warna Body
                    _buildColorVariants(),

                    const SizedBox(height: 16),

                    // Jumlah Pembelian Stepper
                    _buildQuantityStepper(product.stock),

                    const SizedBox(height: 18),

                    // Deskripsi Produk
                    _buildProductDescription(product.description),

                    const SizedBox(height: 18),

                    // Spesifikasi Teknis
                    _buildTechnicalSpecs(product.specs),

                    const SizedBox(height: 16),

                    // Kartu Packing Kayu & Asuransi Resmi
                    _buildGuaranteeCard(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0, // Beranda tab sesuai Figma Detail Produk
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/all-products');
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

  Widget _buildHeader(BuildContext context) {
    final cartCount = _cartService.items.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F0ED), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Tombol Kembali
          InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Teks Beranda
          const Text(
            'Beranda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),

          const Spacer(),

          // Ikon Pencarian
          InkWell(
            onTap: _handleOpenSearch,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(
                Icons.search_rounded,
                size: 22,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Ikon Keranjang dengan Badge
          InkWell(
            onTap: _handleOpenCart,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 23,
                    color: AppColors.textPrimaryDark,
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: -4,
                      right: -5,
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
          ),

          const SizedBox(width: 8),

          // Avatar Profil
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFB45309),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          // Breadcrumb Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFECEAE6), width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 10,
                  color: Color(0xFF6E6560),
                ),
                const SizedBox(width: 4),
                Text(
                  'Katalog ${widget.product.category}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6E6560),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Official Store Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFECEAE6), width: 1.0),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 12,
                  color: AppColors.primaryOrange,
                ),
                SizedBox(width: 4),
                Text(
                  'Official Store',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6E6560),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Icon Favorit di subheader
          InkWell(
            onTap: () => _favoriteService.toggleFavorite(widget.product),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                _favoriteService.isFavorite(widget.product.id)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 20,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroGallery(Product product, bool isFav) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Stack(
        children: [
          // Foto Utama Produk
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(
                _selectedThumbIndex < _thumbnails.length
                    ? _thumbnails[_selectedThumbIndex]['image']!
                    : product.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  product.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported_rounded,
                    size: 48,
                    color: AppColors.placeholder,
                  ),
                ),
              ),
            ),
          ),

          // Badge ORIGINAL
          if (product.isOriginal)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ORIGINAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),

          // Tombol Favorit di Hero
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _favoriteService.toggleFavorite(product),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ),
          ),

          // Pill "Lihat 360°"
          Positioned(
            bottom: 12,
            left: 12,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mode Tampilan Interaktif 360° dibuka.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE0DDD8),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.threesixty_rounded,
                      size: 14,
                      color: AppColors.primaryOrange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Lihat 360°',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pill Page Indicator "1/4"
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedThumbIndex + 1}/${_thumbnails.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_thumbnails.length, (index) {
          final isSelected = _selectedThumbIndex == index;
          final thumb = _thumbnails[index];

          return InkWell(
            onTap: () {
              setState(() {
                _selectedThumbIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 76,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryOrange
                      : const Color(0xFFEBE8E3),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        thumb['image']!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.photo_size_select_actual_outlined,
                              size: 20,
                              color: AppColors.placeholder,
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    left: 0,
                    right: 0,
                    child: Text(
                      thumb['title']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: isSelected
                            ? AppColors.primaryOrange
                            : const Color(0xFF6E6560),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBrandAndCode(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${product.brand.toUpperCase()} GUITARS • USA HERITAGE',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF8E837D),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
            ),
            child: Text(
              'Kode : ${product.code}',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6E6560),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingAndSales(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Icon(
            Icons.star_rounded,
            size: 15,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 3),
          Text(
            product.rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${product.reviewCount} Pembeli Terverifikasi)',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          const Text('•', style: TextStyle(color: Color(0xFFCCC8C4))),
          const SizedBox(width: 8),
          const Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 14,
                color: AppColors.primaryOrange,
              ),
              SizedBox(width: 2),
              Text(
                'Terjual 120+',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Tombol + Keranjang
          Expanded(
            child: SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: _handleAddToCart,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF7ED),
                  side: const BorderSide(
                    color: AppColors.primaryOrange,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 16,
                      color: AppColors.primaryOrange,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '+ Keranjang',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Tombol Beli Sekarang
          Expanded(
            child: SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: _handleBuyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Beli Sekarang',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockAlert(int stock) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFEDD5), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Stok : $stock Unit Terakhir',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard(int discountAmount, int rewardPoints) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDDF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  size: 20,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keuntungan Membership',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      'Silver Member Terdeteksi',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF8E837D),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF5A524D),
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Dapatkan Potongan Tambahan '),
                const TextSpan(
                  text: '10% (Hemat ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '${formatRupiah(discountAmount)})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' serta poin '),
                TextSpan(
                  text: '$rewardPoints Poin Reward',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const TextSpan(
                  text: ' untuk pembelian ini. Kumpulkan poin menuju Gold untuk gratis ongkir se-Indonesia!',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/games');
                },
                child: const Row(
                  children: [
                    Text(
                      'Pelajari Semua Tier Membership',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: AppColors.textPrimaryDark,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Color(0xFF5A524D),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Otomatis Terpasang',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5A524D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorVariants() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilihan Warna Body',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                _selectedColor,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildColorSwatchChip(
                name: 'Sunburst',
                dotColor: const Color(0xFF8B4513),
              ),
              const SizedBox(width: 10),
              _buildColorSwatchChip(
                name: 'Polar White',
                dotColor: const Color(0xFFF5F5F5),
                hasBorder: true,
              ),
              const SizedBox(width: 10),
              _buildColorSwatchChip(
                name: 'Aquatone Blue',
                dotColor: const Color(0xFF0284C7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatchChip({
    required String name,
    required Color dotColor,
    bool hasBorder = false,
  }) {
    final isSelected = _selectedColor.toLowerCase().contains(
      name.toLowerCase(),
    );

    return InkWell(
      onTap: () {
        setState(() {
          _selectedColor = name;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOrange
                : const Color(0xFFEBE8E3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                border: hasBorder
                    ? Border.all(color: const Color(0xFFD4D0C8), width: 1.0)
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF6E6560),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(int stock) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jumlah Pembelian',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Maksimal $stock unit per akun member',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          // Stepper Box
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _decrementQuantity,
                  icon: const Icon(Icons.remove, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: _quantity > 1
                      ? AppColors.textPrimaryDark
                      : AppColors.placeholder,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _incrementQuantity,
                  icon: const Icon(Icons.add, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: _quantity < stock
                      ? AppColors.textPrimaryDark
                      : AppColors.placeholder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDescription(String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deskripsi Produk',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Icon(
                Icons.music_note_rounded,
                size: 16,
                color: AppColors.primaryOrange,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            maxLines: _isDescriptionExpanded ? null : 3,
            overflow: _isDescriptionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF5A524D),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isDescriptionExpanded ? 'Sembunyikan' : 'Lihat Selengkapnya',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
                Icon(
                  _isDescriptionExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors.primaryOrange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalSpecs(Map<String, String> specs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.primaryOrange,
              ),
              SizedBox(width: 6),
              Text(
                'Spesifikasi Teknis',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
            ),
            child: Column(
              children: specs.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isEven = index % 2 == 0;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isEven ? const Color(0xFFFAF9F7) : Colors.white,
                    border: index < specs.length - 1
                        ? const Border(
                            bottom: BorderSide(
                              color: Color(0xFFF0EDE9),
                              width: 1.0,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          item.key,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7E756F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free Packing Kayu & Asuransi Resmi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pengiriman cepat dan aman bersertifikasi ekspedisi musik profesional. Jaminan 100% Ganti Baru bila paket mengalami kerusakan selama transit.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF5A524D),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.security_rounded,
                size: 13,
                color: AppColors.primaryOrange,
              ),
              SizedBox(width: 4),
              Text(
                'Insured 100%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
              SizedBox(width: 8),
              Text('•', style: TextStyle(color: Color(0xFFCCC8C4))),
              SizedBox(width: 8),
              Text(
                'Dikirim dari Jakarta Pusat',
                style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
