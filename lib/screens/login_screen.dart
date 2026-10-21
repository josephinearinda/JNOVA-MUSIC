import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/google_logo.dart';
import 'register_screen.dart';

/// Halaman Login JNOVAMUSIC sesuai spesifikasi desain Figma asli.
///
/// Fitur:
/// - Logo identitas toko asli hasil ekstrak Figma
/// - Field input Email dengan validasi format
/// - Field input Kata Sandi dengan tombol tampilkan/sembunyikan
/// - Tombol Masuk dengan drop shadow oranye dan state loading
/// - Pemisah "ATAU" dan tombol "Lanjutkan dengan Google"
/// - 3 kartu kategori toko (Gitar & Bass, Keyboard, Audio & Studio)
/// - Tautan registrasi ("Daftar")
/// - Badge jaminan keamanan transaksi toko resmi
class LoginScreen extends StatefulWidget {
  final VoidCallback? onRegisterPressed;
  final VoidCallback? onForgotPasswordPressed;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onRegisterPressed,
    this.onForgotPasswordPressed,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Proses masuk akun dengan validasi input
  Future<void> _handleLogin() async {
    // Tutup keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.instance.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message,
          style: const TextStyle(fontSize: 13),
        ),
        backgroundColor: result.isSuccess ? Colors.green : AppColors.darkGrey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );

    if (result.isSuccess) {
      widget.onLoginSuccess?.call();
    }
  }

  /// Penanganan tombol Google
  Future<void> _handleGoogleLogin() async {
    final result = await AuthService.instance.loginWithGoogle();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message,
          style: const TextStyle(fontSize: 13),
        ),
        backgroundColor: AppColors.darkGrey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  /// Penanganan Lupa Kata Sandi
  void _handleForgotPassword() {
    if (widget.onForgotPasswordPressed != null) {
      widget.onForgotPasswordPressed!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Halaman Lupa Kata Sandi disiapkan untuk tahap berikutnya.',
            style: TextStyle(fontSize: 13),
          ),
          backgroundColor: AppColors.darkGrey,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
    }
  }

  /// Penanganan navigasi Daftar
  void _handleRegister() {
    if (widget.onRegisterPressed != null) {
      widget.onRegisterPressed!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterScreen(
            onRegisterSuccess: () {
              widget.onLoginSuccess?.call();
            },
            onLoginPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // A. Logo dan Identitas Toko
                Center(
                  child: Image.asset(
                    'assets/images/login_header_logo.png',
                    width: 148,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 24),

                // B. Judul dan Deskripsi
                const Text(
                  'Selamat Datang!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Temukan alat musik yang tepat untuk menemani kreativitasmu.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryBrown,
                  ),
                ),

                const SizedBox(height: 22),

                // C. Form Login: Field 1 - Alamat Email
                const Text(
                  'Alamat Email',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textPrimaryDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan alamat email',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.placeholder,
                    ),
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.placeholder,
                      size: 19,
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
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
                        color: AppColors.primaryOrange,
                        width: 1.2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat email wajib diisi';
                    }
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // C. Form Login: Field 2 - Kata Sandi
                const Text(
                  'Kata Sandi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textPrimaryDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan kata sandi',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.placeholder,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.placeholder,
                      size: 19,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.placeholder,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
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
                        color: AppColors.primaryOrange,
                        width: 1.2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.2,
                      ),
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

                // D. Lupa Kata Sandi
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 0,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Lupa Kata Sandi?',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // E. Tombol Masuk
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      disabledBackgroundColor:
                          AppColors.primaryOrange.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Masuk \u2192',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                // F. Pemisah ATAU
                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: AppColors.borderLight,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'ATAU',
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: AppColors.borderLight,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // F. Tombol Lanjutkan dengan Google
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GoogleLogo(size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Lanjutkan dengan Google',
                          style: TextStyle(
                            color: AppColors.textPrimaryDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // G. Tiga Kategori Toko (Gitar & Bass, Keyboard, Audio & Studio)
                Row(
                  children: [
                    _buildCategoryCard(
                      icon: Icons.graphic_eq_rounded,
                      title: 'Gitar & Bass',
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryCard(
                      icon: Icons.piano_rounded,
                      title: 'Keyboard',
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryCard(
                      icon: Icons.headphones_rounded,
                      title: 'Audio & Studio',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // H. Tautan Registrasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun? ',
                      style: TextStyle(
                        color: AppColors.textSecondaryBrown,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleRegister,
                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // I. Informasi Keamanan & Garansi Toko
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.primaryOrange,
                          size: 13.5,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Transaksi Aman & Bergaransi Resmi Toko',
                          style: TextStyle(
                            color: AppColors.textSecondaryBrown,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                const Center(
                  child: Text(
                    'Jaminan produk orisinal 100% langsung dari distributor terpercaya',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Komponen kartu kategori horizontal kecil
  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.primaryOrange,
              size: 18,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
