import 'package:flutter/material.dart';

import 'package:jnova/core/constants/app_colors.dart';
import 'package:jnova/core/utils/currency_formatter.dart';
import 'package:jnova/models/product.dart';
import 'package:jnova/services/cart_service.dart';
import 'package:jnova/services/currency_service.dart';
import 'package:jnova/services/favorite_service.dart';
import 'package:jnova/services/membership_service.dart';
import 'package:jnova/services/blockchain_certificate_service.dart';
import 'package:jnova/services/product_stock_service.dart';
import 'package:jnova/widgets/app_bottom_nav.dart';
import 'package:jnova/screens/certificate/certificate_detail_screen.dart';

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
  final ProductStockService _stockService = ProductStockService.instance;

  int _selectedThumbIndex = 0;
  int _quantity = 1;
  late String _selectedColor;
  bool _isDescriptionExpanded = false;

  int get currentStock => _stockService.getStock(
    widget.product.id,
    defaultStock: widget.product.stock,
  );

  bool get isOutOfStock => currentStock <= 0;

  List<Map<String, String>> get _thumbnails {
    if (widget.product.id.startsWith('catalog_')) {
      return [
        {'title': 'PRODUK', 'image': widget.product.image},
      ];
    }
    return [
      {'title': 'FRONT', 'image': 'assets/images/thumb_front.png'},
      {'title': 'BACK', 'image': 'assets/images/thumb_back.png'},
      {'title': 'HEADSTOCK', 'image': 'assets/images/thumb_headstock.png'},
      {'title': 'PICKUPS', 'image': 'assets/images/thumb_pickups.png'},
    ];
  }

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.product.colorVariants.isNotEmpty
        ? widget.product.colorVariants.first
        : '';
    _cartService.addListener(_handleStateChanged);
    _favoriteService.addListener(_handleStateChanged);
    _currencyService.addListener(_handleStateChanged);
    _stockService.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    _cartService.removeListener(_handleStateChanged);
    _favoriteService.removeListener(_handleStateChanged);
    _currencyService.removeListener(_handleStateChanged);
    _stockService.removeListener(_handleStateChanged);
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) {
      if (currentStock > 0 && _quantity > currentStock) {
        _quantity = currentStock;
      }
      setState(() {});
    }
  }

  void _incrementQuantity() {
    if (isOutOfStock) return;
    if (_quantity < currentStock) {
      setState(() {
        _quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batas maksimum pembelian adalah $currentStock unit.'),
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
    if (isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maaf, stok produk ini sedang habis.'),
          backgroundColor: AppColors.textPrimaryDark, // Warna latar pesan pemberitahuan pada bagian komponen ini
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _cartService.addToCart(
      widget.product.copyWith(stock: currentStock),
      quantity: _quantity,
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$_quantity unit ${widget.product.name} berhasil ditambahkan ke keranjang.',
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor:
            AppColors.textPrimaryDark, // Warna teks pada "Buka Keranjang"
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Buka Keranjang',
          textColor:
              AppColors.primaryOrange, // Warna visual pada bagian komponen ini
          onPressed: _handleOpenCart,
        ),
      ),
    );
  }

  void _handleBuyNow() {
    if (isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maaf, produk ini sedang habis terjual.'),
          backgroundColor: AppColors.textPrimaryDark, // Warna latar pesan pemberitahuan pada bagian komponen ini
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _cartService.addToCart(
      widget.product.copyWith(stock: currentStock),
      quantity: _quantity,
    );
    _handleOpenCart();
  }

  void _handleOpenCart() {
    if (!mounted) return;
    if (widget.onOpenCart != null) {
      widget.onOpenCart!();
    } else {
      Navigator.pushNamed(context, '/cart');
    }
  }

  void _handleOpenSearch() {
    if (!mounted) return;
    if (widget.onOpenSearch != null) {
      widget.onOpenSearch!();
    } else {
      Navigator.pushNamed(context, '/search');
    }
  }

  void _handleBack() {
    if (!mounted) return;
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
      backgroundColor:
          AppColors.white, // Warna latar kotak untuk "/all-products"
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
                          color: AppColors.textPrimaryDark, // Warna teks pada "${product.name} - ${product.variant}"
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
                    _buildStockAlert(currentStock),

                    const SizedBox(height: 14),

                    // Keuntungan Membership (Silver Member 10%)
                    _buildMembershipCard(discountAmount, rewardPoints),

                    // Jaminan Keaslian Blockchain (Khusus Kategori Instrumen > 6 Jt)
                    if (product.hasBlockchainCertificate) ...[
                      const SizedBox(height: 14),
                      _buildBlockchainGuaranteeCard(product),
                    ],

                    const SizedBox(height: 16),

                    // Pilihan Warna Body
                    if (widget.product.colorVariants.isNotEmpty)
                      _buildColorVariants(),

                    const SizedBox(height: 16),

                    // Jumlah Pembelian Stepper
                    _buildQuantityStepper(currentStock),

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
        color: AppColors.white, // Warna border atau garis tepi untuk "/profile"
        border: Border(
          bottom: BorderSide(
            color: Color(
              0xFFF2F0ED,
            ), // Warna border atau garis tepi untuk "/profile"
            width: 1.0,
          ),
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
                color: AppColors
                    .textPrimaryDark, // Warna ikon ikon untuk "Beranda"
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
              color: AppColors.textPrimaryDark, // Warna teks pada "Beranda"
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
                color: AppColors.textPrimaryDark, // Warna ikon ikon pada bagian komponen ini
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
                    color: AppColors.textPrimaryDark, // Warna ikon ikon pada bagian komponen ini
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: -4,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOrange, // Warna latar kotak atau kartu untuk "$cartCount"
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
                            color: Colors.white, // Warna teks pada "$cartCount"
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
                color: Color(0xFFB45309), // Warna ikon ikon untuk "/profile"
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: Colors.white, // Warna ikon ikon untuk "/profile"
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
              color: const Color(
                0xFFF7F6F4,
              ), // Warna border atau garis tepi bagian komponen ini
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(
                  0xFFECEAE6,
                ), // Warna border atau garis tepi bagian komponen ini
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 10,
                  color: Color(0xFF6E6560), // Warna ikon ikon untuk "Katalog ${widget.product.category}"
                ),
                const SizedBox(width: 4),
                Text(
                  'Katalog ${widget.product.category}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(
                      0xFF6E6560,
                    ), // Warna teks pada "Katalog ${widget.product.category}"
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
              color: const Color(0xFFF7F6F4), // Warna border atau garis tepi untuk "Katalog ${widget.product.category}"
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFECEAE6), // Warna border atau garis tepi untuk "Katalog ${widget.product.category}"
                width: 1.0,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 12,
                  color: AppColors
                      .primaryOrange, // Warna ikon ikon untuk "Official Store"
                ),
                SizedBox(width: 4),
                Text(
                  'Official Store',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(
                      0xFF6E6560,
                    ), // Warna teks pada "Official Store"
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
                color: AppColors
                    .primaryOrange, // Warna ikon ikon pada bagian komponen ini
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
        color: const Color(
          0xFFFAF9F7,
        ), // Warna border atau garis tepi bagian komponen ini
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(
            0xFFEBE8E3,
          ), // Warna border atau garis tepi untuk "image"
          width: 1.0,
        ),
      ),
      child: Stack(
        children: [
          // Foto Utama Produk
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(
                _thumbnails[_selectedThumbIndex]['image'] ?? product.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  product.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported_rounded,
                    size: 48,
                    color:
                        AppColors.placeholder, // Warna ikon ikon untuk "image"
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
                  color: AppColors.primaryOrange, // Warna teks pada "ORIGINAL"
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ORIGINAL',
                  style: TextStyle(
                    color: Colors.white, // Warna teks pada "ORIGINAL"
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
              color: Colors.white, // Warna visual pada bagian komponen ini
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Colors.black.withValues(
                // Warna visual pada bagian komponen ini

                alpha: 0.1,
              ),
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
                    color:
                        AppColors.primaryOrange, // Warna ikon ikon untuk "1/4"
                  ),
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
                color: Colors.black.withValues(
                  // Warna latar kotak atau kartu untuk "1/4"

                  alpha: 0.55,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedThumbIndex + 1}/${_thumbnails.length}',
                style: const TextStyle(
                  color: Colors.white, // Warna teks pada "${_selectedThumbIndex + 1}/${_thumb..."
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

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 3.0,
                right: index == _thumbnails.length - 1 ? 0 : 3.0,
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedThumbIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF7F6F4,
                    ), // Warna border atau garis tepi bagian komponen ini
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors
                                .primaryOrange // Warna border atau garis tepi untuk "image"
                          : const Color(
                              0xFFEBE8E3,
                            ), // Warna border atau garis tepi untuk "image"
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
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.photo_size_select_actual_outlined,
                                  size: 20,
                                  color: AppColors.placeholder, // Warna ikon ikon untuk "image"
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
                                ? AppColors
                                      .primaryOrange // Warna teks pada "title"
                                : const Color(
                                    0xFF6E6560,
                                  ), // Warna teks pada "title"
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
        children: [
          Expanded(
            child: Text(
              '${product.brand.toUpperCase()} • ${product.category.toUpperCase()}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Color(
                  0xFF8E837D,
                ), // Warna teks pada "${product.brand.toUpperCase()} • ${..."
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (product.hasBlockchainCertificate) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E162E), // Warna border atau garis tepi untuk "${product.brand.toUpperCase()} • ${..."
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF9E86FF), // Warna border atau garis tepi untuk "${product.brand.toUpperCase()} • ${..."
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 10,
                    color: Color(
                      0xFFD6C7FF,
                    ), // Warna ikon ikon untuk "ON-CHAIN"
                  ),
                  SizedBox(width: 3),
                  Text(
                    'ON-CHAIN',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD6C7FF), // Warna teks pada "ON-CHAIN"
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F4), // Warna border atau garis tepi untuk "Kode : ${product.code}"
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFEBE8E3), // Warna border atau garis tepi untuk "Kode : ${product.code}"
                  width: 1.0,
                ),
              ),
              child: Text(
                'Kode : ${product.code}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(
                    0xFF6E6560,
                  ), // Warna teks pada "Kode : ${product.code}"
                ),
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
          if (product.reviewCount > 0) ...[
            const Icon(
              Icons.star_rounded,
              size: 15,
              color: AppColors.primaryOrange, // Warna ikon ikon untuk "(${product.reviewCount} Pembeli Ter..."
            ),
            const SizedBox(width: 3),
            Text(
              product.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark, // Warna teks pada "(${product.reviewCount} Pembeli Ter..."
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '(${product.reviewCount} Pembeli Terverifikasi)',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted, // Warna teks pada "(${product.reviewCount} Pembeli Ter..."
                ),
              ),
            ),
          ] else
            const Text(
              'Belum ada ulasan',
              style: TextStyle(
                fontSize: 10.5,
                color:
                    AppColors.textMuted, // Warna teks pada "Belum ada ulasan"
              ),
            ),
          if (!product.id.startsWith('catalog_')) ...[
            const SizedBox(width: 8),
            const Text(
              '•',
              style: TextStyle(
                color: Color(0xFFCCC8C4), // Warna teks pada "catalog_"
              ),
            ),
            const SizedBox(width: 8),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: AppColors
                      .primaryOrange, // Warna ikon ikon untuk "Terjual 120+"
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
                onPressed: isOutOfStock ? null : _handleAddToCart,
                style: OutlinedButton.styleFrom(
                  backgroundColor: isOutOfStock
                      ? const Color(
                          0xFFF3F4F6,
                        ) // Warna border atau garis tepi tombol
                      : const Color(
                          0xFFFFF7ED,
                        ), // Warna border atau garis tepi tombol
                  side: BorderSide(
                    color: isOutOfStock
                        ? const Color(
                            0xFFE5E7EB,
                          ) // Warna border atau garis tepi tombol
                        : AppColors.primaryOrange, // Warna border atau garis tepi tombol
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOutOfStock
                          ? Icons.remove_shopping_cart_rounded
                          : Icons.shopping_bag_outlined,
                      size: 16,
                      color: isOutOfStock
                          ? const Color(
                              0xFF9CA3AF,
                            ) // Warna ikon ikon untuk "Stok Habis"
                          : AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOutOfStock ? 'Stok Habis' : '+ Keranjang',
                      style: TextStyle(
                        color: isOutOfStock
                            ? const Color(
                                0xFF9CA3AF,
                              ) // Warna teks pada "Stok Habis"
                            : AppColors.primaryOrange, // Warna teks pada "Stok Habis"
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
                onPressed: isOutOfStock ? null : _handleBuyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock
                      ? const Color(0xFFE5E7EB) // Warna visual pada tombol
                      : AppColors.primaryOrange, // Warna visual pada tombol
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flash_on_rounded,
                      size: 16,
                      color: isOutOfStock
                          ? const Color(
                              0xFF9CA3AF,
                            ) // Warna ikon ikon untuk "Habis Terjual"
                          : Colors
                                .white, // Warna ikon ikon untuk "Habis Terjual"
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOutOfStock ? 'Habis Terjual' : 'Beli Sekarang',
                      style: TextStyle(
                        color: isOutOfStock
                            ? const Color(
                                0xFF9CA3AF,
                              ) // Warna teks pada "Habis Terjual"
                            : Colors.white, // Warna teks pada "Habis Terjual"
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
    final isOut = stock <= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isOut
              ? const Color(
                  0xFFFEF2F2,
                ) // Warna latar kotak atau kartu pada bagian komponen ini
              : const Color(
                  0xFFFFF7ED,
                ), // Warna border atau garis tepi bagian komponen ini
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOut
                ? const Color(
                    0xFFFECACA,
                  ) // Warna border atau garis tepi bagian komponen ini
                : const Color(
                    0xFFFFEDD5,
                  ), // Warna border atau garis tepi bagian komponen ini
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOut
                    ? const Color(0xFFDC2626) // Warna latar kotak atau kartu untuk "Stok Habis (0 Unit Tersedia)"
                    : AppColors.primaryOrange, // Warna latar kotak atau kartu untuk "Stok Habis (0 Unit Tersedia)"
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOut
                  ? 'Stok Habis (0 Unit Tersedia)'
                  : 'Stok : $stock Unit Terakhir',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isOut
                    ? const Color(
                        0xFFB91C1C,
                      ) // Warna teks pada "Stok : $stock Unit Terakhir"
                    : const Color(0xFFB45309), // Warna area atau kotak untuk "Stok : $stock Unit Terakhir"
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
        color: const Color(
          0xFFF9F8F6,
        ), // Warna border atau garis tepi untuk "Stok : $stock Unit Terakhir"
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(
            0xFFEBE8E3,
          ), // Warna border atau garis tepi untuk "Stok : $stock Unit Terakhir"
          width: 1.0,
        ),
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
                  color: const Color(
                    0xFFFFEDDF,
                  ), // Warna ikon ikon untuk "Stok : $stock Unit Terakhir"
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  size: 20,
                  color: AppColors.primaryOrange, // Warna ikon ikon untuk "Stok : $stock Unit Terakhir"
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keuntungan Membership',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark, // Warna teks pada "Keuntungan Membership"
                      ),
                    ),
                    Text(
                      '${MembershipService.instance.tierName} Terdeteksi',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted, // Warna ikon ikon untuk "${MembershipService.instance.tierNa..."
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF8E837D), // Warna ikon ikon untuk "${MembershipService.instance.tierNa..."
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 11,
                color: Color(
                  0xFF5A524D,
                ), // Warna teks pada "Dapatkan Potongan Tambahan"
                height: 1.4,
              ),
              children: MembershipService.instance.discountPercentage > 0
                  ? [
                      const TextSpan(text: 'Dapatkan Potongan Tambahan '),
                      TextSpan(
                        text:
                            '${MembershipService.instance.discountPercentage}% (Hemat ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
                          color: AppColors.primaryOrange, // Warna teks pada "$rewardPoints Poin Reward"
                        ),
                      ),
                      const TextSpan(
                        text: ' untuk pembelian ini. Kumpulkan poin menuju Gold untuk gratis ongkir se-Indonesia!',
                      ),
                    ]
                  : [
                      const TextSpan(text: 'Dapatkan '),
                      TextSpan(
                        text: '$rewardPoints Poin Reward',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryOrange, // Warna teks pada "$rewardPoints Poin Reward"
                        ),
                      ),
                      TextSpan(
                        text:
                            ' dari pembelian ini. Kumpulkan ${(1000 - MembershipService.instance.currentPoints).clamp(0, 1000)} poin lagi untuk naik ke Silver Member dan nikmati diskon 10%!',
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/games');
                  },
                  child: const Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Pelajari Semua Tier Membership',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryDark, // Warna ikon ikon untuk "Pelajari Semua Tier Membership"
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: AppColors.textPrimaryDark, // Warna ikon ikon untuk "Pelajari Semua Tier Membership"
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBE7), // Warna latar kotak atau kartu untuk "Pelajari Semua Tier Membership"
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Color(
                        0xFF5A524D,
                      ), // Warna ikon ikon untuk "Otomatis Terpasang"
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Otomatis Terpasang',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(
                          0xFF5A524D,
                        ), // Warna teks pada "Otomatis Terpasang"
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
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildColorSwatchChip(
                name: 'Sunburst',
                dotColor: const Color(
                  0xFF8B4513,
                ), // Warna visual pada bagian komponen ini
              ),
              _buildColorSwatchChip(
                name: 'Polar White',
                dotColor: const Color(
                  0xFFF5F5F5,
                ), // Warna visual pada bagian komponen ini
                hasBorder: true,
              ),
              _buildColorSwatchChip(
                name: 'Aquatone Blue',
                dotColor: const Color(
                  0xFF0284C7,
                ), // Warna visual pada bagian komponen ini
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
          color: const Color(
            0xFFF7F6F4,
          ), // Warna border atau garis tepi bagian komponen ini
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors
                      .primaryOrange // Warna border atau garis tepi bagian komponen ini
                : const Color(
                    0xFFEBE8E3,
                  ), // Warna border atau garis tepi bagian komponen ini
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
                    ? Border.all(
                        color: const Color(
                          0xFFD4D0C8,
                        ), // Warna border atau garis tepi bagian komponen ini
                        width: 1.0,
                      )
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
                    ? AppColors
                          .textPrimaryDark // Warna teks pada bagian komponen ini
                    : const Color(
                        0xFF6E6560,
                      ), // Warna teks pada bagian komponen ini
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(int stock) {
    final isOut = stock <= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
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
                  isOut
                      ? 'Stok saat ini sedang habis'
                      : 'Maksimal $stock unit per akun member',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted, // Warna teks pada "Maksimal $stock unit per akun member"
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Stepper Box
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F4), // Warna border atau garis tepi untuk "Maksimal $stock unit per akun member"
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFEBE8E3), // Warna border atau garis tepi untuk "Maksimal $stock unit per akun member"
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: isOut ? null : _decrementQuantity,
                  icon: const Icon(Icons.remove, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: !isOut && _quantity > 1
                      ? AppColors
                            .textPrimaryDark // Warna visual pada bagian komponen ini
                      : AppColors.placeholder, // Warna teks pada ":"
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    isOut ? '0' : '$_quantity',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isOut
                          ? AppColors
                                .textMuted // Warna teks pada ":"
                          : AppColors
                                .textPrimaryDark, // Warna ikon ikon untuk ":"
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isOut ? null : _incrementQuantity,
                  icon: const Icon(Icons.add, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: !isOut && _quantity < stock
                      ? AppColors
                            .primaryOrange // Warna visual pada bagian komponen ini
                      : AppColors.placeholder, // Warna visual pada bagian komponen ini
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
                  color: AppColors.textPrimaryDark, // Warna ikon ikon untuk "Deskripsi Produk"
                ),
              ),
              Icon(
                Icons.music_note_rounded,
                size: 16,
                color: AppColors
                    .primaryOrange, // Warna ikon ikon untuk "Deskripsi Produk"
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
              color: Color(0xFF5A524D), // Warna teks pada "Deskripsi Produk"
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
                    color: AppColors
                        .primaryOrange, // Warna ikon ikon untuk "Sembunyikan"
                  ),
                ),
                Icon(
                  _isDescriptionExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors
                      .primaryOrange, // Warna ikon ikon untuk "Sembunyikan"
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
                color: AppColors.primaryOrange, // Warna ikon ikon untuk "Spesifikasi Teknis"
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
              border: Border.all(
                color: const Color(
                  0xFFEBE8E3,
                ), // Warna border atau garis tepi bagian komponen ini
                width: 1.0,
              ),
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
                    color: isEven
                        ? const Color(
                            0xFFFAF9F7,
                          ) // Warna border atau garis tepi bagian komponen ini
                        : Colors.white, // Warna border atau garis tepi bagian komponen ini
                    border: index < specs.length - 1
                        ? const Border(
                            bottom: BorderSide(
                              color: Color(0xFFF0EDE9), // Warna border atau garis tepi bagian komponen ini
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
                            color: Color(
                              0xFF7E756F,
                            ), // Warna teks pada bagian komponen ini
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
                            color: AppColors.textPrimaryDark, // Warna teks pada bagian komponen ini
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
        color: const Color(0xFFF9F8F6), // Warna border atau garis tepi kartu
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEBE8E3), // Warna border atau garis tepi kartu
          width: 1.0,
        ),
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
                  color: AppColors.primaryOrange, // Warna ikon ikon pada kartu
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: Colors.white, // Warna ikon ikon untuk "Free Packing Kayu & Asuransi Resmi"
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
                        color: AppColors.textPrimaryDark, // Warna teks pada "Free Packing Kayu & Asuransi Resmi"
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pengiriman cepat dan aman bersertifikasi ekspedisi musik profesional. Jaminan 100% Ganti Baru bila paket mengalami kerusakan selama transit.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF5A524D), // Warna teks pada "Free Packing Kayu & Asuransi Resmi"
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
                color: AppColors
                    .primaryOrange, // Warna ikon ikon untuk "Insured 100%"
              ),
              SizedBox(width: 4),
              Text(
                'Insured 100%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color:
                      AppColors.primaryOrange, // Warna teks pada "Insured 100%"
                ),
              ),
              SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(
                  color: Color(0xFFCCC8C4), // Warna teks pada "Insured 100%"
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Dikirim dari Jakarta Pusat',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(
                    0xFF8E837D,
                  ), // Warna teks pada "Dikirim dari Jakarta Pusat"
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainGuaranteeCard(Product product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white, // Warna border atau garis tepi kartu
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFD1B3), // Warna border atau garis tepi kartu
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(
                      0xFFFF6B00,
                    ) // Warna latar kotak atau kartu pada kartu
                    .withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(
              // Warna bayangan pada kartu

              alpha: 0.03,
            ),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
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
                  color: const Color(
                    0xFFFFF2EB,
                  ), // Warna border atau garis tepi kartu
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(
                      0xFFFFD1B3,
                    ), // Warna ikon ikon pada kartu
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 18,
                  color: Color(0xFFFF6B00), // Warna ikon ikon untuk "Sertifikat Keaslian Blockchain (ERC..."
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sertifikat Keaslian Blockchain (ERC-721)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF222222), // Warna teks pada "Sertifikat Keaslian Blockchain (ERC..."
                      ),
                    ),
                    Text(
                      'Jaminan originalitas permanen di jaringan Polygon',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF777777), // Warna teks pada "Jaminan originalitas permanen di ja..."
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFECFDF5,
                  ), // Warna border atau garis tepi untuk "RESMI"
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFA7F3D0), // Warna teks pada "RESMI"
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'RESMI',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF059669), // Warna teks pada "RESMI"
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pembelian instrumen ini dilengkapi NFT Sertifikat Keaslian resmi di blockchain Polygon dengan nomor seri unik.',
            style: TextStyle(
              fontSize: 10.5,
              color: Color(0xFF555555), // Warna teks pada "RESMI"
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              final cert = BlockchainCertificateService.instance
                  .getCertificateForProduct(product);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlockchainCertificatePage(
                    certificate: cert,
                    isPreview: true,
                  ),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility_rounded,
                  size: 14,
                  color: Color(0xFFFF6B00), // Warna ikon ikon untuk "Pratinjau Sertifikat Keaslian Digital"
                ),
                SizedBox(width: 6),
                Text(
                  'Pratinjau Sertifikat Keaslian Digital',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF6B00), // Warna ikon ikon untuk "Pratinjau Sertifikat Keaslian Digital"
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: Color(0xFFFF6B00), // Warna ikon ikon untuk "Pratinjau Sertifikat Keaslian Digital"
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
