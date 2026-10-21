import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
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
  bool _isRefreshingRecovery = false;

  @override
  void initState() {
    super.initState();
    _profileService.addListener(_handleProfileChanged);
  }

  void _handleProfileChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _profileService.removeListener(_handleProfileChanged);
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRefreshRecovery() async {
    setState(() => _isRefreshingRecovery = true);
    await _profileService.refreshProfile();
    if (!mounted) return;
    setState(() => _isRefreshingRecovery = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Metode pemulihan & verifikasi telah disinkronkan.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showEmailInfoDialog(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.mail_outline_rounded, color: AppColors.primaryOrange, size: 20),
            SizedBox(width: 8),
            Text(
              'Email Autentikasi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          email.isNotEmpty
              ? 'Alamat email "$email" terhubung langsung dengan kredensial autentikasi akun Anda.\n\nUntuk menjaga keamanan akun dari pengambilalihan yang tidak sah, perubahan alamat email harus melalui verifikasi keamanan autentikasi.'
              : 'Belum ada email yang terhubung dengan akun ini. Silakan masuk atau lengkapi data profil Anda.',
          style: const TextStyle(fontSize: 12, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Tutup',
              style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(String currentPhone) {
    final phoneController = TextEditingController(text: currentPhone);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: const Row(
              children: [
                Icon(Icons.phone_outlined, color: AppColors.primaryOrange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Ubah Nomor Telepon',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nomor telepon ini tersinkron langsung dengan Profil akun JNOVAMUSIC Anda dan digunakan untuk verifikasi keamanan.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF6E6560), height: 1.3),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Contoh: +62 812-3456-7890',
                    prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF7E756F))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final newPhone = phoneController.text.trim();
                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() => isSaving = true);
                        final success = await _profileService.updateProfile(phoneNumber: newPhone);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Nomor telepon berhasil diperbarui & tersinkron.'),
                              backgroundColor: Color(0xFF15803D),
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Gagal menyimpan nomor telepon.'),
                              backgroundColor: Color(0xFFDC2626),
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
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

  Future<void> _handleBiometricToggle(bool val) async {
    final profile = _profileService.profile;

    if (!val) {
      final res =
          await AuthService.instance.disableBiometricsForUser(profile.email);
      await _profileService.toggleBiometric(false);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: const Color(0xFF2E2E2E),
        ),
      );
      return;
    }

    // 1. Periksa dukungan hardware perangkat
    final isSupported = await BiometricService.instance.isDeviceSupported();
    if (!isSupported) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text(
                'Perangkat Tidak Mendukung',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Perangkat Anda tidak memiliki sensor biometrik atau hardware sidik jari tidak didukung.',
            style: TextStyle(fontSize: 12.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Periksa apakah sidik jari sudah didaftarkan
    final hasEnrolled = await BiometricService.instance.hasEnrolledBiometrics();
    if (!hasEnrolled) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.fingerprint_rounded, color: AppColors.primaryOrange),
              SizedBox(width: 8),
              Text(
                'Sidik Jari Belum Ada',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Belum ada sidik jari yang terdaftar di perangkat Anda.\n\nSilakan daftarkan sidik jari Anda terlebih dahulu melalui Pengaturan Keamanan ponsel Android Anda, kemudian aktifkan kembali opsi ini.',
            style: TextStyle(fontSize: 12.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Mengerti',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 3. Autentikasi dan simpan kredensial aman
    final result = await AuthService.instance.enableBiometricsForUser(
      email: profile.email,
      fullName: profile.fullName,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      await _profileService.toggleBiometric(true);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    } else {
      await _profileService.toggleBiometric(false);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
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
                    _buildRecoveryMethodsCard(profile),

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

  Widget _buildRecoveryMethodsCard(dynamic profile) {
    final String email = profile.email as String? ?? '';
    final String phone = profile.phoneNumber as String? ?? '';
    final bool isEmailVerif = profile.isEmailVerified as bool? ?? false;
    final bool isPhoneVerif = profile.isPhoneVerified as bool? ?? false;

    final hasEmail = email.isNotEmpty;
    final hasPhone = phone.isNotEmpty;

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
                onPressed: _isRefreshingRecovery ? null : _handleRefreshRecovery,
                icon: _isRefreshingRecovery
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryOrange,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email Terdaftar',
                        style: TextStyle(fontSize: 9, color: Color(0xFF8E837D)),
                      ),
                      Text(
                        hasEmail ? email : 'Belum tersedia',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasEmail ? FontWeight.w700 : FontWeight.normal,
                          fontStyle: hasEmail ? FontStyle.normal : FontStyle.italic,
                          color: hasEmail ? AppColors.textPrimaryDark : const Color(0xFF8E837D),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (!hasEmail)
                  _buildMissingBadge('Belum Ada')
                else if (isEmailVerif)
                  _buildVerifiedBadge('Terverifikasi')
                else
                  _buildUnverifiedBadge('Belum Terverifikasi'),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _showEmailInfoDialog(email),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F0ED),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Info',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5A524D),
                      ),
                    ),
                  ),
                ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nomor Telepon',
                        style: TextStyle(fontSize: 9, color: Color(0xFF8E837D)),
                      ),
                      Text(
                        hasPhone ? phone : 'Belum tersedia',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasPhone ? FontWeight.w700 : FontWeight.normal,
                          fontStyle: hasPhone ? FontStyle.normal : FontStyle.italic,
                          color: hasPhone ? AppColors.textPrimaryDark : const Color(0xFF8E837D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (!hasPhone)
                  _buildMissingBadge('Belum Ada')
                else if (isPhoneVerif)
                  _buildVerifiedBadge('Terverifikasi')
                else
                  _buildUnverifiedBadge('Belum Terverifikasi'),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _showEditPhoneDialog(phone),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F0ED),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Ubah',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5A524D),
                      ),
                    ),
                  ),
                ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Verifikasi 2 Langkah',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (profile.phoneNumber as String? ?? '').isNotEmpty
                                  ? 'Aktif'
                                  : 'Nonaktif',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: (profile.phoneNumber as String? ?? '').isNotEmpty
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          (profile.phoneNumber as String? ?? '').isNotEmpty
                              ? 'OTP via SMS / WhatsApp aktif (${profile.phoneNumber})'
                              : 'Tambahkan nomor HP di Profil untuk mengaktifkan OTP',
                          style: const TextStyle(
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
                    color: profile.isBiometricEnabled
                        ? const Color(0xFFFFEDDF)
                        : const Color(0xFFEDEBE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 16,
                    color: profile.isBiometricEnabled
                        ? AppColors.primaryOrange
                        : const Color(0xFF5A524D),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login dengan Sidik Jari',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      Text(
                        'Gunakan sidik jari untuk masuk akun lebih cepat dan aman',
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
                  onChanged: (val) => _handleBiometricToggle(val),
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

  Widget _buildVerifiedBadge([String label = 'Terverifikasi']) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 9, color: Color(0xFF15803D)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnverifiedBadge([String label = 'Belum Terverifikasi']) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded, size: 9, color: Color(0xFFB45309)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingBadge([String label = 'Belum Ada']) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEBE7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7E756F),
        ),
      ),
    );
  }
}
