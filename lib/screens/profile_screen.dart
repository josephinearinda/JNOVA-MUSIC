import 'dart:io';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import '../services/membership_service.dart';
import '../services/order_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/logout_confirmation_dialog.dart';

/// Halaman PROFIL SAYA JNOVAMUSIC sesuai desain Figma 5
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserProfileService _profileService = UserProfileService.instance;
  final MembershipService _membershipService = MembershipService.instance;
  final CurrencyService _currencyService = CurrencyService.instance;
  final OrderService _orderService = OrderService.instance;

  @override
  void initState() {
    super.initState();
    _profileService.addListener(_handleStateChanged);
    _membershipService.addListener(_handleStateChanged);
    _currencyService.addListener(_handleStateChanged);
    _orderService.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    _profileService.removeListener(_handleStateChanged);
    _membershipService.removeListener(_handleStateChanged);
    _currencyService.removeListener(_handleStateChanged);
    _orderService.removeListener(_handleStateChanged);
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profileService.profile;
    final currentPoints = _membershipService.currentPoints;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Konten Scrollable Profil Saya
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Sub Header: Profil Saya & Pengaturan
                    _buildSubHeader(),

                    const SizedBox(height: 12),

                    // Kartu Utama Pengguna (Foto, Nama, Handle, Badge, Tombol Edit)
                    _buildUserHeroCard(profile),

                    const SizedBox(height: 14),

                    // Informasi Pribadi
                    _buildPersonalInfoCard(profile),

                    const SizedBox(height: 14),

                    // Alamat Saya
                    _buildAddressCard(profile),

                    const SizedBox(height: 14),

                    // Aktivitas Saya
                    _buildUserActivitiesSection(currentPoints),

                    const SizedBox(height: 14),

                    // Pengaturan Aplikasi
                    _buildAppSettingsSection(profile),

                    const SizedBox(height: 18),

                    // Tombol Keluar dari Akun
                    _buildLogoutButton(),

                    const SizedBox(height: 10),

                    // Versi Aplikasi
                    const Text(
                      'JNOVAMUSIC Mobile v2.4.1 (Build 1204)',
                      style: TextStyle(fontSize: 9.5, color: Color(0xFFB0AAA4)),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4, // Profil aktif
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/all-products');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/membership');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/order-detail');
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
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/soundwave_loader.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            color: const Color(0xFF4A403A),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Container(
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
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil Saya',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                'Kelola informasi dan akun JNOVAMUSIC kamu',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF8E837D)),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/account-security');
            },
            icon: const Icon(Icons.settings_outlined, size: 21),
            color: const Color(0xFF4A403A),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeroCard(UserProfileModel profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar dengan Badge Kamera
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile-edit'),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD8BF),
                          width: 2.0,
                        ),
                      ),
                      child: ClipOval(
                        child: _buildAvatarImage(profile.photoUrl),
                      ),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryOrange,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Identitas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: Color(0xFF0284C7),
                        ),
                      ],
                    ),
                    Text(
                      '@${profile.username}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6E6560),
                      ),
                    ),
                    Text(
                      profile.email,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF8E837D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEBE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        profile.tier.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Color(0xFF5A524D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tombol Edit Profil
          SizedBox(
            width: double.infinity,
            height: 34,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEDEBE7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/profile-edit');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_outlined, size: 14, color: Color(0xFF4A403A)),
                  SizedBox(width: 6),
                  Text(
                    'Edit Profil',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A403A),
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

  Widget _buildPersonalInfoCard(UserProfileModel profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
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
                    Icons.badge_outlined,
                    size: 15,
                    color: AppColors.primaryOrange,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Informasi Pribadi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/profile-edit'),
                child: const Text(
                  'Ubah',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Nama Lengkap', profile.fullName),
          const SizedBox(height: 6),
          _buildInfoRow('Tanggal Lahir', profile.birthDate),
          const SizedBox(height: 6),
          _buildInfoRow(
            'Email',
            profile.email.isNotEmpty ? profile.email : 'Belum diisi',
            tag: profile.email.isNotEmpty
                ? (profile.isEmailVerified
                      ? 'Terverifikasi'
                      : 'Belum Verifikasi')
                : null,
            tagColor: profile.isEmailVerified
                ? const Color(0xFF15803D)
                : const Color(0xFFB45309),
            tagBgColor: profile.isEmailVerified
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEF3C7),
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            'Nomor HP',
            profile.phoneNumber.isNotEmpty
                ? profile.phoneNumber
                : 'Belum diisi',
            tag: profile.phoneNumber.isNotEmpty
                ? (profile.isPhoneVerified
                      ? 'Terverifikasi'
                      : 'Belum Verifikasi')
                : null,
            tagColor: profile.isPhoneVerified
                ? const Color(0xFF15803D)
                : const Color(0xFFB45309),
            tagBgColor: profile.isPhoneVerified
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEF3C7),
          ),
          const SizedBox(height: 6),
          _buildInfoRow('Username', '@${profile.username}'),
        ],
      ),
    );
  }

  Widget _buildAddressCard(UserProfileModel profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
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
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.primaryOrange,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Alamat Saya',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/address-edit'),
                child: const Text(
                  'Ubah Alamat >',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDDF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  profile.addressLabel,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Alamat Utama',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5A524D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${profile.streetAddress}, ${profile.rtRw}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryDark,
            ),
          ),
          Text(
            'Kelurahan ${profile.kelurahan}, Kecamatan ${profile.kecamatan}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF6E6560)),
          ),
          Text(
            '${profile.city}, Provinsi ${profile.province}, ${profile.postalCode}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF6E6560)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBE7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.note_alt_outlined,
                  size: 13,
                  color: Color(0xFF7E756F),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan: ${profile.courierNotes}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF5A524D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Digunakan otomatis untuk kalkulasi kurir saat checkout instrumen.',
            style: TextStyle(fontSize: 9, color: Color(0xFF8E837D)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActivitiesSection(int points) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                size: 15,
                color: AppColors.primaryOrange,
              ),
              SizedBox(width: 6),
              Text(
                'Aktivitas Saya',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildActivityItem(
            icon: Icons.military_tech_outlined,
            title: 'Membership Saya',
            subtitle:
                'Tier ${_membershipService.tierName} • $points Poin • Benefit Diskon ${_membershipService.discountPercentage}%',
            onTap: () => Navigator.pushNamed(context, '/membership-settings'),
          ),
          _buildActivityItem(
            icon: Icons.favorite_border_rounded,
            title: 'Favorit Saya',
            subtitle: 'Instrumen Musik Tersimpan',
            onTap: () => Navigator.pushNamed(context, '/favorite'),
          ),
          _buildActivityItem(
            icon: Icons.receipt_long_outlined,
            title: 'Riwayat Pesanan',
            subtitle: _orderService.orders.isEmpty
                ? 'Belum Ada Transaksi'
                : '${_orderService.orders.length} Pesanan Tersimpan',
            onTap: () => Navigator.pushNamed(context, '/order-history'),
          ),
          _buildActivityItem(
            icon: Icons.sports_esports_outlined,
            title: 'Riwayat Game',
            subtitle: 'JNova Rhythm - Skor 18.450',
            onTap: () => Navigator.pushNamed(context, '/games'),
          ),
          _buildActivityItem(
            icon: Icons.stars_outlined,
            title: 'Riwayat Poin',
            subtitle: 'Poin Masuk & Penukaran Reward',
            onTap: () => Navigator.pushNamed(context, '/point-history'),
          ),
          _buildActivityItem(
            icon: Icons.music_note_outlined,
            title: 'Preferensi Musik & Lagu',
            subtitle: 'Atur genre, instrumen & gaya bermusikmu',
            onTap: () => Navigator.pushNamed(context, '/music-preferences'),
          ),
          _buildActivityItem(
            icon: Icons.rate_review_outlined,
            title: 'Saran dan Kesan',
            subtitle: 'Kirim Feedback ke Tim JNOVAMUSIC',
            onTap: () => Navigator.pushNamed(context, '/suggestion-review'),
          ),
          _buildActivityItem(
            icon: Icons.auto_awesome_rounded,
            title: 'JNOVA Music AI Assistant',
            subtitle: 'Asisten musik pintar untuk membantumu',
            onTap: () => Navigator.pushNamed(context, '/ai-chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection(UserProfileModel profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 15,
                color: AppColors.primaryOrange,
              ),
              SizedBox(width: 6),
              Text(
                'Pengaturan Aplikasi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Login Biometrik Switch
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEBE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    size: 17,
                    color: Color(0xFF5A524D),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login Biometrik',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      Text(
                        'Sidik Jari / Face Unlock',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF7E756F),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: profile.isBiometricEnabled,
                  onChanged: (val) async {
                    if (val) {
                      final res = await AuthService.instance
                          .enableBiometricsForUser(
                            email: profile.email,
                            fullName: profile.fullName,
                          );
                      if (!mounted) return;
                      if (res.isSuccess) {
                        await _profileService.toggleBiometric(true);
                      } else {
                        await _profileService.toggleBiometric(false);
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: res.isSuccess
                              ? const Color(0xFF15803D)
                              : const Color(0xFFDC2626),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      final res = await AuthService.instance
                          .disableBiometricsForUser(profile.email);
                      await _profileService.toggleBiometric(false);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  activeThumbColor: AppColors.primaryOrange,
                  activeTrackColor: AppColors.primaryOrange.withValues(
                    alpha: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEBE8E3), height: 1),

          _buildActivityItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notifikasi',
            subtitle: 'Promo Gear, Update Pengiriman',
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          _buildActivityItem(
            icon: Icons.payments_outlined,
            title: 'Preferensi Mata Uang',
            subtitle: 'Format kalkulasi harga',
            badgeText: _currencyService.selectedCurrency == 'USD'
                ? 'USD (\$)'
                : (_currencyService.selectedCurrency == 'EUR'
                      ? 'EUR (€)'
                      : 'IDR (Rp)'),
            onTap: () => Navigator.pushNamed(context, '/currency-preferences'),
          ),
          _buildActivityItem(
            icon: Icons.schedule_rounded,
            title: 'Jam Dunia',
            subtitle: 'Waktu real-time WIB, WITA, WIT & London',
            onTap: () => Navigator.pushNamed(context, '/world-clock'),
          ),
          _buildActivityItem(
            icon: Icons.shield_outlined,
            title: 'Keamanan Akun',
            subtitle: 'Ganti Kata Sandi, Verifikasi 2 Langkah',
            onTap: () => Navigator.pushNamed(context, '/account-security'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEBE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF5A524D)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF7E756F),
                    ),
                  ),
                ],
              ),
            ),
            if (badgeText != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEAE6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5A524D),
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFFB0AAA4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    String? tag,
    Color tagColor = const Color(0xFF15803D),
    Color tagBgColor = const Color(0xFFDCFCE7),
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF7E756F)),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
            if (tag != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFFEF2F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            LogoutConfirmationDialog.show(context);
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 15, color: Color(0xFFDC2626)),
              SizedBox(width: 6),
              Text(
                'Keluar dari Akun',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String photoUrl) {
    if (photoUrl.isEmpty) {
      return Container(
        color: const Color(0xFFFFECE5),
        child: const Icon(
          Icons.person_rounded,
          size: 34,
          color: AppColors.primaryOrange,
        ),
      );
    }
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.person_rounded,
          size: 34,
          color: AppColors.primaryOrange,
        ),
      );
    }
    if (photoUrl.startsWith('assets/')) {
      return Image.asset(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.person_rounded,
          size: 34,
          color: AppColors.primaryOrange,
        ),
      );
    }
    final file = File(photoUrl);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.person_rounded,
          size: 34,
          color: AppColors.primaryOrange,
        ),
      );
    }
    return const Icon(
      Icons.person_rounded,
      size: 34,
      color: AppColors.primaryOrange,
    );
  }
}
