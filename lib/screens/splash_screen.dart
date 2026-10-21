import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Halaman Splash Screen JNOVAMUSIC sesuai desain Figma asli.
///
/// Menggunakan animasi bertahap (staggered animation) yang halus:
/// - Logo diamond & pick: Fade-in dan subtle scale
/// - Ambient glow: Muncul lembut di latar belakang logo
/// - Brand title (JNOVAMUSIC): Fade-in & slide-up halus
/// - Badge resmi & tagline: Fade-in teratur
/// - Soundwave loader: Gelombang suara ritmik halus yang kemudian stabil
/// - Footer versi: Fade-in di bagian bawah layar
class SplashScreen extends StatefulWidget {
  /// Callback opsional ketika durasi animasi selesai.
  /// Jika halaman berikutnya belum siap, Splash Screen tetap tampil.
  final VoidCallback? onAnimationFinished;

  const SplashScreen({
    super.key,
    this.onAnimationFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staggered animations
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _glowFadeAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<Offset> _titleSlideAnimation;
  late final Animation<double> _badgeFadeAnimation;
  late final Animation<double> _taglineFadeAnimation;
  late final Animation<double> _soundwaveFadeAnimation;
  late final Animation<double> _footerFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Durasi total 2.0 detik (antara 1.5 - 2.5 detik)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 1. Logo Diamond: 0.0 -> 0.55
    _logoFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Ambient glow hangat: 0.10 -> 0.65
    _glowFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.65, curve: Curves.easeOut),
    );

    // 3. JNOVAMUSIC title: 0.35 -> 0.75
    _titleFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Pill badge resmi: 0.50 -> 0.82
    _badgeFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.82, curve: Curves.easeOut),
    );

    // 5. Tagline: 0.60 -> 0.88
    _taglineFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.88, curve: Curves.easeOut),
    );

    // 6. Soundwave loader: 0.20 -> 0.70
    _soundwaveFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.20, 0.70, curve: Curves.easeOut),
    );

    // 7. Footer versi: 0.70 -> 1.0
    _footerFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.70, 1.0, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationFinished?.call();
      }
    });

    // Jalankan animasi satu kali tanpa looping berulang
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Radial Glow hangat di balik logo utama
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0.0, -0.15),
                child: FadeTransition(
                  opacity: _glowFadeAnimation,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.orange.withValues(alpha: 0.12),
                          AppColors.orange.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Konten Tengah & Footer
            Column(
              children: [
                const Spacer(flex: 3),

                // Area Logo Diamond & Hero
                _buildDiamondLogo(),

                const SizedBox(height: 28),

                // Brand Name "JNOVAMUSIC"
                _buildBrandTitle(),

                const SizedBox(height: 14),

                // Pill Badge: Toko Alat Musik & Audio Studio Resmi
                _buildVerifiedBadge(),

                const SizedBox(height: 14),

                // Tagline: Temukan Nada, Ciptakan Karya
                _buildTagline(),

                const Spacer(flex: 4),

                // Indikator Gelombang Suara (3 Bar Oranye)
                _buildSoundwaveLoader(),

                const SizedBox(height: 18),

                // Footer Versi & Kredit
                _buildFooterText(),

                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Logo Diamond dengan Guitar Pick asli hasil ekstrak Figma
  Widget _buildDiamondLogo() {
    return FadeTransition(
      opacity: _logoFadeAnimation,
      child: ScaleTransition(
        scale: _logoScaleAnimation,
        child: Center(
          child: Image.asset(
            'assets/images/diamond_logo.png',
            width: 124,
            height: 116,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  /// Teks logo "JNOVAMUSIC"
  Widget _buildBrandTitle() {
    return SlideTransition(
      position: _titleSlideAnimation,
      child: FadeTransition(
        opacity: _titleFadeAnimation,
        child: Center(
          child: Image.asset(
            'assets/images/jnovamusic_title.png',
            width: 175,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  /// Badge Pill: TOKO ALAT MUSIK & AUDIO STUDIO RESMI
  Widget _buildVerifiedBadge() {
    return FadeTransition(
      opacity: _badgeFadeAnimation,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.badgeBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon verified oranye
              const Icon(
                Icons.verified,
                color: AppColors.orange,
                size: 15,
              ),
              const SizedBox(width: 6),
              const Text(
                'TOKO ALAT MUSIK & AUDIO STUDIO RESMI',
                style: TextStyle(
                  color: AppColors.darkGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tagline: Temukan Nada, Ciptakan Karya
  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineFadeAnimation,
      child: const Text(
        'Temukan Nada, Ciptakan Karya',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Indikator Gelombang Suara (3 Bar Oranye) dengan animasi ritmik halus
  Widget _buildSoundwaveLoader() {
    return FadeTransition(
      opacity: _soundwaveFadeAnimation,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Progress animasi gelombang suara
          final double t = _controller.value;

          // Animasi gelombang ritmik halus yang meredup menjelang akhir animasi
          // Base sizes sesuai desain Figma: left=8, center=22, right=8
          final double dampening = (1.0 - t).clamp(0.0, 1.0);
          final double wave1 = math.sin(t * math.pi * 5.0) * 4.0 * dampening;
          final double wave2 = math.cos(t * math.pi * 5.0) * 5.0 * dampening;
          final double wave3 = math.sin(t * math.pi * 5.0 + 1.0) * 4.0 * dampening;

          final double hLeft = (8.0 + wave1).clamp(6.0, 16.0);
          final double hCenter = (22.0 - wave2).clamp(14.0, 24.0);
          final double hRight = (8.0 + wave3).clamp(6.0, 16.0);

          return SizedBox(
            height: 26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildWaveBar(hLeft),
                const SizedBox(width: 5),
                _buildWaveBar(hCenter),
                const SizedBox(width: 5),
                _buildWaveBar(hRight),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 5.5,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  /// Teks versi & identitas di bagian bawah
  Widget _buildFooterText() {
    return FadeTransition(
      opacity: _footerFadeAnimation,
      child: const Text(
        'v2.4.0 \u2022 Karya Musik Indonesia',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
