import 'package:flutter/foundation.dart';
import '../core/storage/secure_storage_service.dart';

/// Layanan terpusat untuk preferensi mata uang dan konversi harga di JNOVAMUSIC
class CurrencyService extends ChangeNotifier {
  CurrencyService._() {
    _loadCurrency();
  }

  static final CurrencyService instance = CurrencyService._();
  final SecureStorageService _storage = SecureStorageService.instance;

  // Mata uang aktif: IDR, USD, EUR
  String _selectedCurrency = 'IDR';
  String get selectedCurrency => _selectedCurrency;

  // Kurs konversi dari base IDR (Rupiah)
  // Sesuai Figma 7: Rp 1.650.000 -> USD $99.00 -> EUR €92.00
  static const double idrPerUsd = 16666.6667;
  static const double idrPerEur = 17934.7826;

  Future<void> _loadCurrency() async {
    try {
      final saved = await _storage.getCurrency();
      if (saved != null && (saved == 'IDR' || saved == 'USD' || saved == 'EUR')) {
        _selectedCurrency = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Mengubah mata uang yang aktif di seluruh aplikasi
  Future<void> setCurrency(String currencyCode) async {
    if (_selectedCurrency == currencyCode) return;
    _selectedCurrency = currencyCode;
    notifyListeners();
    try {
      await _storage.saveCurrency(currencyCode);
    } catch (_) {}
  }

  /// Format nominal harga (dalam IDR dasar) ke mata uang yang dipilih saat ini
  String format(num idrAmount) {
    return formatPrice(idrAmount, _selectedCurrency);
  }

  /// Format nominal harga spesifik mata uang
  static String formatPrice(num idrAmount, String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        final usd = idrAmount / idrPerUsd;
        return _formatWithSymbol('\$', usd, decimals: 2, thousandsSeparator: ',', decimalSeparator: '.');
      case 'EUR':
        final eur = idrAmount / idrPerEur;
        return _formatWithSymbol('€', eur, decimals: 2, thousandsSeparator: '.', decimalSeparator: ',');
      case 'IDR':
      default:
        final int val = idrAmount.round();
        return _formatIdr(val);
    }
  }

  static String _formatIdr(int intValue) {
    final String str = intValue.abs().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    final String sign = intValue < 0 ? '-Rp ' : 'Rp ';
    return '$sign${buffer.toString()}';
  }

  static String _formatWithSymbol(
    String symbol,
    double amount, {
    required int decimals,
    required String thousandsSeparator,
    required String decimalSeparator,
  }) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final fixedStr = absAmount.toStringAsFixed(decimals);
    final parts = fixedStr.split('.');
    final wholePart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < wholePart.length; i++) {
      if (i > 0 && (wholePart.length - i) % 3 == 0) {
        buffer.write(thousandsSeparator);
      }
      buffer.write(wholePart[i]);
    }

    final String sign = isNegative ? '-' : '';
    return '$sign$symbol${buffer.toString()}$decimalSeparator$decPart';
  }
}
