import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Layanan audio pendukung mini-game JNova Beat Tilt
class BeatTiltAudioService extends ChangeNotifier {
  BeatTiltAudioService._();

  static final BeatTiltAudioService instance = BeatTiltAudioService._();

  bool _isPlaying = false;
  bool _isMuted = false;
  String? _errorMessage;
  final AudioPlayer _player = AudioPlayer();

  final String songTitle = 'Mine Mine';
  final String artistName = 'Naykilla';
  final int bpm = 128;
  final String genre = 'Pop Elektronik';

  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;
  String? get errorMessage => _errorMessage;

  Future<void> togglePlay() {
    return _runAudioCommand(() async {
      if (_isPlaying) {
        await _player.pause();
        _isPlaying = false;
      } else {
        await _playAsset();
      }
    });
  }

  Future<void> play() {
    return _runAudioCommand(_playAsset);
  }

  Future<void> _playAsset() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_isMuted ? 0 : 1);
    if (_player.state == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.play(AssetSource('audio/lagu.mp3'));
    }
    _isPlaying = true;
  }

  Future<void> pause() {
    return _runAudioCommand(() async {
      await _player.pause();
      _isPlaying = false;
    });
  }

  Future<void> stop() {
    return _runAudioCommand(() async {
      await _player.stop();
      _isPlaying = false;
    });
  }

  Future<void> toggleMute() {
    return _runAudioCommand(() async {
      final shouldMute = !_isMuted;
      await _player.setVolume(shouldMute ? 0 : 1);
      _isMuted = shouldMute;
    });
  }

  Future<void> _runAudioCommand(Future<void> Function() command) async {
    try {
      await command();
      _errorMessage = null;
    } on Exception catch (error, stackTrace) {
      _errorMessage = error.toString();
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'game audio',
          context: ErrorDescription('while controlling the game music'),
        ),
      );
    }
    notifyListeners();
  }
}
