import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../widgets/app_bottom_nav.dart';

class MusicCategoryItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const MusicCategoryItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Halaman PREFERENSI MUSIK & LAGU JNOVAMUSIC sesuai spesifikasi prompt
class MusicPreferencesPage extends StatefulWidget {
  final VoidCallback? onBack;

  const MusicPreferencesPage({super.key, this.onBack});

  @override
  State<MusicPreferencesPage> createState() => _MusicPreferencesPageState();
}

class _MusicPreferencesPageState extends State<MusicPreferencesPage> {
  final Set<String> _selectedCategories = {
    'Gitar & Bass',
    'Audio & Studio',
    'Keyboard & Piano',
  };

  final List<MusicCategoryItem> _categories = const [
    MusicCategoryItem(
      title: 'Gitar & Bass',
      subtitle: 'Akustik, elektrik, bass, pickup & aksesoris',
      icon: Icons.music_note_rounded,
    ),
    MusicCategoryItem(
      title: 'Drum & Perkusi',
      subtitle: 'Akustik drum, electronic v-drums & cymbals',
      icon: Icons.album_outlined,
    ),
    MusicCategoryItem(
      title: 'Keyboard & Piano',
      subtitle: 'Digital piano, synthesizer, MIDI controller',
      icon: Icons.piano_rounded,
    ),
    MusicCategoryItem(
      title: 'Audio & Studio',
      subtitle: 'Audio interface, monitor speakers, headphone',
      icon: Icons.headphones_rounded,
    ),
    MusicCategoryItem(
      title: 'Instrumen Gesek & Tiup',
      subtitle: 'Biola akustik, saxophone, flute & brass',
      icon: Icons.graphic_eq_rounded,
    ),
    MusicCategoryItem(
      title: 'Amplifier & Efek Pedal',
      subtitle: 'Tube amp, digital modeler, distortion pedals',
      icon: Icons.speaker_rounded,
    ),
  ];

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedCategories.length} preferensi musik berhasil disimpan!',
        ),
        backgroundColor: const Color(0xFF1E1A18),
        duration: const Duration(seconds: 2),
      ),
    );
    _handleBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Konten Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubHeader(),

                      const SizedBox(height: 14),

                      // Info Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF9F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEBE8E3)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pilih kategori instrumen dan musik favorit Anda untuk mendapatkan rekomendasi produk yang lebih personal di katalog JNOVAMUSIC.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF5A524D),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Daftar Kartu Pilihan
                      ..._categories.map((cat) {
                        final isSelected = _selectedCategories.contains(
                          cat.title,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedCategories.remove(cat.title);
                                } else {
                                  _selectedCategories.add(cat.title);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFFBF7)
                                    : const Color(0xFFFAF9F7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : const Color(0xFFEBE8E3),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFFEDDF)
                                          : const Color(0xFFEDEBE7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      cat.icon,
                                      size: 18,
                                      color: isSelected
                                          ? AppColors.primaryOrange
                                          : const Color(0xFF5A524D),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat.title,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimaryDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          cat.subtitle,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            color: Color(0xFF7E756F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primaryOrange
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryOrange
                                            : const Color(0xFFD4D0C8),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Tombol Simpan
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Simpan Preferensi Musik',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

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
        currentIndex: 4,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/favorite');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/all-products');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/games');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/order-detail');
          } else if (index == 4) {
            _handleBack();
          }
        },
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F0ED), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/soundwave_loader.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            color: const Color(0xFF4A403A),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFB45309),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F0ED), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F4),
                shape: BoxShape.circle,
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
                  'Preferensi Musik & Lagu',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  'Pilih genre dan kategori instrumen favorit Anda.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
