import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/order_model.dart';
import '../models/store_branch.dart';
import '../services/order_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/qr_code_widget.dart';
import '../services/blockchain_certificate_service.dart';
import 'blockchain_certificate_page.dart';

/// Halaman DETAIL PESANAN JNOVAMUSIC dengan alur Ambil di Toko Resmi (Store Pickup)
/// sesuai standar showroom & luthier desk JNOVA MUSIC
class OrderDetailScreen extends StatefulWidget {
  final OrderModel? order;
  final VoidCallback? onBack;
  final VoidCallback? onOpenTracking;

  const OrderDetailScreen({
    super.key,
    this.order,
    this.onBack,
    this.onOpenTracking,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    OrderService.instance.addListener(_handleOrderStateChanged);
  }

  @override
  void dispose() {
    OrderService.instance.removeListener(_handleOrderStateChanged);
    super.dispose();
  }

  void _handleOrderStateChanged() {
    if (mounted) setState(() {});
  }

  void _handleBack(BuildContext context) {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _showCustomerServiceOptions(BuildContext context) async {
    final admin = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Hubungi Bantuan CS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_rounded),
              title: const Text('Admin 1'),
              subtitle: const Text('081575586614'),
              onTap: () => Navigator.pop(sheetContext, '6281575586614'),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_rounded),
              title: const Text('Admin 2'),
              subtitle: const Text('0882005171057'),
              onTap: () => Navigator.pop(sheetContext, '62882005171057'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (admin == null || !context.mounted) return;

    final uri = Uri.https('wa.me', '/$admin');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp tidak dapat dibuka.')),
        );
      }
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp tidak dapat dibuka.')),
        );
      }
    }
  }

  void _showQrModal(
    BuildContext context,
    OrderModel activeOrder,
    StoreBranch store,
  ) {
    final pickupCode = activeOrder.pickupCode.isNotEmpty
        ? activeOrder.pickupCode
        : 'PKP-8841-JNV';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4D0C8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QR Code Pengambilan Toko',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(child: QrCodeWidget(data: pickupCode, size: 150)),
            const SizedBox(height: 14),
            Text(
              pickupCode,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${store.name} • ${activeOrder.orderNumber}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7E756F),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEBE8E3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 15,
                    color: AppColors.primaryOrange,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tunjukkan QR Code ini kepada kasir atau luthier desk di store JNOVAMUSIC untuk verifikasi instrumen & unboxing bersama.',
                      style: TextStyle(fontSize: 10, color: Color(0xFF5A524D)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pickupCode));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode pengambilan disalin ke clipboard!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Salin Kode Pengambilan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = OrderService.instance.orders;
    final activeOrder =
        widget.order ??
        (ModalRoute.of(context)?.settings.arguments as OrderModel?) ??
        OrderService.instance.currentOrder ??
        (orders.isNotEmpty ? orders.first : null);

    if (activeOrder == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopAppBar(context),
              Expanded(child: _buildEmptyOrderState(context)),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: 3,
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

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar dengan Pesanan Saya, Notifikasi, Profil
            _buildTopAppBar(context),

            // Konten Detail Pesanan yang dapat di-scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-Header Order Code, Status & Badge Pickup Toko
                    _buildSubHeader(activeOrder),

                    const SizedBox(height: 12),

                    // Card Status Pesanan Ringkas & Jelas
                    _buildOrderStatusCard(activeOrder),

                    const SizedBox(height: 14),

                    // Informasi Toko Pengambilan
                    _buildPickupStoreInfoCard(context, activeOrder),

                    const SizedBox(height: 14),

                    // Produk yang Dipesan (Menampilkan seluruh item)
                    _buildOrderedProductsSection(activeOrder),

                    // Kartu Sertifikat Keaslian Blockchain Resmi
                    if (activeOrder.hasBlockchainCertificate) ...[
                      const SizedBox(height: 14),
                      _buildBlockchainCertificateOrderCard(context, activeOrder),
                    ],

                    const SizedBox(height: 14),

                    // Rincian Pembayaran
                    _buildPaymentDetailsCard(activeOrder),

                    const SizedBox(height: 16),

                    // Tombol Aksi (Pesanan Selesai, Unduh Invoice, CS, Beli Lagi)
                    _buildActionButtons(context, activeOrder),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3, // Pesanan tab aktif
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

  Widget _buildTopAppBar(BuildContext context) {
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pesanan Saya',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Pantau pembelian alat musikmu di sini.',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF7E756F)),
              ),
            ],
          ),
          const Spacer(),

          // Notifikasi Icon dengan badge dot
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tidak ada notifikasi baru untuk pesananmu.',
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: AppColors.textPrimaryDark,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Avatar profil brown circle
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
                size: 19,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(OrderModel activeOrder) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: Tombol Kembali di kiri & Badge Terverifikasi di kanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _handleBack(context),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activeOrder.isCompleted
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFFEFE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      activeOrder.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.storefront_rounded,
                      size: 12,
                      color: activeOrder.isCompleted
                          ? const Color(0xFF15803D)
                          : const Color(0xFFC2410C),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activeOrder.isCompleted
                          ? 'PESANAN SELESAI'
                          : 'PICKUP DI TOKO RESMI',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: activeOrder.isCompleted
                            ? const Color(0xFF15803D)
                            : const Color(0xFFC2410C),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Baris 2: Judul Detail Pesanan & Kode Pesanan (Orange)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail Pesanan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  activeOrder.orderNumber,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),

          // Baris 3: Tanggal & Waktu Pemesanan
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Color(0xFF7E756F),
              ),
              const SizedBox(width: 4),
              Text(
                activeOrder.dateFormatted.isNotEmpty
                    ? activeOrder.dateFormatted
                    : '18 Mei 2025, 14:32 WIB',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF7E756F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Baris 4: Informasi Metode Pemenuhan (Ambil di Toko Resmi)
          _buildFulfillmentBadge(),
        ],
      ),
    );
  }

  /// Badge Metode Pemenuhan Toko Resmi JNOVA MUSIC
  Widget _buildFulfillmentBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD8BF), width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.storefront_rounded,
            size: 20,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metode: Ambil di Toko Resmi (Store Pickup)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ambil langsung di gerai resmi pilihan & cek fisik bersama Luthier',
                  style: TextStyle(fontSize: 9.5, color: Color(0xFF7E756F)),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Color(0xFFFFEFE5),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Text(
              'GRATIS',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFFC2410C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard(OrderModel activeOrder) {
    final isCompleted = activeOrder.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF86EFAC)
              : const Color(0xFFFFD8BF),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFEDDF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.pending_actions_rounded,
              size: 22,
              color: isCompleted
                  ? const Color(0xFF15803D)
                  : AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted
                      ? 'Pesanan Selesai'
                      : 'Menunggu Pengambilan & Pembayaran',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isCompleted
                        ? const Color(0xFF15803D)
                        : const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isCompleted
                      ? 'Barang telah diambil & pembayaran telah diselesaikan di kasir toko. Poin reward telah masuk ke akun Anda.'
                      : 'Silakan kunjungi cabang toko terpilih. Cek fisik & tes suara instrumen bersama luthier kami, lalu lakukan pembayaran langsung di kasir toko.',
                  style: TextStyle(
                    fontSize: 10,
                    color: isCompleted
                        ? const Color(0xFF166534)
                        : const Color(0xFF7C2D12),
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

  Widget _buildPickupStoreInfoCard(
    BuildContext context,
    OrderModel activeOrder,
  ) {
    final store = activeOrder.pickupStore ?? StoreBranch.branches.first;
    final pickupCode = activeOrder.pickupCode.isNotEmpty
        ? activeOrder.pickupCode
        : 'PKP-8841-JNV';

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
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 15,
                      color: AppColors.primaryOrange,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Informasi Toko Pengambilan',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Siap Diambil',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'CABANG TOKO RESMI',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8E837D),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            store.name,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            store.address,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6E6560),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 12,
                color: Color(0xFF8E837D),
              ),
              const SizedBox(width: 3),
              Text(
                '${store.distance} • Buka: ${store.operatingHours}',
                style: const TextStyle(fontSize: 9.5, color: Color(0xFF7E756F)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Kode Pengambilan',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8E837D),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kode: $pickupCode',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC2410C),
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: pickupCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kode pengambilan disalin ke clipboard!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFD4D0C8)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        size: 10,
                        color: Color(0xFF7E756F),
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Salin',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7E756F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tombol QR Code Pengambilan & Navigasi
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showQrModal(context, activeOrder, store),
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEAE6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 14,
                          color: Color(0xFF2E2825),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Tampilkan QR Code',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E2825),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(store.getDirectionsUrl());
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Membuka rute ke ${store.name}...'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEAE6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_rounded,
                          size: 14,
                          color: Color(0xFF2E2825),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Petunjuk Arah',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E2825),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBE7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 11,
                  color: Color(0xFF5A524D),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Termasuk inspeksi intonasi gratis, cek fisik di Luthier Desk, & unboxing resmi.',
                    style: TextStyle(fontSize: 8.5, color: Color(0xFF5A524D)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderedProductsSection(OrderModel activeOrder) {
    final items = activeOrder.items;
    final totalUnits = items.fold<int>(0, (sum, i) => sum + i.quantity);

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
                'Produk yang Dipesan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEAE6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalUnits Unit (${items.length} Barang)',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5A524D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(color: Color(0xFFEBE8E3), height: 1),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 58,
                        height: 58,
                        color: Colors.white,
                        child: Stack(
                          children: [
                            Center(
                              child: Image.asset(
                                item.product.image,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 20,
                                  color: AppColors.placeholder,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              left: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF333333)
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Text(
                                  'ORIGINAL',
                                  style: TextStyle(
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item.product.variant.isNotEmpty
                                ? item.product.variant
                                : item.product.brand.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF7E756F),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDEAE6),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '${item.quantity} Unit',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5A524D),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '@ ${formatRupiah(item.product.price)}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF7E756F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Item',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6E6560),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  formatRupiah(item.itemTotal),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFC2410C),
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
              ],
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBE7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 12,
                  color: Color(0xFFC2410C),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Termasuk Free Hard Packaging Kayu, Deluxe Gigbag & Lembar QC Luthier Resmi.',
                    style: TextStyle(fontSize: 8.5, color: Color(0xFF5A524D)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard(OrderModel activeOrder) {
    const shippingFee = 0;
    final totalPayment =
        activeOrder.subtotal -
        activeOrder.discount +
        shippingFee +
        activeOrder.serviceFee;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rincian Pembayaran',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                'QRIS Instant',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7E756F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Subtotal Produk',
            formatRupiah(activeOrder.subtotal),
          ),
          if (activeOrder.discount > 0) ...[
            const SizedBox(height: 5),
            _buildDetailRow(
              'Diskon Membership',
              '- ${formatRupiah(activeOrder.discount)}',
              valueColor: const Color(0xFFC2410C),
              showInfoIcon: true,
            ),
          ],
          const SizedBox(height: 5),
          _buildDetailRow(
            'Biaya Ambil di Toko',
            'Gratis (Rp 0)',
            valueColor: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 5),
          _buildDetailRow(
            'Asuransi & Setup Khusus Toko',
            'Rp 0 (Promo Gratis)',
            valueColor: const Color(0xFFC2410C),
          ),
          const SizedBox(height: 5),
          _buildDetailRow(
            'Biaya Layanan Transaksi',
            formatRupiah(activeOrder.serviceFee),
          ),
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
                    'TOTAL PEMBAYARAN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Text(
                    'Termasuk PPN 11%',
                    style: TextStyle(fontSize: 8.5, color: Color(0xFF8E837D)),
                  ),
                ],
              ),
              Text(
                formatRupiah(totalPayment),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC2410C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Baris Metode Pembayaran
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F4F0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEBE8E3)),
            ),
            child: Row(
              children: [
                const Text(
                  'Metode',
                  style: TextStyle(fontSize: 10, color: Color(0xFF7E756F)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.point_of_sale_rounded,
                        size: 13,
                        color: Color(0xFF8E837D),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          activeOrder.isCompleted
                              ? '${activeOrder.paymentMethod} • Lunas di Kasir'
                              : '${activeOrder.paymentMethod} • Bayar saat Pengambilan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool showInfoIcon = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF6E6560)),
                ),
              ),
              if (showInfoIcon) ...[
                const SizedBox(width: 3),
                const Icon(
                  Icons.help_outline_rounded,
                  size: 11,
                  color: Color(0xFF8E837D),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimaryDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderModel activeOrder) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Tombol Pesanan Selesai (Idempotent)
          if (activeOrder.isCompleted)
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Color(0xFF15803D),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pesanan Telah Selesai',
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _confirmOrderCompletion(context, activeOrder),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Pesanan Selesai',
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

          const SizedBox(height: 10),

          // Tombol Bantuan CS & Beli Lagi dengan grey pill background
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCustomerServiceOptions(context),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEAE6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.headset_mic_outlined,
                          size: 14,
                          color: AppColors.textPrimaryDark,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Bantuan CS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/all-products');
                  },
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEAE6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 15,
                          color: AppColors.textPrimaryDark,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Beli Lagi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryDark,
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

  Future<void> _confirmOrderCompletion(
    BuildContext context,
    OrderModel order,
  ) async {
    final branchName = order.pickupStore?.name ?? 'Toko JNOVAMUSIC';
    final pointsEarned = (order.totalPayment / 10000).floor();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: AppColors.primaryOrange,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Konfirmasi Selesai',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'Pastikan Anda telah mengambil barang dan menyelesaikan pembayaran di kasir $branchName.\n\nAnda akan mendapatkan +$pointsEarned Poin Membership JNOVAMUSIC.',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF5A524D),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Belum',
              style: TextStyle(color: Color(0xFF7E756F)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ya, Sudah Selesai',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await OrderService.instance.completeOrder(order);
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pesanan berhasil diselesaikan! +$pointsEarned Poin ditambahkan ke Membership Anda.',
            ),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildEmptyOrderState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 44,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kamu belum memiliki riwayat pesanan aktif. Kunjungi showroom katalog kami dan temukan alat musik impianmu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF7E756F),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/all-products');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Mulai Belanja',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockchainCertificateOrderCard(
    BuildContext context,
    OrderModel order,
  ) {
    final eligibleItems = order.blockchainItems;
    final firstItem = eligibleItems.isNotEmpty ? eligibleItems.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E172E), Color(0xFF120E1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFE5A93C).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5A93C).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: const Color(0xFF2E2248),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF9E86FF), width: 0.8),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: Color(0xFFD6C7FF),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sertifikat Keaslian Blockchain Terbit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Smart Contract ERC-721 di Jaringan Polygon',
                      style: TextStyle(fontSize: 9.5, color: Color(0xFFBFB5D1)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3B2E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ON-CHAIN',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF34D399),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pesanan ini mencakup ${eligibleItems.length} instrumen dengan Sertifikat Keaslian Digital resmi yang tercatat di blockchain Polygon.',
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFFD1C8DC),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () {
                if (firstItem != null) {
                  final buyerName = BlockchainCertificateService.instance
                      .getCurrentBuyerName(order: order);

                  final cert = BlockchainCertificateService.instance
                      .getCertificateForProduct(
                    firstItem.product,
                    orderNumber: order.orderNumber,
                    ownerName: buyerName,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BlockchainCertificatePage(certificate: cert),
                    ),
                  );
                } else {
                  Navigator.pushNamed(context, '/blockchain-certificates');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.workspace_premium_rounded, size: 16),
              label: const Text(
                'Buka Sertifikat Keaslian NFT',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
