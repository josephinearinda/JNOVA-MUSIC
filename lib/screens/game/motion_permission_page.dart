import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/game_sensor_service.dart';

/// Halaman Pertama: Izin Sensor Gerak (MotionPermissionPage) sesuai Figma Game 9
class MotionPermissionPage extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onPermissionGranted;

  const MotionPermissionPage({
    super.key,
    this.onBack,
    this.onPermissionGranted,
  });

  @override
  State<MotionPermissionPage> createState() => _MotionPermissionPageState();
}

class _MotionPermissionPageState extends State<MotionPermissionPage> {
  bool _isChecking = false;

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _handleGrantAndStart() async {
    setState(() {
      _isChecking = true;
    });

    final isAvailable = await GameSensorService.instance.checkSensorAvailability();

    if (!mounted) return;
    setState(() {
      _isChecking = false;
    });

    if (widget.onPermissionGranted != null) {
      widget.onPermissionGranted!();
    } else {
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sensor accelerometer fisik tidak terdeteksi. Game berjalan dalam mode simulasi interaktif.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      Navigator.pushReplacementNamed(context, '/game-home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back, Title, Profile
            _buildHeader(context),

            // Konten yang dapat di-scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 14),

                    // Ilustrasi HP & Sensor Akselerometer
                    _buildPhoneIllustration(),

                    const SizedBox(height: 14),

                    // Judul & Deskripsi
                    const Text(
                      'Siap Mengumpulkan Poin?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Game ini membutuhkan akses sensor gerak (Accelerometer) pada ponsel Anda untuk menghitung setiap goyangan secara presisi selama 10 detik.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6E6560),
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tiga Kartu Informasi
                    _buildInfoCard(
                      icon: Icons.vibration_rounded,
                      title: 'Sensor Akselerometer HP',
                      desc:
                          'Mendeteksi frekuensi dan tempo goyangan tangan secara real-time.',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      icon: Icons.pan_tool_outlined,
                      title: 'Panduan Keamanan',
                      desc:
                          'Pegang ponsel dengan erat menggunakan kedua tangan agar tidak tergelincir saat digoyangkan.',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      icon: Icons.graphic_eq_rounded,
                      title: 'Validasi Studio Cerdas',
                      desc:
                          'Sistem memvalidasi goyangan ritmis dan mengabaikan getaran kecil.',
                    ),

                    const SizedBox(height: 12),

                    // Kartu Peringatan Sensor
                    _buildWarningCard(),

                    const SizedBox(height: 20),

                    // Tombol Aksi
                    _buildActionButtons(),

                    const SizedBox(height: 12),

                    // Footer Keamanan & Privasi
                    _buildPrivacyFooter(),

                    const SizedBox(height: 20),
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
            'Izin Sensor Gerak',
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

  Widget _buildPhoneIllustration() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Lingkaran oranye pudar di belakang
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF0E5),
              ),
            ),

            // Bodi Ponsel
            Container(
              width: 54,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4A403A), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Speaker earpiece
                  Container(
                    width: 14,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF555555),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Reticle / target ikon sensor
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryOrange, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.track_changes_rounded,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Badge Pill Akses Accelerometer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 6, color: AppColors.primaryOrange),
              SizedBox(width: 5),
              Text(
                'AKSES ACCELEROMETER DIPERLUKAN',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryOrange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5A524D),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFEDD5), width: 1.0),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFB45309)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Jika sensor gerak tidak terdeteksi atau tidak didukung pada browser/perangkat Anda, skor tidak akan terhitung palsu dan Anda dapat kembali ke katalog JNOVAMUSIC.',
              style: TextStyle(
                fontSize: 9.5,
                color: Color(0xFF78350F),
                height: 1.3,
              ),
            ),
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
            onPressed: _isChecking ? null : _handleGrantAndStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isChecking
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
                      Text(
                        'IZINKAN & MULAI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.check, size: 16, color: Colors.white),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _handleBack,
          child: const Text(
            'Kembali ke Beranda JNOVAMUSIC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6E6560),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF8E837D)),
        SizedBox(width: 4),
        Text(
          'Privasi Terjaga • Data sensor diproses lokal di perangkat.',
          style: TextStyle(
            fontSize: 9.5,
            color: Color(0xFF8E837D),
          ),
        ),
      ],
    );
  }
}
