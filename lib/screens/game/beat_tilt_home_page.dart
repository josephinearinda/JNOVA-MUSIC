import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/membership_service.dart';
import '../../services/beat_tilt_audio_service.dart';

/// Halaman kedua: beranda game JNova Beat Tilt.
class BeatTiltHomePage extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onStartGame;

  const BeatTiltHomePage({super.key, this.onBack, this.onStartGame});

  @override
  State<BeatTiltHomePage> createState() => _BeatTiltHomePageState();
}

class _BeatTiltHomePageState extends State<BeatTiltHomePage> {
  final MembershipService _membershipService = MembershipService.instance;
  final BeatTiltAudioService _audioService = BeatTiltAudioService.instance;

  @override
  void initState() {
    super.initState();
    _membershipService.addListener(_handleStateChanged);
    _audioService.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    _membershipService.removeListener(_handleStateChanged);
    _audioService.removeListener(_handleStateChanged);
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/all-products');
    }
  }

  void _handleStartGame() {
    if (widget.onStartGame != null) {
      widget.onStartGame!();
    } else {
      Navigator.pushNamed(context, '/game-play');
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Bar Saldo Poin & Link Kembali
                    _buildSubHeader(),

                    const SizedBox(height: 14),

                    // Judul Mini Game
                    _buildGameTitleSection(),

                    const SizedBox(height: 14),

                    // Ilustrasi Goyang HP & Status Sensor
                    _buildPhoneAnimationCard(),

                    const SizedBox(height: 14),

                    // Lagu Tantangan Hari Ini ("Mine Mine - Naykilla")
                    _buildSongCard(),

                    const SizedBox(height: 14),

                    // Petunjuk Cara Bermain Singkat
                    _buildHowToPlayCard(),

                    const SizedBox(height: 18),

                    // Tombol Mulai Goyang ⚡
                    _buildStartButton(),

                    const SizedBox(height: 10),

                    // Link Pelajari Aturan
                    Center(
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Aturan kompetisi ritme & sistem poin adil.',
                              ),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Text(
                          'Pelajari Aturan & Keamanan Sensor >',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7E756F),
                          ),
                        ),
                      ),
                    ),

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
            'JNova Beat Tilt',
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

  Widget _buildSubHeader() {
    final points = _membershipService.currentPoints;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: _handleBack,
          child: const Row(
            children: [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 11,
                color: Color(0xFF6E6560),
              ),
              SizedBox(width: 4),
              Text(
                'Kembali ke JNOVAMUSIC',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E6560),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD8BF), width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.flash_on_rounded,
                size: 12,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 3),
              Text(
                '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} Poin',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'MINI-GAME MEMBERSHIP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'JNova Beat Tilt',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '"Feel the Beat, Move with the Rhythm!"',
          style: TextStyle(
            fontSize: 11.5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB45309),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Goyangkan HP selama 10 detik dan kumpulkan poin membership sebanyak-banyaknya!',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF6E6560),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneAnimationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Garis gelombang goyang kiri
              const Text(
                '(((',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrange,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 14),

              // Ponsel Visual
              Container(
                width: 58,
                height: 98,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD4D0C8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Layar dengan Equalizer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildEqBar(10),
                        const SizedBox(width: 2.5),
                        _buildEqBar(20),
                        const SizedBox(width: 2.5),
                        _buildEqBar(28),
                        const SizedBox(width: 2.5),
                        _buildEqBar(18),
                        const SizedBox(width: 2.5),
                        _buildEqBar(8),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),
              // Garis gelombang goyang kanan
              const Text(
                ')))',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrange,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tiga titik animasi
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 4, color: AppColors.placeholder),
              SizedBox(width: 4),
              Icon(Icons.circle, size: 4, color: AppColors.primaryOrange),
              SizedBox(width: 4),
              Icon(Icons.circle, size: 4, color: AppColors.placeholder),
            ],
          ),
          const SizedBox(height: 8),

          // Status Sensor Siap Digunakan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 6, color: Color(0xFF15803D)),
                SizedBox(width: 5),
                Text(
                  'Sensor Siap Digunakan',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqBar(double height) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSongCard() {
    final isPlaying = _audioService.isPlaying;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LAGU TANTANGAN HARI INI',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF8E837D),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD4D0C8)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  '180G VINYL CUT',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7E756F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Vinyl Disc Artwork
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF221F1D),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD8BF), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Detail Lagu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _audioService.songTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      _audioService.artistName,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF6E6560),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEAE6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${_audioService.bpm} BPM',
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5A524D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${_audioService.genre}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF8E837D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tombol Play / Pause Preview
              IconButton(
                onPressed: () async {
                  await _audioService.togglePlay();
                  if (_audioService.errorMessage == null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _audioService.isPlaying
                              ? 'Memutar lagu Mine Mine — Naykilla.'
                              : 'Preview audio Mine Mine dijeda.',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 36,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          if (_audioService.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              'Musik gagal diputar: ${_audioService.errorMessage}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHowToPlayCard() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 14,
                color: AppColors.primaryOrange,
              ),
              SizedBox(width: 6),
              Text(
                'Cara Bermain Singkat',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPlayStep('1', 'Tekan tombol "MULAI GOYANG" di bawah.'),
          const SizedBox(height: 6),
          _buildPlayStep('2', 'Dengarkan ritme & ketukan lagu "Mine Mine".'),
          const SizedBox(height: 6),
          _buildPlayStep(
            '3',
            'Goyangkan HP secepat & sekonsisten mungkin selama 10 detik!',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBE7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 12, color: Color(0xFF5A524D)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Sensor accelerometer memvalidasi goyangan ritmis nyata dan menyaring getaran palsu untuk skor yang adil.',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF5A524D),
                      height: 1.25,
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

  Widget _buildPlayStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFECEAE6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5A524D),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF5A524D),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: _handleStartGame,
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
              'MULAI GOYANG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
