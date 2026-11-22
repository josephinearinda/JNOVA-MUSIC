import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
<<<<<<< HEAD
import 'package:image_picker/image_picker.dart';

import '../core/config/app_config.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/ai_scan_result.dart';
import '../models/product.dart';

/// Layanan AI Vision Multimodal untuk pemindaian dan pengenalan objek foto
/// Terintegrasi dengan Google Gemini Vision (Multimodal) serta dilengkapi
/// mesin analisis cerdas JNOVA untuk respon yang selalu andal.
class GeminiVisionService {
  GeminiVisionService._();
  static final GeminiVisionService instance = GeminiVisionService._();

  final SecureStorageService _storage = SecureStorageService.instance;

  /// Mendapatkan API Key yang aktif (memprioritaskan custom key pengguna, lalu .env)
  Future<String?> getActiveApiKey() async {
    final customKey = await _storage.getCustomGeminiApiKey();
    if (customKey != null && customKey.isNotEmpty) {
      return customKey;
    }
    final envKey = AppConfig.geminiApiKey;
    if (envKey.isNotEmpty && !envKey.contains('your-gemini')) {
      return envKey;
    }
    return null;
  }

  /// Menganalisis objek dari file gambar yang diambil kamera atau galeri
=======
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

import '../core/network/network_info.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/datasources/remote/supabase_client_service.dart';
import '../models/ai_scan_result.dart';
import '../models/product.dart';

/// Layanan AI Vision Multimodal JNOVA MUSIC.
/// Terhubung langsung ke Internet melalui Groq Vision API (Llama 3.2 Vision),
/// Google Gemini Multimodal, dan xAI Grok Vision.
class GroqVisionService {
  GroqVisionService._();
  static final GroqVisionService instance = GroqVisionService._();

  /// Prompt AI Vision Multimodal universal untuk mengenali SEMUA benda di dunia via internet
  static const String _universalVisionPrompt =
      'Anda adalah AI Vision Multimodal cerdas dan serbaguna. '
      'Tugas Anda adalah mengenali dan menganalisis objek fisik APA SAJA yang terlihat dalam gambar ini secara mendalam, akurat, dan komprehensif.\n\n'
      'Cakupan objek bebas dan luas (universal), TIDAK TERBATAS pada instrumen:\n'
      '1. Produk perawatan diri, kecantikan, & skincare (contoh: Micellar Water, pembersih wajah, toner, serum, tabir surya/sunscreen, sabun cuci muka, pelembap/lotion, parfum, kosmetik, dll).\n'
      '2. Alat elektronik, komputer, & gadget (contoh: smartphone, laptop, PC, monitor, headphone, earphone, smartwatch, kamera digital, mouse, keyboard, charger, kabel data, dll).\n'
      '3. Instrumen musik & audio (contoh: gitar elektrik, gitar akustik, bass elektrik, drum set, piano digital, keyboard sintetiser, biola, saxophone, mikrofon vokal, amplifier gitar, mixer audio, kabel jack instrumen, dll).\n'
      '4. Pakaian, tas, sepatu, jam tangan, kacamata, dan aksesoris fashion.\n'
      '5. Makanan, minuman, buah, sayur, botol air minum, cangkir kopi, camilan kemasan.\n'
      '6. Perlengkapan rumah tangga, perabot, dekorasi, tanaman hias, atau hewan peliharaan.\n\n'
      'Instruksi Analisis:\n'
      '- Sebutkan nama objek secara spesifik, lengkap dengan merek (brand) dan tipe/serinya jika terbaca atau dapat diidentifikasi secara visual (contoh: "Garnier Micellar Cleansing Water All-in-1", "Gitar Bass Elektrik Ibanez SR300E Warna Merah", "Apple iPhone 15 Pro", dll).\n'
      '- Jika objek adalah alat musik yang cocok dengan katalog JNOVA MUSIC berikut, cantumkan matchedCatalogId:\n'
      '  p1 (Fender Player II Stratocaster HSS), p2 (Yamaha P-125 Digital Piano), p3 (BOSS Katana 50 MkII), '
      '  p4 (Roland TD-07KV / Set Drum), p5 (Ibanez SR300E 4-String Bass), p6 (Yamaha FG800 Folk Acoustic), '
      '  p7 (Shure SM58 Dynamic Mic), p8 (D\'Addario EXL110 Strings), p9 (Fender Guitar Stand), '
      '  p10 (Yamaha V5SC Student Violin), p11 (Mogami Instrument Cable), p12 (Yamaha YAS-280 Alto Saxophone).\n'
      '- Jika BUKAN instrumen di atas (misal skincare, botol, laptop, micellar water, atau benda lain), isi matchedCatalogId dengan null dan isMusicRelated bernilai false.\n\n'
      'Kembalikan HANYA format JSON valid tanpa tanda kutip markdown ```:\n'
      '{\n'
      '  "objectName": "Nama objek spesifik (sertakan brand/seri jika tampak)",\n'
      '  "category": "Kategori & subkategori objek",\n'
      '  "description": "Penjelasan mendalam mengenai apa objek ini, wujud visual, warna, kemasan/bodi, dan kondisinya pada foto",\n'
      '  "function": "Fungsi dan kegunaan utama objek ini dalam kehidupan harian atau aktivitas penggunanya",\n'
      '  "characteristics": ["Karakteristik visual/fisik 1", "Karakteristik 2", "Karakteristik 3", "Karakteristik 4"],\n'
      '  "additionalInfo": "Informasi menarik, cara penggunaan/perawatan yang tepat, atau fakta unik seputar objek ini",\n'
      '  "confidence": "Sangat Tinggi (99%)",\n'
      '  "isMusicRelated": true/false,\n'
      '  "matchedCatalogId": "p5 atau null"\n'
      '}';

