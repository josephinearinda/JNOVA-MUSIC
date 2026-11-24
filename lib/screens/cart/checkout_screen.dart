import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jnova/core/constants/app_colors.dart';
import 'package:jnova/core/utils/currency_formatter.dart';
import 'package:jnova/models/order_model.dart';
import 'package:jnova/models/product.dart';
import 'package:jnova/models/store_branch.dart';
import 'package:jnova/services/cart_service.dart';
import 'package:jnova/services/blockchain_certificate_service.dart';
import 'package:jnova/services/location_service.dart';
import 'package:jnova/services/order_service.dart';
import 'package:jnova/services/user_profile_service.dart';
import 'package:jnova/widgets/app_bottom_nav.dart';
import 'package:jnova/screens/cart/select_pickup_store_screen.dart';

/// Halaman CHECKOUT JNOVAMUSIC dengan alur Ambil di Toko Resmi (Store Pickup)
class CheckoutScreen extends StatefulWidget {
  final FulfillmentMethod initialMethod;
  final VoidCallback? onBack;

  const CheckoutScreen({
    super.key,
    this.initialMethod = FulfillmentMethod.pickup,
    this.onBack,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService.instance;
  final OrderService _orderService = OrderService.instance;
  final LocationService _locationService = LocationService.instance;

  late StoreBranch _selectedStore;
  final String _selectedPaymentMethod = 'Bayar di Toko (Pickup & Pay)';
  bool _showAllBranches = false;
  bool _isProcessingPayment = false;

  // State deteksi lokasi GPS & pemilihan toko otomatis
  bool _isDetectingLocation = false;
  double? _userLat;
  double? _userLng;
  String? _locationStatusMessage;
  bool _locationDetected = false;
  List<StoreBranchWithDistance> _sortedBranchesWithDistance = [];

  final int _serviceFee = 1000;

  @override
  void initState() {
    super.initState();
    _selectedStore = StoreBranch.branches.first;
    _cartService.addListener(_handleCartUpdated);
    _detectLocationAndAutoSelectStore(); //deteksi lokasi
  }

  Future<void> _detectLocationAndAutoSelectStore() async {
    if (!mounted) return;
    setState(() {
      _isDetectingLocation = true;
      _locationStatusMessage = null;
    });

    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;

    if (result.isSuccess &&
        result.latitude != null &&
        result.longitude != null) {
      final lat = result.latitude!;
      final lng = result.longitude!;
      final sorted = _locationService.sortStoresByDistance(
        lat,
        lng,
        StoreBranch.branches,
      );

      setState(() {
        _isDetectingLocation = false;
        _userLat = lat;
        _userLng = lng;
        _locationDetected = true;
        _sortedBranchesWithDistance = sorted;
        if (sorted.isNotEmpty) {
          _selectedStore = sorted.first.branch;
        }
      });
    } else {
      setState(() {
        _isDetectingLocation = false;
        _locationDetected = false;
        _locationStatusMessage = result.message;
        if (!StoreBranch.branches.any((b) => b.id == _selectedStore.id)) {
          _selectedStore = StoreBranch.branches.first;
        }
      });
    }
  }

  Future<void> _openGoogleMaps(StoreBranch branch) async {
    final url = branch.getDirectionsUrl(_userLat, _userLng);
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _cartService.removeListener(_handleCartUpdated);
    super.dispose();
  }

  void _handleCartUpdated() {
    if (mounted) setState(() {});
  }

  List<CartItem> _getCheckoutItems() {
    final selected = _cartService.items.where((i) => i.isSelected).toList();
    if (selected.isNotEmpty) return selected;
    // Fallback jika tidak ada yang dicentang: produk default katalog Figma Fender Player II
    return [
      CartItem(
        product: Product.allCatalog.first,
        quantity: 1,
        isSelected: true,
      ),
    ];
  }

  int _calculateSubtotal(List<CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.itemTotal);
  }

  int _calculateDiscount(int subtotal) { //perhitungan total item dikasli diskon
    return (subtotal * _cartService.discountRate).round();
  }

  int _calculateTotal(int subtotal, int discount) {
    final total = subtotal - discount + _serviceFee;
    return total > 0 ? total : 0;
  }

  Future<void> _handlePayNow(List<CartItem> items, int total) async {
    if (_isProcessingPayment) return;

    setState(() {
      _isProcessingPayment = true;
    });

    final buyerName = BlockchainCertificateService.instance
        .getCurrentBuyerName();
    final activeEmail = UserProfileService.instance.profile.email;

    final order = await _orderService.checkout(
      items: items,
      fulfillment: FulfillmentMethod.pickup,
      paymentMethod: _selectedPaymentMethod,
      store: _selectedStore,
      recipientName: buyerName,
      userEmail: activeEmail,
    );

    if (!mounted) return;

    setState(() {
      _isProcessingPayment = false;
    });

    // Navigasi ke halaman detail pengambilan toko
    Navigator.pushReplacementNamed(context, '/pickup-detail', arguments: order);
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getCheckoutItems();
    final subtotal = _calculateSubtotal(items);
    final discount = _calculateDiscount(subtotal);
    final totalPayment = _calculateTotal(subtotal, discount);

    return Scaffold(
      backgroundColor: AppColors.white, // Warna latar kotak untuk "/cart"
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, Checkout Title, Security Icon
            _buildHeader(context),

            // Top Status Bar (SSL 256-bit note)
            _buildTopSecurityBar(),

            // Konten Checkout yang dapat di-scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Bagian Produk yang Dipesan
                    _buildOrderedProductsSection(items),

                    const SizedBox(height: 16),

                    // Metode Pemenuhan (Ambil Langsung di Toko Resmi JNOVAMUSIC)
                    _buildFulfillmentMethodSelector(),

                    const SizedBox(height: 16),

                    // Konten Spesifik Metode Pemenuhan Ambil di Toko Resmi
                    _buildLuthierServiceCard(),

                    const SizedBox(height: 16),

                    // Daftar Cabang Toko Pengambilan
                    _buildPickupStoresSection(),

                    const SizedBox(height: 16),

                    // Informasi Pengambilan Pesanan (Petunjuk Kasir)
                    _buildPickupInstructionsCard(),

                    const SizedBox(height: 16),

                    // Kartu Membership Silver
                    _buildMembershipCard(discount),

                    const SizedBox(height: 16),

                    // Metode Pembayaran
                    _buildPaymentMethodSection(),

                    const SizedBox(height: 16),

                    // Ringkasan Biaya / Rincian Pembayaran
                    _buildCostSummary(subtotal, discount, totalPayment),

                    const SizedBox(height: 14),

                    // Catatan Keamanan Enkripsi
                    _buildEncryptionFooter(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Payment Bar
            _buildBottomPaymentBar(items, totalPayment),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3, // Pesanan tab
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/all-products');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/membership');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: AppColors
                    .textPrimaryDark, // Warna ikon ikon untuk "Checkout"
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Checkout',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color:
                  AppColors.textPrimaryDark, // Warna ikon ikon untuk "Checkout"
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.shield_outlined,
            size: 20,
            color: Color(0xFF7E756F), // Warna ikon ikon untuk "Checkout"
          ),
        ],
      ),
    );
  }

  Widget _buildTopSecurityBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      color: const Color(
        0xFFFAF9F7,
      ), // Warna latar kotak atau kartu untuk "Checkout"
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryOrange, // Warna teks pada "Ambil di Toko (Store Pickup)"
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Ambil di Toko (Store Pickup)',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange, // Warna teks pada "Ambil di Toko (Store Pickup)"
                ),
              ),
            ],
          ),
          const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: Color(0xFF8E837D), // Warna ikon ikon untuk "SSL 256-Bit"
              ),
              SizedBox(width: 3),
              Text(
                'SSL 256-Bit',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E837D), // Warna teks pada "SSL 256-Bit"
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderedProductsSection(List<CartItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Produk yang Dipesan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                '${items.length} Produk',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: items.map((item) {
              final prod = item.product;
              return Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFAF9F7,
                  ), // Warna border atau garis tepi bagian produk
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(
                      0xFFEBE8E3,
                    ), // Warna border atau garis tepi bagian produk
                    width: 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar Produk
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 64,
                            height: 64,
                            color: Colors
                                .white, // Warna ikon ikon pada bagian produk
                            child: Image.asset(
                              prod.image,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image, size: 28),
                            ),
                          ),
                        ),
                        if (prod.isOriginal)
                          Positioned(
                            top: 2,
                            left: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange, // Warna teks pada "ORIGINAL"
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'ORIGINAL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Detail Teks
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${prod.brand.toUpperCase()} • ${prod.category}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8E837D), // Warna teks pada "${prod.brand.toUpperCase()} • ${pro..."
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prod.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryDark, // Warna teks pada "3-Color Sunburst • Maple Fingerboard"
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prod.variant.isNotEmpty
                                ? prod.variant
                                : '3-Color Sunburst • Maple Fingerboard',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF7E756F), // Warna teks pada "3-Color Sunburst • Maple Fingerboard"
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatRupiah(prod.price),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryOrange, // Warna teks pada "3-Color Sunburst • Maple Fingerboard"
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECEAE6), // Warna teks pada "${item.quantity} Barang"
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item.quantity} Barang',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5A524D), // Warna teks pada "${item.quantity} Barang"
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildFulfillmentMethodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metode Pemenuhan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(
                0xFFFFF7ED,
              ), // Warna border atau garis tepi untuk "Metode Pemenuhan"
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryOrange,
                width: 1.5,
              ), // Warna border atau garis tepi untuk "Metode Pemenuhan"
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFEFE5,
                    ), // Warna ikon ikon untuk "Metode Pemenuhan"
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 22,
                    color: AppColors.primaryOrange, // Warna ikon ikon untuk "Metode Pemenuhan"
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambil di Toko Resmi (Store Pickup)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark, // Warna teks pada "Ambil di Toko Resmi (Store Pickup)"
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gratis Bebas Biaya • Sound Check & Unboxing di Toko',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7E756F), // Warna teks pada "Gratis Bebas Biaya • Sound Check &..."
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(
                      // Warna latar kotak atau kartu untuk "GRATIS"

                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'GRATIS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16A34A), // Warna teks pada "GRATIS"
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

  Widget _buildLuthierServiceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7), // Warna border atau garis tepi kartu
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEBE8E3), // Warna border atau garis tepi kartu
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDF), // Warna ikon ikon pada kartu
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 18,
              color: AppColors.primaryOrange, // Warna ikon ikon untuk "Gratis Sound Check & Luthier Setup"
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gratis Sound Check & Luthier Setup',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark, // Warna teks pada "Gratis Sound Check & Luthier Setup"
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ambil instrumen tanpa antre di toko resmi. Cek kelengkapan fisik, set action senar, dan uji soundboard bersama kru spesialis musik kami.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(
                      0xFF5A524D,
                    ), // Warna teks pada "Gratis Sound Check & Luthier Setup"
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupStoresSection() {
    final List<StoreBranchWithDistance> sourceList =
        _sortedBranchesWithDistance.isNotEmpty
        ? _sortedBranchesWithDistance
        : StoreBranch.branches
              .map(
                (b) => StoreBranchWithDistance(branch: b, distanceMeters: null),
              )
              .toList();

    final displayedList = _showAllBranches
        ? sourceList
        : sourceList.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
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
                      'Pilih Toko Pengambilan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark, // Warna teks pada "Pilih Toko Pengambilan"
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Cabang resmi JNOVAMUSIC (Pickup & Pay)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted, // Warna teks pada "Cabang resmi JNOVAMUSIC (Pickup & Pay)"
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final branch = await Navigator.push<StoreBranch>(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) =>
                          SelectPickupStorePage(selectedBranch: _selectedStore),
                    ),
                  );
                  if (branch != null && mounted) {
                    setState(() {
                      _selectedStore = branch;
                    });
                  }
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 14,
                      color: AppColors
                          .primaryOrange, // Warna ikon ikon untuk "Ganti Toko"
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Ganti Toko',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange, // Warna ikon ikon untuk "Ganti Toko"
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.map_outlined,
                      size: 14,
                      color: AppColors
                          .primaryOrange, // Warna ikon ikon untuk "Peta & Rute"
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Peta & Rute',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Indikator Status Lokasi
          if (_isDetectingLocation)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFEF6F0,
                ), // Warna border atau garis tepi bagian komponen ini
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(
                    0xFFFFDEC9,
                  ), // Warna border atau garis tepi bagian komponen ini
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryOrange, // Warna indikator loading pada bagian komponen ini
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mencari toko JNOVA MUSIC terdekat dari koordinatmu...',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF8D4315), // Warna teks pada "Mencari toko JNOVA MUSIC terdekat d..."
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_locationDetected)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // Warna border atau garis tepi untuk "Mencari toko JNOVA MUSIC terdekat d..."
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFBBF7D0), // Warna border atau garis tepi untuk "Mencari toko JNOVA MUSIC terdekat d..."
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    size: 15,
                    color: Color(0xFF16A34A), // Warna ikon ikon untuk "Lokasi terdeteksi. Cabang terdekat..."
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Lokasi terdeteksi. Cabang terdekat otomatis terpilih.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF166534), // Warna teks pada "Lokasi terdeteksi. Cabang terdekat..."
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _detectLocationAndAutoSelectStore,
                    child: const Text(
                      'Perbarui',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_locationStatusMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFFFBEB,
                ), // Warna border atau garis tepi bagian komponen ini
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(
                    0xFFFDE68A,
                  ), // Warna border atau garis tepi bagian komponen ini
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    size: 15,
                    color: Color(
                      0xFFD97706,
                    ), // Warna ikon ikon pada bagian komponen ini
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationStatusMessage!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF92400E), // Warna teks pada "Coba Lagi"
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _detectLocationAndAutoSelectStore,
                    child: const Text(
                      'Coba Lagi',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Column(
            children: displayedList.map((item) {
              final branch = item.branch;
              final isSelected = _selectedStore.id == branch.id;
              final isNearest =
                  item.isNearest ||
                  (_locationDetected &&
                      _sortedBranchesWithDistance.isNotEmpty &&
                      _sortedBranchesWithDistance.first.branch.id == branch.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(
                          0xFFFFFBF7,
                        ) // Warna border atau garis tepi bagian komponen ini
                      : const Color(
                          0xFFFAF9F7,
                        ), // Warna border atau garis tepi bagian komponen ini
                  borderRadius: BorderRadius.circular(12),
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
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedStore = branch;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 16,
                              color: isSelected
                                  ? AppColors
                                        .primaryOrange // Warna ikon ikon pada bagian komponen ini
                                  : const Color(0xFF7E756F), // Warna ikon ikon pada bagian komponen ini
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                branch.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryDark, // Warna ikon ikon pada bagian komponen ini
                                ),
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: isSelected
                                  ? AppColors
                                        .primaryOrange // Warna ikon ikon untuk "${branch.tag} • ${item.formattedDis..."
                                  : const Color(
                                      0xFFB0AAA4,
                                    ), // Warna visual pada bagian komponen ini
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.distanceMeters != null
                                    ? '${branch.tag} • ${item.formattedDistance} dari lokasimu (garis lurus)'
                                    : '${branch.tag} • ${branch.distance}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryOrange, // Warna teks pada "${branch.tag} • ${branch.distance}"
                                ),
                              ),
                            ),
                            if (isNearest) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEDDF), // Warna latar kotak atau kartu untuk "Toko Terdekat"
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Toko Terdekat',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(
                                      0xFFC2410C,
                                    ), // Warna teks pada "Toko Terdekat"
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          branch.address,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(
                              0xFF6E6560,
                            ), // Warna teks pada "Toko Terdekat"
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: Color(
                                    0xFF8E837D,
                                  ), // Warna ikon ikon untuk "Toko Terdekat"
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  branch.operatingHours,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Color(
                                      0xFF6E6560,
                                    ), // Warna teks pada "Toko Terdekat"
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(
                                        0xFFFFEFE5,
                                      ) // Warna teks pada "Toko Terdekat"
                                    : const Color(
                                        0xFFECEAE6,
                                      ), // Warna teks pada "Toko Terdekat"
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                branch.stockStatus,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors
                                            .primaryOrange // Warna teks pada "Toko Terdekat"
                                      : const Color(
                                          0xFF5A524D,
                                        ), // Warna teks pada "Toko Terdekat"
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Tombol Aksi Rute Google Maps & Penanda Pilihan
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: InkWell(
                                onTap: () => _openGoogleMaps(branch),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white, // Warna border atau garis tepi bagian komponen ini
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFE0DDD7), // Warna ikon ikon untuk "Buka Rute Google Maps"
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.directions_outlined,
                                        size: 12,
                                        color: AppColors.primaryOrange, // Warna ikon ikon untuk "Buka Rute Google Maps"
                                      ),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Buka Rute Google Maps',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryOrange, // Warna teks pada "Buka Rute Google Maps"
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (isSelected)
                              const Text(
                                '✓ Toko Terpilih',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryOrange, // Warna teks pada "✓ Toko Terpilih"
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Tombol Tampilkan Lebih Banyak Cabang
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllBranches = !_showAllBranches;
                });
              },
              child: Text(
                _showAllBranches
                    ? 'Sembunyikan Cabang Lain ⌃'
                    : 'Tampilkan Semua Cabang (${sourceList.length}) ⌵',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(
                    0xFF6E6560,
                  ), // Warna teks pada "Tampilkan Semua Cabang (${sourceLis..."
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupInstructionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7), // Warna border atau garis tepi kartu
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEBE8E3), // Warna border atau garis tepi kartu
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Color(
                  0xFF7E756F,
                ), // Warna ikon ikon untuk "Informasi Pengambilan Pesanan"
              ),
              SizedBox(width: 6),
              Text(
                'Informasi Pengambilan Pesanan',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark, // Warna teks pada "Informasi Pengambilan Pesanan"
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInstructionStep(
            '1',
            'Tunggu notifikasi WhatsApp & Email status "Siap Diambil" sebelum datang ke toko.',
          ),
          const SizedBox(height: 6),
          _buildInstructionStep(
            '2',
            'Tunjukkan QR Code e-Invoice pada menu Pesanan beserta KTP/SIM kepada kasir pickup.',
          ),
          const SizedBox(height: 6),
          _buildInstructionStep(
            '3',
            'QC fisik gitar & setting neck/senar gratis langsung di luthier corner JNOVAMUSIC.',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(
              0xFFECEAE6,
            ), // Warna latar kotak atau kartu pada bagian komponen ini
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5A524D), // Warna teks pada bagian komponen ini
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF5A524D), // Warna teks pada bagian komponen ini
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipCard(int discount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7), // Warna border atau garis tepi kartu
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEBE8E3), // Warna border atau garis tepi kartu
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDF), // Warna ikon ikon pada kartu
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              size: 18,
              color: AppColors.primaryOrange, // Warna ikon ikon pada kartu
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _cartService.tierName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color:
                            AppColors.textPrimaryDark, // Warna teks pada kartu
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: _cartService.isMember
                            ? AppColors
                                  .primaryOrange // Warna teks pada kartu
                            : const Color(0xFF8E837D), // Warna teks pada kartu
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _cartService.userTier,
                        style: const TextStyle(
                          color: Colors.white, // Warna teks pada "Diskon ${_cartService.discountPerce..."
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _cartService.discountPercentage > 0
                      ? 'Diskon ${_cartService.discountPercentage}% otomatis dipotong'
                      : 'Kumpulkan min. 1.000 poin untuk diskon Silver',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7E756F), // Warna teks pada "Kumpulkan min. 1.000 poin untuk dis..."
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-${formatRupiah(discount)}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryOrange, // Warna teks pada "-${formatRupiah(discount)}"
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                'Bayar Langsung di Kasir',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(
                    0xFF16A34A,
                  ), // Warna teks pada "Bayar Langsung di Kasir"
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(
                0xFFFFF7ED,
              ), // Warna border atau garis tepi untuk "Bayar Langsung di Kasir"
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryOrange,
                width: 1.5,
              ), // Warna border atau garis tepi untuk "Bayar Langsung di Kasir"
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFEFE5,
                    ), // Warna ikon ikon untuk "Bayar Langsung di Kasir"
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.point_of_sale_rounded,
                    size: 22,
                    color: AppColors.primaryOrange, // Warna ikon ikon untuk "Bayar Langsung di Kasir"
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bayar di Toko (Pickup & Pay)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark, // Warna teks pada "Bayar di Toko (Pickup & Pay)"
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bayar langsung di kasir toko saat pengambilan (Tunai, Kartu Debit/Kredit EDC, QRIS Toko)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(
                            0xFF7E756F,
                          ), // Warna teks pada "Bayar di Toko (Pickup & Pay)"
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryOrange, // Warna ikon ikon untuk "Bayar di Toko (Pickup & Pay)"
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary(int subtotal, int discount, int totalPayment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Biaya',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors
                  .textPrimaryDark, // Warna teks pada "Ringkasan Biaya"
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(
                0xFFFAF9F7,
              ), // Warna border atau garis tepi untuk "Ringkasan Biaya"
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(
                  0xFFEBE8E3,
                ), // Warna border atau garis tepi untuk "Ringkasan Biaya"
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal Produk', formatRupiah(subtotal)),
                const SizedBox(height: 6),
                _buildSummaryRow(
                  'Diskon Membership Silver (10%)',
                  '-${formatRupiah(discount)}',
                  valueColor: AppColors
                      .primaryOrange, // Warna visual pada bagian komponen ini
                ),
                const SizedBox(height: 6),
                _buildSummaryRow(
                  'Biaya Ambil di Toko',
                  'Gratis (Rp 0)',
                  valueColor: const Color(
                    0xFF16A34A,
                  ), // Warna visual pada bagian komponen ini
                ),
                const SizedBox(height: 6),
                _buildSummaryRow(
                  'Asuransi & Setup Khusus Toko',
                  'Rp 0 (Gratis)',
                  valueColor: const Color(
                    0xFF16A34A,
                  ), // Warna visual pada bagian komponen ini
                ),
                const SizedBox(height: 6),
                _buildSummaryRow(
                  'Biaya Layanan JNOVAMUSIC',
                  formatRupiah(_serviceFee),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(
                    color: Color(
                      0xFFEBE8E3,
                    ), // Warna garis pemisah pada bagian komponen ini
                    height: 1,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Tagihan',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryDark, // Warna teks pada "Total Tagihan"
                          ),
                        ),
                        Text(
                          'Termasuk PPN 11%',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(
                              0xFF8E837D,
                            ), // Warna teks pada "Termasuk PPN 11%"
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formatRupiah(totalPayment),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange, // Warna teks pada "Termasuk PPN 11%"
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF6E6560), // Warna teks pada bagian komponen ini
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color:
                valueColor ??
                AppColors
                    .textPrimaryDark, // Warna teks pada bagian komponen ini
          ),
        ),
      ],
    );
  }

  Widget _buildEncryptionFooter() {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: Color(
              0xFF8E837D,
            ), // Warna ikon ikon untuk "Transaksi aman dengan enkripsi SSL..."
          ),
          SizedBox(width: 4),
          Text(
            'Transaksi aman dengan enkripsi SSL 256-bit',
            style: TextStyle(
              fontSize: 10,
              color: Color(
                0xFF8E837D,
              ), // Warna teks pada "Transaksi aman dengan enkripsi SSL..."
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPaymentBar(List<CartItem> items, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white, // Warna border atau garis tepi untuk "Transaksi aman dengan enkripsi SSL..."
        border: const Border(
          top: BorderSide(
            color: Color(0xFFF0EDE9), // Warna border atau garis tepi untuk "Transaksi aman dengan enkripsi SSL..."
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              // Warna latar kotak atau kartu untuk "Transaksi aman dengan enkripsi SSL..."

              alpha: 0.04,
            ),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Color(
                    0xFF7E756F,
                  ), // Warna teks pada "Total Pembayaran"
                ),
              ),
              const SizedBox(height: 1),
              Text(
                formatRupiah(total),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrange,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: () => _handlePayNow(items, total),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange, // Warna latar tombol pada bagian komponen ini
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'Konfirmasi Pesanan Pickup',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white, // Warna ikon ikon untuk "Konfirmasi Pesanan Pickup"
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
