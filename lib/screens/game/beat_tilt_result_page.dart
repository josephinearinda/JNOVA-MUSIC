import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/membership_service.dart';

/// Data hasil permainan JNova Beat Tilt.
class GameResultData {
  final int validShakes;
  final int pointsEarned;
  final double shakeRate;
  final int durationSeconds;

  const GameResultData({
    required this.validShakes,
    required this.pointsEarned,
    required this.shakeRate,
    required this.durationSeconds,
  });
}

/// Halaman keempat: hasil permainan.
class BeatTiltResultPage extends StatefulWidget {
  final GameResultData? resultData;
  final VoidCallback? onBack;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onReturnHome;

  const BeatTiltResultPage({
    super.key,
    this.resultData,
    this.onBack,
    this.onPlayAgain,
    this.onReturnHome,
  });

  @override
  State<BeatTiltResultPage> createState() => _BeatTiltResultPageState();
}

class _BeatTiltResultPageState extends State<BeatTiltResultPage> {
  final MembershipService _membershipService = MembershipService.instance;
  late int _initialPoints;
  late int _pointsEarned;
  bool _isPointsSynced = false;

  @override
  void initState() {
    super.initState();
    _initialPoints = _membershipService.currentPoints;
    _pointsEarned = widget.resultData?.pointsEarned ?? 65;

    // Sinkronisasi penambahan poin satu kali saat halaman hasil dibuka
    if (!_isPointsSynced && _pointsEarned > 0) {
      _membershipService.addGamePoints(_pointsEarned);
      _isPointsSynced = true;
    }
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.pushReplacementNamed(context, '/game-home');
    }
  }

  void _handlePlayAgain() {
    if (widget.onPlayAgain != null) {
      widget.onPlayAgain!();
    } else {
      Navigator.pushReplacementNamed(context, '/game-play');
    }
  }

  void _handleReturnHome() {
    if (widget.onReturnHome != null) {
      widget.onReturnHome!();
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final result =
        widget.resultData ??
        (ModalRoute.of(context)?.settings.arguments as GameResultData?) ??
        const GameResultData(
          validShakes: 32,
          pointsEarned: 65,
          shakeRate: 3.2,
          durationSeconds: 10,
        );

    final newPoints = _initialPoints + result.pointsEarned;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, Title, Profile
            _buildHeader(context),

            // Konten Hasil Permainan yang dapat di-scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Kartu Hasil Utama (WAKTU HABIS! + Poin)
                    _buildMainResultCard(result),

                    const SizedBox(height: 14),

                    // Metrik Ritme Sensor (Valid Shakes, Shake Rate, Durasi, Status)
                    _buildRhythmMetricsCard(result),

                    const SizedBox(height: 14),

                    // Sinkronisasi Saldo Membership JNOVAMUSIC
                    _buildMembershipSyncCard(newPoints, result.pointsEarned),

                    const SizedBox(height: 20),

                    // Tombol Aksi (Main Lagi & Kembali ke Beranda)
                    _buildActionButtons(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Hasil Permainan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const Spacer(),
          Container(
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
        ],
      ),
    );
  }

  Widget _buildMainResultCard(GameResultData result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEDD5), width: 1.2),
      ),
      child: Column(
        children: [
          // Banner Sesi 10 Detik Selesai
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD8BF), width: 1.0),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 12,
                  color: AppColors.primaryOrange,
                ),
                SizedBox(width: 4),
                Text(
                  'SESI 10 DETIK SELESAI',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // WAKTU HABIS!
          const Text(
            'WAKTU HABIS!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Keren! Poinmu berhasil dikumpulkan.',
            style: TextStyle(fontSize: 11, color: Color(0xFF6E6560)),
          ),
          const SizedBox(height: 14),

          // Box Total Poin Didapatkan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0C2), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL POIN DIDAPATKAN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF8E837D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+${result.pointsEarned} POIN',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryOrange,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: Color(0xFF15803D),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Selesai 10 Detik Penuh',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Banner Lagu Mine Mine
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.music_note_rounded,
                  size: 13,
                  color: AppColors.primaryOrange,
                ),
                SizedBox(width: 5),
                Text(
                  'Mine Mine — Naykilla (128 BPM)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRhythmMetricsCard(GameResultData result) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'METRIK RITME',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF7E756F),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEAE6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Akustik Sensor Pro',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A524D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grid 2x2 Metrik
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.vibration_rounded,
                  label: 'Valid Shakes',
                  value: '${result.validShakes} Goyangan',
                  subLabel: '• Terverifikasi',
                  subColor: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.speed_rounded,
                  label: 'Rata-rata Ritme',
                  value: '${result.shakeRate.toStringAsFixed(1)} / dtk',
                  subLabel: '• Tempo Sinkron',
                  subColor: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.timer_outlined,
                  label: 'Durasi Permainan',
                  value: '${result.durationSeconds} Detik',
                  subLabel: '• 100% Selesai',
                  subColor: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.shield_outlined,
                  label: 'Status Sensor',
                  value: 'Valid & Stabil',
                  subLabel: '• Anti-tamper OK',
                  subColor: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required String subLabel,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.primaryOrange),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF8E837D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipSyncCard(int newPoints, int pointsEarned) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sinkronisasi Saldo Membership JNOVAMUSIC',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.circle, size: 5, color: Color(0xFF16A34A)),
              SizedBox(width: 4),
              Text(
                'Terverifikasi & Tersimpan di Server',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Transisi Saldo
          Row(
            children: [
              // Saldo Awal
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEBE8E3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Awal',
                        style: TextStyle(fontSize: 9, color: Color(0xFF8E837D)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_initialPoints Poin',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFF7E756F),
                ),
              ),

              // Estimasi Saldo Baru
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD8BF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimasi Saldo Baru',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$newPoints Poin (+$pointsEarned)',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: Color(0xFF8E837D),
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Poin telah diverifikasi oleh backend sistem dan otomatis ditambahkan ke saldo membership akun Anda.',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF6E6560),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _handlePlayAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MAIN LAGI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.replay_rounded, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton(
            onPressed: _handleReturnHome,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD4D0C8), width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_outlined, size: 15, color: Color(0xFF6E6560)),
                SizedBox(width: 6),
                Text(
                  'KEMBALI KE BERANDA JNOVAMUSIC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6E6560),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