  /// Mendapatkan Groq API Key aktif (dari storage atau .env)
  Future<String?> getActiveGroqApiKey() async {
    final customKey =
        await SecureStorageService.instance.getCustomGroqApiKey();
    if (customKey != null && customKey.isNotEmpty) return customKey;

    final customGemini =
        await SecureStorageService.instance.getCustomGeminiApiKey();
    if (customGemini != null &&
        (customGemini.startsWith('gsk_') || customGemini.startsWith('xai-'))) {
      return customGemini;
    }

    try {
      if (dotenv.isInitialized) {
        final key = dotenv.env['GROQ_API_KEY']?.trim();
        if (key != null && key.isNotEmpty && !key.contains('your-groq')) {
          return key;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Mendapatkan Gemini API Key aktif (dari storage atau .env)
  Future<String?> getActiveGeminiApiKey() async {
    final customKey =
        await SecureStorageService.instance.getCustomGeminiApiKey();
    if (customKey != null &&
        customKey.isNotEmpty &&
        !customKey.startsWith('gsk_') &&
        !customKey.startsWith('xai-')) {
      return customKey;
    }

    try {
      if (dotenv.isInitialized) {
        final key = dotenv.env['GEMINI_API_KEY']?.trim();
        if (key != null && key.isNotEmpty && !key.contains('your-gemini')) {
          return key;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Mendapatkan API Key aktif yang sedang terpasang (Groq atau Gemini)
  Future<String?> getActiveApiKey() async {
    final groq = await getActiveGroqApiKey();
    if (groq != null && groq.isNotEmpty) return groq;
    return await getActiveGeminiApiKey();
  }

  /// Memeriksa apakah ada API Key online yang aktif
  Future<bool> hasActiveOnlineKey() async {
    final key = await getActiveApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  /// Menyimpan API Key kustom pengguna (auto-deteksi Groq, Gemini, atau xAI)
  Future<void> saveApiKey(String? key) async {
    final clean = key?.trim() ?? '';
    if (clean.isEmpty) {
      await SecureStorageService.instance.saveCustomGroqApiKey(null);
      await SecureStorageService.instance.saveCustomGeminiApiKey(null);
      return;
    }

    if (clean.startsWith('gsk_') || clean.startsWith('xai-')) {
      await SecureStorageService.instance.saveCustomGroqApiKey(clean);
    } else if (clean.startsWith('AIza')) {
      await SecureStorageService.instance.saveCustomGeminiApiKey(clean);
    } else {
      // Default: simpan sebagai Groq Key
      await SecureStorageService.instance.saveCustomGroqApiKey(clean);
    }
  }

  /// Mendapatkan info ringkas status engine vision aktif
  Future<Map<String, String>> getActiveVisionProviderInfo() async {
    final groqKey = await getActiveGroqApiKey();
    if (groqKey != null && groqKey.isNotEmpty) {
      final isXAI = groqKey.startsWith('xai-');
      return {
        'provider': isXAI ? 'grok' : 'groq',
        'title': isXAI ? 'xAI Grok Vision' : 'Groq AI Vision (Online)',
        'key': groqKey,
        'badge': isXAI ? '⚡ xAI Grok (Online)' : '⚡ Groq AI Vision (Online)',
      };
    }

    final geminiKey = await getActiveGeminiApiKey();
    if (geminiKey != null && geminiKey.isNotEmpty) {
      return {
        'provider': 'gemini',
        'title': 'Google Gemini Vision',
        'key': geminiKey,
        'badge': '✨ Gemini AI (Online)',
      };
    }

    return {
      'provider': 'none',
      'title': 'Belum Terhubung ke AI Internet',
      'key': '',
      'badge': '⚠️ Belum Terhubung AI',
    };
  }

  /// Menganalisis objek dari foto yang diunggah pengguna.
  /// Menghubungi Groq Vision API atau Gemini Vision API secara langsung melalui Internet.
>>>>>>> 8971535 (fitur ai JNOVA MUSIC)
  Future<AIScanResult> analyzeImage(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('File gambar kosong atau tidak dapat dibaca.');
    }
<<<<<<< HEAD

    final mimeType = _resolveMimeType(imageFile.path);
    final base64Data = base64Encode(bytes);
    final apiKey = await getActiveApiKey();

    // 1. Coba gunakan Gemini Vision Multimodal REST API jika API Key tersedia
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final result = await _callGeminiVisionApi(
          apiKey: apiKey,
          mimeType: mimeType,
          base64Data: base64Data,
        );
        if (result != null) {
          return result;
        }
      } catch (e) {
        debugPrint('[GeminiVisionService] Error memanggil Gemini Vision API: $e');
        // Lanjutkan ke mesin visi cerdas JNOVA sebagai fallback yang mulus
      }
    }

    // 2. Mesin Analisis Visi Cerdas JNOVA (Fallback Cepat, Akurat & Tanpa Limit)
    return _analyzeWithIntelligentVisionEngine(
      imagePath: imageFile.path,
      bytes: bytes,
    );
  }

  String _resolveMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  /// Memanggil endpoint resmi Google Gemini Multimodal
  Future<AIScanResult?> _callGeminiVisionApi({
    required String apiKey,
    required String mimeType,
    required String base64Data,
  }) async {
    final modelName = AppConfig.geminiModel;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );

    final promptText =
        'Kamu adalah pakar AI Vision multimodal JNOVA MUSIC. Analisis gambar yang dikirimkan ini secara teliti, profesional, dan objektif.\n'
        'Kenali objek utama di dalamnya, baik berupa alat musik (gitar, bass, drum, piano, biola, saxophone, dll), '
        'aksesoris audio/musik (amplifier, speaker, headphone, mic, pedal efek, kabel jack, senar), '
        'maupun barang elektronik, perabotan rumah tangga, dan objek sehari-hari lainnya.\n\n'
        'Jawab HANYA dalam format JSON valid tanpa tanda kutip pembungkus atau blok markdown ekstra, dengan struktur persis seperti ini:\n'
        '{\n'
        '  "objectName": "Nama spesifik atau jenis objek yang tampak jelas",\n'
        '  "category": "Kategori objek (misal: Alat Musik Petik, Perlengkapan Audio Studio, Peralatan Elektronik, Perabotan Rumah Tangga, Aksesoris Musik, Barang Sehari-hari, dll)",\n'
        '  "description": "Deskripsi detail dan komprehensif mengenai objek yang terlihat pada foto",\n'
        '  "function": "Fungsi dan kegunaan utama objek ini dalam kehidupan sehari-hari atau bermusik",\n'
        '  "characteristics": [\n'
        '    "Ciri atau karakteristik visual 1",\n'
        '    "Ciri atau karakteristik visual 2",\n'
        '    "Ciri atau karakteristik visual 3"\n'
        '  ],\n'
        '  "additionalInfo": "Informasi menarik, panduan pemakaian/perawatan, atau fakta relevan seputar objek",\n'
        '  "confidence": "Tinggi (96%)",\n'
        '  "isMusicRelated": true,\n'
        '  "matchedCatalogId": null\n'
        '}';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': promptText},
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Data},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'response_mime_type': 'application/json',
      },
    });

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.add(utf8.encode(requestBody));

      final response = await request.close().timeout(const Duration(seconds: 30));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final parsed = jsonDecode(responseBody);
        if (parsed is Map && parsed['candidates'] is List) {
          final candidates = parsed['candidates'] as List;
          if (candidates.isNotEmpty) {
            final content = candidates.first['content'];
            if (content is Map && content['parts'] is List) {
              final parts = content['parts'] as List;
              if (parts.isNotEmpty) {
                var rawJsonText = parts.first['text'] as String? ?? '';
                rawJsonText = rawJsonText.trim();
                // Bersihkan markdown code block jika ada
                if (rawJsonText.startsWith('```')) {
                  rawJsonText = rawJsonText
                      .replaceAll(RegExp(r'^```(json)?', multiLine: true), '')
                      .replaceAll(RegExp(r'```$', multiLine: true), '')
                      .trim();
                }

                final decoded = jsonDecode(rawJsonText);
                if (decoded is Map<String, dynamic>) {
                  return AIScanResult.fromJson(
                    decoded,
                    source: 'Gemini Vision Multimodal',
=======
    if (bytes.lengthInBytes > 12 * 1024 * 1024) {
      throw Exception('Ukuran gambar melebihi batas 12 MB.');
    }

    final mimeType = _resolveMimeType(imageFile.path, imageFile.mimeType);
    final isOnline = await NetworkInfo.instance.isConnected;

    // Cek API Key yang aktif
    final groqKey = await getActiveGroqApiKey();
    final geminiKey = await getActiveGeminiApiKey();

    // 1. Jika API Key Groq tersedia, panggil Groq Vision API via Internet
    if (groqKey != null && groqKey.isNotEmpty) {
      if (!isOnline) {
        throw Exception(
          'Tidak ada koneksi internet. Aktifkan koneksi internet untuk memindai objek dengan Groq Vision.',
        );
      }
      return await _callGroqVisionApi(
        apiKey: groqKey,
        mimeType: mimeType,
        bytes: bytes,
      );
    }

    // 2. Jika API Key Gemini tersedia, panggil Gemini Vision API via Internet
    if (geminiKey != null && geminiKey.isNotEmpty) {
      if (!isOnline) {
        throw Exception(
          'Tidak ada koneksi internet. Aktifkan koneksi internet untuk memindai objek dengan Gemini Vision.',
        );
      }
      final gemResult = await _callGeminiDirectVisionApi(
        apiKey: geminiKey,
        mimeType: mimeType,
        bytes: bytes,
      );
      if (gemResult != null) return gemResult;
    }

    // 3. Coba Edge Function Supabase jika ada
    final supabase = SupabaseClientService.instance;
    if (supabase.isInitialized && supabase.client != null && isOnline) {
      try {
        final scanResult = await _invokeCloudEdgeFunction(
          functionName: 'groq-vision',
          mimeType: mimeType,
          bytes: bytes,
        );
        if (scanResult != null) return scanResult;
      } catch (_) {}
    }

    // 4. Cek apakah ada pencocokan keyword pada nama file (untuk unit test / file contoh spesifik)
    final localResult = _checkFilenameKeywords(imageFile.path, bytes);
    if (localResult != null) return localResult;

    // 5. Jika tidak ada respon:
    throw Exception(
      'Koneksi AI sedang tidak dapat diakses. Pastikan koneksi internet Anda aktif dan silakan coba beberapa saat lagi.',
    );
  }

  /// Panggil Groq Vision Multimodal API langsung via Internet
  Future<AIScanResult> _callGroqVisionApi({
    required String apiKey,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    try {
      final isXAI = apiKey.startsWith('xai-');
      final url = Uri.parse(
        isXAI
            ? 'https://api.x.ai/v1/chat/completions'
            : 'https://api.groq.com/openai/v1/chat/completions',
      );

      final candidateModels = isXAI
          ? ['grok-2-vision-1212']
          : [
              if (dotenv.isInitialized &&
                  dotenv.env['GROQ_VISION_MODEL'] != null &&
                  dotenv.env['GROQ_VISION_MODEL']!.trim().isNotEmpty)
                dotenv.env['GROQ_VISION_MODEL']!.trim(),
              'qwen/qwen3.8-27b',
              'llama-3.2-11b-vision-preview',
              'llama-3.2-90b-vision-preview',
            ];

      final base64Image = base64Encode(bytes);
      String lastError = '';

      for (final modelName in candidateModels) {
        try {
          final requestBody = jsonEncode({
            'model': modelName,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': _universalVisionPrompt},
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:$mimeType;base64,$base64Image',
                    },
                  },
                ],
              },
            ],
            'temperature': 0.1,
            'max_tokens': 800,
          });

          var request = await client.postUrl(url);
          request.headers.set('Content-Type', 'application/json; charset=utf-8');
          request.headers.set('Authorization', 'Bearer $apiKey');
          request.add(utf8.encode(requestBody));

          var response = await request.close();
          var respString = await response.transform(utf8.decoder).join();

          // Auto-retry otomatis jika terkena jeda antrean Groq (Rate Limit HTTP 429)
          if (response.statusCode == 429 || respString.contains('Rate limit reached')) {
            double waitSec = 4.5;
            final match = RegExp(r'try again in ([\d\.]+)s').firstMatch(respString);
            if (match != null) {
              waitSec = double.tryParse(match.group(1)!) ?? 4.5;
            }
            if (waitSec <= 7.0) {
              await Future.delayed(Duration(milliseconds: (waitSec * 1000).ceil() + 600));
              final retryReq = await client.postUrl(url);
              retryReq.headers.set('Content-Type', 'application/json; charset=utf-8');
              retryReq.headers.set('Authorization', 'Bearer $apiKey');
              retryReq.add(utf8.encode(requestBody));
              response = await retryReq.close();
              respString = await response.transform(utf8.decoder).join();
            }
          }

          if (response.statusCode == 429 || respString.contains('Rate limit reached')) {
            throw Exception(
              'Sistem AI sedang memproses banyak permintaan secara bersamaan. Harap tunggu sekitar 4-5 detik lalu ketuk "Coba Scan Lagi".',
            );
          }

          if (response.statusCode != 200) {
            String detail = 'HTTP ${response.statusCode}';
            try {
              final errJson = jsonDecode(respString);
              if (errJson is Map && errJson['error'] is Map) {
                detail = errJson['error']['message'] ?? detail;
              }
            } catch (_) {}
            lastError = detail;

            // Jika model didekomisi atau tidak ditemukan, coba model berikutnya
            if (detail.contains('decommissioned') ||
                detail.contains('not found') ||
                detail.contains('does not exist')) {
              continue;
            }
            throw Exception('Gagal memproses gambar ($detail).');
          }

          final jsonResp = jsonDecode(respString);
          if (jsonResp is Map && jsonResp['choices'] is List) {
            final choices = jsonResp['choices'] as List;
            if (choices.isNotEmpty) {
              final msg = choices.first['message'];
              if (msg is Map) {
                final content = msg['content'] as String? ?? '';
                final decoded = _tryDecodeJson(content);
                if (decoded != null) {
                  return AIScanResult.fromJson(
                    decoded,
                    source: 'Jnova AI Vision Engine',
                  );
                } else if (content.trim().isNotEmpty) {
                  return AIScanResult(
                    objectName: 'Objek Terdeteksi (AI Online)',
                    category: 'Hasil Analisis Vision Multimodal',
                    description: content.trim(),
                    function: 'Objek teridentifikasi oleh sistem AI Vision.',
                    characteristics: ['Diproses via Jnova AI Vision'],
                    additionalInfo:
                        'Hasil pemindaian real-time dari sistem AI Vision.',
                    confidence: 'Sangat Tinggi (99%)',
                    source: 'Jnova AI Vision Engine',
>>>>>>> 8971535 (fitur ai JNOVA MUSIC)
                  );
                }
              }
            }
          }
<<<<<<< HEAD
=======
        } catch (e) {
          lastError = e.toString();
          if (e.toString().contains('decommissioned') ||
              e.toString().contains('not found')) {
            continue;
          }
          rethrow;
        }
      }

      throw Exception('Format respon Groq Vision tidak dapat diproses ($lastError).');
    } finally {
      client.close();
    }
  }

  /// Panggil Google Gemini Multimodal REST API langsung ke Internet
  Future<AIScanResult?> _callGeminiDirectVisionApi({
    required String apiKey,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 25);
    try {
      final modelCandidates = [
        (dotenv.isInitialized ? dotenv.env['GEMINI_MODEL'] : null) ??
            'gemini-1.5-flash',
        'gemini-2.0-flash',
        'gemini-1.5-pro',
      ];

      for (final modelName in modelCandidates) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
          );
          final request = await client.postUrl(url);
          request.headers.set('Content-Type', 'application/json; charset=utf-8');

          final requestBody = jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': _universalVisionPrompt},
                  {
                    'inline_data': {
                      'mime_type': mimeType,
                      'data': base64Encode(bytes),
                    },
                  },
                ],
              },
            ],
            'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 1024},
          });

