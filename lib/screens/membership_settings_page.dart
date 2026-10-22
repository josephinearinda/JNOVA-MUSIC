import 'dart:io';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/membership_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman UBAH MEMBERSHIP JNOVAMUSIC sesuai desain Figma 4 / 7
class MembershipSettingsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const MembershipSettingsPage({super.key, this.onBack});

  @override
  State<MembershipSettingsPage> createState() => _MembershipSettingsPageState();
}

class _MembershipSettingsPageState extends State<MembershipSettingsPage> {
  final MembershipService _membershipService = MembershipService.instance;
  final UserProfileService _profileService = UserProfileService.instance;

  @override
  void initState() {
    super.initState();
    _membershipService.addListener(_handleStateChanged);
    _profileService.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    _membershipService.removeListener(_handleStateChanged);
    _profileService.removeListener(_handleStateChanged);
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = _membershipService.currentPoints;
    final targetPoints = _membershipService.targetPoints;
    final pointsNeeded = (targetPoints - points).clamp(0, targetPoints);
    final progress = (points / targetPoints).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Konten Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Card Membership Kamu (ID: JNV-882190)
                      _buildUserMembershipCard(
                        points,
                        targetPoints,
                        pointsNeeded,
                        progress,
                      ),

                      const SizedBox(height: 16),

                      // Section Tingkat Membership
                      _buildMembershipTiersSection(),

                      const SizedBox(height: 16),

                      // Section Aktivitas Poin
                      _buildPointActivitiesSection(),

                      const SizedBox(height: 14),

                      // Footer note
                      const Center(
                        child: Text(
                          'Poin didapatkan setelah pesanan diambil, dibayar di toko, dan dikonfirmasi "Pesanan Selesai" oleh pelanggan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF8E837D),
                            height: 1.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2, // Membership tab aktif
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/all-products');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/order-detail');
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (Navigator.canPop(context)) ...[
                GestureDetector(
                  onTap: _handleBack,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ),
              ],
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Membership',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Text(
                    'More Points, More Music Benefits',
                    style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 22),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
                color: const Color(0xFF4A403A),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFB45309),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserMembershipCard(
    int points,
    int targetPoints,
    int pointsNeeded,
    double progress,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEDD5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDDF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.military_tech_rounded,
                      size: 11,
                      color: AppColors.primaryOrange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'MEMBERSHIP KAMU',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'ID: JNV-882190',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8E837D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildUserAvatar(
                _profileService.profile.photoUrl,
                _profileService.profile.fullName,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profileService.profile.fullName.isNotEmpty
                        ? _profileService.profile.fullName
                        : 'Pengguna JNOVAMUSIC',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        _membershipService.isMember
                            ? Icons.verified_rounded
                            : Icons.lock_outline_rounded,
                        size: 13,
                        color: _membershipService.isMember
                            ? const Color(0xFFB45309)
                            : const Color(0xFF8E837D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _membershipService.tierName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _membershipService.isMember
                              ? const Color(0xFF8D4315)
                              : const Color(0xFF7E756F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEDEBE7),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 16,
                  color: Color(0xFF5A524D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Saldo Poin & Gunakan Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Poin Kamu',
                    style: TextStyle(fontSize: 10, color: Color(0xFF7E756F)),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        size: 18,
                        color: AppColors.primaryOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} Poin',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimaryDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/all-products'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Gunakan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress menuju tier berikutnya
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    size: 12,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _membershipService.nextTierName == 'Maksimal'
                        ? 'Tier maksimal tercapai'
                        : _membershipService.isMember
                            ? 'Progres ke ${_membershipService.nextTierName} Member'
                            : 'Kumpulkan 1.000 Poin untuk Jadi Member',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6E6560),
                    ),
                  ),
                ],
              ),
              Text(
                '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} / ${targetPoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} Poin',
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
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE0C2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _membershipService.nextTierName == 'Maksimal'
                        ? 'Kamu sudah mencapai tier tertinggi dengan benefit diskon ${_membershipService.discountPercentage}%.'
                        : _membershipService.isMember
                            ? 'Target: ${targetPoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} poin. Butuh $pointsNeeded poin lagi untuk membuka benefit ${_membershipService.nextTierName}.'
                            : 'Belanja & kumpulkan $pointsNeeded poin lagi untuk membuka keanggotaan Silver Member dan nikmati diskon 10%!',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF78350F),
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

  Widget _buildMembershipTiersSection() {
    final currentTier = _membershipService.userTier;
    final isNonMember = currentTier == 'NON-MEMBER';
    final isSilverActive = currentTier == 'TIER 1';
    final isGoldActive = currentTier == 'TIER 2';
    final isPlatinumActive = currentTier == 'TIER 3';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tingkat Membership',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 1),
        const Text(
          'Perbandingan benefit dan keuntungan tiap tingkat keanggotaan',
          style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
        ),
        const SizedBox(height: 12),

        // 1. SILVER
        _buildTierCard(
          isActive: isSilverActive,
          isNextTier: isNonMember,
          tagColor: AppColors.primaryOrange,
          tagBg: const Color(0xFFFFEDDF),
          pointRange: '1.000 - 2.999 POIN',
          title: 'SILVER',
          subtitle: 'Kolektor Musik Pemula',
          icon: Icons.shield_rounded,
          iconBg: const Color(0xFFEDEBE7),
          iconColor: const Color(0xFF7E756F),
          discountBenefit: 'Diskon 10%',
          benefits: [
            'Diskon 10% untuk semua pembelian alat musik & aksesoris',
            'Akses awal pre-order, diskon seasonal sale',
            'Konsultasi gear dasar bersama audio specialist',
          ],
          borderColor: const Color(0xFFEBE8E3),
        ),
        const SizedBox(height: 12),

        // 2. GOLD
        _buildTierCard(
          isActive: isGoldActive,
          isNextTier: isSilverActive,
          tagColor: const Color(0xFFB45309),
          tagBg: const Color(0xFFFEF3C7),
          pointRange: '3.000 - 9.999 POIN',
          title: 'GOLD',
          subtitle: 'Musisi Aktif & Creator',
          icon: Icons.military_tech_rounded,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          discountBenefit: 'Diskon 20%',
          benefits: [
            'Diskon 20% untuk semua pembelian alat musik & aksesoris',
            'Gratis ongkir sesuai ketentuan yang berlaku',
            'Prioritas layanan servis alat musik & luthier',
            'Akses workshop & klinik musik berkala eksklusif',
          ],
          borderColor: const Color(0xFFEBE8E3),
        ),
        const SizedBox(height: 12),

        // 3. PLATINUM
        _buildTierCard(
          isActive: isPlatinumActive,
          isNextTier: isGoldActive,
          tagColor: const Color(0xFF0369A1),
          tagBg: const Color(0xFFE0F2FE),
          pointRange: '10.000+ POIN',
          title: 'PLATINUM',
          subtitle: 'VIP & Pro Audiophile',
          icon: Icons.workspace_premium_rounded,
          iconBg: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0284C7),
          discountBenefit: 'Diskon 35%',
          discountColor: const Color(0xFF0284C7),
          benefits: [
            'Diskon 35% untuk semua instrumen & aksesoris',
            'Gratis ongkir sesuai ketentuan',
            'Cashback tunai / saldo voucher Rp100.000',
            'Merchandise gratis eksklusif JNOVAMUSIC',
            'Layanan VIP & undangan peluncuran gear eksklusif',
          ],
          borderColor: const Color(0xFFEBE8E3),
        ),
      ],
    );
  }

  Widget _buildTierCard({
    required bool isActive,
    required bool isNextTier,
    required Color tagColor,
    required Color tagBg,
    required String pointRange,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String discountBenefit,
    Color? discountColor,
    required List<String> benefits,
    required Color borderColor,
  }) {
    final tag = isActive
        ? 'Tier Aktif Kamu'
        : isNextTier
        ? 'Tingkat Berikutnya'
        : 'Keanggotaan';
    final effectiveTagColor = isActive
        ? AppColors.primaryOrange
        : isNextTier
        ? tagColor
        : const Color(0xFF8E837D);
    final effectiveTagBg = isActive
        ? const Color(0xFFFFEDDF)
        : isNextTier
        ? tagBg
        : const Color(0xFFEDEBE7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.primaryOrange : borderColor,
          width: isActive ? 1.8 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: effectiveTagBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: effectiveTagColor,
                  ),
                ),
              ),
              Text(
                pointRange,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8E837D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF6E6560),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'BENEFIT UTAMA',
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Color(0xFF8E837D),
                    ),
                  ),
                  Text(
                    discountBenefit,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: discountColor ?? AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          const Text(
            'Keuntungan Member:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 4),

          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check,
                    size: 13,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF5A524D),
                        height: 1.25,
                      ),
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

  Widget _buildPointActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aktivitas Poin',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 1),
        const Text(
          'Kelola dan nikmati hadiah dari setiap belanjaan musikmu',
          style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEBE8E3)),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/point-history'),
                child: const Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: AppColors.primaryOrange,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat Poin',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          Text(
                            'Lihat poin yang diperoleh dan digunakan',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF7E756F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF8E837D),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(String photoUrl, String fullName) {
    if (photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            photoUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildInitialsAvatar(fullName),
          ),
        );
      } else if (photoUrl.startsWith('assets/')) {
        return ClipOval(
          child: Image.asset(
            photoUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildInitialsAvatar(fullName),
          ),
        );
      } else if (File(photoUrl).existsSync()) {
        return ClipOval(
          child: Image.file(
            File(photoUrl),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildInitialsAvatar(fullName),
          ),
        );
      }
    }
    return _buildInitialsAvatar(fullName);
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = name.trim().isNotEmpty
        ? name
              .trim()
              .split(' ')
              .where((e) => e.isNotEmpty)
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'JN';
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEDEBE7),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4A403A),
          ),
        ),
      ),
    );
  }
}
