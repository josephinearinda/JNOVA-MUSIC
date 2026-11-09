import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/utils/currency_formatter.dart';
import '../models/ai_scan_result.dart';
import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../services/gemini_vision_service.dart';

/// Halaman Fitur AI Object Scanner JNOVA MUSIC
/// Terintegrasi dengan Gemini Vision Multimodal & Mesin Cerdas JNOVA
class AIScannerPage extends StatefulWidget {
  const AIScannerPage({super.key});

  @override
  State<AIScannerPage> createState() => _AIScannerPageState();
}

class _AIScannerPageState extends State<AIScannerPage>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final GeminiVisionService _visionService = GeminiVisionService.instance;
  final SecureStorageService _storage = SecureStorageService.instance;

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isScanning = false;
  AIScanResult? _scanResult;
  String? _errorMessage;

  // Animasi Laser Scanner
  late AnimationController _scanAnimController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    super.dispose();
  }

  // ================= PILIH GAMBAR =================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1440,
        maxHeight: 1440,
        imageQuality: 88,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = picked;
        _imageBytes = bytes;
        _scanResult = null;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengakses kamera/galeri: ${e.toString()}';
      });
    }
  }

  // Pilih preset bawaan untuk kemudahan testing (terutama pada Android Emulator)
  Future<void> _loadPresetSample({
    required String assetPath,
    required String label,
  }) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      final tempFile = XFile.fromData(
        bytes,
        name: '$label.png',
        mimeType: 'image/png',
      );

      setState(() {
        _selectedImage = tempFile;
        _imageBytes = bytes;
        _scanResult = null;
        _errorMessage = null;
      });

      // Beri haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat preset gambar: $e';
      });
    }
  }

  // ================= PROSES SCAN DENGAN AI =================

  Future<void> _startScan() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih atau ambil gambar terlebih dahulu.'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _scanResult = null;
    });

    _scanAnimController.repeat(reverse: true);

    try {
      final result = await _visionService.analyzeImage(_selectedImage!);
      if (!mounted) return;

      setState(() {
        _scanResult = result;
        _isScanning = false;
      });
      _scanAnimController.stop();
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage =
            'Proses scan AI mengalami kendala: ${e.toString().replaceAll('Exception:', '').trim()}';
      });
      _scanAnimController.stop();
    }
  }

  void _resetScan() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _scanResult = null;
      _errorMessage = null;
      _isScanning = false;
    });
    _scanAnimController.stop();
  }

  // ================= PENGATURAN API KEY GEMINI =================

  void _showApiKeyDialog() async {
    final activeKey = await _visionService.getActiveApiKey();
    final customKey = await _storage.getCustomGeminiApiKey();
    final textController = TextEditingController(text: customKey ?? '');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: AppColors.primaryOrange, size: 24),
            SizedBox(width: 8),
            Text(
              'Status AI Vision',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        activeKey != null
                            ? 'Gemini 1.5 Multimodal Aktif'
                            : 'Engine Visi Cerdas JNOVA Siap',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'AI Scanner menggunakan model Gemini Multimodal untuk menganalisis gambar secara real-time. Jika kuota API habis, mesin visi cerdas internal JNOVA siap mengenali instrumen dan barang secara otomatis tanpa limit.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF5A524D), height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'Custom Gemini API Key (Opsional):',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: textController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryOrange),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (customKey != null && customKey.isNotEmpty)
            TextButton(
              onPressed: () async {
                await _storage.saveCustomGeminiApiKey(null);
                if (!mounted) return;
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key kustom telah dihapus.')),
                );
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final val = textController.text.trim();
              await _storage.saveCustomGeminiApiKey(val.isEmpty ? null : val);
              if (!mounted) return;
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengaturan API Key disimpan.')),
              );
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ================= BUILD UI UTAMA =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Info Banner
              _buildIntroBanner(),

              const SizedBox(height: 16),

              // 2. Chip Preset Pengujian Cepat
              _buildPresetTestingBar(),

              const SizedBox(height: 16),

              // 3. Area Gambar / Preview / Kamera
              _buildImageSection(),

              const SizedBox(height: 16),

              // 4. Tombol Aksi Utama (Scan dengan AI / Ganti Gambar)
              _buildActionButtons(),

              // 5. Pesan Error Jika Ada
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _buildErrorCard(),
              ],

              // 6. Kartu Hasil Scan
              if (_scanResult != null) ...[
                const SizedBox(height: 20),
                _buildResultCard(_scanResult!),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WIDGET HELPER =================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E1E1E)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Object Scanner',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1E1E),
              letterSpacing: -0.2,
            ),
          ),
          Text(
            'Vision Multimodal & Object Recognition',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7E7E7E),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Status & Pengaturan AI',
          icon: const Icon(Icons.info_outline_rounded, color: AppColors.primaryOrange),
          onPressed: _showApiKeyDialog,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: const Color(0xFFEEEEEE),
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9F5), Color(0xFFFDEEE3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE2CF), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_enhance_rounded,
              color: AppColors.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identifikasi Pintar AI Vision',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ambil foto atau unggah gambar instrumen musik maupun barang sehari-hari. AI akan mengenali nama, kategori, fungsi, dan karakteristik visualnya.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6E6E6E),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTestingBar() {
    final presets = [
      {'label': 'Gitar Akustik', 'icon': '🎸', 'asset': 'assets/images/prod_yamaha_acoustic.png'},
      {'label': 'Piano Digital', 'icon': '🎹', 'asset': 'assets/images/prod_piano.png'},
      {'label': 'Biola Klasik', 'icon': '🎻', 'asset': 'assets/images/prod_violin.png'},
      {'label': 'Mic Shure', 'icon': '🎙️', 'asset': 'assets/images/prod_shure.png'},
      {'label': 'Saxophone', 'icon': '🎷', 'asset': 'assets/images/prod_sax.png'},
      {'label': 'Gitar Fender', 'icon': '⚡', 'asset': 'assets/images/product_fender.png'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.touch_app_rounded, size: 14, color: AppColors.primaryOrange),
            SizedBox(width: 4),
            Text(
              'Uji Cepat Sampel Objek (Emulator / Cepat):',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: presets.map((preset) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: Text(preset['icon']!, style: const TextStyle(fontSize: 12)),
                  label: Text(
                    preset['label']!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                  ),
                  backgroundColor: const Color(0xFFF8F8F8),
                  side: const BorderSide(color: Color(0xFFE5E5E5)),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: _isScanning
                      ? null
                      : () => _loadPresetSample(
                            assetPath: preset['asset']!,
                            label: preset['label']!,
                          ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    if (_imageBytes == null) {
      // Tampilan Belum Ada Gambar
      return Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                size: 38,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada objek yang dipilih',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Buka kamera atau unggah gambar dari galeri Anda',
              style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  label: const Text('Kamera', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 16, color: AppColors.primaryOrange),
                  label: const Text('Galeri', style: TextStyle(fontSize: 12, color: AppColors.primaryOrange, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryOrange, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Tampilan Gambar yang Dipilih + Efek Animasi Scanning
    return Container(
      width: double.infinity,
      height: 270,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isScanning ? AppColors.primaryOrange : const Color(0xFFE0E0E0),
          width: _isScanning ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gambar Utama
            Positioned.fill(
              child: Image.memory(
                _imageBytes!,
                fit: BoxFit.contain,
              ),
            ),

            // Efek Animasi Laser / Scanner Radar saat sedang menganalisis
            if (_isScanning) ...[
              // Efek scan line vertikal
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: _scanAnimation.value * 230,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF5500),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Overlay semi-transparan status
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'AI Vision menganalisis objek...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Badge status selesai scan
            if (!_isScanning && _scanResult != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Teridentifikasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_imageBytes == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Tombol Utama "Scan dengan AI"
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isScanning ? null : _startScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              disabledBackgroundColor: AppColors.primaryOrange.withValues(alpha: 0.6),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isScanning
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Sedang Menganalisis...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Scan dengan AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 10),

        // Pilihan Ganti Gambar / Scan Ulang
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isScanning ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 15, color: Color(0xFF4A4A4A)),
                label: const Text(
                  'Foto Ulang',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD6D6D6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isScanning ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 15, color: Color(0xFF4A4A4A)),
                label: const Text(
                  'Pilih Lainnya',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD6D6D6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Hapus Gambar',
              onPressed: _isScanning ? null : _resetScan,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF888888)),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFFB91C1C),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= KARTU HASIL IDENTIFIKASI =================

  Widget _buildResultCard(AIScanResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE2CF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5500).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status Kepercayaan & Sumber
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD5B8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 12, color: AppColors.primaryOrange),
                    const SizedBox(width: 4),
                    Text(
                      result.confidence,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                result.source ?? 'AI Vision',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Nama Objek
          Text(
            result.objectName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1E1E),
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 4),

          // Kategori Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              result.category,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF555555),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Divider halus
          Container(height: 1, color: const Color(0xFFF0F0F0)),

          const SizedBox(height: 14),

          // Deskripsi
          _buildInfoSection(
            icon: Icons.description_outlined,
            title: 'Deskripsi Objek',
            content: result.description,
          ),

          const SizedBox(height: 14),

          // Fungsi & Kegunaan
          _buildInfoSection(
            icon: Icons.build_circle_outlined,
            title: 'Fungsi & Kegunaan',
            content: result.function,
          ),

          const SizedBox(height: 14),

          // Karakteristik & Ciri Utama
          if (result.characteristics.isNotEmpty) ...[
            _buildCharacteristicsSection(result.characteristics),
            const SizedBox(height: 14),
          ],

          // Informasi Tambahan
          _buildInfoSection(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Informasi Tambahan',
            content: result.additionalInfo,
          ),

          // Rekomendasi Katalog JNOVA (Jika relevan dengan alat musik)
          if (result.matchedProduct != null) ...[
            const SizedBox(height: 16),
            _buildCatalogProductRecommendation(result.matchedProduct!),
          ],

          const SizedBox(height: 16),

          // Tombol Tindakan Lanjut: Tanya AI Chatbot
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/ai-chat');
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primaryOrange),
              label: const Text(
                'Tanyakan Lebih Lanjut ke AI Chatbot',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryOrange, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primaryOrange),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF222222),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          content,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF4E4E4E),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacteristicsSection(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.primaryOrange),
            SizedBox(width: 6),
            Text(
              'Ciri & Karakteristik Utama',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF222222),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5.0, right: 8.0),
                  child: Icon(Icons.circle, size: 5, color: AppColors.primaryOrange),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF4E4E4E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCatalogProductRecommendation(Product product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFDEC7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storefront_rounded, size: 14, color: AppColors.primaryOrange),
              SizedBox(width: 6),
              Text(
                'Tersedia di Katalog JNOVA MUSIC',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Gambar Produk
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Image.asset(
                  product.image,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Icon(
                    Icons.music_note,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nama & Harga
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(product.price),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Lihat Produk
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(product: product),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Lihat',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
