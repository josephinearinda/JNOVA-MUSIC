import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../services/cart_service.dart';
import '../services/currency_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/cart_item_card.dart';

/// Halaman Keranjang Saya JNOVAMUSIC sesuai spesifikasi desain Figma
class CartScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCheckout;
  final VoidCallback? onOpenProfile;

  const CartScreen({
    super.key,
    this.onBack,
    this.onCheckout,
    this.onOpenProfile,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService.instance;
  final CurrencyService _currencyService = CurrencyService.instance;

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_onCartUpdate);
    _currencyService.addListener(_onCartUpdate);
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartUpdate);
    _currencyService.removeListener(_onCartUpdate);
    super.dispose();
  }

  void _onCartUpdate() {
    if (mounted) setState(() {});
  }

  /// Dialog konfirmasi Kosongkan Keranjang
  Future<void> _confirmClearCart() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content: const Text(
          'Seluruh barang di dalam keranjang belanja akan dihapus.',
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
            child: const Text('Kosongkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _cartService.clearCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _cartService.items;
    final int selectedCount = _cartService.selectedCount;
    final int totalPayment = _cartService.totalPayment;
    final int discountAmount = _cartService.discountAmount;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // A. Header
            _buildHeader(),

            // Konten Scrollable Keranjang
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          // B. Baris "Pilih Semua" & "Hapus Pilihan"
                          _buildSelectAllBar(selectedCount),

                          const SizedBox(height: 12),

                          // C. Daftar Item Produk
                          ...items.map(
                            (item) => CartItemCard(
                              item: item,
                              onToggleSelect: (_) =>
                                  _cartService.toggleItemSelection(item.product.id),
                              onIncrement: () =>
                                  _cartService.updateQuantity(item.product.id, 1),
                              onDecrement: () =>
                                  _cartService.updateQuantity(item.product.id, -1),
                              onRemove: () =>
                                  _cartService.removeItem(item.product.id),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // D. Kartu Membership (Silver Member)
                          _buildMembershipCard(discountAmount),

                          const SizedBox(height: 14),

                          // E. Kartu Garansi Instrumen & Kayu Aman
                          _buildGuaranteeCard(),

                          const SizedBox(height: 14),

                          // F. Ringkasan Belanja
                          _buildPriceSummary(selectedCount, discountAmount, totalPayment),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),

            // G. Bottom Payment Bar (Sticky di atas Bottom Navigation)
            if (items.isNotEmpty)
              _buildBottomPaymentBar(selectedCount, totalPayment, discountAmount),

            // Bottom Navigation Bar
            AppBottomNav(
              currentIndex: 3, // Tab Pesanan / Transaksi
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else if (index == 1) {
                  Navigator.pushReplacementNamed(context, '/all-products');
                } else if (index == 2) {
                  Navigator.pushNamed(context, '/membership');
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

  /// Header Keranjang Saya
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
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
          const SizedBox(width: 8),

          // Judul
          const Text(
            'Keranjang Saya',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const Spacer(),

          // Aksi "Kosongkan"
          if (_cartService.items.isNotEmpty)
            GestureDetector(
              onTap: _confirmClearCart,
              child: Row(
                children: const [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 15,
                    color: Color(0xFF6E6560),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Kosongkan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6E6560),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 10),

          // Profil Cokelat
          GestureDetector(
            onTap: widget.onOpenProfile,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF8D4315),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Baris "Pilih Semua (3)" dan "Hapus Pilihan"
  Widget _buildSelectAllBar(int selectedCount) {
    final bool isAll = _cartService.isAllSelected;

    return Row(
      children: [
        // Checkbox Pilih Semua
        GestureDetector(
          onTap: () => _cartService.toggleSelectAll(!isAll),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isAll ? AppColors.primaryOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isAll ? AppColors.primaryOrange : const Color(0xFFCCCCCC),
                    width: 1.5,
                  ),
                ),
                child: isAll
                    ? const Icon(
                        Icons.check,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pilih Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '($selectedCount)',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Tombol Hapus Pilihan
        if (selectedCount > 0)
          GestureDetector(
            onTap: () => _cartService.removeSelected(),
            child: Row(
              children: const [
                Icon(
                  Icons.delete_sweep_outlined,
                  size: 15,
                  color: Color(0xFF6E6560),
                ),
                SizedBox(width: 4),
                Text(
                  'Hapus Pilihan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6E6560),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Kartu Silver Member
  Widget _buildMembershipCard(int discountAmount) {
    final int points = _cartService.currentPoints;
    final int target = _cartService.targetPoints;
    final double progress = (points / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF6F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFDEC9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Member
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Silver Member Terdeteksi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE3D2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _cartService.userTier,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFA64A13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Teks Benefit Diskon
          Text(
            'Diskon 10% (Hemat ${formatRupiah(discountAmount)}) otomatis terpasang. Kumpulkan ${target - points} poin lagi menuju Gold untuk benefit Bebas Ongkir se-Indonesia!',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6E6560),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),

          // Progress Bar Poin
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Silver (${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} Poin)',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                'Target Gold: ${target.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Linear Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFEADBCE),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
              minHeight: 5.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Garansi Instrumen & Kayu Aman
  Widget _buildGuaranteeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF6F3EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF9E562A),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garansi Instrumen & Kayu Aman',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Kemasan packing kayu standar ekspor + asuransi 100% penggantian unit.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF7E756F),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: Color(0xFFBBBBBB),
          ),
        ],
      ),
    );
  }

  /// Ringkasan Belanja
  Widget _buildPriceSummary(int selectedCount, int discountAmount, int totalPayment) {
    final int subtotal = _cartService.subtotal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Belanja',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 12),

          // Total Harga (N Barang)
          _buildSummaryRow(
            label: 'Total Harga ($selectedCount Barang)',
            value: formatRupiah(subtotal),
            isBold: true,
          ),
          const SizedBox(height: 8),

          // Diskon Silver Member
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text(
                    'Diskon Silver Member (10%)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6E6560),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: Color(0xFFA64A13),
                  ),
                ],
              ),
              Text(
                '-${formatRupiah(discountAmount)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA64A13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Estimasi Ongkir & Asuransi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimasi Ongkir & Asuransi',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6E6560),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F2F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Packing Kayu',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5A524D),
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                'Dihitung saat\ncheckout',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF7E756F),
                  height: 1.25,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
          ),

          // Total Pembayaran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                formatRupiah(totalPayment),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isBold ? AppColors.textPrimaryDark : const Color(0xFF6E6560),
            fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }

  /// Sticky Bottom Payment Bar
  Widget _buildBottomPaymentBar(int selectedCount, int totalPayment, int discountAmount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total & Penghematan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF7E756F),
                  ),
                ),
                Text(
                  formatRupiah(totalPayment),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryOrange,
                  ),
                ),
                if (discountAmount > 0)
                  Text(
                    'Hemat ${formatRupiah(discountAmount)}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8D4315),
                    ),
                  ),
              ],
            ),
          ),

          // Tombol Lanjut Checkout
          ElevatedButton(
            onPressed: selectedCount == 0
                ? null
                : () {
                    if (widget.onCheckout != null) {
                      widget.onCheckout!();
                    } else {
                      Navigator.pushNamed(context, '/checkout');
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              disabledBackgroundColor: const Color(0xFFCCCCCC),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lanjut Checkout ($selectedCount)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Empty State ketika keranjang kosong
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
                Icons.shopping_cart_outlined,
                size: 36,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keranjangmu Masih Kosong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Temukan berbagai instrumen musik berkualitas dan masukkan ke keranjang belanja.',
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
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Mulai Belanja',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
