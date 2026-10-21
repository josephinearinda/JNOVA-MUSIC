import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../data/repositories/product_repository.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/currency_service.dart';
import '../services/favorite_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/product_favorite_card.dart';

/// Halaman SEMUA PRODUK JNOVAMUSIC sesuai desain Figma 4
class AllProductsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenCart;
  final VoidCallback? onOpenSearch;
  final ValueChanged<Product>? onSelectProduct;

  const AllProductsScreen({
    super.key,
    this.onBack,
    this.onOpenCart,
    this.onOpenSearch,
    this.onSelectProduct,
  });

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final CartService _cartService = CartService.instance;
  final FavoriteService _favoriteService = FavoriteService.instance;
  final CurrencyService _currencyService = CurrencyService.instance;

  String _selectedCategory = 'Semua';
  String _selectedSort = 'Terpopuler';
  List<Product> _allProducts = Product.allCatalog;

  final List<String> _categories = [
    'Semua',
    'Gitar',
    'Drum',
    'Bass',
    'Piano',
    'Audio',
  ];

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_handleStateChanged);
    _favoriteService.addListener(_handleStateChanged);
    _currencyService.addListener(_handleStateChanged);
    _loadProductsFromRepository();
  }

  Future<void> _loadProductsFromRepository() async {
    try {
      final prods = await ProductRepository.instance.getProducts();
      if (mounted && prods.isNotEmpty) {
        setState(() {
          _allProducts = prods;
        });
      }
    } catch (_) {}
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

  List<Product> _getFilteredProducts() {
    List<Product> list;
    if (_selectedCategory == 'Semua') {
      list = _allProducts.take(12).toList();
    } else {
      list = _allProducts
          .where(
            (p) => p.category.toLowerCase() == _selectedCategory.toLowerCase(),
          )
          .toList();
    }

    switch (_selectedSort) {
      case 'Harga Terendah':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Harga Tertinggi':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating Tertinggi':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Terpopuler':
      default:
        // Urutan standar katalog
        break;
    }

    return list;
  }

  void _handleSelectProduct(Product product) {
    if (widget.onSelectProduct != null) {
      widget.onSelectProduct!(product);
    } else {
      Navigator.pushNamed(context, '/product-detail', arguments: product);
    }
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
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _getFilteredProducts();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, Title & Subtitle, Cart Badge, Avatar
            _buildHeader(context),

            // Konten yang dapat di-scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar yang dapat ditekan untuk membuka pencarian
                    _buildSearchBar(),

                    const SizedBox(height: 12),

                    // Filter Kategori Horizontal
                    _buildCategoryFilter(),

                    const SizedBox(height: 14),

                    // Jumlah Produk & Bar Pengurutan
                    _buildSubHeader(products.length),

                    const SizedBox(height: 10),

                    // Grid 2 Kolom Produk
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.60,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                            ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final isFav = _favoriteService.isFavorite(product.id);

                          return ProductFavoriteCard(
                            product: product,
                            isFavorite: isFav,
                            onTap: () => _handleSelectProduct(product),
                            onToggleFavorite: () {
                              _favoriteService.toggleFavorite(product);
                            },
                            onAddToCart: () {
                              _cartService.addToCart(product);
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.name} berhasil ditambahkan ke keranjang.',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: AppColors.textPrimaryDark,
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: 'Lihat',
                                    textColor: AppColors.primaryOrange,
                                    onPressed: _handleOpenCart,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Informasi Pengiriman Cepat & Aman
                    _buildShippingCard(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1, // Kategori terpilih sesuai Figma Semua Produk
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
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
          const SizedBox(width: 10),

          // Judul & Subtitle
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Semua Produk',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Temukan alat musik yang cocok...',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

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

          // Ikon Profil Bulat
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFB45309), // Oranye kecokelatan sesuai Figma
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleOpenSearch,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F5F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFECEAE6), width: 1.0),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.placeholder,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cari nama alat musik atau merek...',
                    style: TextStyle(
                      color: AppColors.placeholder,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 7.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryOrange
                      : const Color(0xFFF7F6F4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryOrange
                        : const Color(0xFFEBE8E3),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6E6560),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Jumlah produk
          Text(
            'Menampilkan $count Produk',
            style: const TextStyle(
              color: AppColors.textSecondaryBrown,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Filter & Pengurutan
          Row(
            children: [
              InkWell(
                onTap: _showFilterBottomSheet,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: AppColors.textSecondaryBrown,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Filter',
                        style: TextStyle(
                          color: AppColors.textSecondaryBrown,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                initialValue: _selectedSort,
                onSelected: (val) {
                  setState(() {
                    _selectedSort = val;
                  });
                },
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedSort,
                      style: const TextStyle(
                        color: AppColors.textSecondaryBrown,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.textSecondaryBrown,
                    ),
                  ],
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Terpopuler',
                    child: Text('Terpopuler', style: TextStyle(fontSize: 12)),
                  ),
                  const PopupMenuItem(
                    value: 'Harga Terendah',
                    child: Text(
                      'Harga Terendah',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Harga Tertinggi',
                    child: Text(
                      'Harga Tertinggi',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Rating Tertinggi',
                    child: Text(
                      'Rating Tertinggi',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShippingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              size: 20,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengiriman Cepat & Aman',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Packing kayu & asuransi resmi ke seluruh Indonesia.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Produk',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((c) {
                      final isSelected = _selectedCategory == c;
                      return ChoiceChip(
                        label: Text(
                          c,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimaryDark,
                            fontSize: 11.5,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primaryOrange,
                        backgroundColor: const Color(0xFFF6F5F3),
                        onSelected: (val) {
                          setModalState(() {
                            _selectedCategory = c;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
