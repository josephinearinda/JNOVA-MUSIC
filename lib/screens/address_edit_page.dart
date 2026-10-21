import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/user_profile_service.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman UBAH ALAMAT JNOVAMUSIC sesuai desain referensi visual resmi
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
  late TextEditingController _rtRwController;
  late TextEditingController _postalCodeController;
  late TextEditingController _courierNotesController;

  String _selectedProvince = 'DKI Jakarta';
  String _selectedCity = 'Kota Jakarta Utara';
  String _selectedKecamatan = 'Kelapa Gading';
  String _selectedKelurahan = 'Kelapa Gading Brt';

  bool _isPrimaryAddress = true;
  bool _isLoading = false;

  final List<String> _provinces = const [
    'DKI Jakarta',
    'Jawa Barat',
    'Jawa Tengah',
    'DI Yogyakarta',
    'Jawa Timur',
    'Banten',
    'Bali',
  ];

  final List<String> _cities = const [
    'Kota Jakarta Utara',
    'Kota Jakarta Selatan',
    'Kota Jakarta Pusat',
    'Kota Jakarta Barat',
    'Kota Jakarta Timur',
    'Kota Bandung',
    'Kota Surabaya',
  ];

  final List<String> _kecamatans = const [
    'Kelapa Gading',
    'Tanjung Priok',
    'Koja',
    'Cilincing',
    'Pademangan',
    'Penjaringan',
  ];

  final List<String> _kelurahans = const [
    'Kelapa Gading Brt',
    'Kelapa Gading Timur',
    'Pegangsaan Dua',
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
      text: profile.fullName.isNotEmpty ? profile.fullName : 'Budi Pratama',
    );

    // Format phone: strip +62 if already present
    String phone = profile.phoneNumber;
    if (phone.startsWith('+62')) {
      phone = phone.substring(3).trim();
    } else if (phone.startsWith('62')) {
      phone = phone.substring(2).trim();
    }
    _phoneController = TextEditingController(
      text: phone.isNotEmpty ? phone : '812-3456-7890',
    );

    _streetAddressController = TextEditingController(
      text: profile.streetAddress.isNotEmpty
          ? profile.streetAddress
          : 'Jl. Musik Harmoni No. 42',
    );
    _rtRwController = TextEditingController(
      text: profile.rtRw.isNotEmpty ? profile.rtRw : 'RT 04 / RW 08',
    );
    _postalCodeController = TextEditingController(
      text: profile.postalCode.isNotEmpty ? profile.postalCode : '14240',
    );
    _courierNotesController = TextEditingController(
      text: profile.courierNotes.isNotEmpty
          ? profile.courierNotes
          : 'Dekat Studio Musik Melodi, pagar hitam ada bel pintu.',
    );

    if (profile.province.isNotEmpty && _provinces.contains(profile.province)) {
      _selectedProvince = profile.province;
    }
    if (profile.city.isNotEmpty && _cities.contains(profile.city)) {
      _selectedCity = profile.city;
    }
    if (profile.kecamatan.isNotEmpty &&
        _kecamatans.contains(profile.kecamatan)) {
      _selectedKecamatan = profile.kecamatan;
    }

    _isPrimaryAddress = profile.isDefaultAddress;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _recipientNameController.dispose();
    _phoneController.dispose();
    _streetAddressController.dispose();
    _rtRwController.dispose();
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final success = await _profileService.updateProfile(
      fullName: _recipientNameController.text.trim(),
      phoneNumber: '+62 ${_phoneController.text.trim()}',
      streetAddress: _streetAddressController.text.trim(),
      rtRw: _rtRwController.text.trim(),
      courierNotes: _courierNotesController.text.trim(),
      kelurahan: _selectedKelurahan,
      kecamatan: _selectedKecamatan,
      city: _selectedCity,
      province: _selectedProvince,
      postalCode: _postalCodeController.text.trim(),
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
            // Top App Bar dengan Soundwave Logo, Pencarian, Notifikasi, Avatar
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

                      // Form Input Alamat
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
          // Soundwave Logo + Brand Name
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

          // Search Icon
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 21),
            onPressed: () => Navigator.pushNamed(context, '/search'),
            color: const Color(0xFF4A403A),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),

          // Notification Bell with Badge Dot
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

          // Profile Avatar
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
          // Label Alamat
          _buildInputLabel('Label Alamat'),
          const SizedBox(height: 5),
          _buildTextFormField(
            controller: _labelController,
            prefixIcon: Icons.bookmark_outline_rounded,
          ),
          const SizedBox(height: 12),

          // Nama Penerima
          _buildInputLabel('Nama Penerima', rightNote: '* Wajib'),
          const SizedBox(height: 5),
          _buildTextFormField(
            controller: _recipientNameController,
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nama penerima wajib diisi' : null,
          ),
          const SizedBox(height: 12),

          // Nomor HP Penerima dengan Badge +62
          _buildInputLabel('Nomor HP Penerima', rightNote: '* Wajib'),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                height: 40,
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

          // Alamat Jalan & Nomor Rumah
          _buildInputLabel('Alamat Jalan & Nomor Rumah', rightNote: '* Wajib'),
          const SizedBox(height: 5),
          _buildTextFormField(
            controller: _streetAddressController,
            prefixIcon: Icons.location_on_outlined,
            hintText: 'Nama jalan, nomor rumah, gedung...',
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Alamat jalan wajib diisi'
                : null,
          ),
          const SizedBox(height: 12),

          // RT / RW & Kode Pos
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('RT / RW (Opsional)'),
                    const SizedBox(height: 5),
                    _buildTextFormField(
                      controller: _rtRwController,
                      hintText: 'RT 04 / RW 08',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Kode Pos', rightNote: '* Wajib'),
                    const SizedBox(height: 5),
                    _buildTextFormField(
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      hintText: '14240',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Kode pos wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kartu Wilayah Administratif
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WILAYAH ADMINISTRATIF',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF6E6560),
                  ),
                ),
                const SizedBox(height: 10),

                // Provinsi
                _buildInputLabel('Provinsi *'),
                const SizedBox(height: 4),
                _buildDropdown(_provinces, _selectedProvince, (val) {
                  setState(() => _selectedProvince = val!);
                }),
                const SizedBox(height: 10),

                // Kabupaten / Kota
                _buildInputLabel('Kabupaten / Kota *'),
                const SizedBox(height: 4),
                _buildDropdown(_cities, _selectedCity, (val) {
                  setState(() => _selectedCity = val!);
                }),
                const SizedBox(height: 10),

                // Kecamatan & Kelurahan
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Kecamatan *'),
                          const SizedBox(height: 4),
                          _buildDropdown(_kecamatans, _selectedKecamatan, (val) {
                            setState(() => _selectedKecamatan = val!);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Kelurahan *'),
                          const SizedBox(height: 4),
                          _buildDropdown(_kelurahans, _selectedKelurahan, (val) {
                            setState(() => _selectedKelurahan = val!);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Catatan untuk Kurir
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
                hintText: 'Dekat Studio Musik Melodi, pagar hitam ada bel pintu.',
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
    TextInputType? keyboardType,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 40,
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
            vertical: 10,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 16, color: const Color(0xFF7E756F))
              : null,
          prefixIconConstraints: const BoxConstraints(
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

  Widget _buildDropdown(
    List<String> items,
    String selected,
    ValueChanged<String?> onChanged,
  ) {
    final value = items.contains(selected) ? selected : items.first;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2EE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Color(0xFF6E6560),
          ),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1E1E),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          items: items.map((e) {
            return DropdownMenuItem<String>(value: e, child: Text(e));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
