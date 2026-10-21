import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman SARAN DAN KESAN JNOVAMUSIC sesuai desain Figma (figma_slice_11_905x782.png)
class SuggestionReviewPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SuggestionReviewPage({super.key, this.onBack});

  @override
  State<SuggestionReviewPage> createState() => _SuggestionReviewPageState();
}

class _SuggestionReviewPageState extends State<SuggestionReviewPage> {
  final UserProfileService _profileService = UserProfileService.instance;
  final TextEditingController _feedbackController = TextEditingController();

  // 0: Saran, 1: Kesan, 2: Kritik
  int _selectedTypeIndex = 0;
  int _rating = 0; // 0: Belum dinilai, 1..5
  bool _simulateServerError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _profileService.addListener(_handleProfileChanged);
    _feedbackController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _profileService.removeListener(_handleProfileChanged);
    _feedbackController.dispose();
    super.dispose();
  }

  void _handleProfileChanged() {
    if (mounted) setState(() {});
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return '1 / 5 (Kurang)';
      case 2:
        return '2 / 5 (Cukup)';
      case 3:
        return '3 / 5 (Baik)';
      case 4:
        return '4 / 5 (Sangat Baik)';
      case 5:
        return '5 / 5 (Luar Biasa!)';
      default:
        return 'Belum dinilai';
    }
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tulis pesan masukan Anda terlebih dahulu.'),
          backgroundColor: Color(0xFFC2410C),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulasi delay jaringan
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    if (_simulateServerError) {
      setState(() => _isSubmitting = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 8),
              Text(
                'Gangguan Server',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          content: const Text(
            'Pengiriman masukan gagal karena simulasi gangguan server aktif. Matikan sakelar simulasi untuk mengirim secara normal.',
            style: TextStyle(fontSize: 12, color: Color(0xFF5A524D)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Tutup',
                style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = false;
      _feedbackController.clear();
      _rating = 0;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
            SizedBox(width: 8),
            Text(
              'Masukan Terkirim!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ],
        ),
        content: const Text(
          'Terima kasih atas masukan tulus Anda. Tim kurator & layanan pelanggan JNOVAMUSIC akan meninjau saran Anda untuk penyempurnaan layanan.',
          style: TextStyle(fontSize: 12, color: Color(0xFF5A524D)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleBack();
            },
            child: const Text(
              'Kembali ke Profil',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profileService.profile;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sub Header
                      _buildSubHeader(),

                      const SizedBox(height: 12),

                      // Card Banner: Suara Anda Berarti Bagi Kami
                      _buildHeaderBanner(),

                      const SizedBox(height: 14),

                      // Formulir Saran dan Kesan
                      _buildFeedbackForm(profile),

                      const SizedBox(height: 14),

                      // Footer JNOVAMUSIC Care
                      _buildFooterCare(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4, // Profil tab aktif
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/favorite');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/all-products');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/membership-settings');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/order-detail');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F0ED), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: _handleBack,
                child: const Row(
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.textPrimaryDark,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Profil',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF8D4315),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        children: [
          InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F3EF),
                border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saran dan Kesan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  'JNOVAMUSIC FEEDBACK',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF8E837D),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Kritik dan saran Anda sangat membantu kami dalam menyempurnakan kurasi dan layanan musisi.',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F3EF),
                border: Border.all(color: const Color(0xFFE8E5DF)),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                size: 15,
                color: Color(0xFF6E6560),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD8BF), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
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
                  'Suara Anda Berarti Bagi Kami',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bantu JNOVAMUSIC menyempurnakan kurasi alat musik akustik, elektrik, dan studio audio dengan berbagi ulasan tulus Anda.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6E6560),
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

  Widget _buildFeedbackForm(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Jenis Masukan
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jenis Masukan *',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                'Pilih salah satu',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF8E837D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Chips Jenis Masukan (Saran, Kesan, Kritik)
          Row(
            children: [
              Expanded(
                child: _buildTypeChip(
                  index: 0,
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Saran',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeChip(
                  index: 1,
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  label: 'Kesan',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTypeChip(
                  index: 2,
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Kritik',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row Pesan Masukan
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pesan Masukan *',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                'Detail & jujur',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF8E837D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Textarea Masukan
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEBE8E3)),
            ),
            child: TextField(
              controller: _feedbackController,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textPrimaryDark,
                height: 1.35,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(12),
                hintText:
                    'Tulis saran, kesan, atau kritikmu tentang JNOVAMUSIC (misal: pengemasan gitar akustik, respon teknisi, atau ketersediaan stok synths)...',
                hintStyle: TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF9E958F),
                  height: 1.35,
                ),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0, right: 2.0),
              child: Text(
                '${_feedbackController.text.length}/500',
                style: const TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF8E837D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Rating Pengalaman
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rating Pengalaman (Opsional)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                _ratingLabel,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: _rating > 0
                      ? AppColors.primaryOrange
                      : const Color(0xFF8E837D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Star Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEBE8E3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isSelected = starIndex <= _rating;
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (_rating == starIndex) {
                        _rating = 0; // Toggle off
                      } else {
                        _rating = starIndex;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      isSelected
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 28,
                      color: isSelected
                          ? const Color(0xFFF58A45)
                          : const Color(0xFFD4CFC9),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Identitas Pengirim
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8D4315),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Dikirim sebagai: ',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6E6560),
                        ),
                      ),
                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDDF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${profile.tier} Member',
                          style: const TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC2410C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Simulasi Gangguan Server Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEBE8E3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 15,
                  color: Color(0xFF6E6560),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Simulasi Gangguan Server',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5A524D),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: _simulateServerError,
                    onChanged: (val) {
                      setState(() => _simulateServerError = val);
                    },
                    activeThumbColor: AppColors.primaryOrange,
                    activeTrackColor: AppColors.primaryOrange.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tombol Kirim Masukan
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isSubmitting ? null : _submitFeedback,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 15, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Kirim Masukan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTypeIndex == index;

    return InkWell(
      onTap: () {
        setState(() => _selectedTypeIndex = index);
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEDDF) : const Color(0xFFFAF9F7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOrange
                : const Color(0xFFEBE8E3),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColors.primaryOrange
                  : const Color(0xFF6E6560),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryOrange
                    : const Color(0xFF5A524D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterCare() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.headset_mic_outlined,
            size: 14,
            color: Color(0xFF8E837D),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukan Anda akan ditinjau secara langsung oleh tim layanan pelanggan JNOVAMUSIC.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF8E837D),
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'JNOVAMUSIC Care © 2024',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB0AAA4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