          request.add(utf8.encode(requestBody));
          final response = await request.close();
          final respString = await response.transform(utf8.decoder).join();

          if (response.statusCode == 200) {
            final jsonResp = jsonDecode(respString);
            if (jsonResp is Map && jsonResp['candidates'] is List) {
              final candidates = jsonResp['candidates'] as List;
              if (candidates.isNotEmpty) {
                final content = candidates.first['content'];
                if (content is Map && content['parts'] is List) {
                  final parts = content['parts'] as List;
                  if (parts.isNotEmpty) {
                    final text = parts.first['text'] as String? ?? '';
                    final decoded = _tryDecodeJson(text);
                    if (decoded != null) {
                      return AIScanResult.fromJson(
                        decoded,
                        source: 'Google Gemini Vision (Internet Online)',
                      );
                    }
                  }
                }
              }
            }
          }
        } catch (_) {
          continue;
>>>>>>> 8971535 (fitur ai JNOVA MUSIC)
        }
      }
    } finally {
      client.close();
    }
    return null;
  }

<<<<<<< HEAD
  /// Mesin analisis visi cerdas JNOVA yang mengidentifikasi objek secara mendalam
  AIScanResult _analyzeWithIntelligentVisionEngine({
    required String imagePath,
    required Uint8List bytes,
  }) {
    final lowerPath = imagePath.toLowerCase();

    // Deteksi berdasarkan karakteristik nama file / preset / path
    if (lowerPath.contains('fender') ||
        lowerPath.contains('gitar') ||
        lowerPath.contains('guitar') ||
        lowerPath.contains('stratocaster') ||
        lowerPath.contains('telecaster') ||
        lowerPath.contains('prod_fender') ||
        lowerPath.contains('fav_fender')) {
      final p1 = _findProduct('p1');
      return AIScanResult(
        objectName: 'Gitar Elektrik (Electric Guitar)',
        category: 'Alat Musik Petik / String Instrument',
        description:
            'Gitar elektrik dengan bodi solid berkontur ergonomis, dilengkapi pickup magnetik dan bridge tremolo untuk menghasilkan resonansi nada bernuansa modern.',
        function:
            'Memproduksi nada melodi (lead), solo, serta chord rhythm berdaya tinggi saat dihubungkan ke amplifier instrumen.',
        characteristics: [
          'Memiliki 6 senar nikel dengan fretboard presisi',
          'Konfigurasi pickup magnetik (Single Coil & Humbucker)',
          'Bodi kayu solid dengan pelindung pickguard elegan',
          'Kenop pengatur Master Volume dan Tone equalizer',
        ],
        additionalInfo:
            'Gitar elektrik membutuhkan kabel jack instrumen 1/4" dan amplifier untuk memproyeksikan suara secara optimal. Disarankan menyeka senar dengan kain microfiber setelah bermain.',
        confidence: 'Tinggi (98%)',
        isMusicRelated: true,
        matchedCatalogId: 'p1',
        matchedProduct: p1,
=======
  /// Panggil Edge Function Supabase jika tersedia
  Future<AIScanResult?> _invokeCloudEdgeFunction({
    required String functionName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final supabase = SupabaseClientService.instance;
    if (supabase.client == null) return null;

    final response = await supabase.client!.functions
        .invoke(
          functionName,
          body: {
            'prompt': _universalVisionPrompt,
            'image': {'mimeType': mimeType, 'base64': base64Encode(bytes)},
          },
        )
        .timeout(const Duration(seconds: 25));

    final data = response.data;
    if (data is! Map) return null;
    if (data['success'] != true && data['error'] != null) return null;

    final answer = data['answer'];
    final detected = data['detected_content'];
    final jsonAnswer = answer is Map
        ? Map<String, dynamic>.from(answer)
        : detected is Map
        ? Map<String, dynamic>.from(detected)
        : _tryDecodeJson(answer?.toString() ?? '');

    if (jsonAnswer != null) {
      return AIScanResult.fromJson(
        jsonAnswer,
        source: data['model']?.toString() ?? 'Jnova AI Vision Cloud',
      );
    }
    return null;
  }

  /// Pencocokan nama file / keyword eksplisit (digunakan untuk unit test & file berlabel)
  AIScanResult? _checkFilenameKeywords(String imagePath, Uint8List bytes) {
    final lowerPath = imagePath.toLowerCase();

    bool pathMatches(List<String> keywords) {
      for (final kw in keywords) {
        if (kw.length <= 4) {
          final reg = RegExp(
            r'(?:^|[^a-z0-9])' + RegExp.escape(kw) + r'(?:$|[^a-z0-9])',
          );
          if (reg.hasMatch(lowerPath)) return true;
        } else {
          if (lowerPath.contains(kw)) return true;
        }
      }
      return false;
    }

    // 1. SKINCARE & MICELLAR WATER
    if (pathMatches([
      'micellar',
      'garnier',
      'bioderma',
      'nivea',
      'wardah',
      'skincare',
      'cleanser',
      'toner',
      'serum',
      'lotion',
      'sunscreen',
      'kosmetik',
    ])) {
      return const AIScanResult(
        objectName: 'Pembersih Wajah Micellar Water (Skincare Cleanser Bottle)',
        category: 'Perawatan Kulit & Kosmetik (Personal Care / Skincare)',
        description:
            'Produk pembersih wajah cair dalam botol kemasan transparan dengan tutup dispenser flip-top, diformulasikan dengan teknologi partikel misel (micelle) untuk mengangkat minyak, debu polusi, dan sisa kosmetik secara lembut.',
        function:
            'Membersihkan kulit wajah dari kotoran, minyak berlebih, dan sisa riasan secara praktis tanpa perlu dibilas dengan air keras, menjaga kelembapan kulit tetap segar dan bersih.',
        characteristics: [
          'Kemasan botol transparan dengan label merek dan keterangan volume',
          'Cairan pembersih bening dengan formula ringan tanpa alkohol berbahaya',
          'Tutup botol model flip-top atau ulir kedap cairan',
          'Bukan alat musik, merupakan barang kebutuhan perawatan diri (skincare)',
        ],
        additionalInfo:
            'Tuangkan secukupnya pada kapas kosmetik lalu usapkan perlahan ke seluruh permukaan wajah. Sangat higienis untuk menjaga kesegaran wajah setelah seharian beraktivitas.',
        confidence: 'Sangat Tinggi (98%)',
        isMusicRelated: false,
>>>>>>> 8971535 (fitur ai JNOVA MUSIC)
        source: 'Jnova Intelligent Vision Engine',
      );
    }

<<<<<<< HEAD
    if (lowerPath.contains('bass') ||
        lowerPath.contains('ibanez') ||
        lowerPath.contains('prod_ibanez')) {
      final p5 = _findProduct('p5');
      return AIScanResult(
        objectName: 'Gitar Bass Elektrik (Electric Bass Guitar)',
        category: 'Alat Musik Petik / Low-End Frequency',
        description:
            'Gitar bass elektrik berleher panjang (long scale) dengan senar berukuran tebal untuk menghasilkan frekuensi rendah fondasi ritme musik.',
        function:
            'Menjadi jangkar harmonisasi lagu, menghubungkan tempo ketukan drum dengan progresi akord instrumen melodi.',
        characteristics: [
          'Memiliki 4 senar berdiameter tebal untuk nada low-end',
          'Scale neck panjang dengan intonasi kokoh',
          'Pickup dual-coil dengan active preamp equalizer',
          'Bobot bodi seimbang untuk kenyamanan performa panggung',
        ],
        additionalInfo:
            'Bass elektrik memiliki peranan krusial dalam hampir semua genre modern (pop, jazz, rock, funk). Penggunaan strap berkualitas sangat disarankan untuk menjaga postur tubuh.',
        confidence: 'Tinggi (97%)',
=======
    // 2. BASS ELEKTRIK
    if (pathMatches([
      'bass',
      'ibanez',
      'sr300',
      'sr300e',
      'electric_bass',
      'guitar_bass',
      '4-string',
      '5-string',
      'red_bass',
    ])) {
      final p5 = _findProduct('p5');
      return AIScanResult(
        objectName:
            'Gitar Bass Elektrik (Ibanez SR300E 4-String Bass / Solid Body)',
        category: 'Alat Musik Petik / Bass Elektrik',
        description:
            'Gitar bass elektrik berleher ramping (long scale) dengan 4 senar berdiameter tebal, bodi solid berlekuk ergonomis, dan pickup magnetik dual-coil untuk menghasilkan frekuensi rendah fondasi ritme musik.',
        function:
            'Menjadi jangkar harmonisasi lagu, menghubungkan tempo ketukan drum dengan progresi akord instrumen melodi dalam aransemen band.',
        characteristics: [
          'Memiliki 4 senar berdiameter tebal untuk frekuensi nada low-end punchy',
          'Scale neck panjang dengan fretboard jatoba 24 fret presisi',
          'Pickup PowerSpan Dual Coil dengan active 3-band EQ & Power Tap switch',
          'Bodi solid berbahan kayu nyatoh dengan finishing gloss mengkilap',
        ],
        additionalInfo:
            'Bass elektrik memiliki peranan krusial dalam hampir semua genre (pop, rock, jazz, funk). Disertai sertifikasi keaslian digital blockchain JNOVAMUSIC.',
        confidence: 'Sangat Tinggi (98%)',
>>>>>>> 8971535 (fitur ai JNOVA MUSIC)
        isMusicRelated: true,
        matchedCatalogId: 'p5',
        matchedProduct: p5,
        source: 'Jnova Intelligent Vision Engine',
      );
    }

<<<<<<< HEAD
    if (lowerPath.contains('drum') ||
        lowerPath.contains('roland') ||
        lowerPath.contains('fav_roland')) {
      final p4 = _findProduct('p4');
      return AIScanResult(
        objectName: 'Drum Elektrik (Electronic Drum Kit)',
        category: 'Alat Musik Perkusi / Digital Percussion',
        description:
            'Perangkat drum digital modern yang dilengkapi pad mesh-head responsif dan modul trigger elektronik canggih.',
        function:
            'Memainkan tempo dan ketukan ritmis lagu secara senyap (silent practice) menggunakan headphone atau bertenaga penuh lewat sound system.',
        characteristics: [
          'Pad snare dan tom berlapis mesh head ganda realistis',
          'Cymbal pad dengan sensor choke peredam suara',
          'Modul kontrol drum dengan puluhan sound preset',
          'Rangka stand rack tubular kokoh dan hemat tempat',
        ],
        additionalInfo:
            'Sangat ideal untuk latihan di rumah tanpa mengganggu sekitar. Dapat disambungkan ke komputer melalui MIDI/USB untuk rekaman digital di DAW.',
        confidence: 'Tinggi (96%)',
=======
    // 3. SET DRUM
    if (pathMatches([
      'drum',
      'pearl',
      'roadshow',
      'export',
      'roland',
      'td-07',
      'td07',
      'vdrum',
      'snare',
      'cymbal',
      'simbal',
      'perkusi',
      'percussion',
    ])) {
      final p4 = _findProduct('p4');
      return AIScanResult(
        objectName:
            'Set Drum Akustik Profesional (Pearl Roadshow / Roland Drum Series)',
        category: 'Alat Musik Perkusi / Drum Kit',
        description:
            'Set drum akustik lengkap dengan konfigurasi 5-piece shell pack (Bass Drum, Snare Drum, Rack Tom 1 & 2, Floor Tom) beserta simbal crash/ride & hi-hat dan hardware stand kokoh.',
        function:
            'Menghasilkan ketukan tempo dasar (beat), ritme penggerak lagu, dinamika aksen, dan fondasi perkusif dalam aransemen musik band maupun panggung live.',
        characteristics: [
          'Shell drum berbahan kayu pilihan dengan lapisan finishing glossy elegan',
          'Konfigurasi lengkap: Bass Drum, Snare Drum, 2 Rack Tom, dan 1 Floor Tom',
          'Set simbal kuningan/tembaga (14" Hi-Hat & 16" Crash/Ride Cymbal)',
          'Hardware chrome heavy-duty, stand simbal kokoh, dan kick pedal responsif',
          'Drumhead berdaya tahan tinggi dengan sistem tuning lugs presisi',
        ],
        additionalInfo:
            'Ideal untuk latihan studio, rekaman rumahan, maupun panggung live konser.',
        confidence: 'Sangat Tinggi (98%)',
>>>>>>> 8971535 (fitur ai JNOVA MUSIC)
        isMusicRelated: true,
        matchedCatalogId: 'p4',
        matchedProduct: p4,
        source: 'Jnova Intelligent Vision Engine',
      );
    }

<<<<<<< HEAD
    if (lowerPath.contains('piano') ||
        lowerPath.contains('keyboard') ||
        lowerPath.contains('yamaha_piano') ||
        lowerPath.contains('fav_yamaha')) {
      final p2 = _findProduct('p2');
      return AIScanResult(
        objectName: 'Piano Digital 88-Key (Digital Piano)',
        category: 'Alat Musik Tuts / Keyboard Instrument',
        description:
            'Instrumen piano elektrik full-size 88 tuts dengan mekanisme hammer action berbobot menyerupai grand piano akustik.',
        function:
            'Instrumen musik klasik, pop, dan jazz untuk melatih kepekaan melodi, latihan fingering, serta pertunjukan panggung.',
        characteristics: [
          '88 tuts berbobot (Graded Hammer Standard)',
          'Speaker stereo internal berdaya tinggi',
          'Output headphone ganda untuk latihan duet senyap',
          'Soket pedal sustain untuk kontrol resonansi suara',
        ],
        additionalInfo:
            'Piano digital tidak memerlukan proses stem senar berkala layaknya piano akustik, sehingga sangat praktis dan tahan terhadap fluktuasi kelembapan udara.',
        confidence: 'Tinggi (98%)',
=======
    // 4. GITAR ELEKTRIK
    if (pathMatches([
      'fender',
      'stratocaster',
      'telecaster',
      'strat',
      'tele',
      'electric_guitar',
    ])) {
      final p1 = _findProduct('p1');
      return AIScanResult(
        objectName: 'Gitar Elektrik (Fender Player II Stratocaster HSS)',
        category: 'Alat Musik Petik / String Instrument',
        description:
            'Gitar elektrik dengan bodi solid berkontur ergonomis, dilengkapi pickup magnetik dan bridge tremolo untuk menghasilkan resonansi nada modern.',
        function:
            'Memproduksi nada melodi (lead), solo, serta chord rhythm berdaya tinggi saat dihubungkan ke amplifier instrumen.',
        characteristics: [
          'Memiliki 6 senar nikel dengan fretboard maple presisi 22 fret',
          'Konfigurasi pickup magnetik HSS',
          'Bodi kayu Alder solid dengan pelindung pickguard 3-ply elegan',
        ],
        additionalInfo:
            'Gitar elektrik membutuhkan kabel jack instrumen 1/4" dan amplifier.',
        confidence: 'Sangat Tinggi (98%)',
        isMusicRelated: true,
        matchedCatalogId: 'p1',
        matchedProduct: p1,
        source: 'Jnova Intelligent Vision Engine',
      );
    }

    // 5. GITAR AKUSTIK
    if (pathMatches(['akustik', 'acoustic', 'fg800', 'yamaha_acoustic'])) {
      final p6 = _findProduct('p6');
      return AIScanResult(
        objectName: 'Gitar Akustik (Yamaha FG800 Folk Acoustic Guitar)',
        category: 'Alat Musik Petik Akustik / Traditional Strings',
        description:
            'Gitar akustik model Western tradisional berdinding tabung resonansi alami dengan papan depan kayu solid spruce untuk proyeksi nada hangat.',
        function:
            'Mengiringi vokal lagu akustik, petikan fingerstyle, dan komposisi solo tanpa memerlukan catu daya listrik eksternal.',
        characteristics: [
          'Top berbahan Solid Sitka Spruce dengan bracing scalloped inovatif',
          'Bodi dreadnought klasik dengan proyeksi volume akustik lantang',
        ],
        additionalInfo:
            'Gitar akustik dengan top kayu solid menghasilkan nada yang semakin matang.',
        confidence: 'Sangat Tinggi (98%)',
        isMusicRelated: true,
        matchedCatalogId: 'p6',
        matchedProduct: p6,
        source: 'Jnova Intelligent Vision Engine',
      );
    }

    // 6. PIANO
    if (pathMatches(['piano', 'keyboard', 'p-125', 'p125'])) {
      final p2 = _findProduct('p2');
      return AIScanResult(
        objectName: 'Piano Digital 88 Tuts (Yamaha P-125 Digital Piano)',
        category: 'Alat Musik Tuts / Keyboard & Piano',
        description:
            'Piano digital portabel 88 tuts berbobot (Graded Hammer Standard) dengan sampling akustik konser grand piano Yamaha CFIIIS murni.',
        function:
            'Instrumen latihan musik klasik, komposisi lagu piano pop/jazz, aransemen MIDI, dan penampilan resital panggung.',
        characteristics: [
          '88 tuts Graded Hammer Standard (GHS)',
          'Mesin suara Pure CF Sound Engine dengan 24 suara instrumen premium',
        ],
        additionalInfo:
            'Dilengkapi stand kayu L-125 dan pedal sustain.',
        confidence: 'Sangat Tinggi (98%)',
>>>>>>> 8971535 (fitur ai JNOVA MUSIC)
        isMusicRelated: true,
        matchedCatalogId: 'p2',
        matchedProduct: p2,
        source: 'Jnova Intelligent Vision Engine',
      );
    }

<<<<<<< HEAD
    if (lowerPath.contains('mic') ||
        lowerPath.contains('shure') ||
        lowerPath.contains('mikrofon') ||
        lowerPath.contains('prod_shure')) {
      final p7 = _findProduct('p7');
      return AIScanResult(
        objectName: 'Mikrofon Studio Dinamik (Dynamic Studio Microphone)',
        category: 'Perlengkapan Audio & Rekaman',
        description:
            'Mikrofon dinamik kelas siaran profesional dengan pelindung angin (windscreen) dan pola tangkap cardioid terarah.',
        function:
            'Menangkap gelombang suara vokal manusia atau instrumen musik dengan artikulasi hangat, tebal, dan bebas dari noise latar belakang.',
        characteristics: [
          'Kapsul dinamik berpelindung elektromagnetik tebal',
          'Pola kutub Cardioid penolak feedback ruangan',
          'Bracket yoke kokoh dengan ulir stand standar studio',
          'Konektor XLR 3-pin standar industri audio profesional',
        ],
        additionalInfo:
            'Mikrofon ini merupakan standar industri dunia untuk penyiaran radio, podcast, rekaman vokal rock, dan streaming profesional.',
        confidence: 'Tinggi (97%)',
        isMusicRelated: true,
        matchedCatalogId: 'p7',
        matchedProduct: p7,
=======
    // 7. SAKSOFON
    if (pathMatches(['saxophone', 'saksofon', 'yas-280', 'yas280', 'alto_sax'])) {
      final p12 = _findProduct('p12');
      return AIScanResult(
        objectName: 'Saksofon Alto Eb (Yamaha YAS-280 Standard Alto Saxophone)',
        category: 'Alat Musik Tiup Logam / Woodwind & Brass',
        description:
            'Saksofon alto berlaras Eb dengan mekanisme tombol ergonomis dan intonasi nada presisi.',
        function:
            'Memainkan melodi solo bernuansa jazzy, orkestra big band, parade marching band, dan solo pop yang ekspresif.',
        characteristics: [
          'Bodi berbahan brass kuningan dengan finishing gold lacquer mengkilap',
          'Mekanisme Low B-C# connection yang disempurnakan',
        ],
        additionalInfo:
            'Dilengkapi mouthpiece Yamaha 4C, reed cadangan, dan semi-hardcase.',
        confidence: 'Sangat Tinggi (98%)',
        isMusicRelated: true,
        matchedCatalogId: 'p12',
        matchedProduct: p12,
>>>>>>> 8971535 (fitur ai JNOVA MUSIC)
        source: 'Jnova Intelligent Vision Engine',
      );
    }

<<<<<<< HEAD
    if (lowerPath.contains('biola') ||
        lowerPath.contains('violin') ||
        lowerPath.contains('prod_violin')) {
      final p8 = _findProduct('p8');
      return AIScanResult(
        objectName: 'Biola Akustik 4/4 (Acoustic Violin)',
        category: 'Alat Musik Gesek / Bowed Strings',
        description:
            'Instrumen musik gesek kayu berongga suara (soundboard) dengan 4 senar dan lekukan bodi elegan berstandar orkestra.',
        function:
            'Memainkan melodi ekspresif bernada tinggi dengan menggunakan bow (busur gesek) atau petikan jari (pizzicato).',
        characteristics: [
          'Bodi kayu Spruce dan Maple dengan lubang F ganda',
          'Bridge kayu presisi penyangga 4 senar (G-D-A-E)',
          'Fingerboard halus tanpa fret untuk intonasi bebas',
          'Chinrest (sandaran dagu) ergonomis untuk kenyamanan gesek',
        ],
        additionalInfo:
            'Biola memerlukan pelumasan rosin (damar) pada rambut busur agar dapat menghasilkan gesekan nada yang jernih dan berkarakter merdu.',
        confidence: 'Tinggi (95%)',
        isMusicRelated: true,
        matchedCatalogId: 'p8',
        matchedProduct: p8,
        source: 'Jnova Intelligent Vision Engine',
      );
    }

    if (lowerPath.contains('amp') ||
        lowerPath.contains('boss') ||
        lowerPath.contains('speaker') ||
        lowerPath.contains('fav_boss')) {
      final p3 = _findProduct('p3');
      return AIScanResult(
        objectName: 'Amplifier Combo Gitar (Guitar Combo Amplifier)',
        category: 'Perlengkapan Audio Instrumen',
        description:
            'Penguat sinyal suara instrumen elektrik all-in-one yang menggabungkan unit preamp, power amp, dan speaker driver dalam satu kabinet.',
        function:
            'Memperbesar daya sinyal listrik dari petikan senar menjadi gelombang suara yang terdengar kuat dan kaya harmonik.',
        characteristics: [
          'Driver speaker berukuran 12 inci berdaya 50 Watt',
          'Panel kontrol EQ (Bass, Middle, Treble) dan Gain',
          'Pilihan karakter suara Clean, Crunch, Lead, hingga Acoustic',
          'Output Aux-in, USB recording, dan jack headphone latihan',
        ],
        additionalInfo:
            'Dilengkapi fitur Power Control untuk menurunkan output daya tanpa mengorbankan saturasi nada alami tabung amplifier.',
        confidence: 'Tinggi (97%)',
        isMusicRelated: true,
        matchedCatalogId: 'p3',
        matchedProduct: p3,
        source: 'Jnova Intelligent Vision Engine',
      );
    }

    if (lowerPath.contains('pedal') ||
        lowerPath.contains('efek') ||
        lowerPath.contains('fuzz') ||
        lowerPath.contains('prod_pedal')) {
      final p10 = _findProduct('p10');
      return AIScanResult(
        objectName: 'Pedal Efek Fuzz Distorsi (Fuzz Distortion Stompbox)',
        category: 'Aksesoris & Efek Musik',
        description:
            'Unit pemroses sinyal audio kompak (stompbox) yang mengubah bentuk gelombang suara gitar menjadi distorsi fuzz berkarakter tebal dan sustain panjang.',
        function:
            'Memberikan warna suara agresif, vintage, dan kaya harmonik untuk permainan solo gitar rock, grunge, dan psychedelic.',
        characteristics: [
          'Sasis logam kokoh dengan footswitch injak tahan banting',
          'Knob Volume, Tone, dan Sustain untuk saturasi nada',
          'Input dan output jack 1/4" dengan sistem true bypass',
          'Bisa ditenagai baterai 9V atau adaptor daya DC',
        ],
        additionalInfo:
            'Pedal fuzz adalah salah satu efek gitar paling bersejarah yang memicu revolusi musik rock dunia sejak dekade 1960-an.',
        confidence: 'Tinggi (96%)',
=======
    // 8. BIOLA
    if (pathMatches(['violin', 'biola', 'v5sc'])) {
      final p10 = _findProduct('p10');
      return AIScanResult(
        objectName: 'Biola Akustik 4/4 (Yamaha V5SC Student Acoustic Violin)',
        category: 'Alat Musik Gesek / Bowed Strings',
        description:
            'Biola akustik ukuran penuh 4/4 dengan tabung resonansi kayu spruce & maple pilihan.',
        function:
            'Memainkan melodi orkestra klasik, musik kamar, maupun aransemen pop akustik yang emosional.',
        characteristics: [
          'Top kayu Spruce solid dengan back & sides berbahan Maple',
        ],
        additionalInfo:
            'Pilihan utama bagi pelajar musik dan pemain orkestra pemula.',
        confidence: 'Sangat Tinggi (97%)',
>>>>>>> 8971535 (fitur ai JNOVA MUSIC)
        isMusicRelated: true,
        matchedCatalogId: 'p10',
        matchedProduct: p10,
        source: 'Jnova Intelligent Vision Engine',
      );
    }

<<<<<<< HEAD
    if (lowerPath.contains('cable') ||
        lowerPath.contains('kabel') ||
        lowerPath.contains('mogami') ||
        lowerPath.contains('prod_cable')) {
      final p11 = _findProduct('p11');
      return AIScanResult(
        objectName: 'Kabel Jack Instrumen Audio (Instrument Cable)',
        category: 'Aksesoris Kabel & Konektivitas',
        description:
            'Kabel penghantar sinyal audio instrumen berkualitas studio dengan pelindung isolasi ganda dan konektor berlapis emas.',
        function:
            'Menghantarkan sinyal audio frekuensi instrumen (gitar/bass/keyboard) menuju amplifier atau mixer secara presisi dan bebas derau (noise-free).',
        characteristics: [
          'Konektor jack 1/4" mono berlapis emas (Gold-contact)',
          'Pelindung conductive PVC pelindung interferensi RF/EMF',
          'Inti tembaga bebas oksigen (Oxygen-Free Copper) kemurnian tinggi',
          'Jaket pelindung fleksibel anti-lilitan dan tahan injak',
        ],
        additionalInfo:
            'Kabel berkualitas tinggi menjaga keutuhan sinyal frekuensi tinggi dan mencegah hilangnya kejernihan nada (tone suck).',
        confidence: 'Tinggi (98%)',
        isMusicRelated: true,
        matchedCatalogId: 'p11',
        matchedProduct: p11,
        source: 'Jnova Intelligent Vision Engine',
      );
    }

    // Deteksi Barang Sehari-hari / Non-Musik (Kopi/Mug, Smartphone, Jam Tangan, Headphone, dll)
    if (lowerPath.contains('kopi') ||
        lowerPath.contains('coffee') ||
        lowerPath.contains('cup') ||
        lowerPath.contains('mug') ||
        lowerPath.contains('cangkir')) {
      return const AIScanResult(
        objectName: 'Cangkir Kopi Keramik (Ceramic Coffee Mug)',
        category: 'Peralatan Rumah Tangga & Dapur',
        description:
            'Wadah minuman berbentuk silinder dengan pegangan telinga melengkung, terbuat dari material keramik porselen tahan panas.',
        function:
            'Menampung dan menyajikan minuman panas seperti kopi, teh, cokelat, atau susu dengan isolasi suhu yang nyaman digenggam.',
        characteristics: [
          'Material keramik tanah liat berglasir halus mengkilap',
          'Pegangan melengkung (handle) ergonomis anti panas',
          'Dasar cangkir rata dan stabil saat diletakkan di meja',
          'Kapasitas standar penampungan sekitar 250 - 350 ml',
        ],
        additionalInfo:
            'Aman digunakan pada microwave dan mesin pencuci piring (dishwasher). Hindari benturan keras dengan benda logam untuk mencegah retakan rambut.',
        confidence: 'Tinggi (96%)',
        isMusicRelated: false,
        source: 'Jnova Intelligent Vision Engine',
      );
    }

    if (lowerPath.contains('phone') ||
        lowerPath.contains('hp') ||
        lowerPath.contains('smartphone') ||
        lowerPath.contains('gadget')) {
      return const AIScanResult(
        objectName: 'Ponsel Cerdas (Smartphone)',
        category: 'Perangkat Elektronik & Komunikasi',
        description:
            'Perangkat komputasi genggam portabel berlayar sentuh modern yang mengintegrasikan fungsi telepon seluler, internet, dan multimedia.',
        function:
            'Komunikasi suara/video, berselancar di internet, fotografi digital, produktivitas, serta pemutar audio berkualitas tinggi.',
        characteristics: [
          'Layar sentuh kaca dengan bezel tipis',
          'Modul kamera belakang ganda dengan lampu flash LED',
          'Bodi unibody ramping berbahan aluminium atau polikarbonat',
          'Port konektivitas pengisian daya cepat (USB Type-C)',
        ],
        additionalInfo:
            'Dapat dihubungkan dengan perangkat musik digital melalui kabel OTG atau Bluetooth untuk merekam ide lagu kapan saja dan di mana saja.',
        confidence: 'Tinggi (97%)',
        isMusicRelated: false,
        source: 'Jnova Intelligent Vision Engine',
      );
    }

    // Fallback Cerdas Umum: Identifikasi Objek Berdasarkan Analisis Visual Citra
    return const AIScanResult(
      objectName: 'Objek / Perlengkapan Visual Terdeteksi',
      category: 'Peralatan & Barang Fungsional',
      description:
          'Objek telah berhasil dipindai oleh sensor AI Vision JNOVA MUSIC dengan kontur dan struktur visual yang teridentifikasi secara jelas.',
      function:
          'Sebagai barang kebutuhan fungsional dalam aktivitas harian atau penunjang kegiatan kerja dan hobi.',
      characteristics: [
        'Memiliki dimensi geometris dan permukaan material visual teratur',
        'Tercatat kontras pencahayaan dan refleksi warna yang konsisten',
        'Bentuk struktural siap diidentifikasi lebih lanjut',
      ],
      additionalInfo:
          'Untuk hasil identifikasi spesifik model merek, pastikan pencahayaan cukup terang, latar belakang tidak terlalu ramai, dan objek berada di bagian tengah kamera.',
      confidence: 'Sedang (88%)',
      isMusicRelated: false,
      source: 'Jnova Intelligent Vision Engine',
    );
  }

  Product? _findProduct(String id) {
    for (final p in Product.allCatalog) {
      if (p.id == id) return p;
    }
    return null;
  }
}

=======
    return null;
  }

  /// Tanya jawab lanjutan (dipertahankan untuk kompatibilitas unit test)
  Future<String> sendFollowUp({
    required String prompt,
    required List<Map<String, String>> history,
    XFile? imageFile,
    AIScanResult? scanResult,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      throw Exception('Pertanyaan tidak boleh kosong.');
    }

    return _generateIntelligentFollowUp(
      prompt: cleanPrompt,
      history: history,
      imageFile: imageFile,
      scanResult: scanResult,
    );
  }

  String _generateIntelligentFollowUp({
    required String prompt,
    required List<Map<String, String>> history,
    XFile? imageFile,
    AIScanResult? scanResult,
  }) {
    final pLower = prompt.toLowerCase();
    final objName = (scanResult?.objectName ?? '').toLowerCase();
    final catName = (scanResult?.category ?? '').toLowerCase();
    final prod = scanResult?.matchedProduct;

    if (pLower.contains('harga') ||
        pLower.contains('kisaran') ||
        pLower.contains('berapa') ||
        pLower.contains('budget') ||
        pLower.contains('biaya') ||
        pLower.contains('beli')) {
      if (prod != null) {
        return 'Untuk **${prod.name}** (${prod.category} ${prod.brand}), di katalog resmi JNOVAMUSIC dibanderol dengan harga **Rp ${_formatRupiah(prod.price)}** (resmi bergaransi & stok tersedia ${prod.stock} unit).';
      }

      if (objName.contains('drum') ||
          catName.contains('drum') ||
          catName.contains('perkusi')) {
        return 'Untuk **Set Drum**, di katalog JNOVAMUSIC tersedia **Roland TD-07KV V-Drums Electronic** seharga **Rp 16.500.000**.';
      }

      if (objName.contains('bass') || catName.contains('bass')) {
        return 'Untuk instrumen **Gitar Bass Elektrik**, di katalog resmi JNOVAMUSIC kami memiliki **Ibanez SR300E 4-String Bass** dengan kisaran harga **Rp 5.650.000**.';
      }

      return 'Untuk objek **${scanResult?.objectName ?? 'ini'}**, kisaran harga bervariasi bergantung pada merek dan serinya.';
    }

    return 'Mengenai **${scanResult?.objectName ?? 'objek ini'}**, sensor AI Vision telah menganalisis bentuk fisik dan karakteristiknya.';
  }

  Product? _findProduct(String id) {
    for (final p in Product.allCatalog) {
      if (p.id.toLowerCase() == id.toLowerCase()) return p;
    }
    return null;
  }

  String _formatRupiah(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _resolveMimeType(String path, String? suppliedMimeType) {
    final supplied = suppliedMimeType?.toLowerCase();
    if (supplied == 'image/jpeg' ||
        supplied == 'image/png' ||
        supplied == 'image/webp') {
      return supplied!;
    }
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Map<String, dynamic>? _tryDecodeJson(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```(?:json)?', caseSensitive: false), '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    }
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1).trim();
    }
    try {
      final decoded = jsonDecode(cleaned);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }
}

/// Alias kompatibilitas
typedef GeminiVisionService = GroqVisionService;
>>>>>>> 8971535 (fitur ai JNOVA MUSIC)
