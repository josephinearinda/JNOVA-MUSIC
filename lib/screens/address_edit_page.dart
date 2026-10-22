import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/user_profile_service.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman UBAH ALAMAT JNOVAMUSIC
/// Disesuaikan agar struktur dan nama field persis seperti formulir alamat saat registrasi akun.
class AddressEditPage extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  const AddressEditPage({super.key, this.onBack, this.onSaved});

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final UserProfileService _profileService = UserProfileService.instance;
  final _formKey = GlobalKey<FormState>();

  String _selectedLocationType = 'Rumah';
  late TextEditingController _labelController;
  late TextEditingController _recipientNameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetAddressController;
  late TextEditingController _kelurahanController;
  late TextEditingController _kecamatanController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
  late TextEditingController _postalCodeController;
  late TextEditingController _courierNotesController;

  bool _isPrimaryAddress = true;
  bool _isLoading = false;

  static const List<String> _provinces = [
    'Aceh',
    'Sumatera Utara',
    'Sumatera Barat',
    'Riau',
    'Kepulauan Riau',
    'Jambi',
    'Sumatera Selatan',
    'Kepulauan Bangka Belitung',
    'Bengkulu',
    'Lampung',
    'DKI Jakarta',
    'Banten',
    'Jawa Barat',
    'Jawa Tengah',
    'DI Yogyakarta',
    'Jawa Timur',
    'Bali',
    'Nusa Tenggara Barat',
    'Nusa Tenggara Timur',
    'Kalimantan Barat',
    'Kalimantan Tengah',
    'Kalimantan Selatan',
    'Kalimantan Timur',
    'Kalimantan Utara',
    'Sulawesi Utara',
    'Gorontalo',
    'Sulawesi Tengah',
    'Sulawesi Barat',
    'Sulawesi Selatan',
    'Sulawesi Tenggara',
    'Maluku',
    'Maluku Utara',
    'Papua',
    'Papua Barat',
    'Papua Selatan',
    'Papua Tengah',
    'Papua Pegunungan',
    'Papua Barat Daya',
  ];

  @override
  void initState() {
    super.initState();
    final profile = _profileService.profile;

    _labelController = TextEditingController(
      text: profile.addressLabel.isNotEmpty
          ? profile.addressLabel
          : 'Rumah Utama',
    );
    _recipientNameController = TextEditingController(
      text: profile.fullName.isNotEmpty ? profile.fullName : '',
    );

    // Format phone: strip +62 if already present
    String phone = profile.phoneNumber;
    if (phone.startsWith('+62')) {
      phone = phone.substring(3).trim();
    } else if (phone.startsWith('62')) {
      phone = phone.substring(2).trim();
    }
    _phoneController = TextEditingController(text: phone);

    _streetAddressController = TextEditingController(
      text: profile.streetAddress.isNotEmpty ? profile.streetAddress : '',
    );
    _kelurahanController = TextEditingController(
      text: profile.kelurahan.isNotEmpty ? profile.kelurahan : '',
    );
    _kecamatanController = TextEditingController(
      text: profile.kecamatan.isNotEmpty ? profile.kecamatan : '',
    );
    _cityController = TextEditingController(
      text: profile.city.isNotEmpty ? profile.city : '',
    );
    _provinceController = TextEditingController(
      text: profile.province.isNotEmpty ? profile.province : '',
    );
    _postalCodeController = TextEditingController(
      text: profile.postalCode.isNotEmpty ? profile.postalCode : '',
    );
    _courierNotesController = TextEditingController(
      text: profile.courierNotes.isNotEmpty ? profile.courierNotes : '',
    );

    _isPrimaryAddress = profile.isDefaultAddress;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _recipientNameController.dispose();
    _phoneController.dispose();
    _streetAddressController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _courierNotesController.dispose();
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

  void _showProvincePicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Pilih Provinsi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _provinces.length,
                  itemBuilder: (context, index) {
                    final province = _provinces[index];
                    final isSelected = _provinceController.text == province;
                    return ListTile(
                      title: Text(
                        province,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected
                              ? const Color(0xFFFF5500)
                              : const Color(0xFF1E1E1E),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Color(0xFFFF5500),
                              size: 18,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _provinceController.text = province;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final phoneDigits = _phoneController.text.trim();
    final fullPhone = phoneDigits.isNotEmpty ? '+62 $phoneDigits' : '';

    final success = await _profileService.updateProfile(
      fullName: _recipientNameController.text.trim(),
      phoneNumber: fullPhone,
      addressLabel: _labelController.text.trim(),
      streetAddress: _streetAddressController.text.trim(),
      kelurahan: _kelurahanController.text.trim(),
      kecamatan: _kecamatanController.text.trim(),
      city: _cityController.text.trim(),
      province: _provinceController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      courierNotes: _courierNotesController.text.trim(),
      isDefaultAddress: _isPrimaryAddress,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat pengiriman berhasil diperbarui!'),
          backgroundColor: Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
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

  void _handleDelete() {
    if (_isPrimaryAddress) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Tidak Dapat Menghapus',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Alamat utama tidak dapat dihapus. Silakan tentukan alamat utama lainnya terlebih dahulu.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6E6560)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Mengerti',
                style: TextStyle(
                  color: Color(0xFFFF5500),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Hapus Alamat',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Apakah kamu yakin ingin menghapus alamat pengiriman ini?',
            style: TextStyle(fontSize: 12, color: Color(0xFF6E6560)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF6E6560)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alamat berhasil dihapus.'),
                    duration: Duration(seconds: 1),
                  ),
                );
                _handleBack();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Form Konten Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Sub Header Ubah Alamat
                      _buildSubHeader(),

                      const SizedBox(height: 12),

                      // Banner Pengiriman Khusus Audio & Instrumen
                      _buildSpecialCourierNotice(),

                      const SizedBox(height: 14),

                      // Tipe Lokasi Tabs (Rumah, Kantor, Studio/Kost)
                      _buildLocationTypeSelector(),

                      const SizedBox(height: 14),

                      // Form Input Alamat (Sesuai kolom pendaftaran: Alamat Lengkap, Kelurahan, Kecamatan, Kota/Kabupaten, Provinsi, Kode Pos)
                      _buildAddressFormFields(),

                      const SizedBox(height: 14),

                      // Card Jadikan Alamat Utama dengan Switch
                      _buildPrimarySwitchCard(),

                      const SizedBox(height: 18),

                      // Action Buttons (Simpan & Hapus)
                      _buildActionButtons(),

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
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/all-products');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/membership');
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F0ED), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5500),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildWaveBar(height: 5),
                      const SizedBox(width: 1.5),
                      _buildWaveBar(height: 10),
                      const SizedBox(width: 1.5),
                      _buildWaveBar(height: 15),
                      const SizedBox(width: 1.5),
                      _buildWaveBar(height: 10),
                      const SizedBox(width: 1.5),
                      _buildWaveBar(height: 5),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'JNOVAMUSIC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 21),
            onPressed: () => Navigator.pushNamed(context, '/search'),
            color: const Color(0xFF4A403A),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 21),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
                color: const Color(0xFF4A403A),
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
                    color: Color(0xFFFF5500),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFB45309),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveBar({required double height}) {
    return Container(
      width: 1.8,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1.0),
      ),
    );
  }

  Widget _buildSubHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 19,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubah Alamat',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Kelola pengiriman alat musik & aksesoris',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF7E7E7E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialCourierNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEBDD), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              size: 16,
              color: Color(0xFFFF5500),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengiriman Khusus Audio & Instrumen',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pastikan nomor kontak selalu aktif agar kurir spesialis dapat melakukan konfirmasi sebelum pengantaran.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF7E7E7E),
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

  Widget _buildLocationTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIPE LOKASI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF5A524D),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip('Rumah', Icons.home_outlined),
              const SizedBox(width: 8),
              _buildTypeChip('Kantor', Icons.business_outlined),
              const SizedBox(width: 8),
              _buildTypeChip('Studio/Kost', Icons.graphic_eq_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String title, IconData icon) {
    final isSelected = _selectedLocationType == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedLocationType = title;
            if (title == 'Rumah' &&
                (_labelController.text == 'Kantor' ||
                    _labelController.text == 'Studio Musik')) {
              _labelController.text = 'Rumah Utama';
            } else if (title == 'Kantor' &&
                (_labelController.text == 'Rumah Utama' ||
                    _labelController.text == 'Studio Musik')) {
              _labelController.text = 'Kantor';
            } else if (title == 'Studio/Kost' &&
                (_labelController.text == 'Rumah Utama' ||
                    _labelController.text == 'Kantor')) {
              _labelController.text = 'Studio Musik';
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF5500)
                : const Color(0xFFF4F2EE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF6E6560),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6E6560),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressFormFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Label Alamat
          _buildInputLabel('Label Alamat'),
          const SizedBox(height: 5),
          _buildTextFormField(
            controller: _labelController,
            prefixIcon: Icons.bookmark_outline_rounded,
            hintText: 'Contoh: Rumah Utama, Kantor, Studio',
          ),
          const SizedBox(height: 12),

          // 2. Nama Penerima
          _buildInputLabel('Nama Penerima', rightNote: '* Wajib'),
          const SizedBox(height: 5),
          _buildTextFormField(
            controller: _recipientNameController,
            prefixIcon: Icons.person_outline_rounded,
            hintText: 'Nama lengkap penerima',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nama penerima wajib diisi' : null,
          ),
          const SizedBox(height: 12),

          // 3. Nomor HP Penerima dengan Badge +62
          _buildInputLabel('Nomor HP Penerima', rightNote: '* Wajib'),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F2EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇮🇩', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 5),
                    Text(
                      '+62',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  hintText: '812-3456-7890',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nomor HP wajib diisi'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Alamat Lengkap (Sesuai Form Pendaftaran)
          _buildInputLabel('Alamat Lengkap', rightNote: '* Wajib'),
          const SizedBox(height: 5),
          _buildTextFormField(
            controller: _streetAddressController,
            prefixIcon: Icons.home_outlined,
            hintText: 'Masukkan nama jalan, nomor bangunan, RT/RW',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Alamat lengkap wajib diisi'
                : null,
          ),
          const SizedBox(height: 12),

          // 5. Kelurahan (Sesuai Form Pendaftaran)
          _buildInputLabel('Kelurahan', rightNote: '* Wajib'),
          const SizedBox(height: 5),
          _buildTextFormField(
            controller: _kelurahanController,
            prefixIcon: Icons.location_on_outlined,
            hintText: 'Masukkan kelurahan / desa',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Kelurahan wajib diisi'
                : null,
          ),
          const SizedBox(height: 12),

          // 6. Kecamatan (Sesuai Form Pendaftaran)
          _buildInputLabel('Kecamatan', rightNote: '* Wajib'),
          const SizedBox(height: 5),
          _buildTextFormField(
            controller: _kecamatanController,
            prefixIcon: Icons.location_city_outlined,
            hintText: 'Masukkan kecamatan',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Kecamatan wajib diisi'
                : null,
          ),
          const SizedBox(height: 12),

          // 7. Kota/Kabupaten (Sesuai Form Pendaftaran)
          _buildInputLabel('Kota/Kabupaten', rightNote: '* Wajib'),
          const SizedBox(height: 5),
          _buildTextFormField(
            controller: _cityController,
            prefixIcon: Icons.apartment_outlined,
            hintText: 'Contoh: Jakarta Pusat',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Kota/Kabupaten wajib diisi'
                : null,
          ),
          const SizedBox(height: 12),

          // 8. Provinsi (Sesuai Form Pendaftaran, dengan Modal Picker)
          _buildInputLabel('Provinsi', rightNote: '* Wajib'),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: _showProvincePicker,
            child: AbsorbPointer(
              child: _buildTextFormField(
                controller: _provinceController,
                prefixIcon: Icons.map_outlined,
                hintText: 'Pilih provinsi',
                suffixIcon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF757575),
                  size: 20,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Provinsi wajib dipilih'
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 9. Kode Pos (Sesuai Form Pendaftaran)
          _buildInputLabel('Kode Pos', rightNote: '* Wajib'),
          const SizedBox(height: 5),
          _buildTextFormField(
            controller: _postalCodeController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.markunread_mailbox_outlined,
            hintText: 'Contoh: 10110',
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Kode Pos wajib diisi';
              }
              if (!RegExp(r'^\d{5}$').hasMatch(v.trim())) {
                return 'Kode Pos harus 5 digit angka';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // 10. Catatan untuk Kurir (Opsional)
          _buildInputLabel('Catatan untuk Kurir', rightNote: 'Opsional'),
          const SizedBox(height: 5),
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F2EE),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextFormField(
              controller: _courierNotesController,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E1E1E),
                height: 1.3,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Dekat patokan rumah, warna pagar, ada bel pintu...',
                hintStyle: TextStyle(fontSize: 11.5, color: Color(0xFF9E9E9E)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimarySwitchCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEDDF),
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 17,
              color: Color(0xFFFF5500),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadikan Alamat Utama',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Diprioritaskan otomatis saat checkout pemesanan instrumen.',
                  style: TextStyle(fontSize: 9.5, color: Color(0xFF7E7E7E)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Custom Orange Switch with Checkmark Knob
          GestureDetector(
            onTap: () {
              setState(() {
                _isPrimaryAddress = !_isPrimaryAddress;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _isPrimaryAddress
                    ? const Color(0xFFFF5500)
                    : const Color(0xFFD4D0C8),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: _isPrimaryAddress
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: _isPrimaryAddress
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Color(0xFFFF5500),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Tombol Simpan Perubahan Alamat Solid Orange
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Simpan Perubahan Alamat',
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
          const SizedBox(height: 10),

          // Tombol Hapus Alamat Ini Soft Grey Pill
          GestureDetector(
            onTap: _handleDelete,
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F2EE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 15,
                    color: Color(0xFFDC2626),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Hapus Alamat Ini',
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
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, {String? rightNote}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF262626),
          ),
        ),
        if (rightNote != null)
          Text(
            rightNote,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: rightNote.contains('*')
                  ? const Color(0xFFFF5500)
                  : const Color(0xFF8E837D),
            ),
          ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E1E1E),
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 16, color: const Color(0xFF7E756F))
              : null,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 34,
          ),
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 34,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
