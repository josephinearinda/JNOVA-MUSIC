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
  final String? errorCode;

  const GeminiResponse({
    required this.isSuccess,
    required this.text,
    this.recommendedProduct,
    this.badge,
    this.pointsLabel,
    this.errorCode,
  });

  /// Kompatibilitas dengan pembaca lama jika ada
  String? get errorMessage => errorCode;
}

/// Service integrasi resmi Google Gemini AI terpisah dari UI
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
      'Tugasmu adalah membantu pelanggan JNOVAMUSIC dengan saran musik terpercaya, edukasi teknis instrumen, dan rekomendasi produk yang tepat sesuai kebutuhan, tingkat keahlian (pemula/menengah/profesional), genre musik, dan anggaran belanja.',
    );
    buffer.writeln(
      'Gunakan bahasa Indonesia yang ramah, santun, bersahabat, profesional, dan kaya wawasan musik.',
    );

    buffer.writeln('\n========================================');
    buffer.writeln('DATA RESMI KATALOG PRODUK AKTIF JNOVAMUSIC:');
    buffer.writeln('========================================');
    for (final p in Product.allCatalog) {
      final formattedPrice =
          'Rp${p.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
      buffer.writeln(
        '- [ID: ${p.id}] ${p.brand} ${p.name} | Kategori: ${p.category} | Harga: $formattedPrice (${p.price}) | Varian: ${p.variant} | Stok: ${p.stock} unit',
      );
    }

    buffer.writeln('\n========================================');
    buffer.writeln('PANDUAN & ATURAN WAJIB JNOVA AI:');
    buffer.writeln('========================================');
    buffer.writeln('1. KEJUJURAN ANGGARAN & KATALOG:');
    buffer.writeln(
      '   - Selalu bandingkan anggaran pelanggan dengan data harga produk sebenarnya di katalog JNOVAMUSIC.',
    );
    buffer.writeln(
      '   - Jika pengguna menanyakan rekomendasi dengan anggaran yang tidak cukup atau produknya tidak tersedia (contoh spesifik: "Carikan rekomendasi bass harga Rp1.000.000"):',
    );
    buffer.writeln(
      '     * Jelaskan secara JUJUR, TRANSPARAN, dan RAMAH bahwa di katalog resmi JNOVAMUSIC saat ini belum tersedia bass baru di kisaran harga Rp1.000.000 (satu-satunya bass baru yang tersedia di katalog JNOVAMUSIC adalah Ibanez SR300E seharga Rp5.650.000 dengan stok 6 unit).',
    );
    buffer.writeln(
      '     * JANGAN PERNAH menyematkan tag [REKOMENDASI: ...] untuk produk yang harganya jauh melampaui budget pengguna tanpa persetujuan.',
    );
    buffer.writeln(
      '     * Berikan konsultasi objektif untuk budget tersebut: jelaskan bahwa bass baru seharga Rp1.000.000 sangat langka untuk standar kelayakan intonasi, kekuatan truss rod, dan kestabilan neck; sarankan alternatif cerdas seperti mencari bass bekas berkualitas (pre-owned) di pasar second (misalnya Cort Action Bass second atau Yamaha RBX series second), atau menyarankan menabung sedikit lagi ke kisaran Rp1.800.000 - Rp2.500.000 untuk mendapatkan bass baru pemula yang lebih nyaman dan awet.',
    );
    buffer.writeln(
      '     * Jangan pernah mengarang produk, stok fiktif, atau harga palsu yang tidak ada dalam data katalog.',
    );
    buffer.writeln('2. REKOMENDASI PRODUK KATALOG RESMI:');
    buffer.writeln(
      '   - Jika ada produk di katalog JNOVAMUSIC yang benar-benar cocok dengan kebutuhan dan budget pelanggan:',
    );
    buffer.writeln(
      '     * Jelaskan spesifikasi dan keunggulannya secara jelas dan memikat.',
    );
    buffer.writeln(
      '     * Cantumkan tag [REKOMENDASI: ID_PRODUK] (contoh: [REKOMENDASI: p6]) tepat satu kali di baris terakhir jawabanmu agar aplikasi dapat menampilkan kartu produk interaktif.',
    );
    buffer.writeln('     * Contoh pencocokan resmi:');
    buffer.writeln(
      '       - Gitar pemula budget Rp2-3 juta -> Yamaha FG800 Folk Acoustic (ID: p6, Rp2.850.000)',
    );
    buffer.writeln(
      '       - Gitar elektrik ikonik -> Fender Player II Stratocaster HSS (ID: p1, Rp14.850.000)',
    );
    buffer.writeln(
      '       - Senar gitar elektrik serbaguna -> Ernie Ball Regular Slinky (ID: p12, Rp95.000)',
    );
    buffer.writeln(
      '       - Amplifier serbaguna -> BOSS Katana 50 MkII (ID: p3, Rp4.290.000)',
    );
    buffer.writeln(
      '       - Drum elektrik latihan rumah -> Roland TD-07KV (ID: p4, Rp16.500.000)',
    );
    buffer.writeln(
      '       - Kabel instrumen kelas studio -> Mogami Gold Instrument Cable (ID: p11, Rp780.000)',
    );
    buffer.writeln(
      '       - Pedal efek fuzz legendaris -> EHX Big Muff Pi (ID: p10, Rp1.450.000)',
    );
    buffer.writeln('3. PENGETAHUAN MUSIK MENDALAM & EDUKATIF:');
    buffer.writeln(
      '   - Bass untuk pemula: Jelaskan kriteria penting (neck yang ergonomis/ramah tangan, bobot seimbang, konfigurasi pickup PJ atau dual-coil serbaguna). Rekomendasikan Ibanez SR300E (ID: p5) jika budget mencukupi.',
    );
    buffer.writeln(
      '   - Bass aktif vs pasif: Jelaskan perbedaan teknis mendalam: Bass aktif memiliki preamp onboard bertenaga baterai (9V/18V) dengan output tinggi dan EQ 3-band aktif (bisa boost/cut frekuensi bass, mid, treble) cocok untuk musik modern/slap; bass pasif tidak membutuhkan baterai, menghasilkan nada warm, dinamis, vintage, dan organik tanpa risiko baterai habis di panggung.',
    );
    buffer.writeln(
      '   - Jenis senar gitar: Jelaskan perbedaan bahan (nickel-plated steel yang bright-balanced vs stainless steel yang tajam dan tahan karat vs pure nickel yang vintage warm) dan konstruksi (roundwound untuk nada bright sustain panjang vs flatwound untuk nada smooth warm jazz tanpa bunyi decit jari), serta ukuran gauge (.009, .010, .011).',
    );
    buffer.writeln(
      '   - Perlengkapan drum: Jelaskan kebutuhan vital: stik drum (misal ukuran 5A kayu hickory), drum throne (kursi ergonomis), kick pedal, pelindung telinga (hearing protection), practice pad untuk latihan senyap, serta paket drum kit elektrik/akustik.',
    );
    buffer.writeln(
      '   - Pemilihan amplifier bass: Jelaskan panduan memilih berdasarkan daya/wattage (latihan kamar 15W-40W, studio 50W-100W, panggung 100W+), ukuran driver speaker (10 inci untuk respons cepat & slap, 12 inci untuk seimbang, 15 inci untuk low-end dalam), dan keberadaan fitur XLR Direct Out (DI).',
    );
    buffer.writeln('4. FORMAT JAWABAN:');
    buffer.writeln(
      '   - Singkat, padat, terstruktur rapi (2-4 paragraf atau bullet points).',
    );
    buffer.writeln('   - Enak dibaca di layar smartphone.');
    buffer.writeln(
      '   - Jangan pernah menampilkan kode mentah, tag internal yang bocor, atau JSON mentah.',
    );
    buffer.writeln('5. KEAMANAN:');
    buffer.writeln(
      '   - Jangan meminta atau memproses data rahasia seperti PIN, password, atau nomor rekening pribadi pengguna.',
    );

    return buffer.toString();
  }

  void _initModelIfNeeded([String? modelOverride]) {
    if (!AppConfig.isGeminiConfigured) return;

    final targetModel = modelOverride ?? AppConfig.geminiModel;

    _model ??= GenerativeModel(
      model: targetModel,
      apiKey: AppConfig.geminiApiKey,
      systemInstruction: Content.system(_buildSystemPrompt()),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1000,
      ),
    );
    _chatSession ??= _model!.startChat();
  }

  /// Reset sesi dan model agar membaca konfigurasi/key terbaru
  void reconfigure() {
    _chatSession = null;
    _model = null;
  }

  /// Reset riwayat percakapan sesi ini
  void resetChat() {
    _chatSession = null;
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }

  /// Menguji koneksi Gemini API dengan key dan model tertentu secara langsung
  Future<({bool success, String message})> testConnection({
    required String apiKey,
    String? model,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty || cleanKey.length < 10) {
      return (
        success: false,
        message: 'Format API Key tidak valid. Kunci harus memiliki minimal 10 karakter.',
      );
    }

    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline) {
      return (
        success: false,
        message: 'Tidak ada koneksi internet. Pastikan perangkat Anda terhubung ke internet.',
      );
    }

    final targetModel = (model != null && model.trim().isNotEmpty)
        ? model.trim()
        : AppConfig.geminiModel;

    try {
      final testModel = GenerativeModel(
        model: targetModel,
        apiKey: cleanKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: 10,
          temperature: 0.1,
        ),
      );
      final res = await testModel.generateContent([
        Content.text('Halo'),
      ]).timeout(const Duration(seconds: 15));

      if (res.text != null && res.text!.trim().isNotEmpty) {
        return (
          success: true,
          message: 'Koneksi ke Google Gemini API ($targetModel) berhasil!',
        );
      } else {
        return (
          success: false,
          message: 'Model terhubung namun tidak mengembalikan respons.',
        );
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('api_key_invalid') ||
          errStr.contains('api key not valid') ||
          errStr.contains('invalid api key') ||
          (errStr.contains('400') && errStr.contains('api_key'))) {
        return (
          success: false,
          message:
              'API Key tidak valid. Silakan periksa kembali API Key Anda di Google AI Studio (aistudio.google.com).',
        );
      }
      if (errStr.contains('permission_denied') || errStr.contains('403')) {
        return (
          success: false,
          message:
              'Akses ditolak (Permission Denied). Pastikan API Key memiliki izin Generative Language API.',
        );
      }
      if (errStr.contains('quota') || errStr.contains('429')) {
        return (
          success: false,
          message:
              'Batas kuota penggunaan (Rate Limit) tercapai. Silakan coba beberapa saat lagi.',
        );
      }
      if (errStr.contains('not found') || errStr.contains('404')) {
        return (
          success: false,
          message:
              'Model "$targetModel" tidak tersedia. Coba gunakan model gemini-1.5-flash.',
        );
      }
      return (
        success: false,
        message: 'Gagal terhubung ke Gemini: ${e.toString().split('\n').first}',
      );
    }
  }

  /// Mengirim pesan ke Google Gemini API dengan penanganan error terperinci
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
            'Koneksi internet tidak tersedia. Jnova AI memerlukan koneksi online untuk memproses pertanyaan musik Anda.',
        errorCode: 'offline',
      );
    }

    // 2. Cek Konfigurasi API Key
    if (!AppConfig.isGeminiConfigured) {
      return const GeminiResponse(
        isSuccess: false,
        text:
            'Google Gemini API belum dikonfigurasi. Silakan tambahkan GEMINI_API_KEY resmi pada file .env atau atur langsung melalui ikon kunci di atas.',
        errorCode: 'unconfigured_key',
      );
    }

    try {
      _initModelIfNeeded();

      if (_chatSession == null) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Gagal menginisialisasi sesi percakapan dengan Google Gemini API.',
          errorCode: 'session_init_failed',
        );
      }

      GenerateContentResponse? response;
      try {
        response = await _chatSession!
            .sendMessage(Content.text(cleanMessage))
            .timeout(const Duration(seconds: 30));
      } catch (innerError) {
        final innerStr = innerError.toString().toLowerCase();

        // Jika model tidak ditemukan (404), coba fallback otomatis ke model resmi alternatif
        if (innerStr.contains('not found') || innerStr.contains('404')) {
          final fallbackModels = [
            'gemini-1.5-flash',
            'gemini-2.0-flash',
            'gemini-2.5-flash',
          ].where((m) => m != AppConfig.geminiModel).toList();

          for (final fbModel in fallbackModels) {
            try {
              final tempModel = GenerativeModel(
                model: fbModel,
                apiKey: AppConfig.geminiApiKey,
                systemInstruction: Content.system(_buildSystemPrompt()),
                generationConfig: GenerationConfig(
                  temperature: 0.7,
                  maxOutputTokens: 1000,
                ),
              );
              final tempChat = tempModel.startChat();
              final fbResponse = await tempChat
                  .sendMessage(Content.text(cleanMessage))
                  .timeout(const Duration(seconds: 30));

              if (fbResponse.text != null && fbResponse.text!.trim().isNotEmpty) {
                _model = tempModel;
                _chatSession = tempChat;
                response = fbResponse;
                break;
              }
            } catch (_) {
              continue;
            }
          }
        }

        // Jika sesi error karena masalah urutan riwayat percakapan sebelumnya
        if (response == null &&
            (innerStr.contains('previous turn') || innerStr.contains('session'))) {
          resetChat();
          if (_chatSession != null) {
            response = await _chatSession!
                .sendMessage(Content.text(cleanMessage))
                .timeout(const Duration(seconds: 30));
          }
        }

        if (response == null) {
          rethrow;
        }
      }

      final rawText = response.text ?? '';
      if (rawText.trim().isEmpty) {
        return const GeminiResponse(
          isSuccess: false,
          text:
              'Maaf, Jnova AI tidak menghasilkan respons untuk pertanyaan tersebut. Silakan ulangi pertanyaanmu.',
          errorCode: 'empty_response',
        );
      }

      // Deteksi rekomendasi produk dari tag [REKOMENDASI: ID]
      Product? recommendedProduct;
      String cleanedText = rawText;
      final tagMatch = RegExp(
        r'\[REKOMENDASI:\s*([a-zA-Z0-9_\-\s]+)\]',
        caseSensitive: false,
      ).firstMatch(rawText);

      if (tagMatch != null) {
        final prodQuery = tagMatch.group(1)?.toLowerCase().trim() ?? '';
        final idMatches = Product.allCatalog.where(
          (p) => p.id.toLowerCase() == prodQuery,
        );
        if (idMatches.isNotEmpty) {
          recommendedProduct = idMatches.first;
        } else {
          // Cari berdasarkan kecocokan nama produk jika model menyebutkan nama
          final nameMatches = Product.allCatalog.where(
            (p) =>
                p.name.toLowerCase().contains(prodQuery) ||
                prodQuery.contains(p.name.toLowerCase()),
          );
          if (nameMatches.isNotEmpty) {
            recommendedProduct = nameMatches.first;
          }
        }
      }

      // Bersihkan seluruh tag [REKOMENDASI: ...] agar tidak tampak mentah di teks obrolan pengguna
      cleanedText = cleanedText
          .replaceAll(RegExp(r'\[REKOMENDASI:\s*[^\]]+\]', caseSensitive: false), '')
          .trim();

      String? badge;
      String? pointsLabel;
      if (recommendedProduct != null) {
        badge = 'REKOMENDASI JNOVA AI';
        final pts = (recommendedProduct.price / 20000).round();
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
        text:
            'Waktu permintaan habis (timeout). Silakan periksa kestabilan jaringan internet Anda dan coba lagi.',
        errorCode: 'timeout',
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();

      // Penanganan API Key tidak valid
      if (errStr.contains('api_key_invalid') ||
          errStr.contains('api key not valid') ||
          errStr.contains('invalid api key') ||
          (errStr.contains('400') && errStr.contains('api_key'))) {
        return const GeminiResponse(
          isSuccess: false,
          text:
              'API Key Google Gemini yang digunakan tidak valid atau sudah kedaluwarsa. Silakan periksa kembali API Key Anda di Google AI Studio (aistudio.google.com).',
          errorCode: 'invalid_key',
        );
      }

      // Penanganan Izin Akses Ditolak
      if (errStr.contains('permission_denied') ||
          errStr.contains('permissiondenied') ||
          errStr.contains('403')) {
        return const GeminiResponse(
          isSuccess: false,
          text:
              'Akses Google Gemini API ditolak (Permission Denied). Pastikan API Key Anda memiliki izin untuk menggunakan Generative Language API.',
          errorCode: 'permission_denied',
        );
      }

      // Penanganan Batas Kuota (Rate Limit / Quota Exceeded)
      if (errStr.contains('quota') ||
          errStr.contains('rate') ||
          errStr.contains('429') ||
          errStr.contains('resource_exhausted')) {
        return const GeminiResponse(
          isSuccess: false,
          text:
              'Batas kuota penggunaan Google Gemini API telah tercapai (Rate Limit). Silakan coba kembali dalam beberapa saat.',
          errorCode: 'quota_exceeded',
        );
      }

      // Penanganan Model Tidak Ditemukan / Region Tidak Didukung
      if (errStr.contains('not found') ||
          errStr.contains('model not found') ||
          errStr.contains('404')) {
        return const GeminiResponse(
          isSuccess: false,
          text:
              'Model AI yang dikonfigurasi tidak tersedia pada region atau akun Anda. Silakan periksa konfigurasi model Gemini.',
          errorCode: 'model_not_found',
        );
      }

      // Penanganan Filter Keamanan Konten
      if (errStr.contains('safety') || errStr.contains('blocked')) {
        return const GeminiResponse(
          isSuccess: false,
          text:
              'Pertanyaan tidak dapat diproses karena terdeteksi filter keamanan konten. Silakan gunakan pertanyaan seputar musik dan alat musik.',
          errorCode: 'safety_blocked',
        );
      }

      // Penanganan Masalah Jaringan / Socket
      if (errStr.contains('socketexception') ||
          errStr.contains('handshake') ||
          errStr.contains('failed host lookup') ||
          errStr.contains('network') ||
          errStr.contains('connection')) {
        return const GeminiResponse(
          isSuccess: false,
          text:
              'Gagal terhubung ke layanan Google AI. Periksa koneksi internet Anda dan coba beberapa saat lagi.',
          errorCode: 'network_error',
        );
      }

      // Penanganan Gangguan Server Google
      if (errStr.contains('500') ||
          errStr.contains('503') ||
          errStr.contains('internal server error') ||
          errStr.contains('unavailable')) {
        return const GeminiResponse(
          isSuccess: false,
          text:
              'Layanan Google Gemini AI sedang mengalami gangguan sementara dari sisi server. Silakan coba kembali nanti.',
          errorCode: 'server_error',
        );
      }

      return const GeminiResponse(
        isSuccess: false,
        text:
            'Terjadi kendala saat memproses pertanyaan Anda dengan Jnova AI. Silakan coba kembali sesaat lagi.',
        errorCode: 'general_error',
      );
    }
  }
}
