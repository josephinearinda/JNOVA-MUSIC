import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/qr_code_widget.dart';
import 'order_detail_screen.dart';

/// Dashboard Pesanan JNOVAMUSIC (Daftar Pesanan & Status Pengambilan)
/// Menampilkan daftar pesanan aktif dan selesai secara komprehensif
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService.instance;
  int _selectedFilterIndex = 0; // 0 = Semua, 1 = Menunggu Diambil, 2 = Selesai

  @override
  void initState() {
    super.initState();
    _orderService.addListener(_handleOrdersChanged);
  }

  @override
  void dispose() {
    _orderService.removeListener(_handleOrdersChanged);
    super.dispose();
  }

  void _handleOrdersChanged() {
    if (mounted) setState(() {});
  }

  List<OrderModel> _getFilteredOrders(List<OrderModel> allOrders) {
    if (_selectedFilterIndex == 1) {
      return allOrders.where((o) => !o.isCompleted).toList();
    } else if (_selectedFilterIndex == 2) {
      return allOrders.where((o) => o.isCompleted).toList();
    }
    return allOrders;
  }

  void _showQrModal(BuildContext context, OrderModel order) {
    final pickupCode =
        order.pickupCode.isNotEmpty ? order.pickupCode : 'PKP-8841-JNV';
    final storeName = order.pickupStore?.name ?? 'Toko Resmi JNOVAMUSIC';

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
                const Flexible(
                  child: Text(
                    'QR Code Pengambilan Toko',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
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
              '$storeName • ${order.orderNumber}',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
                      'Tunjukkan QR Code ini kepada kasir/luthier desk di store untuk verifikasi dan serah terima instrumen.',
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
    final allOrders = _orderService.orders;
    final filteredOrders = _getFilteredOrders(allOrders);

    final activeCount = allOrders.where((o) => !o.isCompleted).length;
    final completedCount = allOrders.where((o) => o.isCompleted).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Dashboard Pesanan
            _buildTopAppBar(context),

            // 2. Filter Tabs (Semua, Menunggu Diambil, Selesai)
            _buildFilterTabs(
              totalCount: allOrders.length,
              activeCount: activeCount,
              completedCount: completedCount,
            ),

            // 3. Konten Daftar Pesanan
            Expanded(
              child: filteredOrders.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _OrderDashboardCard(
                          order: order,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => OrderDetailScreen(order: order),
                              ),
                            );
                          },
                          onShowQr: () => _showQrModal(context, order),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3, // Tab Pesanan aktif
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F0ED), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Pesanan',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pantau pembelian & jadwal pengambilan toko',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF7E756F)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Notifikasi Icon
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tidak ada notifikasi baru untuk pesanan Anda.',
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
          const SizedBox(width: 10),

          // Profil Avatar
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

  Widget _buildFilterTabs({
    required int totalCount,
    required int activeCount,
    required int completedCount,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip(
              index: 0,
              label: 'Semua ($totalCount)',
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              index: 1,
              label: 'Menunggu Diambil ($activeCount)',
              hasBadge: activeCount > 0,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              index: 2,
              label: 'Selesai ($completedCount)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required int index,
    required String label,
    bool hasBadge = false,
  }) {
    final isSelected = _selectedFilterIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEFE5) : const Color(0xFFF5F4F1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOrange
                : const Color(0xFFE5E2DC),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBadge) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryOrange
                    : const Color(0xFF5A524D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 38,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Pesanan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pesanan yang Anda buat akan muncul di sini untuk memudahkan pemantauan dan pengambilan barang di toko.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF7E756F), height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/all-products');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              icon: const Icon(Icons.storefront_rounded, size: 16, color: Colors.white),
              label: const Text(
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

/// Kartu Pesanan di Dashboard Pesanan
class _OrderDashboardCard extends StatelessWidget {
  const _OrderDashboardCard({
    required this.order,
    required this.onTap,
    required this.onShowQr,
  });

  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    final totalUnits = order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final isCompleted = order.isCompleted;
    final storeName = order.pickupStore?.name ?? 'JNOVAMUSIC Store';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFE5E7EB)
              : const Color(0xFFFFD8BF),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris 1: Nomor Pesanan & Badge Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 15,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              order.orderNumber,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFFEFE5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.storefront_rounded,
                            size: 11,
                            color: isCompleted
                                ? const Color(0xFF15803D)
                                : const Color(0xFFC2410C),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted ? 'Selesai' : 'Siap Diambil',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isCompleted
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFC2410C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Baris 2: Tanggal & Lokasi Toko
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        order.dateFormatted,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF8E837D),
                        ),
                      ),
                    ),
                    const Text(
                      ' • ',
                      style: TextStyle(fontSize: 9.5, color: Color(0xFF8E837D)),
                    ),
                    Flexible(
                      child: Text(
                        storeName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6E6560),
                        ),
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(color: Color(0xFFF2F0ED), height: 1),
                ),

                // Baris 3: Daftar Produk yang Dipesan
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 42,
                            height: 42,
                            color: const Color(0xFFF8F7F5),
                            child: Image.asset(
                              item.product.image,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                Icons.image_not_supported_rounded,
                                size: 18,
                                color: AppColors.placeholder,
                              ),
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${item.quantity} Unit x ${formatRupiah(item.product.price)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        color: Color(0xFF7E756F),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formatRupiah(item.itemTotal),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4A423E),
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
                }),

                const SizedBox(height: 2),

                // Baris 4: Total & Tombol Aksi
                Container(
                  padding: const EdgeInsets.only(top: 8.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFF2F0ED), width: 1.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Tagihan
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total ($totalUnits Unit)',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF7E756F),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            formatRupiah(order.totalPayment),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ],
                      ),

                      // Tombol QR Code & Lihat Detail
                      Row(
                        children: [
                          if (!isCompleted) ...[
                            OutlinedButton.icon(
                              onPressed: onShowQr,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFE0DDD7),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(0, 32),
                              ),
                              icon: const Icon(
                                Icons.qr_code_2_rounded,
                                size: 14,
                                color: Color(0xFF4A423E),
                              ),
                              label: const Text(
                                'QR Code',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4A423E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCompleted
                                  ? const Color(0xFFECEAE6)
                                  : AppColors.primaryOrange,
                              foregroundColor: isCompleted
                                  ? AppColors.textPrimaryDark
                                  : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lihat Detail',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isCompleted
                                        ? AppColors.textPrimaryDark
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: isCompleted
                                      ? AppColors.textPrimaryDark
                                      : Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
