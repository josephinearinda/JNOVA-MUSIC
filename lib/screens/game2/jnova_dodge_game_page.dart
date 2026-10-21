import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class JNovaDodgeGamePage extends StatefulWidget {
  const JNovaDodgeGamePage({super.key});

  @override
  State<JNovaDodgeGamePage> createState() => _JNovaDodgeGamePageState();
}

class _JNovaDodgeGamePageState extends State<JNovaDodgeGamePage> {
  static const _ballRadius = 20.0;
  static const _blockWidth = 60.0;
  static const _blockHeight = 20.0;

  final _random = Random();
  final _audioPlayer = AudioPlayer();
  final _gameAreaKey = GlobalKey();
  final List<_FallingBlock> _blocks = [];

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _spawnTimer;
  Timer? _gameLoopTimer;
  double _ballPositionX = 0.5;
  double _blockSpeed = 4.0;
  int _score = 0;
  int _lives = 3;
  bool _isPlaying = true;
  String? _statusError;

  @override
  void initState() {
    super.initState();
    _startAccelerometer();
    unawaited(_startMusic());
    _startGameEngine();
  }

  void _startAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (event) {
        if (!_isPlaying || !mounted) return;
        setState(() {
          _ballPositionX = (_ballPositionX - event.x * 0.02)
              .clamp(0.1, 0.9)
              .toDouble();
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'JNova Dodge sensor',
            context: ErrorDescription('while listening to the accelerometer'),
          ),
        );
        if (mounted) {
          setState(() {
            _statusError = 'Sensor gerak tidak tersedia: $error';
          });
        }
      },
    );
  }

  Future<void> _startMusic() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/lagu2.mp3'));
    } on Exception catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'JNova Dodge audio',
          context: ErrorDescription('while playing assets/audio/lagu2.mp3'),
        ),
      );
      if (mounted) {
        setState(() {
          _statusError = 'Musik gagal diputar: $error';
        });
      }
    }
  }

  void _startGameEngine() {
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!_isPlaying || !mounted) return;
      setState(() {
        _blocks.add(_FallingBlock(posX: _random.nextDouble() * 0.8 + 0.1));
        if (_score > 0 && _score % 5 == 0) {
          _blockSpeed = 4.0 + (_score / 5) * 0.5;
        }
      });
    });

    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_isPlaying || !mounted) return;
      _advanceGame();
    });
  }

  void _advanceGame() {
    final area = _gameAreaKey.currentContext?.size;
    if (area == null) return;

    final areaWidth = area.width;
    final areaHeight = area.height;
    final ballCenterX = _ballPositionX * areaWidth;
    final ballCenterY = areaHeight - 54;
    var escapedBlocks = 0;
    var hitCount = 0;

    for (final block in _blocks) {
      block.posY += _blockSpeed;

      final blockCenterX = block.posX * areaWidth;
      final overlapsX =
          (blockCenterX - ballCenterX).abs() <= _blockWidth / 2 + _ballRadius;
      final overlapsY =
          block.posY + _blockHeight >= ballCenterY - _ballRadius &&
          block.posY <= ballCenterY + _ballRadius;

      if (overlapsX && overlapsY) {
        hitCount++;
      } else if (block.posY > areaHeight) {
        escapedBlocks++;
      }
    }

    setState(() {
      _blocks.removeWhere(
        (block) =>
            block.posY > areaHeight ||
            ((block.posX * areaWidth - ballCenterX).abs() <=
                    _blockWidth / 2 + _ballRadius &&
                block.posY + _blockHeight >= ballCenterY - _ballRadius &&
                block.posY <= ballCenterY + _ballRadius),
      );
      _score += escapedBlocks;
      _lives -= hitCount;
      if (_lives < 0) _lives = 0;
    });

    for (var index = 0; index < escapedBlocks; index++) {
      unawaited(HapticFeedback.lightImpact());
    }
    if (hitCount > 0) unawaited(HapticFeedback.vibrate());
    if (_lives == 0) _endGame();
  }

  void _endGame() {
    if (!_isPlaying) return;
    setState(() {
      _isPlaying = false;
    });
    _spawnTimer?.cancel();
    _gameLoopTimer?.cancel();
    unawaited(_audioPlayer.stop());
  }

  void _restartGame() {
    setState(() {
      _ballPositionX = 0.5;
      _blockSpeed = 4.0;
      _score = 0;
      _lives = 3;
      _isPlaying = true;
      _blocks.clear();
      _statusError = null;
    });
    _startGameEngine();
    unawaited(_startMusic());
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _gameLoopTimer?.cancel();
    unawaited(_accelerometerSubscription?.cancel());
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF16213E), Color(0xFF1A1A2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Kembali ke pilihan game',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'JNova Dodge',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SKOR: $_score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        3,
                        (index) => Icon(
                          Icons.favorite,
                          color: index < _lives
                              ? Colors.redAccent
                              : Colors.white30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_statusError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    _statusError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                    ),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final areaWidth = constraints.maxWidth;
                    final areaHeight = constraints.maxHeight;
                    return Stack(
                      key: _gameAreaKey,
                      clipBehavior: Clip.hardEdge,
                      children: [
                        for (final block in _blocks)
                          Positioned(
                            left: block.posX * areaWidth - _blockWidth / 2,
                            top: block.posY,
                            child: Container(
                              width: _blockWidth,
                              height: _blockHeight,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          left: _ballPositionX * areaWidth - _ballRadius,
                          top: areaHeight - 54 - _ballRadius,
                          child: Container(
                            width: _ballRadius * 2,
                            height: _ballRadius * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.cyanAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyan.withValues(alpha: 0.8),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!_isPlaying)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black87,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'GAME OVER',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Skor Akhir: $_score',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    ElevatedButton(
                                      onPressed: _restartGame,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.cyanAccent,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 36,
                                          vertical: 14,
                                        ),
                                      ),
                                      child: const Text(
                                        'MAIN LAGI',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text(
                  'Miringkan HP ke kiri dan kanan untuk menghindar',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallingBlock {
  final double posX;
  double posY = -20;

  _FallingBlock({required this.posX});
}
