import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/game_sensor_service.dart';
import '../../services/beat_tilt_audio_service.dart';
import 'beat_tilt_result_page.dart';

/// Halaman ketiga: gameplay goyang HP selama 10 detik.
class BeatTiltGameplayPage extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<GameResultData>? onGameFinished;

  const BeatTiltGameplayPage({super.key, this.onBack, this.onGameFinished});

  @override
  State<BeatTiltGameplayPage> createState() => _BeatTiltGameplayPageState();
}

class _BeatTiltGameplayPageState extends State<BeatTiltGameplayPage> {
  final GameSensorService _sensorService = GameSensorService.instance;
  final BeatTiltAudioService _audioService = BeatTiltAudioService.instance;

  int _secondsRemaining = 10;
  Timer? _gameTimer;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _sensorService.addListener(_handleSensorUpdate);
    _audioService.addListener(_handleSensorUpdate);
    _startCountdownTimer();
    _sensorService.startListening();
    unawaited(_audioService.play());
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _sensorService.removeListener(_handleSensorUpdate);
    _audioService.removeListener(_handleSensorUpdate);
    _sensorService.stopListening();
    if (!_isGameOver) unawaited(_audioService.stop());
    super.dispose();
  }

  void _handleSensorUpdate() {
    if (mounted) setState(() {});
  }

  void _startCountdownTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    if (_isGameOver) return;
    _isGameOver = true;

    _gameTimer?.cancel();
    _sensorService.stopListening();
    unawaited(_audioService.stop());

    final validShakes = _sensorService.validShakes;
    // Berikan poin sesuai performa goyangan (minimal 25 poin, default 65 jika aktif bergoyang)
    final pointsEarned = _sensorService.currentPoints;
    final shakeRate = validShakes / 10.0;

    final result = GameResultData(
      validShakes: validShakes,
      pointsEarned: pointsEarned,
      shakeRate: shakeRate,
      durationSeconds: 10,
    );

    if (widget.onGameFinished != null) {
      widget.onGameFinished!(result);
    } else {
      Navigator.pushReplacementNamed(
        context,
        '/game-result',
        arguments: result,
      );
    }
  }

  void _handlePause() {
    _gameTimer?.cancel();
    _sensorService.pauseListening();
    unawaited(_audioService.pause());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.pause_circle_rounded,
                color: AppColors.primaryOrange,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Permainan Dijeda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          content: Text(
            'Sisa waktu: $_secondsRemaining detik.\nSkor sementara: +${_sensorService.currentPoints} poin.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E6560),
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _sensorService.stopListening();
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.pushReplacementNamed(context, '/game-home');
                }
              },
              child: const Text(
                'Akhiri Permainan',
                style: TextStyle(
                  color: Color(0xFF8E837D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _sensorService.resumeListening();
                unawaited(_audioService.play());
                _startCountdownTimer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Lanjutkan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerProgress = _secondsRemaining / 10.0;
    final points = _sensorService.currentPoints;
    final streak = _sensorService.streak;
    final validShakes = _sensorService.validShakes;
    final intensity = _sensorService.intensity;
    final magnitude = _sensorService.currentMagnitude;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Pause, Song info, Mute toggle
            _buildGameplayHeader(),

            // Konten Gameplay Utama
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    if (_audioService.errorMessage != null)
                      Text(
                        'Musik gagal diputar: ${_audioService.errorMessage}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                        ),
                      ),

                    // Bar Dua Kartu: Timer & Poin Real-time
                    Row(
                      children: [
                        // Kartu Timer Sisa Waktu
                        Expanded(child: _buildTimerCard(timerProgress)),

                        const SizedBox(width: 12),

                        // Kartu Poin Real-Time
                        Expanded(child: _buildPointsCard(points, streak)),
                      ],
                    ),

                    const Spacer(flex: 1),

                    // Ilustrasi Ponsel Goyang & Prompt Aksi
                    _buildShakingPhonePrompt(intensity),

                    const Spacer(flex: 2),

                    // Indikator Gerakan Terdeteksi & Intensity Bar
                    _buildMotionDetectorCard(validShakes, intensity, magnitude),

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

  Widget _buildGameplayHeader() {
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
          // Tombol Pause
          InkWell(
            onTap: _handlePause,
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
                Icons.pause_rounded,
                size: 18,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),

          // Judul Lagu & Status Sensor
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      size: 13,
                      color: AppColors.primaryOrange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Mine Mine — Naykilla',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, size: 5, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'ACCELEROMETER AKTIF (60Hz)',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: Color(0xFF7E756F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tombol Speaker Mute / Unmute
          InkWell(
            onTap: () => unawaited(_audioService.toggleMute()),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
              ),
              child: Icon(
                _audioService.isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                size: 18,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(double progress) {
    final formattedSec = _secondsRemaining < 10
        ? '0${_secondsRemaining}s'
        : '${_secondsRemaining}s';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        children: [
          // Lingkaran Progress Timer
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4.5,
                  backgroundColor: const Color(0xFFFFEDDF),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryOrange,
                  ),
                ),
                Text(
                  formattedSec,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SISA WAKTU',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF8E837D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(int points, int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.flash_on_rounded,
            size: 18,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(height: 2),
          const Text(
            'POIN REAL-TIME',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Color(0xFF8E837D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+$points',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryOrange,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '• Streak ${streak}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShakingPhonePrompt(double intensity) {
    return Column(
      children: [
        // Ponsel dengan Efek Goyangan & Teks RUSH!
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '(((',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryOrange,
                letterSpacing: -3,
              ),
            ),
            const SizedBox(width: 14),

            // Tap gesture untuk simulasi goyangan jika diuji di emulator / desktop
            GestureDetector(
              onTap: () {
                _sensorService.simulateShake();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 68,
                height: 114,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: intensity > 0.4
                        ? AppColors.primaryOrange
                        : const Color(0xFFD4D0C8),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(
                        alpha: 0.15 + (intensity * 0.2),
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'RUSH!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryOrange,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 4),
                    Icon(
                      Icons.vibration_rounded,
                      size: 16,
                      color: Color(0xFF7E756F),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 14),
            const Text(
              ')))',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryOrange,
                letterSpacing: -3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          'Goyangkan HP secepat mungkin!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ayunkan ponsel dengan bertenaga dan stabil seirama musik!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Color(0xFF6E6560)),
        ),
      ],
    );
  }

  Widget _buildMotionDetectorCard(
    int validShakes,
    double intensity,
    double magnitude,
  ) {
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
              const Row(
                children: [
                  Icon(Icons.circle, size: 7, color: AppColors.primaryOrange),
                  SizedBox(width: 5),
                  Text(
                    'GERAKAN TERDETEKSI',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Color(0xFF7E756F),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEAE6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$validShakes Goyangan Valid',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A524D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bar Visual Intensitas Sensor (Segmented 10 Blocks)
          Row(
            children: List.generate(10, (index) {
              final thresholdIndex = (index + 1) / 10.0;
              final isActive = intensity >= thresholdIndex;

              return Expanded(
                child: Container(
                  height: 10,
                  margin: EdgeInsets.only(right: index < 9 ? 4.0 : 0.0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryOrange
                        : const Color(0xFFEBE8E3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.circle, size: 5, color: Color(0xFF16A34A)),
                  SizedBox(width: 4),
                  Text(
                    'Goyangan Optimal',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6E6560),
                    ),
                  ),
                ],
              ),
              Text(
                'Threshold: ${magnitude > 0 ? magnitude.toStringAsFixed(1) : '14.8'} m/s²',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E837D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
