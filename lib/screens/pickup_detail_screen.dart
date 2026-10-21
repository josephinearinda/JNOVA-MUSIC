import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/qr_code_widget.dart';

/// Halaman DETAIL PENGAMBILAN JNOVAMUSIC sesuai desain Figma 8
class PickupDetailScreen extends StatelessWidget {
  final OrderModel? order;
  final VoidCallback? onBack;
  final VoidCallback? onOpenOrderDetail;

  const PickupDetailScreen({
    super.key,
    this.order,
    this.onBack,
    this.onOpenOrderDetail,
  });

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/all-products');
    }
  }

  void _handleOpenOrderDetail(BuildContext context, OrderModel activeOrder) {
    if (onOpenOrderDetail != null) {
      onOpenOrderDetail!();
    } else {
      Navigator.pushNamed(context, '/order-detail', arguments: activeOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrder =
        order ??
        (ModalRoute.of(context)?.settings.arguments as OrderModel?) ??
        OrderService.instance.currentOrder ??
        OrderService.instance.orders.first;

    final store = activeOrder.pickupStore;
    final item = activeOrder.items.isNotEmpty ? activeOrder.items.first : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, Title, Profile
            _buildHeader(context),

            // Konten Detail Pengambilan yang dapat di-scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Status Bar & Timeline Pengambilan
                    _buildStatusAndTimeline(activeOrder),

                    const SizedBox(height: 14),

                    // Kartu Kode Pengambilan Resmi & QR Code
                    _buildPickupCodeCard(context, activeOrder),

                    const SizedBox(height: 14),

                    // Lokasi Pengambilan
                    _buildPickupLocationCard(context, store),

                    const SizedBox(height: 14),

                    // Ringkasan Produk
                    if (item != null) _buildProductSummaryCard(item),

                    const SizedBox(height: 14),

                    // Petunjuk Singkat
                    _buildQuickInstructionsCard(store?.name),

                    const SizedBox(height: 18),

                    // Tombol Aksi Utama
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
            onTap: () => _handleBack(context),
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
            'Detail Pengambilan',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFB45309),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndTimeline(OrderModel activeOrder) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AMBIL DI TOKO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '• SIAP DIAMBIL',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Siap Diambil di Toko',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            activeOrder.orderNumber,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Progress Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimelineStep('Dibuat', true, false),
              _buildTimelineDivider(true),
              _buildTimelineStep('Dibayar', true, false),
              _buildTimelineDivider(true),
              _buildTimelineStep('Diproses', true, false),
              _buildTimelineDivider(true),
              _buildTimelineStep('Siap Diambil', false, true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String label, bool isDone, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? AppColors.primaryOrange
                : (isActive
                      ? const Color(0xFFFFEDDF)
                      : const Color(0xFFE5E2DC)),
            border: isActive
                ? Border.all(color: AppColors.primaryOrange, width: 2)
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : (isActive
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryOrange,
                          ),
                        )
                      : null),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? AppColors.primaryOrange
                : (isDone
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF8E837D)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: isCompleted ? AppColors.primaryOrange : const Color(0xFFE5E2DC),
      ),
    );
  }

  Widget _buildPickupCodeCard(BuildContext context, OrderModel activeOrder) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEDD5), width: 1.2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 14,
                color: AppColors.primaryOrange,
              ),
              SizedBox(width: 4),
              Text(
                'Kode Pengambilan Resmi',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8E837D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Code Pill + Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFE0C2), width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeOrder.pickupCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: activeOrder.pickupCode),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kode pengambilan berhasil disalin!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: Color(0xFF7E756F),
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Salin Kode',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7E756F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // QR Code
          QrCodeWidget(data: activeOrder.pickupCode, size: 130),

          const SizedBox(height: 12),

          const Text(
            'Tunjukkan kode ini kepada petugas kasir/toko saat mengambil pesanan.',
            textAlign: TextAlign.center,
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

  Widget _buildPickupLocationCard(BuildContext context, dynamic store) {
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
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Lokasi Pengambilan',
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
                  'CABANG UTAMA',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A524D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            store?.name ?? 'JNOVAMUSIC Flagship Jakarta',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            store?.address ?? 'Jl. Sultan Iskandar Muda No. 88, Kebayoran Lama, Jakarta Selatan',
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF6E6560),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 12,
                color: Color(0xFF8E837D),
              ),
              const SizedBox(width: 4),
              Text(
                'Jam Operasional: ${store?.operatingHours ?? '10.00 - 21.00 WIB'}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF6E6560)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Membuka peta navigasi ke toko.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD4D0C8), width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.primaryOrange,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Lihat Lokasi',
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
        ],
      ),
    );
  }

  Widget _buildProductSummaryCard(dynamic item) {
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
                    Icons.inventory_2_outlined,
                    size: 15,
                    color: Color(0xFF7E756F),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Ringkasan Produk',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
              Text(
                '${item.quantity} Unit',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7E756F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 44,
                  height: 44,
                  color: Colors.white,
                  child: Image.asset(item.product.image, fit: BoxFit.contain),
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
                      'Jumlah: ${item.quantity} Unit',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF7E756F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(item.product.price),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange,
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

  Widget _buildQuickInstructionsCard(String? storeName) {
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
                'Petunjuk Singkat',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildQuickStep(
            '1',
            'Tunggu notifikasi status pesanan Siap Diambil.',
          ),
          const SizedBox(height: 6),
          _buildQuickStep(
            '2',
            'Datang ke toko ${storeName ?? 'JNOVAMUSIC Flagship Jakarta'} sesuai jam operasional (10.00 - 21.00 WIB).',
          ),
          const SizedBox(height: 6),
          _buildQuickStep(
            '3',
            'Tunjukkan kode pengambilan kepada kasir untuk verifikasi.',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStep(String number, String text) {
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

  Widget _buildActionButtons(BuildContext context, OrderModel activeOrder) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => _handleOpenOrderDetail(context, activeOrder),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Lihat Detail Pesanan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Menghubungi hotline toko: (021) 728-1920.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD4D0C8), width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: AppColors.textPrimaryDark,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Hubungi Toko',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
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
}
