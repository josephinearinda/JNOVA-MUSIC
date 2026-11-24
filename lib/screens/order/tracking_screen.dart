import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jnova/core/constants/app_colors.dart';
import 'package:jnova/models/order_model.dart';
import 'package:jnova/services/order_service.dart';
import 'package:jnova/widgets/app_bottom_nav.dart';

/// Halaman LACAK PENGIRIMAN JNOVAMUSIC sesuai desain Figma 7
class TrackingScreen extends StatelessWidget {
  final OrderModel? order;
  final VoidCallback? onBack;

  const TrackingScreen({super.key, this.order, this.onBack});

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/all-products');
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
                  color: AppColors.textPrimaryDark, // Warna ikon ikon untuk "Hubungi Bantuan CS"
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

    if (admin != null && context.mounted) {
      await _openWhatsApp(context, admin);
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final uri = Uri.https('wa.me', '/$phoneNumber');
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

  @override
  Widget build(BuildContext context) {
    final orders = OrderService.instance.orders;
    final activeOrder =
        order ??
        (ModalRoute.of(context)?.settings.arguments as OrderModel?) ??
        OrderService.instance.currentOrder ??
        (orders.isNotEmpty ? orders.first : null);

    if (activeOrder == null) {
      return Scaffold(
        backgroundColor: AppColors.white, // Warna latar kotak untuk "Tidak ada pesanan aktif untuk dilacak."
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Expanded(
                child: Center(
                  child: Text(
                    'Tidak ada pesanan aktif untuk dilacak.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7E756F), // Warna teks pada "Tidak ada pesanan aktif untuk dilacak."
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final item = activeOrder.items.isNotEmpty ? activeOrder.items.first : null;

    return Scaffold(
      backgroundColor: AppColors.white, // Warna latar kotak untuk "Tidak ada pesanan aktif untuk dilacak."
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
            onTap: () => _handleBack(context),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: AppColors.textPrimaryDark, // Warna ikon ikon untuk "Jnovamusic Lacak Pengiriman"
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Jnovamusic Lacak Pengiriman',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark, // Warna ikon ikon untuk "Jnovamusic Lacak Pengiriman"
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => _showCustomerServiceOptions(context),
            child: const Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: Color(
                0xFF7E756F,
              ), // Warna ikon ikon untuk "Jnovamusic Lacak Pengiriman"
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
        color: const Color(
          0xFFFFFBF7,
        ), // Warna border atau garis tepi untuk "Jnovamusic Lacak Pengiriman"
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(
            0xFFFFEDD5,
          ), // Warna border atau garis tepi untuk "Jnovamusic Lacak Pengiriman"
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE5), // Warna latar kotak atau kartu untuk "Jnovamusic Lacak Pengiriman"
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 7,
                      color: AppColors.primaryOrange, // Warna ikon ikon untuk "Dalam Pengiriman"
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Dalam Pengiriman',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange, // Warna teks pada "Dalam Pengiriman"
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
                  color: Color(
                    0xFF8E837D,
                  ), // Warna teks pada "Dalam Pengiriman"
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Box Estimasi Tiba
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white, // Warna border atau garis tepi untuk "Dalam Pengiriman"
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(
                  0xFFFFE0C2,
                ), // Warna border atau garis tepi untuk "Dalam Pengiriman"
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFEDDF,
                    ), // Warna ikon ikon untuk "Dalam Pengiriman"
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 20,
                    color: AppColors.primaryOrange, // Warna ikon ikon untuk "Dalam Pengiriman"
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS PENGAMBILAN',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(
                          0xFF8E837D,
                        ), // Warna teks pada "STATUS PENGAMBILAN"
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeOrder.isCompleted
                          ? 'Pesanan Selesai'
                          : 'Siap Diambil di Toko',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark, // Warna teks pada "Siap Diambil di Toko"
                      ),
                    ),
                    Text(
                      activeOrder.isCompleted
                          ? 'Barang telah diambil & lunas di kasir'
                          : 'Kunjungi gerai toko resmi pilihan',
                      style: TextStyle(
                        fontSize: 10,
                        color: activeOrder.isCompleted
                            ? const Color(0xFF15803D) // Warna teks pada "Kunjungi gerai toko resmi pilihan"
                            : const Color(0xFF16A34A), // Warna teks pada "Kunjungi gerai toko resmi pilihan"
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Detail Cabang & Kode Pengambilan
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: Color(
                  0xFFB45309,
                ), // Warna ikon ikon untuk "Gerai Resmi JNOVAMUSIC"
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  activeOrder.pickupStore?.name ?? 'Gerai Resmi JNOVAMUSIC',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark, // Warna teks pada "Gerai Resmi JNOVAMUSIC"
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFE0F2FE,
                  ), // Warna latar kotak atau kartu untuk "Store Pickup"
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Store Pickup',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7), // Warna teks pada "Store Pickup"
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Kode Pengambilan: ',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(
                    0xFF7E756F,
                  ), // Warna teks pada "Kode Pengambilan:"
                ),
              ),
              Text(
                activeOrder.pickupCode,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 8),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white, // Warna border atau garis tepi untuk "Kode pengambilan berhasil disalin!"
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFD4D0C8), // Warna ikon ikon untuk "Kode pengambilan berhasil disalin!"
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        size: 9,
                        color: Color(
                          0xFF7E756F,
                        ), // Warna ikon ikon untuk "Salin"
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Salin',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7E756F), // Warna teks pada "Salin"
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
        color: const Color(
          0xFFFAF9F7,
        ), // Warna border atau garis tepi untuk "MUATAN PAKET"
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(
            0xFFEBE8E3,
          ), // Warna border atau garis tepi untuk "MUATAN PAKET"
          width: 1.0,
        ),
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
                  color: Color(0xFF8E837D), // Warna teks pada "MUATAN PAKET"
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFFEFE5,
                  ), // Warna latar kotak atau kartu untuk "MUATAN PAKET"
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
                  color: Colors.white, // Warna area atau kotak pada kartu
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
                        color: AppColors.textPrimaryDark, // Warna teks pada "3-Color Sunburst"
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Finish: ${item.product.colorVariants.isNotEmpty ? item.product.colorVariants.first : '3-Color Sunburst'}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(
                          0xFF7E756F,
                        ), // Warna teks pada "3-Color Sunburst"
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '1 Unit + Hard Case Kayu + QC Luthier',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange, // Warna teks pada "1 Unit + Hard Case Kayu + QC Luthier"
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
        color: const Color(
          0xFFFAF9F7,
        ), // Warna border atau garis tepi untuk "Riwayat Perjalanan Paket"
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(
            0xFFEBE8E3,
          ), // Warna border atau garis tepi untuk "Riwayat Perjalanan Paket"
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Perjalanan Paket',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark, // Warna teks pada "Riwayat Perjalanan Paket"
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Pembaruan Terakhir: 19 Mei 2025, 08:15 WIB',
            style: TextStyle(
              fontSize: 9.5,
              color: Color(
                0xFF8E837D,
              ), // Warna teks pada "Pembaruan Terakhir: 19 Mei 2025, 08..."
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
                                ? AppColors
                                      .primaryOrange // Warna latar kotak atau kartu pada kartu
                                : (step.isActive
                                      ? const Color(
                                          0xFFFFEDDF,
                                        ) // Warna border atau garis tepi kartu
                                      : const Color(0xFFE5E2DC)), // Warna border atau garis tepi kartu
                            border: step.isActive
                                ? Border.all(
                                    color: AppColors.primaryOrange, // Warna ikon ikon pada kartu
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: step.isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 9,
                                  color: Colors.white,
                                )
                              : (step.isActive
                                    ? Center(
                                        child: Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primaryOrange, // Warna latar kotak atau kartu pada kartu
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
                                  ? AppColors
                                        .primaryOrange // Warna area atau kotak pada kartu
                                  : const Color(
                                      0xFFE5E2DC,
                                    ), // Warna area atau kotak pada kartu
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
                                    fontWeight:
                                        step.isActive || step.isCompleted
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: step.isActive
                                        ? AppColors
                                              .primaryOrange // Warna visual pada kartu
                                        : AppColors.textPrimaryDark, // Warna teks pada kartu
                                  ),
                                ),
                                if (step.time.isNotEmpty)
                                  Text(
                                    step.time,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: Color(
                                        0xFF8E837D,
                                      ), // Warna teks pada kartu
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step.description,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(
                                  0xFF6E6560,
                                ), // Warna teks pada kartu
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
                Icons.storefront_rounded,
                size: 15,
                color: AppColors.primaryOrange, // Warna ikon ikon untuk "Lokasi Toko Pengambilan"
              ),
              SizedBox(width: 6),
              Text(
                'Lokasi Toko Pengambilan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark, // Warna teks pada "Lokasi Toko Pengambilan"
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            activeOrder.pickupStore?.name ?? 'Cabang Toko Resmi JNOVAMUSIC',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark, // Warna teks pada "Cabang Toko Resmi JNOVAMUSIC"
            ),
          ),
          const SizedBox(height: 2),
          Text(
            activeOrder.pickupStore?.address ?? activeOrder.recipientAddress,
            style: const TextStyle(
              fontSize: 10,
              color: Color(
                0xFF6E6560,
              ), // Warna teks pada "Cabang Toko Resmi JNOVAMUSIC"
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
                          content: Text(
                            'Menghubungkan ke layanan pelacakan JNE Cargo...',
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFD4D0C8), // Warna border atau garis tepi untuk "Menghubungkan ke layanan pelacakan..."
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 14,
                          color: AppColors.textPrimaryDark, // Warna ikon ikon untuk "JNE Cargo"
                        ),
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
                    onPressed: () => _showCustomerServiceOptions(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(
                          0xFFD4D0C8,
                        ), // Warna border atau garis tepi tombol
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.headset_mic_outlined,
                          size: 14,
                          color: AppColors.textPrimaryDark, // Warna ikon ikon untuk "Bantuan CS"
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Bantuan CS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryDark, // Warna teks pada "Bantuan CS"
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
                backgroundColor:
                    AppColors.primaryOrange, // Warna visual pada tombol
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
