import 'dart:async';

import '../core/config/app_config.dart';
import '../core/network/network_info.dart';
import '../data/datasources/remote/supabase_client_service.dart';
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

  final List<Map<String, String>> _history = [];

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

  /// Reset local conversation history.
  void reconfigure() {
    _history.clear();
  }

  void resetChat() {
    _history.clear();
  }

  /// Mengirim pesan melalui server agar Gemini API key tidak ada di aplikasi.
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
        text: 'Koneksi internet tidak tersedia. Jnova AI memerlukan koneksi online untuk memproses pertanyaan musik Anda.',
        errorCode: 'offline',
      );
    }

    final supabase = SupabaseClientService.instance;
    if (!AppConfig.isAiBackendConfigured ||
        !supabase.isInitialized ||
        supabase.client == null) {
      return const GeminiResponse(
        isSuccess: false,
        text: 'Jnova AI sedang tidak tersedia. Silakan coba lagi nanti.',
        errorCode: 'backend_not_configured',
      );
    }

    try {
      final response = await supabase.client!.functions
          .invoke(
            'gemini-chat',
            body: {
              'message': cleanMessage,
              'systemInstruction': _buildSystemPrompt(),
              'history': _history,
            },
          )
          .timeout(const Duration(seconds: 35));
      final data = response.data;
      if (data is! Map || data['text'] is! String) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Server AI mengirim respons dengan format yang tidak dikenal.',
          errorCode: 'invalid_server_response',
        );
      }

      final rawText = (data['text'] as String).trim();
      if (rawText.trim().isEmpty) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Maaf, Jnova AI tidak menghasilkan respons untuk pertanyaan tersebut. Silakan ulangi pertanyaanmu.',
          errorCode: 'empty_response',
        );
      }
      _history
        ..add({'role': 'user', 'text': cleanMessage})
        ..add({'role': 'model', 'text': rawText});
      if (_history.length > 12) {
        _history.removeRange(0, _history.length - 12);
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
          .replaceAll(
            RegExp(r'\[REKOMENDASI:\s*[^\]]+\]', caseSensitive: false),
            '',
          )
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
        text: 'Waktu permintaan habis (timeout). Silakan periksa kestabilan jaringan internet Anda dan coba lagi.',
        errorCode: 'timeout',
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();

      if (errStr.contains('authentication_required') ||
          errStr.contains('401') ||
          errStr.contains('jwt')) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Sesi login tidak valid untuk layanan AI. Keluar lalu masuk kembali dengan koneksi internet.',
          errorCode: 'authentication_required',
        );
      }

      if (errStr.contains('rate_limit_exceeded')) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Chat Jnova AI dari jaringan ini sedang dibatasi sementara. Silakan coba lagi nanti.',
          errorCode: 'rate_limit_exceeded',
        );
      }

      if (errStr.contains('daily_limit_exceeded')) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Kuota harian Jnova AI sedang habis. Silakan coba lagi besok.',
          errorCode: 'daily_limit_exceeded',
        );
      }

      if (errStr.contains('quota_exceeded') || errStr.contains('429')) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Kuota gratis Gemini sedang habis. Silakan coba lagi setelah kuota diperbarui.',
          errorCode: 'quota_exceeded',
        );
      }

      if (errStr.contains('ai_not_configured') ||
          errStr.contains('server_not_configured') ||
          errStr.contains('function not found') ||
          errStr.contains('404')) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Jnova AI sedang tidak tersedia. Silakan coba lagi nanti.',
          errorCode: 'backend_not_configured',
        );
      }

      if (errStr.contains('socketexception') ||
          errStr.contains('handshake') ||
          errStr.contains('failed host lookup') ||
          errStr.contains('network') ||
          errStr.contains('connection')) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Gagal terhubung ke server AI. Periksa koneksi internet Anda lalu coba lagi.',
          errorCode: 'network_error',
        );
      }

      if (errStr.contains('upstream_key_invalid')) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Konfigurasi Gemini di server tidak valid. Pemilik aplikasi perlu memperbarui secret API key.',
          errorCode: 'backend_configuration_error',
        );
      }

      if (errStr.contains('upstream_busy') ||
          errStr.contains('upstream_unavailable') ||
          errStr.contains('upstream_error')) {
        return const GeminiResponse(
          isSuccess: false,
          text: 'Layanan Jnova AI sedang ramai. Silakan kirim pesan lagi sebentar.',
          errorCode: 'service_busy',
        );
      }

      return const GeminiResponse(
        isSuccess: false,
        text: 'Terjadi kendala saat memproses pertanyaan Anda dengan Jnova AI. Silakan coba kembali sesaat lagi.',
        errorCode: 'general_error',
      );
    }
  }
}
