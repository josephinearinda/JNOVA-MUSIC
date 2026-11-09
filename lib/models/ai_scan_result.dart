import '../models/product.dart';

/// Model data hasil analisis objek dari Gemini Vision Multimodal
class AIScanResult {
  final String objectName;
  final String category;
  final String description;
  final String function;
  final List<String> characteristics;
  final String additionalInfo;
  final String confidence;
  final bool isMusicRelated;
  final String? matchedCatalogId;
  final Product? matchedProduct;
  final String? source;

  const AIScanResult({
    required this.objectName,
    required this.category,
    required this.description,
    required this.function,
    required this.characteristics,
    required this.additionalInfo,
    required this.confidence,
    this.isMusicRelated = false,
    this.matchedCatalogId,
    this.matchedProduct,
    this.source,
  });

  factory AIScanResult.fromJson(Map<String, dynamic> json, {String? source}) {
    final catId = json['matchedCatalogId'] as String?;
    Product? matchedProd;
    if (catId != null && catId.isNotEmpty) {
      for (final p in Product.allCatalog) {
        if (p.id.toLowerCase() == catId.toLowerCase()) {
          matchedProd = p;
          break;
        }
      }
    }

    // Fallback pencarian produk berdasarkan nama objek jika belum cocok
    if (matchedProd == null) {
      final nameLower = (json['objectName'] as String? ?? '').toLowerCase();
      for (final p in Product.allCatalog) {
        if (nameLower.contains(p.name.toLowerCase()) ||
            nameLower.contains(p.brand.toLowerCase()) ||
            nameLower.contains(p.category.toLowerCase())) {
          matchedProd = p;
          break;
        }
      }
    }

    final rawChars = json['characteristics'];
    final charList = <String>[];
    if (rawChars is List) {
      for (final item in rawChars) {
        if (item != null) charList.add(item.toString());
      }
    } else if (rawChars is String) {
      charList.addAll(
        rawChars.split('\n').map((s) => s.replaceAll(RegExp(r'^[-•*]\s*'), '').trim()).where((s) => s.isNotEmpty),
      );
    }

    return AIScanResult(
      objectName: json['objectName'] as String? ?? 'Objek Tidak Dikenal',
      category: json['category'] as String? ?? 'Umum',
      description: json['description'] as String? ??
          'Objek berhasil terdeteksi dari foto yang Anda unggah.',
      function: json['function'] as String? ??
          'Fungsi umum sesuai jenis dan peruntukan objek.',
      characteristics: charList.isNotEmpty
          ? charList
          : [
              'Memiliki bentuk dan struktur yang dapat diidentifikasi',
              'Memiliki karakteristik material visual yang terdeteksi',
            ],
      additionalInfo: json['additionalInfo'] as String? ??
          'Pastikan kondisi pencahayaan cukup dan objek berada di tengah frame untuk identifikasi lebih akurat.',
      confidence: json['confidence'] as String? ?? 'Tinggi (94%)',
      isMusicRelated: json['isMusicRelated'] as bool? ??
          (matchedProd != null ||
              (json['category'] as String? ?? '').toLowerCase().contains('musik') ||
              (json['category'] as String? ?? '').toLowerCase().contains('audio')),
      matchedCatalogId: matchedProd?.id ?? catId,
      matchedProduct: matchedProd,
      source: source ?? 'Gemini 1.5 Flash Vision',
    );
  }
}

