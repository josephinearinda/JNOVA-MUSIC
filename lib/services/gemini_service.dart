import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/config/app_config.dart';
import '../core/network/network_info.dart';
import '../models/product.dart';

/// Hasil dari respon Gemini AI untuk obrolan JNOVAMUSIC
class GeminiResponse {
  final bool isSuccess;
  final String text;
  final Product? recommendedProduct;
  final String? badge;
  final String? pointsLabel;
  final String? errorMessage;

  const GeminiResponse({
    required this.isSuccess,
    required this.text,
    this.recommendedProduct,
    this.badge,
    this.pointsLabel,
    this.errorMessage,
  });
}

/// Service integrasi Google Gemini AI terpisah dari UI
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  GenerativeModel? _model;
  ChatSession? _chatSession;

  /// Membangun konteks produk katalog JNOVAMUSIC untuk diinjeksikan ke System Instruction
  String _buildSystemPrompt() {
    final buffer = StringBuffer();
    buffer.writeln(
      'Kamu adalah Jnova AI, asisten dan konsultan musik pribadi resmi di toko alat musik JNOVAMUSIC.',
    );
    buffer.writeln(
      'Tugasmu adalah merekomendasikan instrumen musik yang tepat berdasarkan kebutuhan, level keterampilan (pemula/menengah/profesional), genre musik, dan budget pengguna.',
    );
    buffer.writeln(
      'Gunakan gaya bahasa ramah, suportif, informatif, dan profesional seperti seorang konsultan musik berpengalaman.',
    );
    buffer.writeln('\nATURAN PENTING:');
    buffer.writeln(
      '1. Selalu utamakan merekomendasikan produk yang BENAR-BENAR TERSEDIA di katalog resmi JNOVAMUSIC berikut:',
    );

    for (final p in Product.allCatalog) {
      buffer.writeln(
        '- [ID: ${p.id}] ${p.brand} ${p.name} | Kategori: ${p.category} | Harga: Rp${p.price} | Fitur: ${p.variant}',
      );
    }

    buffer.writeln(
      '\n2. Jika kamu merekomendasikan satu produk tertentu, sebutkan nama produknya secara jelas dan cantumkan tag [REKOMENDASI: ID_PRODUK] di akhir jawabanmu agar antarmuka aplikasi dapat menampilkan kartu produk resmi secara otomatis.',
    );
    buffer.writeln(
      '3. Jangan meminta atau memproses data pribadi sensitif seperti kata sandi, nomor kartu kredit, atau PIN rekening.',
    );
    buffer.writeln(
      '4. Jawaban harus padat, jelas, relevan, dan nyaman dibaca di layar ponsel (maksimal 2-3 paragraf ringkas).',
    );

    return buffer.toString();
  }

  void _initModelIfNeeded() {
    if (!AppConfig.isGeminiConfigured) return;

    if (_model == null) {
      _model = GenerativeModel(
        model: AppConfig.geminiModel,
        apiKey: AppConfig.geminiApiKey,
        systemInstruction: Content.system(_buildSystemPrompt()),
      );
      _chatSession = _model!.startChat();
    }
  }

  /// Mengirim pesan ke Google Gemini API
  Future<GeminiResponse> sendMessage(String userMessage) async {
    final cleanMessage = userMessage.trim();
    if (cleanMessage.isEmpty) {
      return const GeminiResponse(
        isSuccess: false,
        text: 'Pesan tidak boleh kosong.',
      );
    }

    // 1. Cek Koneksi Internet
    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline) {
      return const GeminiResponse(
        isSuccess: false,
        text:
            'Koneksi internet tidak tersedia. Jnova AI memerlukan koneksi online untuk menganalisis rekomendasi instrumen.',
        errorMessage: 'offline',
      );
    }

    // 2. Cek Konfigurasi API Key
    if (!AppConfig.isGeminiConfigured) {
      return const GeminiResponse(
        isSuccess: false,
        text:
            'Google Gemini API belum dikonfigurasi. Silakan tambahkan GEMINI_API_KEY resmi pada file .env di perangkat/server Anda.',
        errorMessage: 'unconfigured_key',
      );
    }

    try {
      _initModelIfNeeded();

      if (_chatSession == null) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Gagal menginisialisasi sesi percakapan Gemini.',
        );
      }

      final response = await _chatSession!
          .sendMessage(Content.text(cleanMessage))
          .timeout(const Duration(seconds: 15));

      final rawText = response.text ?? '';
      if (rawText.trim().isEmpty) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Maaf, Jnova AI tidak dapat memberikan respons saat ini. Silakan ulangi pertanyaanmu.',
        );
      }

      // Deteksi rekomendasi produk dari tag [REKOMENDASI: ID]
      Product? recommendedProduct;
      String cleanedText = rawText;
      final tagMatch = RegExp(r'\[REKOMENDASI:\s*([a-zA-Z0-9_\-]+)\]').firstMatch(rawText);

      if (tagMatch != null) {
        final prodId = tagMatch.group(1)?.toLowerCase();
        final matches = Product.allCatalog.where(
          (p) => p.id.toLowerCase() == prodId,
        );
        recommendedProduct =
            matches.isNotEmpty ? matches.first : _matchProductByName(rawText);
        cleanedText = rawText.replaceAll(tagMatch.group(0)!, '').trim();
      } else {
        recommendedProduct = _matchProductByName(rawText);
      }

      String? badge;
      String? pointsLabel;
      if (recommendedProduct != null) {
        badge = 'REKOMENDASI JNOVA AI';
        final pts = (recommendedProduct.price / 100000).round();
        pointsLabel = '+$pts Poin Member';
      }

      return GeminiResponse(
        isSuccess: true,
        text: cleanedText,
        recommendedProduct: recommendedProduct,
        badge: badge,
        pointsLabel: pointsLabel,
      );
    } on TimeoutException {
      return const GeminiResponse(
        isSuccess: false,
        text: 'Waktu permintaan habis (timeout). Silakan periksa koneksi internet Anda dan coba lagi.',
        errorMessage: 'timeout',
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('quota') || errStr.contains('rate') || errStr.contains('429')) {
        return const GeminiResponse(
          isSuccess: false,
          text:
              'Batas kuota penggunaan Gemini API saat ini telah tercapai. Silakan coba kembali dalam beberapa saat.',
          errorMessage: 'quota_exceeded',
        );
      }
      return GeminiResponse(
        isSuccess: false,
        text: 'Terjadi kendala saat menghubungi layanan AI: ${e.toString()}',
        errorMessage: e.toString(),
      );
    }
  }

  /// Mencocokkan nama produk dalam teks respon AI ke katalog lokal
  Product? _matchProductByName(String text) {
    final lower = text.toLowerCase();
    for (final prod in Product.allCatalog) {
      if (lower.contains(prod.name.toLowerCase()) ||
          lower.contains(prod.brand.toLowerCase())) {
        return prod;
      }
    }
    return null;
  }

  /// Reset sesi obrolan
  void resetChat() {
    _chatSession = null;
    _model = null;
  }
}
