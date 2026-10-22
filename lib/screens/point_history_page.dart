import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/point_history_model.dart';
import '../services/membership_service.dart';
import '../services/point_history_repository.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman RIWAYAT POIN JNOVAMUSIC sesuai screenshot Figma asli
class PointHistoryPage extends StatefulWidget {
  final VoidCallback? onBack;

  const PointHistoryPage({super.key, this.onBack});

  @override
  State<PointHistoryPage> createState() => _PointHistoryPageState();
}

class _PointHistoryPageState extends State<PointHistoryPage> {
  final MembershipService _membershipService = MembershipService.instance;
  final PointHistoryRepository _repository = PointHistoryRepository.instance;

  int _selectedFilterIndex = 0; // 0: Semua, 1: Pembelian, 2: Aktivitas Game
  bool _isLoading = false;
  String? _errorMessage;
  List<PointHistoryModel> _historyList = PointHistoryRepository.instance.defaultData;

  @override
  void initState() {
    super.initState();
    _membershipService.addListener(_handleStateChanged);
    _loadData();
  }

  @override
  void dispose() {
    _membershipService.removeListener(_handleStateChanged);
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData({
    bool forceError = false,
    bool forceEmpty = false,
  }) async {
    if (_historyList.isEmpty || forceError || forceEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _repository.getPointHistory(
        forceError: forceError,
        forceEmpty: forceEmpty,
      );
      if (mounted) {
        setState(() {
          _historyList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/membership-settings');
    }
  }

  List<PointHistoryModel> get _filteredHistory {
    if (_selectedFilterIndex == 1) {
      return _historyList.where((item) => item.isPurchase).toList();
    } else if (_selectedFilterIndex == 2) {
      return _historyList.where((item) => item.isGame).toList();
    }
    return _historyList;
  }

  String get _pageTitle {
    if (_selectedFilterIndex == 1) return 'Riwayat Poin Pembelian';
    if (_selectedFilterIndex == 2) return 'Riwayat Poin Aktivitas Game';
    return 'Riwayat Poin';
  }

  void _showTransactionDetail(PointHistoryModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4CFC9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Transaksi Poin',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDDF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.date,
                style: const TextStyle(fontSize: 10, color: Color(0xFF7E756F)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEBE8E3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Poin yang Didapat:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF5A524D)),
                    ),
                    Text(
                      item.formattedPoints,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.orderId != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nomor Pesanan:',
                      style: TextStyle(fontSize: 10, color: Color(0xFF7E756F)),
                    ),
                    Text(
                      item.orderId!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.primaryOrange,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Informasi Poin Membership',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ],
        ),
        content: const Text(
          '1. Poin didapatkan dari pembelian instrumen musik resmi di JNOVAMUSIC (1% dari nominal belanja).\n\n'
          '2. Poin ekstra dapat diperoleh melalui event mingguan dan mini game JNova Rhythm.\n\n'
          '3. Poin diakumulasikan sepanjang tahun aktif untuk menentukan status dan benefit tier Anda.\n\n'
          'Untuk informasi lebih lengkap, silakan cek Syarat & Ketentuan.',
          style: TextStyle(fontSize: 11, color: Color(0xFF5A524D), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Mengerti',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = _membershipService.currentPoints;
    const targetPoints = 3000;
    final pointsNeeded = (targetPoints - points).clamp(0, targetPoints);
    final progress = (points / targetPoints).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sub Header
                      _buildSubHeader(),

                      const SizedBox(height: 12),

                      // Card Saldo & Progress Poin
                      _buildPointsCard(points, pointsNeeded, progress),

                      const SizedBox(height: 14),

                      // Filter Segmented Tabs (Semua, Pembelian, Aktivitas Game)
                      _buildFilterTabs(),

                      const SizedBox(height: 12),

                      // Daftar Riwayat Transaksi (Normal, Loading, Empty, Error)
                      _buildBodyContent(),

                      const SizedBox(height: 14),

                      // Footer Note Poin
                      _buildFooterNote(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2, // Membership tab
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/favorite');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/all-products');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/membership-settings');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/order-detail');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F0ED), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Membership',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                'More Points, More Music Benefits',
                style: TextStyle(fontSize: 9.5, color: Color(0xFF8E837D)),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimaryDark,
                      size: 21,
                    ),
                    Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8D4315),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        children: [
          InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F3EF),
                border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _pageTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          InkWell(
            onTap: _showInfoDialog,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F3EF),
                border: Border.all(color: const Color(0xFFE8E5DF)),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Color(0xFF6E6560),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(int points, int pointsNeeded, double progress) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD8BF), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Header Poin
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Poin Membership',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6E6560),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDDF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ACOUSTIC TIER',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Nilai Poin Aktual & Tombol Lihat Membership
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} Poin',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, '/membership-settings'),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFFFD8BF),
                      width: 1.0,
                    ),
                  ),
                  child: const Text(
                    'Lihat Membership >',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress Menuju Electric Tier',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6E6560),
                ),
              ),
              Text(
                '$points / 3.000 Poin',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFFFEDDF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryOrange,
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'Tinggal $pointsNeeded Poin lagi untuk naik ke Electric Tier!',
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF78350F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['Semua', 'Pembelian', 'Aktivitas Game'];

    return Row(
      children: List.generate(filters.length, (index) {
        final isSelected = _selectedFilterIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryOrange
                    : const Color(0xFFFAF9F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryOrange
                      : const Color(0xFFEBE8E3),
                ),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF5A524D),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryOrange,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Memuat riwayat poin...',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF8E837D)),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 28,
            ),
            const SizedBox(height: 8),
            const Text(
              'Gagal memuat riwayat poin',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFFB91C1C)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
              ),
              onPressed: () => _loadData(),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final items = _filteredHistory;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEBE8E3)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 36,
              color: Color(0xFFB0AAA4),
            ),
            SizedBox(height: 8),
            Text(
              'Belum ada riwayat poin',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Transaksi poin kamu akan muncul di sini.',
              style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.map((item) => _buildHistoryCard(item)).toList(),
    );
  }

  Widget _buildHistoryCard(PointHistoryModel item) {
    IconData iconData;
    switch (item.type) {
      case PointTransactionType.purchase:
        iconData = Icons.shopping_bag_outlined;
        break;
      case PointTransactionType.bonus:
        iconData = Icons.emoji_events_outlined;
        break;
      case PointTransactionType.jackpot:
        iconData = Icons.stars_outlined;
        break;
      case PointTransactionType.game:
        iconData = Icons.sports_esports_outlined;
        break;
    }

    return InkWell(
      onTap: () => _showTransactionDetail(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFECE8), width: 1.0),
        ),
        child: Row(
          children: [
            // Icon Box
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDDF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, size: 16, color: AppColors.primaryOrange),
            ),
            const SizedBox(width: 10),

            // Detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        item.date,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF8E837D),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Color(0xFFB0AAA4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6E6560),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Poin
            Text(
              item.formattedPoints,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECE9E4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.primaryOrange,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Poin membership diakumulasikan sepanjang tahun aktif untuk menentukan status dan benefit tier Anda. Untuk informasi lebih lanjut, silakan cek Syarat & Ketentuan.',
              style: TextStyle(
                fontSize: 9.5,
                color: Color(0xFF6E6560),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
