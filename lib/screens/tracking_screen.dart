import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman LACAK PENGIRIMAN JNOVAMUSIC sesuai desain Figma 7
class TrackingScreen extends StatelessWidget {
  final OrderModel? order;
  final VoidCallback? onBack;

  const TrackingScreen({
    super.key,
    this.order,
    this.onBack,
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

  @override
  Widget build(BuildContext context) {
    final activeOrder = order ??
        (ModalRoute.of(context)?.settings.arguments as OrderModel?) ??
        OrderService.instance.currentOrder ??
        OrderService.instance.orders.first;

    final item = activeOrder.items.isNotEmpty ? activeOrder.items.first : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, Title, Help icon
            _buildHeader(context),

            // Konten Pelacakan yang dapat di-scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Kartu Estimasi Tiba & Status Ekspedisi
                    _buildArrivalCard(context, activeOrder),

                    const SizedBox(height: 14),

                    // Muatan Paket
                    if (item != null) _buildPackagePayloadCard(item),

                    const SizedBox(height: 14),

                    // Riwayat Perjalanan Paket (Timeline)
                    _buildTrackingTimelineCard(activeOrder),

                    const SizedBox(height: 14),

                    // Alamat Tujuan
                    _buildDestinationAddressCard(activeOrder),

                    const SizedBox(height: 16),

                    // Tombol Aksi Bawah
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
            'Jnovamusic Lacak Pengiriman',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bantuan pelacakan dan estimasi ekspedisi.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: Color(0xFF7E756F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivalCard(BuildContext context, OrderModel activeOrder) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: AppColors.primaryOrange),
                    SizedBox(width: 4),
                    Text(
                      'Dalam Pengiriman',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                activeOrder.orderNumber,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8E837D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Box Estimasi Tiba
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0C2), width: 1.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDDF),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    size: 20,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTIMASI TIBA',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF8E837D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeOrder.estimatedArrival,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const Text(
                      'Tiba dalam 1 - 2 hari lagi',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Detail Ekspedisi & Resi
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 14, color: Color(0xFFB45309)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  activeOrder.courierName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Peti Kayu',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Nomor Resi: ',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF7E756F),
                ),
              ),
              Text(
                activeOrder.trackingNumber,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: activeOrder.trackingNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nomor resi berhasil disalin!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFD4D0C8)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 9, color: Color(0xFF7E756F)),
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
        ],
      ),
    );
  }

  Widget _buildPackagePayloadCard(dynamic item) {
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
                'MUATAN PAKET',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF8E837D),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ORIGINAL INSTRUMENT',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryOrange,
                  ),
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
                  child: Image.asset(
                    item.product.image,
                    fit: BoxFit.contain,
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
                      'Finish: ${item.product.colorVariants.isNotEmpty ? item.product.colorVariants.first : '3-Color Sunburst'}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF7E756F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '1 Unit + Hard Case Kayu + QC Luthier',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
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

  Widget _buildTrackingTimelineCard(OrderModel activeOrder) {
    final steps = activeOrder.trackingSteps;

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
          const Text(
            'Riwayat Perjalanan Paket',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Pembaruan Terakhir: 19 Mei 2025, 08:15 WIB',
            style: TextStyle(
              fontSize: 9.5,
              color: Color(0xFF8E837D),
            ),
          ),
          const SizedBox(height: 12),

          // Timeline steps
          Column(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;

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
                            color: step.isCompleted
                                ? AppColors.primaryOrange
                                : (step.isActive
                                    ? const Color(0xFFFFEDDF)
                                    : const Color(0xFFE5E2DC)),
                            border: step.isActive
                                ? Border.all(
                                    color: AppColors.primaryOrange, width: 2)
                                : null,
                          ),
                          child: step.isCompleted
                              ? const Icon(Icons.check,
                                  size: 9, color: Colors.white)
                              : (step.isActive
                                  ? Center(
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryOrange,
                                        ),
                                      ),
                                    )
                                  : null),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              color: step.isCompleted
                                  ? AppColors.primaryOrange
                                  : const Color(0xFFE5E2DC),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: step.isActive || step.isCompleted
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: step.isActive
                                        ? AppColors.primaryOrange
                                        : AppColors.textPrimaryDark,
                                  ),
                                ),
                                if (step.time.isNotEmpty)
                                  Text(
                                    step.time,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: Color(0xFF8E837D),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step.description,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF6E6560),
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
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationAddressCard(OrderModel activeOrder) {
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
              Icon(Icons.location_on_outlined,
                  size: 15, color: AppColors.primaryOrange),
              SizedBox(width: 6),
              Text(
                'Alamat Tujuan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${activeOrder.recipientName} (${activeOrder.recipientPhone})',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            activeOrder.recipientAddress,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6E6560),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Menghubungkan ke layanan pelacakan JNE Cargo...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD4D0C8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 14, color: AppColors.textPrimaryDark),
                        SizedBox(width: 4),
                        Text(
                          'JNE Cargo',
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
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Menghubungi Customer Service JNOVAMUSIC...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD4D0C8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.headset_mic_outlined,
                            size: 14, color: AppColors.textPrimaryDark),
                        SizedBox(width: 4),
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
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => _handleBack(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Kembali ke Detail Pesanan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
