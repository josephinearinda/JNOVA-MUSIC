import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/currency_service.dart';
import '../services/favorite_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/product_favorite_card.dart';

/// Halaman PENCARIAN JNOVAMUSIC sesuai desain Figma 5
class SearchScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenCart;
  final ValueChanged<Product>? onSelectProduct;

  const SearchScreen({
    super.key,
    this.onBack,
    this.onOpenCart,
    this.onSelectProduct,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final CartService _cartService = CartService.instance;
  final FavoriteService _favoriteService = FavoriteService.instance;
  final CurrencyService _currencyService = CurrencyService.instance;
  late final TextEditingController _searchController;

  // Nilai awal: default kosong karena pengguna belum melakukan pencarian
  String _query = '';
  String _selectedCategory = 'Semua';
  String _selectedSort = 'Terpopuler';
  bool _simulateEmptyState = false;

  final List<String> _recentSearches = [];

  final List<String> _popularCategories = [
    'Gitar',
    'Drum',
    'Bass',
    'Piano',
    'Audio',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _query);
    _cartService.addListener(_handleStateChanged);
    _favoriteService.addListener(_handleStateChanged);
    _currencyService.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cartService.removeListener(_handleStateChanged);
    _favoriteService.removeListener(_handleStateChanged);
    _currencyService.removeListener(_handleStateChanged);
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      _simulateEmptyState = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _simulateEmptyState = false;
    });
  }

  void _removeRecentSearch(String item) {
    setState(() {
      _recentSearches.remove(item);
    });
  }

  void _clearAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  void _applyRecentSearch(String item) {
    _searchController.text = item;
    setState(() {
      _query = item;
      _simulateEmptyState = false;
    });
  }

  List<Product> _getSearchResults() {
    if (_simulateEmptyState) return [];

    final q = _query.trim().toLowerCase();
    var list = Product.allCatalog.where((product) {
      if (q.isEmpty) return true;
      final matchName = product.name.toLowerCase().contains(q);
      final matchBrand = product.brand.toLowerCase().contains(q);
      final matchCategory = product.category.toLowerCase().contains(q);
      final matchVariant = product.variant.toLowerCase().contains(q);

      // Pencarian multi-kata (misal: "Gitar Fender" mencocokkan merek Fender & kategori Gitar)
      final words = q.split(RegExp(r'\s+'));
      final matchAllWords = words.every((w) =>
          product.name.toLowerCase().contains(w) ||
          product.brand.toLowerCase().contains(w) ||
          product.category.toLowerCase().contains(w) ||
          product.variant.toLowerCase().contains(w));

      return matchName || matchBrand || matchCategory || matchVariant || matchAllWords;
    }).toList();

    // Saring kategori jika tidak semua
    if (_selectedCategory.isNotEmpty && _selectedCategory != 'Semua') {
      final categoryFiltered = list
          .where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
      // Jika kategori memiliki hasil, prioritaskan
      if (categoryFiltered.isNotEmpty) {
        list = categoryFiltered;
      }
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
    final searchResults = _getSearchResults();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header konsisten dengan Semua Produk
            _buildHeader(context),

            // Konten Pencarian yang dapat di-scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Input Pencarian Aktif & Tombol Batal
                    _buildSearchInputField(),

                    const SizedBox(height: 14),

                    // Bagian Pencarian Terakhir (Chips Kapsul)
                    if (_recentSearches.isNotEmpty) ...[
                      _buildRecentSearchesSection(),
                      const SizedBox(height: 14),
                    ],

                    // Bagian Kategori Populer (11 Kategori)
                    _buildPopularCategoriesSection(),

                    const SizedBox(height: 16),

                    // Header Hasil Pencarian
                    _buildSearchResultHeader(searchResults.length),

                    const SizedBox(height: 8),

                    // Sub-filter spesifikasi & urutkan
                    _buildFilterSpecBar(),

                    const SizedBox(height: 12),

                    // Grid Hasil atau Tampilan Kosong (Empty State)
                    if (searchResults.isEmpty)
                      _buildEmptyState()
                    else
                      _buildProductGrid(searchResults),

                    const SizedBox(height: 16),

                    // Bar Uji Tampilan UX (Simulasikan Tidak Ada Hasil)
                    _buildUxTestBar(),

                    const SizedBox(height: 14),

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
        currentIndex: 1, // Kategori / Pencarian tab
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

  Widget _buildSearchInputField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Kolom Input Abu-abu Muda
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F5F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFECEAE6), width: 1.0),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.placeholder,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onSubmitted: (value) {
                        final trimmed = value.trim();
                        if (trimmed.isNotEmpty) {
                          setState(() {
                            _recentSearches.remove(trimmed);
                            _recentSearches.insert(0, trimmed);
                            if (_recentSearches.length > 5) {
                              _recentSearches.removeLast();
                            }
                          });
                        }
                      },
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Cari produk favoritmu...',
                        hintStyle: TextStyle(
                          color: AppColors.placeholder,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    InkWell(
                      onTap: _clearSearch,
                      borderRadius: BorderRadius.circular(15),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Tombol "Batal" Oranye
          InkWell(
            onTap: () {
              _clearSearch();
              _handleBack();
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pencarian Terakhir',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              InkWell(
                onTap: _clearAllRecentSearches,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  child: Text(
                    'Hapus Semua',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F6F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 13.5,
                      color: Color(0xFF8E837D),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () => _applyRecentSearch(item),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () => _removeRecentSearch(item),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 13.5,
                        color: Color(0xFF8E837D),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kategori Populer',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                '11 Kategori',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: _popularCategories.map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (_selectedCategory == category) {
                        _selectedCategory = 'Semua';
                      } else {
                        _selectedCategory = category;
                      }
                      _simulateEmptyState = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 6.5,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected && category == 'Gitar') ...[
                          const Icon(
                            Icons.music_note_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6E6560),
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultHeader(int count) {
    final hasQuery = _query.trim().isNotEmpty;
    final hasCategory =
        _selectedCategory.isNotEmpty && _selectedCategory != 'Semua';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasQuery
                    ? 'Hasil Pencarian'
                    : (hasCategory
                        ? 'Kategori $_selectedCategory'
                        : 'Semua Produk'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                hasQuery
                    ? 'untuk "$_query"'
                    : (hasCategory
                        ? 'Menampilkan alat musik kategori $_selectedCategory'
                        : 'Jelajahi berbagai pilihan alat musik'),
                style: TextStyle(
                  fontSize: 11,
                  color: hasQuery
                      ? AppColors.textSecondaryBrown
                      : AppColors.textMuted,
                  fontStyle: hasQuery ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),

          // Badge Jumlah Ditemukan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFE5), // Oranye muda lembut
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              hasQuery ? '$count Ditemukan' : '$count Produk',
              style: const TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSpecBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Filter Spesifikasi
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter spesifikasi diaktifkan.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
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
                  SizedBox(width: 5),
                  Text(
                    'Filter Spesifikasi',
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

          // Pilihan Terpopuler
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
                child: Text('Harga Terendah', style: TextStyle(fontSize: 12)),
              ),
              const PopupMenuItem(
                value: 'Harga Tertinggi',
                child: Text('Harga Tertinggi', style: TextStyle(fontSize: 12)),
              ),
              const PopupMenuItem(
                value: 'Rating Tertinggi',
                child: Text('Rating Tertinggi', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F5F3),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: AppColors.placeholder,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Produk Tidak Ditemukan',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba kata kunci lain atau periksa ejaanmu untuk menemukan alat musik yang kamu cari.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                _clearSearch();
                setState(() {
                  _selectedCategory = 'Semua';
                  _simulateEmptyState = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Lihat Semua Produk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUxTestBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'UJI TAMPILAN UX',
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7E756F),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _simulateEmptyState = !_simulateEmptyState;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Text(
                _simulateEmptyState
                    ? 'Kembalikan Hasil Pencarian'
                    : 'Simulasikan "Tidak Ada Hasil"',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
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
          const Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: Color(0xFF7E756F),
          ),
        ],
      ),
    );
  }
}
