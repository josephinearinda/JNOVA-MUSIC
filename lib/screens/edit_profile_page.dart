import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman EDIT PROFIL JNOVAMUSIC sesuai desain Figma 9
class EditProfilePage extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  const EditProfilePage({super.key, this.onBack, this.onSaved});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UserProfileService _profileService = UserProfileService.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _birthDateController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  late TextEditingController _streetAddressController;
  late TextEditingController _courierNotesController;
  late TextEditingController _kelurahanController;
  late TextEditingController _kecamatanController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
  late TextEditingController _postalCodeController;

  bool _isDefaultAddress = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = _profileService.profile;

    _fullNameController = TextEditingController(text: profile.fullName);
    _usernameController = TextEditingController(text: profile.username);
    _birthDateController = TextEditingController(text: profile.birthDate);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phoneNumber);

    _streetAddressController = TextEditingController(
      text: '${profile.streetAddress}, ${profile.rtRw}',
    );
    _courierNotesController = TextEditingController(text: profile.courierNotes);
    _kelurahanController = TextEditingController(text: profile.kelurahan);
    _kecamatanController = TextEditingController(text: profile.kecamatan);
    _cityController = TextEditingController(text: profile.city);
    _provinceController = TextEditingController(text: profile.province);
    _postalCodeController = TextEditingController(text: profile.postalCode);

    _isDefaultAddress = profile.isDefaultAddress;
  }

  static const List<String> _indonesianMonths = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1998, 1, 1),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) {
      final monthName = _indonesianMonths[picked.month - 1];
      setState(() {
        _birthDateController.text = '${picked.day} $monthName ${picked.year}';
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetAddressController.dispose();
    _courierNotesController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final profile = _profileService.profile;
    final success = await _profileService.updateProfile(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: profile.email.isNotEmpty ? profile.email : _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      streetAddress: _streetAddressController.text.trim(),
      courierNotes: _courierNotesController.text.trim(),
      kelurahan: _kelurahanController.text.trim(),
      kecamatan: _kecamatanController.text.trim(),
      city: _cityController.text.trim(),
      province: _provinceController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      isDefaultAddress: _isDefaultAddress,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perubahan profil berhasil disimpan!'),
          backgroundColor: Color(0xFF1E1A18),
          duration: Duration(seconds: 2),
        ),
      );

      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        _handleBack();
      }
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

            // Form Konten yang dapat di-scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Sub Header: Back, Title, Simpan Button
                      _buildSubHeader(),

                      const SizedBox(height: 14),

                      // Avatar & Tombol Ubah Foto
                      _buildAvatarSection(profile),

                      const SizedBox(height: 18),

                      // Bagian 1: Informasi Akun & Kontak
                      _buildAccountInfoCard(profile),

                      const SizedBox(height: 16),

                      // Bagian 2: Alamat Pengiriman Utama
                      _buildShippingAddressCard(),

                      const SizedBox(height: 14),

                      // Kartu Catatan Enkripsi & Keamanan
                      _buildSecurityNoticeCard(),

                      const SizedBox(height: 18),

                      // Tombol Simpan Perubahan & Batal
                      _buildBottomActionButtons(),

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
        currentIndex: 4, // Profil tab aktif
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
                  'Edit Profil',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  'Perbarui informasi akun dan pengiriman',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _isLoading ? null : _handleSave,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDDF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryOrange,
                      ),
                    )
                  : const Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(UserProfileModel profile) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showPhotoSourcePicker,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD8BF), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildAvatarImage(profile.photoUrl),
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryOrange,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: _showPhotoSourcePicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F0ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Ganti Foto',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A403A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _handleRemovePhoto,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Hapus Foto',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Format JPG atau PNG maks. 5MB',
          style: TextStyle(fontSize: 9.5, color: Color(0xFF8E837D)),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(String photoUrl) {
    if (photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        return Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
        );
      } else if (photoUrl.startsWith('assets/')) {
        return Image.asset(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
        );
      } else if (File(photoUrl).existsSync()) {
        return Image.file(
          File(photoUrl),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
        );
      }
    }
    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFF7F6F4),
      child: const Icon(
        Icons.person_rounded,
        size: 44,
        color: Color(0xFF8E837D),
      ),
    );
  }

  void _showPhotoSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D0C8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ubah Foto Profil',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryOrange),
              title: const Text('Ambil Foto (Kamera)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryOrange),
              title: const Text('Pilih dari Galeri', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final result = await _profileService.pickAndUploadPhoto(source: source);
    if (!mounted) return;

    if (result['cancelled'] == true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] as String),
        backgroundColor: (result['success'] as bool? ?? false)
            ? Colors.green
            : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleRemovePhoto() async {
    if (_profileService.profile.photoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil sudah menggunakan avatar default.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await _profileService.removePhoto();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Foto profil berhasil dihapus.' : 'Gagal menghapus foto profil.'),
        backgroundColor: success ? Colors.green : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAccountInfoCard(UserProfileModel profile) {
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
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDDF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  size: 16,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Akun & Kontak',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      'Data identitas member musisi',
                      style: TextStyle(fontSize: 9.5, color: Color(0xFF7E756F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nama Lengkap *
          _buildInputLabel('Nama Lengkap *', rightNote: 'Wajib diisi'),
          const SizedBox(height: 4),
          _buildTextFormField(
            controller: _fullNameController,
            prefixIcon: Icons.person_outline_rounded,
            hintText: 'Nama lengkap Anda',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Nama lengkap wajib diisi'
                : null,
          ),
          const SizedBox(height: 10),

          // Username Profil
          _buildInputLabel('Username Profil'),
          const SizedBox(height: 4),
          _buildTextFormField(
            controller: _usernameController,
            prefixIcon: Icons.alternate_email_rounded,
            hintText: 'Username',
          ),
          const SizedBox(height: 10),

          // Tanggal Lahir
          _buildInputLabel('Tanggal Lahir'),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _pickBirthDate,
            child: AbsorbPointer(
              child: _buildTextFormField(
                controller: _birthDateController,
                prefixIcon: Icons.calendar_today_outlined,
                hintText: 'Pilih tanggal lahir',
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Alamat Email
          _buildInputLabel(
            'Alamat Email',
            customRightWidget: profile.email.isNotEmpty
                ? (profile.isEmailVerified
                    ? _buildVerifiedBadge('Terverifikasi')
                    : _buildUnverifiedBadge('Belum Verifikasi'))
                : null,
          ),
          const SizedBox(height: 4),
          _buildTextFormField(
            controller: _emailController,
            prefixIcon: Icons.mail_outline_rounded,
            hintText: 'Email Anda',
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
            suffixWidget: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF8E837D)),
            ),
          ),
          const SizedBox(height: 10),

          // Nomor Handphone
          _buildInputLabel(
            'Nomor Handphone',
            customRightWidget: profile.phoneNumber.isNotEmpty
                ? (profile.isPhoneVerified
                    ? _buildVerifiedBadge('Terverifikasi')
                    : _buildUnverifiedBadge('Belum Verifikasi'))
                : null,
          ),
          const SizedBox(height: 4),
          _buildTextFormField(
            controller: _phoneController,
            prefixIcon: Icons.phone_outlined,
            hintText: '+62 ...',
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddressCard() {
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
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDDF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alamat Pengiriman Utama',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      'Tujuan pengiriman instrumen & aksesoris',
                      style: TextStyle(fontSize: 9.5, color: Color(0xFF7E756F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Alamat Jalan & No. Bangunan
          _buildInputLabel('Alamat Jalan & No. Bangunan'),
          const SizedBox(height: 4),
          _buildTextFormField(
            controller: _streetAddressController,
            hintText: 'Nama jalan, nomor rumah / gedung',
          ),
          const SizedBox(height: 10),

          // Patokan / Catatan Kurir
          _buildInputLabel('Patokan / Catatan Kurir'),
          const SizedBox(height: 4),
          _buildTextFormField(
            controller: _courierNotesController,
            prefixIcon: Icons.near_me_outlined,
            hintText: 'Patokan lokasi',
          ),
          const SizedBox(height: 10),

          // Row: Kelurahan & Kecamatan
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Kelurahan'),
                    const SizedBox(height: 4),
                    _buildTextFormField(
                      controller: _kelurahanController,
                      hintText: 'Kelurahan',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Kecamatan'),
                    const SizedBox(height: 4),
                    _buildTextFormField(
                      controller: _kecamatanController,
                      hintText: 'Kecamatan',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row: Kota/Kabupaten & Provinsi
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Kota / Kabupaten'),
                    const SizedBox(height: 4),
                    _buildTextFormField(
                      controller: _cityController,
                      hintText: 'Kota/Kab',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Provinsi'),
                    const SizedBox(height: 4),
                    _buildTextFormField(
                      controller: _provinceController,
                      hintText: 'Provinsi',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Kode Pos
          _buildInputLabel('Kode Pos'),
          const SizedBox(height: 4),
          _buildTextFormField(
            controller: _postalCodeController,
            prefixIcon: Icons.markunread_mailbox_outlined,
            hintText: 'Kode pos',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),

          // Checkbox Default
          InkWell(
            onTap: () {
              setState(() {
                _isDefaultAddress = !_isDefaultAddress;
              });
            },
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _isDefaultAddress,
                    onChanged: (val) {
                      setState(() {
                        _isDefaultAddress = val ?? true;
                      });
                    },
                    activeColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Jadikan alamat default untuk checkout pesanan',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A403A),
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

  Widget _buildSecurityNoticeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFEDD5), width: 1.0),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xFFB45309)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data profil Anda dienkripsi aman dan disinkronkan langsung via backend JNOVAMUSIC. Kata sandi akun dapat diperbarui terpisah pada menu Keamanan Akun.',
              style: TextStyle(
                fontSize: 9.5,
                color: Color(0xFF78350F),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              onPressed: _handleBack,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF2F0ED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6E6560),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(
    String label, {
    String? rightNote,
    Widget? customRightWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4A403A),
          ),
        ),
        if (customRightWidget != null)
          customRightWidget
        else if (rightNote != null)
          Text(
            rightNote,
            style: const TextStyle(fontSize: 9, color: Color(0xFF8E837D)),
          ),
      ],
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

  Widget _buildUnverifiedBadge([String label = 'Belum Verifikasi']) {
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


  Widget _buildTextFormField({
    required TextEditingController controller,
    IconData? prefixIcon,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixWidget,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFF7F6F4) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E2DC), width: 1.0),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 16, color: const Color(0xFF8E837D))
              : null,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          suffixIcon: suffixWidget,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFFB0AAA4),
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
