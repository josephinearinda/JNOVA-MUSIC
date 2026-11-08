import 'package:flutter/foundation.dart';

import '../core/storage/secure_storage_service.dart';
import '../data/datasources/local/app_database.dart';
import '../models/ai_chat_message.dart';
import '../models/product.dart';
import 'gemini_service.dart';
import 'user_profile_service.dart';

/// Layanan manajemen riwayat obrolan Jnova AI dengan persistensi SQLite lokal per pengguna
class AIChatService extends ChangeNotifier {
  AIChatService._();
  static final AIChatService instance = AIChatService._();

  List<AIChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentUserEmail;

  List<AIChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  Product get _defaultRecommendedProduct {
    return Product.allCatalog.firstWhere(
      (p) => p.id == 'p6',
      orElse: () => Product.allCatalog.first,
    );
  }

  List<AIChatMessage> _createDefaultMessages() {
    return [
      const AIChatMessage(
        id: 'm1',
        isUser: false,
        text:
            'Halo! Ada yang bisa kubantu hari ini?\n\nAku siap membantumu menemukan alat musik yang sesuai dengan kebutuhan, gaya bermain, dan budget-mu.',
        time: '14:20',
      ),
      const AIChatMessage(
        id: 'm2',
        isUser: true,
        text: 'Aku mau cari gitar untuk pemula dengan budget Rp2.000.000.',
        time: '14:21',
      ),
      AIChatMessage(
        id: 'm3',
        isUser: false,
        text:
            'Tentu! Untuk pemula dengan budget Rp2.000.000, kita bisa mencari gitar yang nyaman dimainkan dan sesuai dengan preferensi suaramu.\n\nKamu lebih tertarik dengan gitar akustik atau gitar elektrik?',
        time: '14:21',
        chips: const ['Gitar Akustik', 'Gitar Elektrik'],
        selectedChip: 'Gitar Akustik',
        recommendedProduct: _defaultRecommendedProduct,
        customProductName: 'Yamaha F310 Natural',
        customProductPrice: 'Rp1.850.000',
        productBadge: 'REKOMENDASI TERBAIK PEMULA',
        productOriginalPrice: 'Rp2.000.000',
        productPoints: '+93 Poin Member',
        productDescription:
            'Action senar rendah bersahabat untuk pemula, kayu spruce terpilih, dan intonasi presisi standar studio Yamaha.',
      ),
    ];
  }

  Future<String> _resolveUserEmail() async {
    final profileEmail = UserProfileService.instance.profile.email.trim();
    if (profileEmail.isNotEmpty) return profileEmail.toLowerCase();
    final storedEmail = await SecureStorageService.instance.getUserEmail();
    if (storedEmail != null && storedEmail.trim().isNotEmpty) {
      return storedEmail.trim().toLowerCase();
    }
    return 'guest@jnovamusic.com';
  }

  /// Memuat riwayat chat pengguna aktif dari database lokal
  Future<List<AIChatMessage>> loadMessages({bool forceReload = false}) async {
    final activeEmail = await _resolveUserEmail();
    if (!forceReload &&
        _currentUserEmail == activeEmail &&
        _messages.isNotEmpty) {
      return _messages;
    }

    _isLoading = true;
    notifyListeners();

    _currentUserEmail = activeEmail;
    try {
      final rows = await AppDatabase.instance.getAiChatMessages(activeEmail);
      if (rows.isEmpty) {
        final initial = _createDefaultMessages();
        _messages = List.from(initial);
        final baseTimestamp = DateTime.now().millisecondsSinceEpoch - 10000;
        for (int i = 0; i < initial.length; i++) {
          final row = initial[i].toMap(
            userEmail: activeEmail,
            createdAt: baseTimestamp + (i * 1000),
          );
          await AppDatabase.instance.saveAiChatMessage(row);
        }
      } else {
        _messages = rows.map((r) => AIChatMessage.fromMap(r)).toList();
      }

      _syncGeminiHistory();
    } catch (e) {
      debugPrint('[AIChatService] Error memuat riwayat pesan: $e');
      if (_messages.isEmpty) {
        _messages = _createDefaultMessages();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _messages;
  }

  /// Menambahkan pesan baru ke memori dan database lokal secara permanen
  Future<void> addMessage(AIChatMessage message) async {
    _messages.add(message);
    notifyListeners();

    try {
      final activeEmail = await _resolveUserEmail();
      final row = message.toMap(userEmail: activeEmail);
      await AppDatabase.instance.saveAiChatMessage(row);
      _syncGeminiHistory();
    } catch (e) {
      debugPrint('[AIChatService] Error menyimpan pesan chat: $e');
    }
  }

  /// Memperbarui pesan yang ada di memori dan database
  Future<void> updateMessage(AIChatMessage updated) async {
    final idx = _messages.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      _messages[idx] = updated;
      notifyListeners();
      try {
        final activeEmail = await _resolveUserEmail();
        final row = updated.toMap(userEmail: activeEmail);
        await AppDatabase.instance.saveAiChatMessage(row);
      } catch (e) {
        debugPrint('[AIChatService] Error memperbarui pesan: $e');
      }
    }
  }

  /// Reset riwayat obrolan untuk pengguna saat ini
  Future<void> resetChat() async {
    final activeEmail = await _resolveUserEmail();
    await AppDatabase.instance.clearAiChatMessages(activeEmail);
    GeminiService.instance.resetChat();

    final initial = _createDefaultMessages();
    _messages = List.from(initial);
    final baseTimestamp = DateTime.now().millisecondsSinceEpoch - 10000;
    for (int i = 0; i < initial.length; i++) {
      final row = initial[i].toMap(
        userEmail: activeEmail,
        createdAt: baseTimestamp + (i * 1000),
      );
      await AppDatabase.instance.saveAiChatMessage(row);
    }
    _syncGeminiHistory();
    notifyListeners();
  }

  /// Bersihkan memori saat pengguna logout
  void clearMemory() {
    _messages.clear();
    _currentUserEmail = null;
    GeminiService.instance.resetChat();
  }

  void _syncGeminiHistory() {
    final recent = <Map<String, String>>[];
    for (final m in _messages) {
      if (m.text.trim().isNotEmpty) {
        recent.add({
          'role': m.isUser ? 'user' : 'model',
          'text': m.text.trim(),
        });
      }
    }
    GeminiService.instance.setHistory(recent);
  }
}

