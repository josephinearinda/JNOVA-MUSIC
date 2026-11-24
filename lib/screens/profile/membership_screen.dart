import 'dart:io';

import 'package:flutter/material.dart';

import 'package:jnova/core/constants/app_colors.dart';
import 'package:jnova/services/membership_service.dart';
import 'package:jnova/services/user_profile_service.dart';
import 'package:jnova/widgets/app_bottom_nav.dart';

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
      backgroundColor: AppColors.white, // Warna latar kotak untuk "/profile"
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
                            color: Color(0xFF8E837D), // Warna teks pada "Poin didapatkan setelah pesanan dia..."
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
                      color: AppColors.textPrimaryDark, // Warna ikon ikon untuk "Membership"
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
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(
                        0xFF8E837D,
                      ), // Warna teks pada "More Points, More Music Benefits"
                    ),
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
                color: const Color(
                  0xFF4A403A,
                ), // Warna ikon ikon untuk "/notifications"
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
                    color: Color(
                      0xFFB45309,
                    ), // Warna ikon ikon untuk "/profile"
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 17,
                    color: Colors.white, // Warna ikon ikon untuk "/profile"
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
        color: const Color(0xFFFFFBF7), // Warna border atau garis tepi kartu
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFEDD5), // Warna border atau garis tepi kartu
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(
              // Warna border atau garis tepi kartu

              alpha: 0.05,
            ),
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
                  color: const Color(
                    0xFFFFEDDF,
                  ), // Warna latar kotak atau kartu untuk "MEMBERSHIP KAMU"
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.military_tech_rounded,
                      size: 11,
                      color: AppColors.primaryOrange, // Warna ikon ikon untuk "MEMBERSHIP KAMU"
                    ),
                    SizedBox(width: 4),
                    Text(
                      'MEMBERSHIP KAMU',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors
                            .primaryOrange, // Warna teks pada "MEMBERSHIP KAMU"
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
                  color: Color(0xFF8E837D), // Warna teks pada "ID: JNV-882190"
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
                      color: AppColors.textPrimaryDark, // Warna ikon ikon untuk "Pengguna JNOVAMUSIC"
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
                            ? const Color(
                                0xFFB45309,
                              ) // Warna ikon ikon untuk "Pengguna JNOVAMUSIC"
                            : const Color(
                                0xFF8E837D,
                              ), // Warna visual pada kartu
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _membershipService.tierName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _membershipService.isMember
                              ? const Color(
                                  0xFF8D4315,
                                ) // Warna teks pada "Pengguna JNOVAMUSIC"
                              : const Color(0xFF7E756F), // Warna latar kotak atau kartu untuk "Pengguna JNOVAMUSIC"
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
                  color: Color(
                    0xFFEDEBE7,
                  ), // Warna ikon ikon untuk "Pengguna JNOVAMUSIC"
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 16,
                  color: Color(
                    0xFF5A524D,
                  ), // Warna ikon ikon untuk "Pengguna JNOVAMUSIC"
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
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(
                        0xFF7E756F,
                      ), // Warna ikon ikon untuk "Saldo Poin Kamu"
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        size: 18,
                        color: AppColors.primaryOrange, // Warna ikon ikon untuk "${points.toString().replaceAllMappe..."
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} Poin',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimaryDark, // Warna teks pada "${points.toString().replaceAllMappe..."
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
                    color: AppColors.primaryOrange, // Warna latar kotak atau kartu untuk "Gunakan"
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Gunakan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color:
                              Colors.white, // Warna ikon ikon untuk "Gunakan"
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: Colors.white, // Warna ikon ikon untuk "Gunakan"
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
                    color: AppColors
                        .primaryOrange, // Warna ikon ikon untuk "Maksimal"
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
                      color: Color(0xFF6E6560), // Warna teks pada "Kumpulkan 1.000 Poin untuk Jadi Member"
                    ),
                  ),
                ],
              ),
              Text(
                '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} / ${targetPoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} Poin',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark, // Warna teks pada "${points.toString().replaceAllMappe..."
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(
                0xFFFFEDDF,
              ), // Warna indikator loading pada kartu
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryOrange, // Warna latar kotak atau kartu untuk "${points.toString().replaceAllMappe..."
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white, // Warna border atau garis tepi untuk "${points.toString().replaceAllMappe..."
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFFE0C2), // Warna border atau garis tepi untuk "${points.toString().replaceAllMappe..."
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Color(0xFFB45309), // Warna ikon ikon untuk "Maksimal"
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
                      color: Color(0xFF78350F), // Warna teks pada "Target: ${targetPoints.toString().r..."
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
          style: TextStyle(
            fontSize: 10,
            color: Color(
              0xFF8E837D,
            ), // Warna teks pada "Perbandingan benefit dan keuntungan..."
          ),
        ),
        const SizedBox(height: 12),

        // 1. SILVER
        _buildTierCard(
          isActive: isSilverActive,
          isNextTier: isNonMember,
          tagColor:
              AppColors.primaryOrange, // Warna visual pada bagian komponen ini
          tagBg: const Color(
            0xFFFFEDDF,
          ), // Warna visual pada bagian komponen ini
          pointRange: '1.000 - 2.999 POIN',
          title: 'SILVER',
          subtitle: 'Kolektor Musik Pemula',
          icon: Icons.shield_rounded,
          iconBg: const Color(
            0xFFEDEBE7,
          ), // Warna visual pada bagian komponen ini
          iconColor: const Color(
            0xFF7E756F,
          ), // Warna visual pada bagian komponen ini
          discountBenefit: 'Diskon 10%',
          benefits: [
            'Diskon 10% untuk semua pembelian alat musik & aksesoris',
            'Akses awal pre-order, diskon seasonal sale',
            'Konsultasi gear dasar bersama audio specialist',
          ],
          borderColor: const Color(
            0xFFEBE8E3,
          ), // Warna visual pada bagian komponen ini
        ),
        const SizedBox(height: 12),

        // 2. GOLD
        _buildTierCard(
          isActive: isGoldActive,
          isNextTier: isSilverActive,
          tagColor: const Color(
            0xFFB45309,
          ), // Warna visual pada bagian komponen ini
          tagBg: const Color(
            0xFFFEF3C7,
          ), // Warna visual pada bagian komponen ini
          pointRange: '3.000 - 9.999 POIN',
          title: 'GOLD',
          subtitle: 'Musisi Aktif & Creator',
          icon: Icons.military_tech_rounded,
          iconBg: const Color(
            0xFFFEF3C7,
          ), // Warna visual pada bagian komponen ini
          iconColor: const Color(
            0xFFD97706,
          ), // Warna visual pada bagian komponen ini
          discountBenefit: 'Diskon 20%',
          benefits: [
            'Diskon 20% untuk semua pembelian alat musik & aksesoris',
            'Gratis ongkir sesuai ketentuan yang berlaku',
            'Prioritas layanan servis alat musik & luthier',
            'Akses workshop & klinik musik berkala eksklusif',
          ],
          borderColor: const Color(
            0xFFEBE8E3,
          ), // Warna visual pada bagian komponen ini
        ),
        const SizedBox(height: 12),

        // 3. PLATINUM
        _buildTierCard(
          isActive: isPlatinumActive,
          isNextTier: isGoldActive,
          tagColor: const Color(
            0xFF0369A1,
          ), // Warna visual pada bagian komponen ini
          tagBg: const Color(
            0xFFE0F2FE,
          ), // Warna visual pada bagian komponen ini
          pointRange: '10.000+ POIN',
          title: 'PLATINUM',
          subtitle: 'VIP & Pro Audiophile',
          icon: Icons.workspace_premium_rounded,
          iconBg: const Color(
            0xFFE0F2FE,
          ), // Warna visual pada bagian komponen ini
          iconColor: const Color(
            0xFF0284C7,
          ), // Warna visual pada bagian komponen ini
          discountBenefit: 'Diskon 35%',
          discountColor: const Color(
            0xFF0284C7,
          ), // Warna visual pada bagian komponen ini
          benefits: [
            'Diskon 35% untuk semua instrumen & aksesoris',
            'Gratis ongkir sesuai ketentuan',
            'Cashback tunai / saldo voucher Rp100.000',
            'Merchandise gratis eksklusif JNOVAMUSIC',
            'Layanan VIP & undangan peluncuran gear eksklusif',
          ],
          borderColor: const Color(
            0xFFEBE8E3,
          ), // Warna visual pada bagian komponen ini
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
        ? AppColors
              .primaryOrange // Warna latar kotak atau kartu untuk "Keanggotaan"
        : isNextTier
        ? tagColor
        : const Color(
            0xFF8E837D,
          ); // Warna latar kotak atau kartu untuk "Keanggotaan"
    final effectiveTagBg = isActive
        ? const Color(
            0xFFFFEDDF,
          ) // Warna latar kotak atau kartu untuk "Keanggotaan"
        : isNextTier
        ? tagBg
        : const Color(
            0xFFEDEBE7,
          ); // Warna latar kotak atau kartu untuk "Keanggotaan"

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFAF9F7,
        ), // Warna border atau garis tepi untuk "Keanggotaan"
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.primaryOrange
              : borderColor, // Warna border atau garis tepi untuk "Keanggotaan"
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
                  color: Color(0xFF8E837D), // Warna teks pada kartu
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
                          color: AppColors
                              .textPrimaryDark, // Warna teks pada kartu
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(
                            0xFF6E6560,
                          ), // Warna teks pada "BENEFIT UTAMA"
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
                      color: Color(
                        0xFF8E837D,
                      ), // Warna teks pada "BENEFIT UTAMA"
                    ),
                  ),
                  Text(
                    discountBenefit,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color:
                          discountColor ??
                          AppColors
                              .primaryOrange, // Warna teks pada "BENEFIT UTAMA"
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
                    color:
                        AppColors.primaryOrange, // Warna ikon ikon pada kartu
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF5A524D), // Warna teks pada kartu
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
            color:
                AppColors.textPrimaryDark, // Warna teks pada "Aktivitas Poin"
          ),
        ),
        const SizedBox(height: 1),
        const Text(
          'Kelola dan nikmati hadiah dari setiap belanjaan musikmu',
          style: TextStyle(
            fontSize: 10,
            color: Color(
              0xFF8E837D,
            ), // Warna teks pada "Kelola dan nikmati hadiah dari seti..."
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9F7), // Warna border atau garis tepi untuk "Kelola dan nikmati hadiah dari seti..."
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFEBE8E3), // Warna border atau garis tepi untuk "Kelola dan nikmati hadiah dari seti..."
            ),
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
                      color: AppColors.primaryOrange, // Warna ikon ikon untuk "/point-history"
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
                              color: AppColors.textPrimaryDark, // Warna teks pada "Riwayat Poin"
                            ),
                          ),
                          Text(
                            'Lihat poin yang diperoleh dan digunakan',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF7E756F), // Warna ikon ikon untuk "Lihat poin yang diperoleh dan digun..."
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF8E837D), // Warna ikon ikon untuk "Lihat poin yang diperoleh dan digun..."
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
        color: Color(
          0xFFEDEBE7,
        ), // Warna latar kotak atau kartu pada bagian komponen ini
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4A403A), // Warna teks pada bagian komponen ini
          ),
        ),
      ),
    );
  }
}

typedef MembershipScreen = MembershipSettingsPage;
