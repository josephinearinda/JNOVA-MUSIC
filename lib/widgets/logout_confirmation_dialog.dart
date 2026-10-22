import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';

/// Komponen Dialog Konfirmasi Logout resmi JNOVAMUSIC sesuai desain Figma
class LogoutConfirmationDialog extends StatelessWidget {
  final VoidCallback? onConfirmLogout;

  const LogoutConfirmationDialog({super.key, this.onConfirmLogout});

  /// Menampilkan dialog konfirmasi logout dengan animasi fade & scale
  /// serta overlay gelap transparan (opacity ~45%) di atas layar aktif.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onConfirmLogout,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'LogoutConfirmation',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (buildContext, animation, secondaryAnimation) {
        return LogoutConfirmationDialog(onConfirmLogout: onConfirmLogout);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _handleConfirmLogout(BuildContext context) async {
    Navigator.of(context, rootNavigator: true).pop();
    await AuthService.instance.logout();
    if (onConfirmLogout != null) {
      onConfirmLogout!();
    } else {
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon Logout Oranye dengan background lingkaran peach lembut
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDE2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),

              // Judul Dialog
              const Text(
                'Yakin ingin keluar?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle Deskripsi
              const Text(
                'Kamu yakin ingin keluar dari akun JNOVAMUSIC? Keranjang dan wishlist kamu akan tersimpan dengan aman.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6E6560),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Utama: Ya, Keluar →
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _handleConfirmLogout(context),
                  child: const Text(
                    'Ya, Keluar →',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Tombol Batal
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFAF9F7),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFEBE8E3), width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5A524D),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Teks Keamanan Sesi
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 12,
                    color: Color(0xFF8E837D),
                  ),
                  SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Sesi belanja terenkripsi aman.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF8E837D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
