import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:jnova/core/constants/app_colors.dart';
import 'package:jnova/core/utils/currency_formatter.dart';
import 'package:jnova/models/ai_scan_result.dart';
import 'package:jnova/models/product.dart';
import 'package:jnova/screens/product/product_detail_screen.dart';
import 'package:jnova/services/gemini_vision_service.dart';

/// Halaman Fitur AI Object Scanner JNOVA MUSIC
/// Terintegrasi langsung dengan Groq Vision (Llama 3.2 Vision) & Google Gemini Multimodal.
class AIScannerPage extends StatefulWidget {
  const AIScannerPage({super.key});

  @override
  State<AIScannerPage> createState() => _AIScannerPageState();
}

class _AIScannerPageState extends State<AIScannerPage>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final GroqVisionService _visionService = GroqVisionService.instance;

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
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 75,
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

    // Pastikan sistem AI online aktif
    final hasKey = await _visionService.hasActiveOnlineKey();
    if (!hasKey) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Layanan AI Vision sedang dalam pemeliharaan. Silakan coba sesaat lagi.',
          ),
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
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
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

              // 2. Area Gambar / Preview / Kamera
              _buildImageSection(),

              const SizedBox(height: 16),

              // 3. Tombol Aksi Utama (Scan dengan AI / Ganti Gambar)
              _buildActionButtons(),

              // 4. Pesan Error Jika Ada
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _buildErrorCard(),
              ],

              // 5. Kartu Hasil Scan Lengkap & Detail (Semua Objek)
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
      title: const Text(
        'AI Object Scanner',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1E1E1E),
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Info AI Vision',
          icon: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryOrange,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'AI Vision pintar siap mengenali objek secara otomatis.',
                ),
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: const Color(0xFFEEEEEE), height: 1.0),
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
                  'Ambil foto atau unggah gambar objek apa saja. AI akan mengenali nama, kategori, fungsi, dan karakteristik visualnya secara akurat.',
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

  Widget _buildImageSection() {
    if (_imageBytes == null) {
      return Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
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
              'Buka kamera atau unggah gambar benda apa saja dari galeri Anda',
              style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Kamera',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(
                    Icons.photo_library_rounded,
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                  label: const Text(
                    'Galeri',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primaryOrange,
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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
          color: _isScanning
              ? AppColors.primaryOrange
              : const Color(0xFFE0E0E0),
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
              child: Image.memory(_imageBytes!, fit: BoxFit.contain),
            ),

            // Efek Animasi Laser / Scanner Radar saat sedang menganalisis
            if (_isScanning) ...[
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

              // Overlay status proses
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryOrange.withValues(alpha: 0.6),
                    ),
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
                        'Mengambil data AI Vision dari internet...',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
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
              disabledBackgroundColor: AppColors.primaryOrange.withValues(
                alpha: 0.6,
              ),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                        'Sedang Menganalisis via Internet...',
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
                onPressed: _isScanning
                    ? null
                    : () => _pickImage(ImageSource.camera),
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  size: 15,
                  color: Color(0xFF4A4A4A),
                ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isScanning
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                icon: const Icon(
                  Icons.photo_library_outlined,
                  size: 15,
                  color: Color(0xFF4A4A4A),
                ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEA580C),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF9A3412),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: const Text(
                'Coba Scan Lagi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= KARTU HASIL IDENTIFIKASI LENGKAP =================

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
          // Header: Status Kepercayaan & Sumber AI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD5B8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: AppColors.primaryOrange,
                    ),
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
              Expanded(
                child: Text(
                  result.source ?? 'AI Vision (Internet Online)',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                  ),
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

          const SizedBox(height: 6),

          // Kategori Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE8E8EC)),
            ),
            child: Text(
              result.category,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF444444),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Divider halus
          Container(height: 1, color: const Color(0xFFF0F0F0)),

          const SizedBox(height: 14),

          // 1. Deskripsi Objek Lengkap
          _buildInfoSection(
            icon: Icons.description_outlined,
            title: 'Deskripsi Objek',
            content: result.description,
          ),

          const SizedBox(height: 14),

          // 2. Fungsi & Kegunaan Utama
          _buildInfoSection(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Fungsi & Kegunaan',
            content: result.function,
          ),

          const SizedBox(height: 14),

          // 3. Karakteristik & Ciri Utama
          if (result.characteristics.isNotEmpty) ...[
            _buildCharacteristicsSection(result.characteristics),
            const SizedBox(height: 14),
          ],

          // 4. Informasi Tambahan & Tips
          _buildInfoSection(
            icon: Icons.info_outline_rounded,
            title: 'Informasi Tambahan & Tips',
            content: result.additionalInfo,
          ),

          // 5. Rekomendasi Produk Katalog jika relevan
          if (result.matchedProduct != null) ...[
            const SizedBox(height: 16),
            _buildCatalogProductRecommendation(result.matchedProduct!),
          ] else ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 15,
                    color: AppColors.primaryOrange,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Objek berhasil dianalisis secara langsung dari internet dengan AI Vision Multimodal.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            Icon(
              Icons.check_circle_outline_rounded,
              size: 14,
              color: AppColors.primaryOrange,
            ),
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
                  child: Icon(
                    Icons.circle,
                    size: 5,
                    color: AppColors.primaryOrange,
                  ),
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
              Icon(
                Icons.storefront_rounded,
                size: 14,
                color: AppColors.primaryOrange,
              ),
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
                      builder: (context) =>
                          ProductDetailScreen(product: product),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Lihat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

typedef AIScannerScreen = AIScannerPage;

