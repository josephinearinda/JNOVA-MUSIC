import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/user_profile_service.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman KEAMANAN AKUN JNOVAMUSIC sesuai desain Figma 8
class AccountSecurityPage extends StatefulWidget {
  final VoidCallback? onBack;

  const AccountSecurityPage({super.key, this.onBack});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  final UserProfileService _profileService = UserProfileService.instance;

  bool _isPasswordExpanded = false;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSavingPassword = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  void _handleChangePassword() async {
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confPass = _confirmPasswordController.text;

    if (oldPass.isEmpty || newPass.isEmpty || confPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom kata sandi wajib diisi.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi baru minimal 6 karakter.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (newPass != confPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi kata sandi tidak cocok.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSavingPassword = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _isSavingPassword = false;
      _isPasswordExpanded = false;
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kata sandi berhasil diperbarui secara aman!'),
        backgroundColor: Color(0xFF15803D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profileService.profile;

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
                child: Column(
                  children: [
                    _buildSubHeader(),

                    const SizedBox(height: 12),

                    // Status Keamanan: Kuat
                    _buildSecurityLevelCard(),

                    const SizedBox(height: 14),

                    // Metode Pemulihan & Verifikasi
                    _buildRecoveryMethodsCard(),

                    const SizedBox(height: 14),

                    // Opsi Keamanan (Ubah Sandi, 2FA, Biometrik)
                    _buildSecurityOptions(profile),

                    const SizedBox(height: 14),

                    // Perangkat & Sesi Login
                    _buildDevicesSection(),

                    const SizedBox(height: 14),

                    // Tips Keamanan JNOVAMUSIC
                    _buildSecurityTipsCard(),

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
            Navigator.pushReplacementNamed(context, '/favorite');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/all-products');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/games');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/order-detail');
          } else if (index == 4) {
            _handleBack();
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
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
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
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F4),
                shape: BoxShape.circle,
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keamanan Akun',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  'Kelola proteksi dan akses JNOVAMUSIC',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 16,
              color: AppColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityLevelCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3)),
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
                    Icon(Icons.circle, size: 6, color: AppColors.primaryOrange),
                    SizedBox(width: 4),
                    Text(
                      'Tingkat Keamanan: Kuat',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDDF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 18,
                  color: Color(0xFF9A3412),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Akun Terlindungi Penuh',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Semua parameter proteksi ganda aktif dan terverifikasi.',
            style: TextStyle(fontSize: 9.5, color: Color(0xFF6E6560)),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.88,
              backgroundColor: Color(0xFFEBE8E3),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryOrange,
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryMethodsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Metode Pemulihan & Verifikasi',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status pemulihan diperbarui.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                color: AppColors.primaryOrange,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Email
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEBE8E3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 16,
                  color: Color(0xFF7E756F),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Terdaftar',
                        style: TextStyle(fontSize: 9, color: Color(0xFF8E837D)),
                      ),
                      Text(
                        'b***.p******@email.com',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildVerifiedBadge(),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Nomor Telepon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEBE8E3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: Color(0xFF7E756F),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nomor Telepon',
                        style: TextStyle(fontSize: 9, color: Color(0xFF8E837D)),
                      ),
                      Text(
                        '+62 812-****-7890',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildVerifiedBadge(),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Color(0xFFB45309),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data ini digunakan untuk pengiriman kode verifikasi OTP dan perlindungan akun JNOVAMUSIC Anda saat login di perangkat baru.',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF78350F),
                      height: 1.3,
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

  Widget _buildSecurityOptions(dynamic profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3)),
      ),
      child: Column(
        children: [
          // Ubah Kata Sandi
          InkWell(
            onTap: () {
              setState(() {
                _isPasswordExpanded = !_isPasswordExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDDF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.key_rounded,
                      size: 16,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah Kata Sandi',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        Text(
                          'Perbarui kata sandi akunmu secara berkala',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF7E756F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isPasswordExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF8E837D),
                  ),
                ],
              ),
            ),
          ),

          if (_isPasswordExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  _buildPasswordField(
                    'Kata Sandi Saat Ini',
                    _oldPasswordController,
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    'Kata Sandi Baru',
                    _newPasswordController,
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    'Konfirmasi Kata Sandi Baru',
                    _confirmPasswordController,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _isSavingPassword
                          ? null
                          : _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSavingPassword
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan Kata Sandi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],

          const Divider(color: Color(0xFFEBE8E3), height: 1),

          // Verifikasi 2 Langkah
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Verifikasi 2 Langkah sudah aktif dengan nomor HP Anda.',
                  ),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Verifikasi 2 Langkah',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Aktif',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'OTP via SMS / WhatsApp aktif',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF7E756F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF8E837D),
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: Color(0xFFEBE8E3), height: 1),

          // Login Biometrik
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEBE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    size: 16,
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
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      Text(
                        'Gunakan Sidik Jari atau Face Unlock',
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
                  onChanged: (val) {
                    _profileService.toggleBiometric(val);
                    setState(() {});
                  },
                  activeThumbColor: AppColors.primaryOrange,
                  activeTrackColor: AppColors.primaryOrange.withValues(
                    alpha: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5A524D),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E2DC)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: controller,
            obscureText: true,
            style: const TextStyle(fontSize: 11),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.devices_rounded,
                  size: 16,
                  color: Color(0xFF4A403A),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perangkat & Sesi Login',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      '2 perangkat saat ini terhubung',
                      style: TextStyle(fontSize: 9.5, color: Color(0xFF7E756F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Perangkat 1: HP Sekarang
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEBE8E3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.smartphone_rounded,
                  size: 18,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Samsung Galaxy S25 FE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDDF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Perangkat Ini',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Icon(Icons.circle, size: 5, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'Jakarta, ID • Aktif sekarang',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF6E6560),
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
          const SizedBox(height: 8),

          // Perangkat 2: Laptop
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEBE8E3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.laptop_chromebook_rounded,
                  size: 18,
                  color: Color(0xFF7E756F),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chrome di Windows 11',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Yogyakarta, ID • Aktif 2 hari lalu',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF7E756F),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Sesi Chrome di Windows 11 berhasil dikeluarkan.',
                        ),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Keluar dari Sesi Lainnya
          SizedBox(
            width: double.infinity,
            height: 34,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Semua sesi login di perangkat lain telah diakhiri.',
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEDEBE7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.power_settings_new_rounded,
                    size: 14,
                    color: Color(0xFF4A403A),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Keluar dari Sesi Lainnya',
                    style: TextStyle(
                      fontSize: 10.5,
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

  Widget _buildSecurityTipsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrange,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Keamanan JNOVAMUSIC',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A3412),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Jangan pernah membagikan kode OTP atau kata sandi Anda kepada siapa pun. Tim resmi JNOVAMUSIC tidak akan pernah meminta kata sandi Anda melalui telepon maupun pesan chat.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF7C2D12),
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

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 9, color: Color(0xFF15803D)),
          SizedBox(width: 3),
          Text(
            'Terverifikasi',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }
}
