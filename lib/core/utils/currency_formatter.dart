import '../../services/currency_service.dart';

/// Fungsi helper untuk memformat angka nominal harga produk
/// Menyesuaikan secara otomatis dengan preferensi mata uang yang aktif (IDR, USD, EUR)
/// Contoh:
/// - IDR: "Rp 14.850.000"
/// - USD: "$891.00"
/// - EUR: "€828.00"
String formatCurrency(num value) {
  return CurrencyService.instance.format(value);
}

/// Helper format harga yang otomatis mengikuti preferensi mata uang aktif (IDR, USD, EUR)
String formatRupiah(num value) {
  return CurrencyService.instance.format(value);
}

/// Helper format Rupiah statis tanpa konversi kurs (untuk checkout / rekening lokal IDR)
String formatRupiahExact(num value) {
  return CurrencyService.formatPrice(value, 'IDR');
}
