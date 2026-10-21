import 'package:flutter_test/flutter_test.dart';
import 'package:jnova/core/config/app_config.dart';
import 'package:jnova/core/network/network_info.dart';
import 'package:jnova/models/product.dart';
import 'package:jnova/services/gemini_service.dart';

void main() {
  setUp(() async {
    NetworkInfo.instance.overrideIsConnected = true;
    await AppConfig.clearCustomGeminiApiKey();
    await AppConfig.clearCustomGeminiModel();
    GeminiService.instance.reconfigure();
  });

  tearDown(() async {
    NetworkInfo.instance.overrideIsConnected = null;
    await AppConfig.clearCustomGeminiApiKey();
    await AppConfig.clearCustomGeminiModel();
    GeminiService.instance.reconfigure();
  });

  group('GeminiService Validation & Error Handling Tests', () {
    test('Empty message validation returns clean error without network call', () async {
      final res = await GeminiService.instance.sendMessage('   ');
      expect(res.isSuccess, isFalse);
      expect(res.text, 'Pesan tidak boleh kosong.');
    });

    test('Offline network condition returns offline error', () async {
      NetworkInfo.instance.overrideIsConnected = false;
      final res = await GeminiService.instance.sendMessage('Rekomendasikan gitar pemula');
      expect(res.isSuccess, isFalse);
      expect(res.errorCode, 'offline');
      expect(res.text, contains('Koneksi internet tidak tersedia'));
    });

    test('Unconfigured API Key returns unconfigured_key error with helpful instructions', () async {
      // By default without setting an active key, AppConfig.isGeminiConfigured is false
      expect(AppConfig.isGeminiConfigured, isFalse);

      final res = await GeminiService.instance.sendMessage('Carikan rekomendasi bass harga Rp1.000.000');
      expect(res.isSuccess, isFalse);
      expect(res.errorCode, 'unconfigured_key');
      expect(res.text, contains('Google Gemini API belum dikonfigurasi'));
    });

    test('testConnection returns validation error for empty or short API key', () async {
      final result1 = await GeminiService.instance.testConnection(apiKey: '');
      expect(result1.success, isFalse);
      expect(result1.message, contains('minimal 10 karakter'));

      final result2 = await GeminiService.instance.testConnection(apiKey: 'short');
      expect(result2.success, isFalse);
      expect(result2.message, contains('minimal 10 karakter'));
    });

    test('AppConfig placeholder validation correctly rejects placeholders', () {
      expect(AppConfig.isGeminiConfigured, isFalse);
    });

    test('Product Catalog mapping contains required instruments', () {
      final bass = Product.allCatalog.where((p) => p.category.toLowerCase() == 'bass').toList();
      expect(bass, isNotEmpty);
      expect(bass.first.id, 'p5');
      expect(bass.first.brand, 'IBANEZ');
      expect(bass.first.price, 5650000);

      final guitars = Product.allCatalog.where((p) => p.category.toLowerCase() == 'gitar').toList();
      expect(guitars, isNotEmpty);
      expect(guitars.any((p) => p.id == 'p6'), isTrue); // Yamaha FG800
    });
  });
}
