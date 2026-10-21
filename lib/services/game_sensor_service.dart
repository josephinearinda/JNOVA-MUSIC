import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Service pendeteksi goyangan fisik menggunakan sensor Accelerometer ponsel
class GameSensorService extends ChangeNotifier {
  GameSensorService._();

  static final GameSensorService instance = GameSensorService._();

  StreamSubscription<UserAccelerometerEvent>? _subscription;

  bool _isListening = false;
  bool _isPaused = false;
  bool _isSensorAvailable = true;

  int _validShakes = 0;
  int _currentPoints = 0;
  int _streak = 1;
  double _currentMagnitude = 0.0;
  double _intensity = 0.0;

  // Ambang batas percepatan goyangan valid (m/s^2)
  static const double _shakeThreshold = 12.5;
  // Jeda minimum antar goyangan (ms) untuk mencegah penghitungan ganda
  static const int _debounceMs = 170;
  DateTime _lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isListening => _isListening;
  bool get isPaused => _isPaused;
  bool get isSensorAvailable => _isSensorAvailable;
  int get validShakes => _validShakes;
  int get currentPoints => _currentPoints;
  int get streak => _streak;
  double get currentMagnitude => _currentMagnitude;
  double get intensity => _intensity;

  /// Memeriksa ketersediaan sensor gerak
  Future<bool> checkSensorAvailability() async {
    try {
      // Dengarkan satu event pertama untuk memastikan sensor aktif
      final completer = Completer<bool>();
      late StreamSubscription sub;
      Timer? timer;

      timer = Timer(const Duration(milliseconds: 600), () {
        if (!completer.isCompleted) {
          sub.cancel();
          _isSensorAvailable = true; // Anggap tersedia di mobile device
          completer.complete(true);
        }
      });

      sub = userAccelerometerEventStream().listen(
        (event) {
          if (!completer.isCompleted) {
            timer?.cancel();
            sub.cancel();
            _isSensorAvailable = true;
            completer.complete(true);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            timer?.cancel();
            sub.cancel();
            _isSensorAvailable = false;
            completer.complete(false);
          }
        },
      );

      return await completer.future;
    } catch (_) {
      _isSensorAvailable = true; // Fallback toleran
      return true;
    }
  }

  /// Memulai pendengaran sensor gerak real-time
  void startListening() {
    reset();
    _isListening = true;
    _isPaused = false;

    _subscription?.cancel();
    try {
      _subscription = userAccelerometerEventStream().listen(
        _handleAccelerometerEvent,
        onError: (error) {
          debugPrint('Error sensor gerak: $error');
          _isSensorAvailable = false;
          notifyListeners();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Gagal membuka stream sensor: $e');
    }

    notifyListeners();
  }

  /// Memproses event akselerometer
  void _handleAccelerometerEvent(UserAccelerometerEvent event) {
    if (!_isListening || _isPaused) return;

    // Hitung magnitudo akselerasi bersih: sqrt(x^2 + y^2 + z^2)
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    _currentMagnitude = magnitude;

    // Hitung intensitas visual (0.0 sampai 1.0)
    _intensity = (magnitude / 24.0).clamp(0.0, 1.0);

    final now = DateTime.now();
    final timeSinceLastShake = now.difference(_lastShakeTime).inMilliseconds;

    // Cek apakah magnitudo melebihi ambang batas dan sudah melewati jeda debounce
    if (magnitude >= _shakeThreshold && timeSinceLastShake >= _debounceMs) {
      _lastShakeTime = now;
      _validShakes++;

      // Streak multiplier: goyangan konsisten meningkatkan streak hingga 4x
      if (timeSinceLastShake <= 450) {
        _streak = min(_streak + 1, 4);
      } else {
        _streak = 1;
      }

      // Setiap goyangan valid memberikan poin ritme (rata-rata 2 poin per goyangan)
      _currentPoints += (2 * (_streak >= 3 ? 2 : 1));

      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  /// Simulasi goyangan manual untuk keperluan testing / emulator
  void simulateShake() {
    if (!_isListening || _isPaused) return;

    _currentMagnitude = 16.5;
    _intensity = 0.85;
    _validShakes++;
    _streak = min(_streak + 1, 4);
    _currentPoints += 2;
    notifyListeners();
  }

  /// Menjeda pembacaan sensor
  void pauseListening() {
    _isPaused = true;
    _intensity = 0.0;
    notifyListeners();
  }

  /// Melanjutkan pembacaan sensor
  void resumeListening() {
    _isPaused = false;
    _lastShakeTime = DateTime.now();
    notifyListeners();
  }

  /// Menghentikan pembacaan sensor dan menutup stream
  void stopListening() {
    _isListening = false;
    _isPaused = false;
    _intensity = 0.0;
    _subscription?.cancel();
    _subscription = null;
    notifyListeners();
  }

  /// Reset metrik gameplay
  void reset() {
    _validShakes = 0;
    _currentPoints = 0;
    _streak = 1;
    _currentMagnitude = 0.0;
    _intensity = 0.0;
    _lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
