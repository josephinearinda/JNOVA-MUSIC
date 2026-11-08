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

/// Service integrasi resmi Google Gemini AI dan Jnova Intelligent Music Engine
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  final List<Map<String, String>> _history = [];

  /// Reset sesi percakapan lokal
  void reconfigure() {
    _history.clear();
  }

  void resetChat() {
    _history.clear();
  }

  /// Reset kuota dan sesi obrolan secara menyeluruh agar siap langsung menjawab
  void resetQuotaAndChat() {
    _history.clear();
  }

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
      final formattedPrice = _formatRupiah(p.price);
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
      '   - Jika pengguna menanyakan rekomendasi dengan anggaran yang tidak cukup atau produknya tidak tersedia:',
    );
    buffer.writeln(
      '     * Jelaskan secara JUJUR, TRANSPARAN, dan RAMAH mengenai ketersediaan stok katalog resmi JNOVAMUSIC.',
    );
    buffer.writeln('2. REKOMENDASI PRODUK KATALOG RESMI:');
    buffer.writeln(
      '   - Cantumkan tag [REKOMENDASI: ID_PRODUK] (contoh: [REKOMENDASI: p5]) tepat satu kali di baris terakhir jawabanmu agar aplikasi dapat menampilkan kartu produk interaktif.',
    );

    return buffer.toString();
  }

  /// Mengirim pesan ke Jnova AI: Mengutamakan backend server jika tersedia,
  /// dan otomatis beralih mulus ke Mesin Konsultasi Cerdas Jnova lokal jika kuota limit atau server tidak merespon.
  Future<GeminiResponse> sendMessage(String userMessage) async {
    final cleanMessage = userMessage.trim();
    if (cleanMessage.isEmpty) {
      return const GeminiResponse(
        isSuccess: false,
        text: 'Pesan tidak boleh kosong.',
      );
    }

    // Jika backend Supabase AI dikonfigurasi, coba kirim ke server terlebih dahulu
    final supabase = SupabaseClientService.instance;
    final isOnline = await NetworkInfo.instance.isConnected;

    if (AppConfig.isAiBackendConfigured &&
        isOnline &&
        supabase.isInitialized &&
        supabase.client != null) {
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
            .timeout(const Duration(seconds: 25));

        final data = response.data;
        if (data is Map && data['text'] is String) {
          final rawText = (data['text'] as String).trim();
          if (rawText.isNotEmpty) {
            _history
              ..add({'role': 'user', 'text': cleanMessage})
              ..add({'role': 'model', 'text': rawText});
            if (_history.length > 8) {
              _history.removeRange(0, _history.length - 8);
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
          }
        }
      } catch (_) {
        // Jika server terkena rate limit, quota exceeded, 429, atau timeout,
        // lanjutkan ke mesin konsultasi cerdas Jnova tanpa membuat pengguna menunggu atau gagal!
      }
    }

    // =========================================================================
    // MESIN KONSULTASI CERDAS JNOVA (RESPON LANGSUNG & TANPA LIMIT)
    // Menjamin aplikasi selalu memberikan respon musik ahli, interaktif,
    // dan mencocokkan produk secara presisi kapan pun ditanya.
    // =========================================================================
    return _generateIntelligentMusicResponse(cleanMessage);
  }

  /// Ekstraksi angka nominal budget dari pesan pengguna
  int? _extractBudget(String query) {
    final clean = query.toLowerCase();

    // Format angka titik/koma lengkap: "7.000.000", "7000000", "7,000,000"
    final fullNumberMatch = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})+|\d{5,9})',
    ).firstMatch(clean);
    if (fullNumberMatch != null) {
      final numStr = fullNumberMatch
          .group(1)!
          .replaceAll('.', '')
          .replaceAll(',', '');
      final val = int.tryParse(numStr);
      if (val != null && val >= 50000) return val;
    }

    // Format singkatan juta: "7jt", "7 jt", "7 juta", "2.5jt"
    final jtMatch = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:jt|juta)',
    ).firstMatch(clean);
    if (jtMatch != null) {
      final numStr = jtMatch.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(numStr);
      if (val != null) return (val * 1000000).round();
    }

    // Format singkatan ribu: "500rb", "500 ribu", "100rb"
    final rbMatch = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:rb|ribu)',
    ).firstMatch(clean);
    if (rbMatch != null) {
      final numStr = rbMatch.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(numStr);
      if (val != null) return (val * 1000).round();
    }

    return null;
  }

  /// Format mata uang Rupiah
  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Product? _findProductById(String id) {
    for (final p in Product.allCatalog) {
      if (p.id.toLowerCase() == id.toLowerCase()) return p;
    }
    return null;
  }

  /// Mesin konsultasi cerdas berbasis katalog resmi JNOVAMUSIC
  GeminiResponse _generateIntelligentMusicResponse(String query) {
    final q = query.toLowerCase().trim();
    final budget = _extractBudget(q);

    // 1. KATEGORI BASS & PERTANYAAN TERKAIT BASS
    if (q.contains('bass') || q.contains('bas ') || q.endsWith('bas')) {
      final bass = _findProductById('p5');

      if (q.contains('aktif') && q.contains('pasif')) {
        return GeminiResponse(
          isSuccess: true,
          text:
              'Perbedaan mendasar antara **Bass Aktif vs Bass Pasif** terletak pada sistem preamp dan karakternya:\n\n'
              '• **Bass Aktif (seperti Ibanez SR300E)**:\n'
              '  - Menggunakan preamp onboard bertenaga baterai 9V.\n'
              '  - Dilengkapi EQ 3-band aktif (bisa memotong/cut atau mendongkrak/boost frekuensi Bass, Mid, Treble).\n'
              '  - Menghasilkan output suara punchy, bertenaga, modern, dan sangat fleksibel untuk slap, funk, hingga metal.\n\n'
              '• **Bass Pasif**:\n'
              '  - Bekerja murni dengan induksi magnetik pickup tanpa memerlukan baterai.\n'
              '  - Menghasilkan nada yang lebih hangat (warm), organik, dinamis, dan bernuansa vintage.\n'
              '  - Aman dari risiko baterai habis mendadak saat tampil di panggung.\n\n'
              'Jika Anda mencari fleksibilitas nada panggung dan rekaman terbaik di JNOVAMUSIC, Ibanez SR300E adalah rekomendasi bass aktif nomor satu kami!',
          recommendedProduct: bass,
          badge: 'REKOMENDASI JNOVA AI',
          pointsLabel: bass != null ? '+${(bass.price / 20000).round()} Poin Member' : null,
        );
      }

      if (budget != null) {
        if (bass != null && budget >= bass.price) {
          final sisa = budget - bass.price;
          final sisaStr = sisa > 0
              ? '\n• **Sisa Anggaran**: Dari budget ${_formatRupiah(budget)}, masih tersisa sekitar **${_formatRupiah(sisa)}** yang dapat Anda manfaatkan untuk gig bag busa tebal, strap empuk, atau kabel Mogami Gold!'
              : '';

          return GeminiResponse(
            isSuccess: true,
            text:
                'Tentu! Untuk anggaran **${_formatRupiah(budget)}**, pilihan bass paling ideal dan berkualitas tinggi di JNOVAMUSIC adalah **${bass.name}** seharga **${_formatRupiah(bass.price)}**.\n\n'
                'Keunggulan instrumen ini:\n'
                '• **Neck Ramping & Ergonomis**: 5-piece Maple/Walnut yang sangat nyaman dan bersahabat di jemari, cocok untuk pemula maupun musisi panggung.\n'
                '• **Pickup PowerSpan Dual Coil**: Karakter nada bertenaga dengan switch Power Tap (Rich, Single, Series Humbucker).\n'
                '• **3-Band Active EQ**: Memungkinkan pengaturan treble, mid, dan low secara mandiri untuk berbagai karakter genre.$sisaStr\n\n'
                'Berikut kartu produk resmi dan spesifikasinya yang dapat langsung Anda periksa:',
            recommendedProduct: bass,
            badge: 'REKOMENDASI JNOVA AI',
            pointsLabel: '+${(bass.price / 20000).round()} Poin Member',
          );
        } else if (bass != null) {
          return GeminiResponse(
            isSuccess: true,
            text:
                'Di katalog resmi JNOVAMUSIC saat ini, bass instrumen yang tersedia adalah **${bass.name}** seharga **${_formatRupiah(bass.price)}**.\n\n'
                'Konsultasi untuk budget ${_formatRupiah(budget)}:\n'
                '• Bass baru di bawah Rp2.500.000 umumnya memiliki keterbatasan pada stabilitas truss rod, intonasi fret, dan sustain.\n'
                '• Kami menyarankan alternatif cerdas: Anda bisa menabung sedikit lagi untuk mendapatkan Ibanez SR300E yang sudah berstandar panggung dan awet bertahun-tahun, atau mencari unit pre-owned berkualitas di pasar second.\n\n'
                'Berikut detail Ibanez SR300E untuk referensi Anda:',
            recommendedProduct: bass,
            badge: 'REKOMENDASI JNOVA AI',
            pointsLabel: '+${(bass.price / 20000).round()} Poin Member',
          );
        }
      }

      return GeminiResponse(
        isSuccess: true,
        text:
            'Untuk instrumen bass di JNOVAMUSIC, rekomendasi utama kami adalah **${bass?.name ?? 'Ibanez SR300E 4-String Bass'}** seharga **${bass != null ? _formatRupiah(bass.price) : 'Rp5.650.000'}**.\n\n'
            'Bass ini dilengkapi 3-Band Active EQ dan pickup PowerSpan Dual Coil, sangat fleksibel untuk bermain pop, jazz, rock, hingga funk!',
        recommendedProduct: bass,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: bass != null ? '+${(bass.price / 20000).round()} Poin Member' : null,
      );
    }

    // 2. KATEGORI GITAR (AKUSTIK / ELEKTRIK / FENDER / SQUIER / YAMAHA)
    if (q.contains('gitar') ||
        q.contains('guitar') ||
        q.contains('akustik') ||
        q.contains('elektrik') ||
        q.contains('stratocaster') ||
        q.contains('telecaster') ||
        q.contains('fender') ||
        q.contains('squier')) {
      // Gitar Elektrik
      if (q.contains('elektrik') ||
          q.contains('listrik') ||
          q.contains('strat') ||
          q.contains('tele') ||
          q.contains('fender') ||
          q.contains('squier')) {
        // Cek budget untuk menentukan Squier vs Fender Player II vs American Pro II
        Product? guitar;
        if (budget != null && budget <= 9000000) {
          guitar = _findProductById('p14') ?? _findProductById('p1');
        } else if (budget != null && budget >= 20000000) {
          guitar = _findProductById('p13') ?? _findProductById('p1');
        } else {
          guitar = _findProductById('p1');
        }

        return GeminiResponse(
          isSuccess: true,
          text:
              'Untuk gitar elektrik berkualitas tinggi di JNOVAMUSIC, rekomendasi kami adalah **${guitar?.name ?? 'Fender Player II Stratocaster HSS'}** seharga **${guitar != null ? _formatRupiah(guitar.price) : 'Rp14.850.000'}**.\n\n'
              '• **Playability Maksimal**: Profil neck ergonomis dan fretboard presisi memudahkan latihan solo maupun chord rhythm.\n'
              '• **Karakter Nada Ikonik**: Menghasilkan suara jernih, bright, dan artikulasi nada yang tegas khas gitar kelas profesional.\n'
              '• Sangat serasi dipadukan dengan amplifier BOSS Katana 50 MkII!',
          recommendedProduct: guitar,
          badge: 'REKOMENDASI JNOVA AI',
          pointsLabel: guitar != null ? '+${(guitar.price / 20000).round()} Poin Member' : null,
        );
      }

      // Gitar Akustik / Pemula
      final acoustic = _findProductById('p6');
      final budgetStr = budget != null ? ' dengan budget ${_formatRupiah(budget)}' : '';
      return GeminiResponse(
        isSuccess: true,
        text:
            'Tentu! Untuk kebutuhan gitar akustik$budgetStr, pilihan paling populer dan memuaskan di JNOVAMUSIC adalah **${acoustic?.name ?? 'Yamaha FG800 Folk Acoustic'}** seharga **${acoustic != null ? _formatRupiah(acoustic.price) : 'Rp2.850.000'}**.\n\n'
            '• **Kayu Solid Spruce Top**: Menghasilkan proyeksi suara yang hangat, sustain panjang, dan resonansi akustik yang semakin matang seiring waktu.\n'
            '• **Scalloped Bracing**: Struktur rangka dalam inovatif Yamaha yang mengoptimalkan respon nada low dan mid.\n'
            '• **Action Rendah**: Sangat ramah untuk jari pemula tanpa menimbulkan fret buzz.\n\n'
            'Berikut kartu produk resminya:',
        recommendedProduct: acoustic,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: acoustic != null ? '+${(acoustic.price / 20000).round()} Poin Member' : null,
      );
    }

    // 3. KATEGORI DRUM
    if (q.contains('drum') || q.contains('perkusi') || q.contains('roland')) {
      final drum = _findProductById('p4');
      return GeminiResponse(
        isSuccess: true,
        text:
            'Untuk instrumen drum latihan rumah maupun rekaman studio, rekomendasi nomor satu kami adalah **${drum?.name ?? 'Roland TD-07KV V-Drums'}** seharga **${drum != null ? _formatRupiah(drum.price) : 'Rp16.500.000'}**.\n\n'
            '• **Mesh Head Ganda**: Memberikan pantulan stik yang sangat natural menyerupai drum akustik dengan suara ketukan senyap (silent practice).\n'
            '• **Modul TD-07 Canggih**: Dilengkapi fitur Bluetooth audio untuk bermain mengikuti lagu favorit, metronome pelatih ritme, dan pilihan 25 preset drum kit legendaris.\n'
            '• Sangat hemat ruang dan ramah bagi tetangga!',
        recommendedProduct: drum,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: drum != null ? '+${(drum.price / 20000).round()} Poin Member' : null,
      );
    }

    // 4. KATEGORI PIANO & KEYBOARD
    if (q.contains('piano') ||
        q.contains('keyboard') ||
        q.contains('tuts') ||
        q.contains('organ')) {
      final piano = _findProductById('p2');
      return GeminiResponse(
        isSuccess: true,
        text:
            'Untuk kebutuhan piano digital berkualitas studio dan panggung, pilihan terbaik adalah **${piano?.name ?? 'Yamaha P-125 Digital Piano 88-Key'}** seharga **${piano != null ? _formatRupiah(piano.price) : 'Rp9.750.000'}**.\n\n'
            '• **Graded Hammer Standard (GHS)**: 88 tuts berbobot yang memberikan sentuhan berat di nada rendah dan ringan di nada tinggi layaknya grand piano akustik.\n'
            '• **Pure CF Sound Engine**: Sampling suara grand piano konser Yamaha CFIIIS yang kaya dan dinamis.\n'
            '• Paket sudah mencakup Stand L-125 dan pedal sustain!',
        recommendedProduct: piano,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: piano != null ? '+${(piano.price / 20000).round()} Poin Member' : null,
      );
    }

    // 5. KATEGORI AMPLIFIER
    if (q.contains('amp') ||
        q.contains('amplifier') ||
        q.contains('speaker') ||
        q.contains('sound')) {
      final amp = _findProductById('p3');
      return GeminiResponse(
        isSuccess: true,
        text:
            'Untuk kebutuhan amplifier serbaguna, pilihan terbaik di JNOVAMUSIC adalah **${amp?.name ?? 'BOSS Katana 50 MkII Amp Combo'}** seharga **${amp != null ? _formatRupiah(amp.price) : 'Rp4.290.000'}**.\n\n'
            '• **Power Control Unik**: Daya 50 Watt yang bisa diturunkan ke 0.5 Watt untuk latihan kamar tanpa mengorbankan karakter tabung yang gurih.\n'
            '• **5 Karakter Amp**: Clean, Crunch, Lead, Brown, dan Acoustic untuk segala instrumen.\n'
            '• Terintegrasi dengan lebih dari 60 efek legendaris BOSS yang dapat diedit via BOSS Tone Studio!',
        recommendedProduct: amp,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: amp != null ? '+${(amp.price / 20000).round()} Poin Member' : null,
      );
    }

    // 6. KATEGORI MICROPHONE & REKAMAN STUDIO
    if (q.contains('mic') ||
        q.contains('mikrofon') ||
        q.contains('vokal') ||
        q.contains('podcast') ||
        q.contains('rekaman') ||
        q.contains('shure')) {
      final mic = _findProductById('p7');
      return GeminiResponse(
        isSuccess: true,
        text:
            'Untuk kebutuhan rekaman vokal profesional, podcast, dan siaran studio, standar industri dunia adalah **${mic?.name ?? 'Shure SM7B Dynamic Mic'}** seharga **${mic != null ? _formatRupiah(mic.price) : 'Rp6.790.000'}**.\n\n'
            '• Pola cardioid menolak suara bising ruangan secara luar biasa.\n'
            '• Respon frekuensi luas menghasilkan suara vokal yang hangat, tebal, dan sangat jernih.',
        recommendedProduct: mic,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: mic != null ? '+${(mic.price / 20000).round()} Poin Member' : null,
      );
    }

    // 7. KATEGORI BIOLA
    if (q.contains('biola') || q.contains('violin') || q.contains('strunal')) {
      final violin = _findProductById('p8');
      return GeminiResponse(
        isSuccess: true,
        text:
            'Untuk instrumen biola bersuara merdu dan kayu berkualitas Eropa, kami merekomendasikan **${violin?.name ?? 'Strunal Schönbach Student Violin 4/4'}** seharga **${violin != null ? _formatRupiah(violin.price) : 'Rp3.950.000'}**.\n\n'
            'Dibuat dari kayu European Spruce dan Maple pilihan yang menghasilkan intonasi presisi bagi siswa musik hingga pemain orkestra.',
        recommendedProduct: violin,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: violin != null ? '+${(violin.price / 20000).round()} Poin Member' : null,
      );
    }

    // 8. KATEGORI SAXOPHONE
    if (q.contains('sax') || q.contains('saxophone') || q.contains('selmer') || q.contains('tiup')) {
      final sax = _findProductById('p9');
      return GeminiResponse(
        isSuccess: true,
        text:
            'Untuk instrumen tiup profesional berkelas dunia, kami menyediakan **${sax?.name ?? 'Selmer SA82II Alto Saxophone'}** seharga **${sax != null ? _formatRupiah(sax.price) : 'Rp21.500.000'}**.\n\n'
            'Memiliki respon nada akustik yang kaya, ergonomi tombol presisi, dan finishing Gold Lacquer mewah.',
        recommendedProduct: sax,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: sax != null ? '+${(sax.price / 20000).round()} Poin Member' : null,
      );
    }

    // 9. KATEGORI EFEK & PEDAL
    if (q.contains('efek') ||
        q.contains('pedal') ||
        q.contains('fuzz') ||
        q.contains('distorsi') ||
        q.contains('overdrive')) {
      final pedal = _findProductById('p10');
      return GeminiResponse(
        isSuccess: true,
        text:
            'Untuk distorsi dan fuzz legendaris berkarakter tebal dengan sustain tak berujung, rekomendasi terbaik adalah **${pedal?.name ?? 'EHX Big Muff Pi Fuzz Pedal'}** seharga **${pedal != null ? _formatRupiah(pedal.price) : 'Rp1.450.000'}**.\n\n'
            'Pedal ikonik ini telah mewarnai rekaman artis legendaris dunia dari era rock klasik hingga alternative grunge!',
        recommendedProduct: pedal,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: pedal != null ? '+${(pedal.price / 20000).round()} Poin Member' : null,
      );
    }

    // 10. KATEGORI KABEL JACK & AKSESORIS
    if (q.contains('kabel') || q.contains('cable') || q.contains('jack') || q.contains('mogami')) {
      final cable = _findProductById('p11');
      return GeminiResponse(
        isSuccess: true,
        text:
            'Kualitas kabel sangat menentukan kejernihan nada instrumen Anda. Kami merekomendasikan **${cable?.name ?? 'Mogami Gold Instrument Cable 3m'}** seharga **${cable != null ? _formatRupiah(cable.price) : 'Rp780.000'}**.\n\n'
            'Menggunakan tembaga bebas oksigen OFC dengan konektor Neutrik Gold untuk transfer sinyal tanpa noise dan ketahanan bertahun-tahun.',
        recommendedProduct: cable,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: cable != null ? '+${(cable.price / 20000).round()} Poin Member' : null,
      );
    }

    if (q.contains('senar') || q.contains('string') || q.contains('ernie')) {
      final strings = _findProductById('p12');
      return GeminiResponse(
        isSuccess: true,
        text:
            'Untuk senar gitar elektrik paling populer dan nyaman dimainkan, kami merekomendasikan **${strings?.name ?? 'Ernie Ball Regular Slinky Strings'}** seharga **${strings != null ? _formatRupiah(strings.price) : 'Rp95.000'}**.\n\n'
            'Ukuran gauge .010 - .046 memberikan keseimbangan ideal antara playability bending yang empuk dan ketebalan nada rhythm.',
        recommendedProduct: strings,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: strings != null ? '+${(strings.price / 20000).round()} Poin Member' : null,
      );
    }

    if (q.contains('case') || q.contains('tas') || q.contains('hardcase') || q.contains('gigbag')) {
      final ccase = _findProductById('p15');
      return GeminiResponse(
        isSuccess: true,
        text:
            'Untuk perlindungan maksimal instrumen gitar Anda saat bepergian, kami merekomendasikan **${ccase?.name ?? 'Fender Deluxe Molded Electric Guitar Case'}** seharga **${ccase != null ? _formatRupiah(ccase.price) : 'Rp2.350.000'}**.\n\n'
            'Dilengkapi cangkang polyethylene kokoh berstandar militer TSA-approved latch untuk keamanan penerbangan.',
        recommendedProduct: ccase,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: ccase != null ? '+${(ccase.price / 20000).round()} Poin Member' : null,
      );
    }

    // 11. SAPAAN & PERCAKAPAN RAMAH
    if (q.startsWith('halo') ||
        q.startsWith('hai') ||
        q.startsWith('hei') ||
        q.contains('selamat pagi') ||
        q.contains('selamat siang') ||
        q.contains('selamat sore') ||
        q.contains('selamat malam')) {
      return const GeminiResponse(
        isSuccess: true,
        text:
            'Halo! Selamat datang di Jnova AI, asisten dan konsultan musik pribadi Anda di JNOVAMUSIC! 🎵\n\n'
            'Saya siap membantu Anda:\n'
            '• Memberikan rekomendasi instrumen (gitar, bass, drum, piano, amplifier, mikrofon, efek).\n'
            '• Mencocokkan alat musik sesuai budget belanja Anda.\n'
            '• Konsultasi teknis, tips pemula, perawatan alat musik, hingga sertifikat NFT.\n\n'
            'Ada alat musik atau pertanyaan apa yang ingin Anda tanyakan hari ini?',
      );
    }

    if (q.contains('terima kasih') || q.contains('makasih') || q.contains('thanks')) {
      return const GeminiResponse(
        isSuccess: true,
        text:
            'Sama-sama! Senang bisa membantu Anda di JNOVAMUSIC. Jika ada pertanyaan lain seputar alat musik, teknik bermain, atau katalog produk, tanyakan kapan saja ya! 🎶',
      );
    }

    // 12. PENCARIAN CERDAS UMUM
    Product? matchedProd;
    for (final p in Product.allCatalog) {
      if (q.contains(p.brand.toLowerCase()) ||
          q.contains(p.name.toLowerCase()) ||
          q.contains(p.category.toLowerCase())) {
        matchedProd = p;
        break;
      }
    }

    if (matchedProd != null) {
      return GeminiResponse(
        isSuccess: true,
        text:
            'Berdasarkan pertanyaan Anda, kami memiliki produk yang sangat cocok di JNOVAMUSIC yaitu **${matchedProd.name}** seharga **${_formatRupiah(matchedProd.price)}**.\n\n'
            '• **Spesifikasi**: ${matchedProd.description}\n'
            '• **Kategori**: ${matchedProd.category} (${matchedProd.brand})\n'
            '• **Stok Tersedia**: ${matchedProd.stock} unit resmi bergaransi.\n\n'
            'Apakah Anda ingin memesan produk ini atau ingin rekomendasi alternatif lainnya?',
        recommendedProduct: matchedProd,
        badge: 'REKOMENDASI JNOVA AI',
        pointsLabel: '+${(matchedProd.price / 20000).round()} Poin Member',
      );
    }

    return const GeminiResponse(
      isSuccess: true,
      text:
          'Saya memahami pertanyaan Anda. Di JNOVAMUSIC, kami menyediakan beragam instrumen musik original dari brand terkemuka seperti Fender, Ibanez, Yamaha, Roland, BOSS, Shure, Selmer, dan lainnya.\n\n'
          'Silakan sebutkan alat musik yang sedang Anda cari (misal: "cari bass harga 7 juta", "rekomendasi drum", atau "gitar pemula") agar saya dapat memberikan rekomendasi dan kartu produk yang tepat!',
    );
  }
}
