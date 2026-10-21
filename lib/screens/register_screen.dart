import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

/// Halaman Registrasi Akun Baru JNOVAMUSIC
/// Dibuat persis sesuai desain referensi visual resmi JNOVAMUSIC.
class RegisterScreen extends StatefulWidget {
  final ValueChanged<String?>? onRegisterSuccess;
  final VoidCallback? onLoginPressed;

  const RegisterScreen({
    super.key,
    this.onRegisterSuccess,
    this.onLoginPressed,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _streetAddressController = TextEditingController();
  final TextEditingController _kelurahanController = TextEditingController();
  final TextEditingController _kecamatanController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

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
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _streetAddressController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  /// Memilih tanggal lahir menggunakan DatePicker
  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initialDate = DateTime(1998, 1, 1);
    final firstDate = DateTime(1940);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF5500),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final monthName = _indonesianMonths[picked.month - 1];
      setState(() {
        _birthDateController.text = '${picked.day} $monthName ${picked.year}';
      });
    }
  }

  /// Memilih provinsi melalui Bottom Sheet
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
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
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
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? const Color(0xFFFF5500) : const Color(0xFF1E1E1E),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFFFF5500), size: 18)
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

  /// Proses registrasi akun
  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Anda harus menyetujui Syarat dan Ketentuan serta Kebijakan Privasi.',
            style: TextStyle(fontSize: 12.5),
          ),
          backgroundColor: const Color(0xFF2E2E2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simpan data profil lengkap ke UserProfileService
    await UserProfileService.instance.updateProfile(
      fullName: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      streetAddress: _streetAddressController.text.trim(),
      kelurahan: _kelurahanController.text.trim(),
      kecamatan: _kecamatanController.text.trim(),
      city: _cityController.text.trim(),
      province: _provinceController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
    );

    // Registrasi ke AuthService
    final result = await AuthService.instance.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? 'Registrasi berhasil! Silakan masuk dengan akun baru Anda.'
              : result.message,
          style: const TextStyle(fontSize: 12.5),
        ),
        backgroundColor: result.isSuccess ? Colors.green : const Color(0xFF2E2E2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );

    if (result.isSuccess) {
      final registeredEmail = _emailController.text.trim();
      if (widget.onRegisterSuccess != null) {
        widget.onRegisterSuccess!(registeredEmail);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
          arguments: registeredEmail,
        );
      }
    }
  }

  void _handleBackToLogin() {
    if (widget.onLoginPressed != null) {
      widget.onLoginPressed!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // 1. Logo dan Identitas Toko (Header Terpusat)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ikon equalizer oranye
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5500),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildWaveBar(height: 7),
                              const SizedBox(width: 2.2),
                              _buildWaveBar(height: 14),
                              const SizedBox(width: 2.2),
                              _buildWaveBar(height: 20),
                              const SizedBox(width: 2.2),
                              _buildWaveBar(height: 14),
                              const SizedBox(width: 2.2),
                              _buildWaveBar(height: 7),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Teks Logo
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'JNÓVAMUSIC',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E1E1E),
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            'TOKO ALAT MUSIK RESMI',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF757575),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Judul dan Deskripsi
                const Center(
                  child: Text(
                    'Buat Akun',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1E1E),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Lengkapi data diri untuk mulai berbelanja\ndi JNOVAMUSIC.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7E7E7E),
                      height: 1.35,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // 3. Header Bagian Data Diri
                Row(
                  children: [
                    Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5500),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Data Diri',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Field 1: Nama Lengkap
                _buildFieldLabel('Nama Lengkap'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E1E1E),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Masukkan nama lengkap',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 2: Username
                _buildFieldLabel('Username'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E1E1E),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Masukkan username (misal: budipratama_music)',
                    prefixIcon: Icons.alternate_email_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username wajib diisi';
                    }
                    if (value.trim().length < 3) {
                      return 'Username minimal 3 karakter';
                    }
                    if (value.contains(' ')) {
                      return 'Username tidak boleh mengandung spasi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 3: Tanggal Lahir
                _buildFieldLabel('Tanggal Lahir'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickBirthDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _birthDateController,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF1E1E1E),
                      ),
                      decoration: _buildInputDecoration(
                        hint: 'Pilih tanggal lahir',
                        prefixIcon: Icons.calendar_today_outlined,
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF757575),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Field 4: Nomor HP
                _buildFieldLabel('Nomor HP'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E1E1E),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Contoh: 081234567890',
                    prefixIcon: Icons.phone_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor HP wajib diisi';
                    }
                    final clean = value.replaceAll(RegExp(r'[\s\-]'), '');
                    if (clean.length < 10) {
                      return 'Format nomor HP tidak valid (minimal 10 digit)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 5: Alamat Email
                _buildFieldLabel('Alamat Email'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E1E1E),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Masukkan alamat email',
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat email wajib diisi';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 6: Kata Sandi
                _buildFieldLabel('Kata Sandi'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E1E1E),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Buat kata sandi',
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF9E9E9E),
                        size: 19,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi wajib diisi';
                    }
                    if (value.length < 6) {
                      return 'Kata sandi minimal 6 karakter';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 7: Konfirmasi Kata Sandi
                _buildFieldLabel('Konfirmasi Kata Sandi'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E1E1E),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Masukkan ulang kata sandi',
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF9E9E9E),
                        size: 19,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi kata sandi wajib diisi';
                    }
                    if (value != _passwordController.text) {
                      return 'Kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 8: Alamat Lengkap
                _buildFieldLabel('Alamat Lengkap'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _streetAddressController,
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E1E1E),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Masukkan nama jalan, nomor bangunan, RT/RW',
                    prefixIcon: Icons.home_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat lengkap wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 9: Kelurahan
                _buildFieldLabel('Kelurahan'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _kelurahanController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E1E1E),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Masukkan kelurahan / desa',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kelurahan wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 10: Kecamatan
                _buildFieldLabel('Kecamatan'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _kecamatanController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E1E1E),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Masukkan kecamatan',
                    prefixIcon: Icons.location_city_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kecamatan wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 11: Kota/Kabupaten
                _buildFieldLabel('Kota/Kabupaten'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cityController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E1E1E),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Contoh: Jakarta Pusat',
                    prefixIcon: Icons.apartment_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kota/Kabupaten wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Field 12: Provinsi
                _buildFieldLabel('Provinsi'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _showProvincePicker,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _provinceController,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF1E1E1E),
                      ),
                      decoration: _buildInputDecoration(
                        hint: 'Pilih provinsi',
                        prefixIcon: Icons.map_outlined,
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF757575),
                          size: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Provinsi wajib dipilih';
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Field 13: Kode Pos
                _buildFieldLabel('Kode Pos'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E1E1E),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Contoh: 10110',
                    prefixIcon: Icons.markunread_mailbox_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kode Pos wajib diisi';
                    }
                    if (!RegExp(r'^\d{5}$').hasMatch(value.trim())) {
                      return 'Kode Pos harus 5 digit angka';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Checkbox Persetujuan Syarat & Ketentuan
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreeTerms = !_agreeTerms;
                        });
                      },
                      child: Container(
                        width: 19,
                        height: 19,
                        decoration: BoxDecoration(
                          color: _agreeTerms ? const Color(0xFFFF5500) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _agreeTerms ? const Color(0xFFFF5500) : const Color(0xFFD6D6D6),
                            width: 1.2,
                          ),
                        ),
                        child: _agreeTerms
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeTerms = !_agreeTerms;
                          });
                        },
                        child: const Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.35,
                            ),
                            children: [
                              TextSpan(
                                text: 'Saya menyetujui ',
                                style: TextStyle(color: Color(0xFF555555)),
                              ),
                              TextSpan(
                                text: 'Syarat dan Ketentuan',
                                style: TextStyle(
                                  color: Color(0xFFFF5500),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ' serta ',
                                style: TextStyle(color: Color(0xFF555555)),
                              ),
                              TextSpan(
                                text: 'Kebijakan Privasi',
                                style: TextStyle(
                                  color: Color(0xFFFF5500),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: '.',
                                style: TextStyle(color: Color(0xFF555555)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Tombol Daftar
                GestureDetector(
                  onTap: _isLoading ? null : _handleRegister,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5500),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44FF5500),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Daftar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Tautan Kembali ke Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(
                        color: Color(0xFF4A4A4A),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleBackToLogin,
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          color: Color(0xFFFF5500),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Badge Jaminan Transaksi Aman
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildShieldIcon(),
                        const SizedBox(width: 6),
                        const Text(
                          'Transaksi Aman & Bergaransi Resmi Toko',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Label setiap field formulir
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF262626),
      ),
    );
  }

  /// Satu batang equalizer soundwave
  Widget _buildWaveBar({required double height}) {
    return Container(
      width: 2.2,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  /// Ikon perisai keamanan bergaransi
  Widget _buildShieldIcon() {
    return SizedBox(
      width: 13,
      height: 14,
      child: CustomPaint(
        painter: _ShieldBadgePainter(),
      ),
    );
  }

  /// Dekorasi input field
  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12.5,
        color: Color(0xFFA8A8A8),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF9E9E9E),
        size: 19,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF6F6F6),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFFF5500),
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.2,
        ),
      ),
    );
  }
}

/// Painter perisai dua-warna (perak & oranye-merah) untuk badge keamanan
class _ShieldBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width * 0.5,
      size.height,
    );
    path.quadraticBezierTo(
      0,
      size.height * 0.6,
      0,
      size.height * 0.2,
    );
    path.close();

    // Sisi kiri (putih / abu perak)
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.5, size.height),
      Paint()..color = const Color(0xFFD4D4D8),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, 0, size.width * 0.5, size.height),
      Paint()..color = const Color(0xFFFF5500),
    );
    canvas.restore();

    final borderPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
