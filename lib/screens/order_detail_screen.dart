import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/order_model.dart';
import '../models/store_branch.dart';
import '../services/order_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/qr_code_widget.dart';

/// Halaman DETAIL PESANAN JNOVAMUSIC dengan interaktivitas penuh
/// antara pilihan Pengiriman Rumah dan Ambil di Toko sesuai desain Figma
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
  bool? _isDelivery;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDelivery == null) {
      final activeOrder =
          widget.order ??
          (ModalRoute.of(context)?.settings.arguments as OrderModel?) ??
          OrderService.instance.currentOrder ??
          OrderService.instance.orders.first;
      _isDelivery =
          activeOrder.fulfillmentMethod == FulfillmentMethod.delivery;
    }
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

  void _handleOpenTracking(BuildContext context, OrderModel activeOrder) {
    if (widget.onOpenTracking != null) {
      widget.onOpenTracking!();
    } else {
      Navigator.pushNamed(context, '/tracking', arguments: activeOrder);
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
            Center(
              child: QrCodeWidget(
                data: pickupCode,
                size: 150,
              ),
            ),
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
    final activeOrder =
        widget.order ??
        (ModalRoute.of(context)?.settings.arguments as OrderModel?) ??
        OrderService.instance.currentOrder ??
        OrderService.instance.orders.first;

    final item = activeOrder.items.isNotEmpty ? activeOrder.items.first : null;
    final isDelivery = _isDelivery ?? true;

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
                    // Sub-Header Order Code, Status & Capsule Switcher
                    _buildSubHeader(activeOrder, isDelivery),

                    const SizedBox(height: 12),

                    // Status Pesanan Timeline (Dinamis sesuai pengiriman vs ambil di toko)
                    _buildOrderStatusTimeline(activeOrder, isDelivery),

                    const SizedBox(height: 14),

                    // Informasi Pengiriman / Pengambilan Toko
                    if (isDelivery)
                      _buildShippingInfoCard(context, activeOrder)
                    else
                      _buildPickupStoreInfoCard(context, activeOrder),

                    const SizedBox(height: 14),

                    // Produk yang Dipesan
                    if (item != null) _buildOrderedProductCard(item),

                    const SizedBox(height: 14),

                    // Rincian Pembayaran
                    _buildPaymentDetailsCard(activeOrder, isDelivery),

                    const SizedBox(height: 16),

                    // Tombol Aksi (Unduh Invoice, CS, Beli Lagi)
                    _buildActionButtons(context),

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
                      content: Text('Tidak ada notifikasi baru untuk pesananmu.'),
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

  Widget _buildSubHeader(OrderModel activeOrder, bool isDelivery) {
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
                  color: const Color(0xFFFFEFE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: Color(0xFFC2410C),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'PEMBAYARAN TERVERIFIKASI',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFC2410C),
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
              Text(
                activeOrder.orderNumber,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC2410C),
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

          // Baris 4: Capsule Switcher Interaktif: Pengiriman Rumah vs Ambil di Toko
          _buildFulfillmentCapsule(isDelivery),
        ],
      ),
    );
  }

  /// Capsule Toggle Switcher interaktif yang dapat diklik untuk beralih
  /// antara "Pengiriman Rumah" dan "Ambil di Toko"
  Widget _buildFulfillmentCapsule(bool isDelivery) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEAE6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          // Tab Pengiriman Rumah
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!isDelivery) {
                  setState(() {
                    _isDelivery = true;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isDelivery ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: isDelivery
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 14,
                        color: isDelivery
                            ? const Color(0xFF2E2825)
                            : const Color(0xFF6E6560),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pengiriman Rumah',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isDelivery
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isDelivery
                              ? const Color(0xFF2E2825)
                              : const Color(0xFF6E6560),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tab Ambil di Toko
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (isDelivery) {
                  setState(() {
                    _isDelivery = false;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: !isDelivery ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: !isDelivery
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 14,
                        color: !isDelivery
                            ? const Color(0xFF2E2825)
                            : const Color(0xFF6E6560),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ambil di Toko',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: !isDelivery
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: !isDelivery
                              ? const Color(0xFF2E2825)
                              : const Color(0xFF6E6560),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusTimeline(OrderModel activeOrder, bool isDelivery) {
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
              const Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Status Pesanan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isDelivery ? 'DALAM PENGIRIMAN' : 'SIAP DIAMBIL',
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Timeline vertikal dinamis
          _buildVerticalTimelineStep(
            'Pesanan Dibuat',
            '18 Mei 2025, 14:32 WIB',
            isCompleted: true,
          ),
          _buildVerticalTimelineStep(
            'Pembayaran Dikonfirmasi',
            'Otomatis via QRIS Instant',
            isCompleted: true,
          ),
          _buildVerticalTimelineStep(
            isDelivery ? 'QC Luthier & Packing Kayu' : 'QC Luthier & Setup Khusus',
            isDelivery
                ? 'Intonasi, action neck & segel lulus inspeksi'
                : 'Intonasi & action neck siap di luthier corner',
            isCompleted: true,
          ),
          _buildVerticalTimelineStep(
            isDelivery ? 'Dalam Pengiriman •' : 'Siap Diambil di Toko •',
            isDelivery
                ? 'Kurir Cargo sedang menuju alamat tujuan\n📅 Estimasi tiba: 20 Mei 2025'
                : 'Pesanan telah siap di luthier corner cabang Flagship.\n📅 Batas pengambilan: 25 Mei 2025',
            isActive: true,
          ),
          _buildVerticalTimelineStep(
            'Pesanan Selesai',
            isDelivery
                ? 'Konfirmasi penerimaan instrumen'
                : 'Serah terima instrumen di store',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalTimelineStep(
    String title,
    String desc, {
    bool isCompleted = false,
    bool isActive = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFFC2410C)
                      : (isActive
                            ? const Color(0xFFFFEDDF)
                            : const Color(0xFFE5E2DC)),
                  border: isActive
                      ? Border.all(color: const Color(0xFFC2410C), width: 2)
                      : null,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 9, color: Colors.white)
                    : (isActive
                          ? Center(
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFC2410C),
                                ),
                              ),
                            )
                          : null),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isCompleted
                        ? const Color(0xFFC2410C)
                        : const Color(0xFFE5E2DC),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isActive || isCompleted
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isActive
                          ? const Color(0xFFC2410C)
                          : AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF7E756F),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfoCard(BuildContext context, OrderModel activeOrder) {
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
              const Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 15,
                    color: AppColors.primaryOrange,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Informasi Pengiriman',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEAE6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Special Cargo',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A524D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'PENERIMA',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8E837D),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${activeOrder.recipientName} (${activeOrder.recipientPhone})',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            activeOrder.recipientAddress,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6E6560),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kurir & Layanan',
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
                activeOrder.courierName,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: activeOrder.trackingNumber),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nomor resi disalin ke clipboard!'),
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
          const SizedBox(height: 2),
          Text(
            'No. Resi : ${activeOrder.trackingNumber}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFFC2410C),
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Lacak Pengiriman Real-time sesuai desain
          GestureDetector(
            onTap: () => _handleOpenTracking(context, activeOrder),
            child: Container(
              width: double.infinity,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFECEAE6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.radar_rounded,
                    size: 14,
                    color: Color(0xFF2E2825),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Lacak Pengiriman Real-time',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E2825),
                    ),
                  ),
                ],
              ),
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
              const Row(
                children: [
                  Icon(
                    Icons.storefront_rounded,
                    size: 15,
                    color: AppColors.primaryOrange,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Informasi Toko Pengambilan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Membuka rute maps ke ${store.name}...'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
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

  Widget _buildOrderedProductCard(dynamic item) {
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
                'Produk yang Dipesan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                '1 Barang',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7E756F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                            color: const Color(0xFF333333).withValues(alpha: 0.85),
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
                          : '3-Color Sunburst • Maple Neck',
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
                        Text(
                          '@ ${formatRupiah(item.product.price)}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF7E756F),
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
                        Text(
                          formatRupiah(item.itemTotal),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC2410C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildPaymentDetailsCard(OrderModel activeOrder, bool isDelivery) {
    // Ongkos kirim hanya berlaku saat delivery
    final shippingFee = isDelivery ? activeOrder.shippingFee : 0;
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
          const SizedBox(height: 5),
          _buildDetailRow(
            'Diskon Silver Tier (10%)',
            '- ${formatRupiah(activeOrder.discount)}',
            valueColor: const Color(0xFFC2410C),
            showInfoIcon: true,
          ),
          const SizedBox(height: 5),
          if (isDelivery) ...[
            _buildDetailRow(
              'Ongkos Kirim (JNE Cargo)',
              formatRupiah(activeOrder.shippingFee),
            ),
            const SizedBox(height: 5),
            _buildDetailRow(
              'Asuransi & Packing Kayu Khusus',
              'Rp 0 (Promo Gratis)',
              valueColor: const Color(0xFFC2410C),
            ),
          ] else ...[
            _buildDetailRow(
              'Biaya Ambil di Toko',
              'Gratis (Rp 0)',
              valueColor: const Color(0xFF16A34A),
            ),
            const SizedBox(height: 5),
            _buildDetailRow(
              'Asuransi & Packing Khusus Toko',
              'Rp 0 (Promo Gratis)',
              valueColor: const Color(0xFFC2410C),
            ),
          ],
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Metode',
                  style: TextStyle(fontSize: 10, color: Color(0xFF7E756F)),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 13,
                      color: Color(0xFF8E837D),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'QRIS • Lunas (Otomatis)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryDark,
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

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool showInfoIcon = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6E6560)),
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
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Tombol Unduh E-Invoice (PDF) Solid Orange
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'E-Invoice resmi berhasil diunduh ke perangkat (PDF).',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Unduh E-Invoice (PDF)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Menghubungkan ke Customer Care JNOVAMUSIC...',
                        ),
                        duration: Duration(seconds: 1),
                      ),
                    );
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
}
