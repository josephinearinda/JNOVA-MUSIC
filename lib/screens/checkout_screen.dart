import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/store_branch.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman CHECKOUT JNOVAMUSIC (Mendukung Ambil di Toko & Kirim ke Rumah sesuai Figma 7 & 8)
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

  late FulfillmentMethod _fulfillmentMethod;
  late StoreBranch _selectedStore;
  String _selectedPaymentMethod = 'Transfer Bank BCA (Rek: 8841-0922-1100)';
  bool _showAllBranches = false;
  bool _includeWoodPackingInsurance = true;
  bool _isProcessingPayment = false;

  final int _shippingFee = 150000;
  final int _serviceFee = 1000;

  @override
  void initState() {
    super.initState();
    _fulfillmentMethod = widget.initialMethod;
    _selectedStore = StoreBranch.branches.first;
    _cartService.addListener(_handleCartUpdated);
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

  int _calculateDiscount(int subtotal) {
    return (subtotal * _cartService.discountRate).round();
  }

  int _calculateTotal(int subtotal, int discount) {
    final shipping = _fulfillmentMethod == FulfillmentMethod.delivery
        ? _shippingFee
        : 0;
    final total = subtotal - discount + shipping + _serviceFee;
    return total > 0 ? total : 0;
  }

  Future<void> _handlePayNow(List<CartItem> items, int total) async {
    if (_isProcessingPayment) return;

    setState(() {
      _isProcessingPayment = true;
    });

    final order = await _orderService.checkout(
      items: items,
      fulfillment: _fulfillmentMethod,
      paymentMethod: _selectedPaymentMethod,
      store: _selectedStore,
      shippingCost: _fulfillmentMethod == FulfillmentMethod.delivery
          ? _shippingFee
          : 0,
      packingCost: 0,
    );

    if (!mounted) return;

    setState(() {
      _isProcessingPayment = false;
    });

    // Navigasi ke halaman detail yang sesuai dengan metode pemenuhan
    if (_fulfillmentMethod == FulfillmentMethod.pickup) {
      Navigator.pushReplacementNamed(
        context,
        '/pickup-detail',
        arguments: order,
      );
    } else {
      Navigator.pushReplacementNamed(
        context,
        '/order-detail',
        arguments: order,
      );
    }
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
      backgroundColor: AppColors.white,
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

                    // Metode Pemenuhan (Ambil di Toko vs Kirim ke Rumah)
                    _buildFulfillmentMethodSelector(),

                    const SizedBox(height: 16),

                    // Konten Spesifik Metode Pemenuhan
                    if (_fulfillmentMethod == FulfillmentMethod.pickup) ...[
                      // Informasi Layanan Gratis Luthier
                      _buildLuthierServiceCard(),

                      const SizedBox(height: 16),

                      // Daftar Cabang Toko Pengambilan
                      _buildPickupStoresSection(),

                      const SizedBox(height: 16),

                      // Informasi Pengambilan Pesanan (Petunjuk Kasir)
                      _buildPickupInstructionsCard(),
                    ] else ...[
                      // Alamat Pengiriman
                      _buildShippingAddressCard(),

                      const SizedBox(height: 16),

                      // Opsi Pengiriman
                      _buildShippingOptionsSection(),

                      const SizedBox(height: 12),

                      // Opsi Packing Kayu & Asuransi
                      _buildWoodPackingOption(),
                    ],

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
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F0ED), width: 1.0),
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
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Checkout',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const Spacer(),
          const Icon(Icons.shield_outlined, size: 20, color: Color(0xFF7E756F)),
        ],
      ),
    );
  }

  Widget _buildTopSecurityBar() {
    final isPickup = _fulfillmentMethod == FulfillmentMethod.pickup;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      color: const Color(0xFFFAF9F7),
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
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isPickup
                    ? 'Ambil di Toko (Store Pickup)'
                    : 'Pengiriman Kurir Ekspedisi',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: Color(0xFF8E837D),
              ),
              SizedBox(width: 3),
              Text(
                'SSL 256-Bit',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E837D),
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
                  color: const Color(0xFFFAF9F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEBE8E3),
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
                            color: Colors.white,
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
                                color: AppColors.primaryOrange,
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
                              color: Color(0xFF8E837D),
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
                              color: AppColors.textPrimaryDark,
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
                              color: Color(0xFF7E756F),
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
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECEAE6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item.quantity} Barang',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5A524D),
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
    final isPickup = _fulfillmentMethod == FulfillmentMethod.pickup;

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
          Row(
            children: [
              // Pilihan 1: Kirim ke Rumah
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _fulfillmentMethod = FulfillmentMethod.delivery;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: !isPickup
                          ? const Color(0xFFFFF7ED)
                          : const Color(0xFFFAF9F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isPickup
                            ? AppColors.primaryOrange
                            : const Color(0xFFEBE8E3),
                        width: !isPickup ? 1.5 : 1.0,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 20,
                              color: !isPickup
                                  ? AppColors.primaryOrange
                                  : const Color(0xFF7E756F),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pengiriman ke Rumah',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: !isPickup
                                    ? AppColors.textPrimaryDark
                                    : const Color(0xFF6E6560),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Estimasi 2-3 Hari',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF8E837D),
                              ),
                            ),
                          ],
                        ),
                        if (!isPickup)
                          const Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Pilihan 2: Ambil di Toko
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _fulfillmentMethod = FulfillmentMethod.pickup;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isPickup
                          ? const Color(0xFFFFF7ED)
                          : const Color(0xFFFAF9F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPickup
                            ? AppColors.primaryOrange
                            : const Color(0xFFEBE8E3),
                        width: isPickup ? 1.5 : 1.0,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 20,
                              color: isPickup
                                  ? AppColors.primaryOrange
                                  : const Color(0xFF7E756F),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ambil di Toko',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isPickup
                                    ? AppColors.textPrimaryDark
                                    : const Color(0xFF6E6560),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Bebas Ongkir',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                        if (isPickup)
                          const Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                      ],
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

  Widget _buildLuthierServiceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 18,
              color: AppColors.primaryOrange,
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
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ambil instrumen tanpa antre di toko resmi. Cek kelengkapan fisik, set action senar, dan uji soundboard bersama kru spesialis musik kami.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5A524D),
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
    final branches = _showAllBranches
        ? StoreBranch.branches
        : StoreBranch.branches.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Toko Pengambilan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Tersedia di 5 cabang resmi JNOVAMUSIC',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Peta sebaran toko resmi dibuka.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 14,
                      color: AppColors.primaryOrange,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Lihat Peta',
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
          Column(
            children: branches.map((branch) {
              final isSelected = _selectedStore.id == branch.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFFBF7)
                      : const Color(0xFFFAF9F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryOrange
                        : const Color(0xFFEBE8E3),
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
                                  ? AppColors.primaryOrange
                                  : const Color(0xFF7E756F),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                branch.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: isSelected
                                  ? AppColors.primaryOrange
                                  : const Color(0xFFB0AAA4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${branch.tag} • ${branch.distance}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          branch.address,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6E6560),
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
                                  color: Color(0xFF8E837D),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  branch.operatingHours,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF6E6560),
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
                                    ? const Color(0xFFFFEFE5)
                                    : const Color(0xFFECEAE6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                branch.stockStatus,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : const Color(0xFF5A524D),
                                ),
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
                    ? 'Sembunyikan Cabang Solo & Bali ⌃'
                    : 'Tampilkan Cabang Solo & Bali ⌵',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6E6560),
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
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Color(0xFF7E756F),
              ),
              SizedBox(width: 6),
              Text(
                'Informasi Pengambilan Pesanan',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
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
            color: Color(0xFFECEAE6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5A524D),
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
              color: Color(0xFF5A524D),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShippingAddressCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alamat Pengiriman',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ubah alamat penerima.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Text(
                  'Ubah Alamat',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Alamat Utama',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Budi Pratama',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '(+62) 812-3456-7890',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF7E756F)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Jl. Senopati No. 42, RT 04 / RW 02, Kebayoran Baru, Jakarta Selatan, DKI Jakarta 12110',
            style: TextStyle(
              fontSize: 10.5,
              color: Color(0xFF5A524D),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingOptionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opsi Pengiriman',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryOrange, width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDDF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JNE Cargo - Music Care',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Estimasi 3 - 5 hari kerja',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7E756F),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatRupiah(_shippingFee),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWoodPackingOption() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _includeWoodPackingInsurance,
            activeColor: AppColors.primaryOrange,
            onChanged: (val) {
              setState(() {
                _includeWoodPackingInsurance = val ?? true;
              });
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Packing Kayu & Asuransi Alat Musik',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      'Gratis (Promo)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Jaminan proteksi 100% ganti unit baru jika terjadi kerusakan transit.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF6E6560),
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

  Widget _buildMembershipCard(int discount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              size: 18,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Member Silver',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TIER 2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Diskon 10% otomatis dipotong',
                  style: TextStyle(fontSize: 10, color: Color(0xFF7E756F)),
                ),
              ],
            ),
          ),
          Text(
            '-${formatRupiah(discount)}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryOrange,
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
                'Terverifikasi Otomatis',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pilihan 1: Transfer Bank BCA
          _buildPaymentRadioTile(
            title: 'Transfer Bank BCA (8841-0922-1100)',
            subtitle: 'a.n. PT JNOVA MUSIK INDONESIA • Verifikasi Resmi',
            icon: Icons.account_balance_rounded,
            isSelected: _selectedPaymentMethod.contains('BCA'),
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'Transfer Bank BCA (Rek: 8841-0922-1100)';
              });
            },
          ),

          const SizedBox(height: 8),

          // Pilihan 2: Transfer Bank Mandiri
          _buildPaymentRadioTile(
            title: 'Transfer Bank Mandiri (137-00-8841922-1)',
            subtitle: 'a.n. PT JNOVA MUSIK INDONESIA • Verifikasi Resmi',
            icon: Icons.account_balance_rounded,
            isSelected: _selectedPaymentMethod.contains('Mandiri'),
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'Transfer Bank Mandiri (Rek: 137-00-8841922-1)';
              });
            },
          ),

          const SizedBox(height: 8),

          // Pilihan 3: QRIS
          _buildPaymentRadioTile(
            title: "QRIS Instant (GoPay, OVO, ShopeePay)",
            subtitle: 'Bebas biaya admin & konfirmasi instan',
            icon: Icons.qr_code_2_rounded,
            isSelected: _selectedPaymentMethod.startsWith('QRIS'),
            onTap: () {
              setState(() {
                _selectedPaymentMethod = "QRIS Instant (GoPay, OVO, ShopeePay)";
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRadioTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBF7) : const Color(0xFFFAF9F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOrange
                : const Color(0xFFEBE8E3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFEDDF)
                    : const Color(0xFFECEAE6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primaryOrange
                    : const Color(0xFF7E756F),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF7E756F),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isSelected
                  ? AppColors.primaryOrange
                  : const Color(0xFFB0AAA4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostSummary(int subtotal, int discount, int totalPayment) {
    final isPickup = _fulfillmentMethod == FulfillmentMethod.pickup;

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
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal Produk', formatRupiah(subtotal)),
                const SizedBox(height: 6),
                _buildSummaryRow(
                  'Diskon Membership Silver (10%)',
                  '-${formatRupiah(discount)}',
                  valueColor: AppColors.primaryOrange,
                ),
                const SizedBox(height: 6),
                if (isPickup) ...[
                  _buildSummaryRow(
                    'Biaya Ambil di Toko',
                    'Gratis (Rp 0)',
                    valueColor: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 6),
                  _buildSummaryRow(
                    'Biaya Layanan JNOVAMUSIC',
                    formatRupiah(_serviceFee),
                  ),
                ] else ...[
                  _buildSummaryRow(
                    'Biaya Pengiriman (JNE Cargo)',
                    formatRupiah(_shippingFee),
                  ),
                  const SizedBox(height: 6),
                  _buildSummaryRow(
                    'Biaya Penanganan Kayu & Asuransi',
                    'Rp 0 (Gratis)',
                    valueColor: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Biaya Layanan', formatRupiah(_serviceFee)),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Color(0xFFEBE8E3), height: 1),
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
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        Text(
                          'Termasuk PPN 11%',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF8E837D),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formatRupiah(totalPayment),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange,
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
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF6E6560)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimaryDark,
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
          Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF8E837D)),
          SizedBox(width: 4),
          Text(
            'Transaksi aman dengan enkripsi SSL 256-bit',
            style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPaymentBar(List<CartItem> items, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF0EDE9), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                style: TextStyle(fontSize: 10.5, color: Color(0xFF7E756F)),
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
                backgroundColor: AppColors.primaryOrange,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'Bayar Sekarang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
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
