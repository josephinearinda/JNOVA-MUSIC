import 'package:flutter/material.dart';

import 'package:jnova/core/constants/app_colors.dart';
import 'package:jnova/services/currency_service.dart';
import 'package:jnova/widgets/app_bottom_nav.dart';

/// Halaman PREFERENSI MATA UANG JNOVAMUSIC sesuai desain Figma 7
class CurrencyPreferencesPage extends StatefulWidget {
  final VoidCallback? onBack;

  const CurrencyPreferencesPage({super.key, this.onBack});

  @override
  State<CurrencyPreferencesPage> createState() =>
      _CurrencyPreferencesPageState();
}

class _CurrencyPreferencesPageState extends State<CurrencyPreferencesPage> {
  final CurrencyService _currencyService = CurrencyService.instance;
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = _currencyService.selectedCurrency;
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

  void _handleSave() {
    _currencyService.setCurrency(_selectedCurrency);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preferensi mata uang $_selectedCurrency berhasil disimpan.',
        ),
        backgroundColor: const Color(
          0xFF1E1A18,
        ), // Warna latar pesan pemberitahuan pada bagian komponen ini
        duration: const Duration(seconds: 2),
      ),
    );
    _handleBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // Warna latar kotak untuk "Preferensi mata uang $_selectedCurr..."
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
                      // Sub Header
                      _buildSubHeader(),

                      const SizedBox(height: 14),

                      // Pilihan Mata Uang: IDR, USD, EUR
                      _buildCurrencyOption(
                        code: 'IDR',
                        title: 'Rupiah Indonesia (Rp)',
                        example: 'Contoh: Rp1.650.000',
                        color: AppColors.primaryOrange,
                        isSelected: _selectedCurrency == 'IDR',
                        onTap: () {
                          setState(() => _selectedCurrency = 'IDR');
                          _currencyService.setCurrency('IDR');
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildCurrencyOption(
                        code: 'USD',
                        title: 'Dolar Amerika (\$)',
                        example: 'Contoh: \$99.00',
                        color: const Color(
                          0xFF5A524D,
                        ), // Warna visual pada bagian komponen ini
                        isSelected: _selectedCurrency == 'USD',
                        onTap: () {
                          setState(() => _selectedCurrency = 'USD');
                          _currencyService.setCurrency('USD');
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildCurrencyOption(
                        code: 'EUR',
                        title: 'Euro (€)',
                        example: 'Contoh: €92.00',
                        color: const Color(
                          0xFF5A524D,
                        ), // Warna visual pada bagian komponen ini
                        isSelected: _selectedCurrency == 'EUR',
                        onTap: () {
                          setState(() => _selectedCurrency = 'EUR');
                          _currencyService.setCurrency('EUR');
                        },
                      ),

                      const SizedBox(height: 14),

                      // Card Preview Tampilan Katalog
                      _buildCatalogPreviewCard(),

                      const SizedBox(height: 14),

                      // Card Info Regulasi & Status Kurs
                      _buildInfoAndRegulationCard(),

                      const SizedBox(height: 20),

                      // Tombol Simpan Preferensi
                      _buildSaveButton(),

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
        currentIndex: 4, // Profil aktif
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
        color: AppColors
            .white, // Warna border atau garis tepi untuk "/order-detail"
        border: Border(
          bottom: BorderSide(
            color: Color(
              0xFFF2F0ED,
            ), // Warna border atau garis tepi untuk "/order-detail"
            width: 1.0,
          ),
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
                  color:
                      AppColors.primaryOrange, // Warna ikon ikon untuk "Profil"
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark, // Warna teks pada "Profil"
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            color: const Color(
              0xFF4A403A,
            ), // Warna ikon ikon untuk "/notifications"
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(
                0xFFB45309,
              ), // Warna ikon ikon untuk "/notifications"
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 17,
              color: Colors.white, // Warna ikon ikon untuk "/notifications"
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
        color: AppColors
            .white, // Warna border atau garis tepi untuk "/notifications"
        border: Border(
          bottom: BorderSide(
            color: Color(
              0xFFF2F0ED,
            ), // Warna border atau garis tepi untuk "/notifications"
            width: 1.0,
          ),
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
                color: const Color(
                  0xFFF7F6F4,
                ), // Warna border atau garis tepi untuk "/notifications"
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(
                    0xFFEBE8E3,
                  ), // Warna ikon ikon untuk "/notifications"
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors
                    .textPrimaryDark, // Warna ikon ikon untuk "/notifications"
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferensi Mata Uang',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark, // Warna teks pada "Preferensi Mata Uang"
                  ),
                ),
                Text(
                  'Pilih mata uang untuk menampilkan harga produk.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8E837D), // Warna ikon ikon untuk "Pilih mata uang untuk menampilkan h..."
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.help_outline_rounded,
            size: 18,
            color: Color(
              0xFF8E837D,
            ), // Warna ikon ikon untuk "Pilih mata uang untuk menampilkan h..."
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyOption({
    required String code,
    required String title,
    required String example,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(
                  0xFFFFFBF7,
                ) // Warna latar kotak atau kartu pada bagian komponen ini
              : const Color(
                  0xFFFAF9F7,
                ), // Warna border atau garis tepi bagian komponen ini
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors
                      .primaryOrange // Warna border atau garis tepi bagian komponen ini
                : const Color(
                    0xFFEBE8E3,
                  ), // Warna border atau garis tepi bagian komponen ini
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors
                          .primaryOrange // Warna latar kotak atau kartu pada bagian komponen ini
                    : const Color(
                        0xFFEDEBE7,
                      ), // Warna teks pada bagian komponen ini
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? Colors
                              .white // Warna teks pada bagian komponen ini
                        : const Color(
                            0xFF4A403A,
                          ), // Warna teks pada bagian komponen ini
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark, // Warna teks pada bagian komponen ini
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    example,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(
                        0xFF7E756F,
                      ), // Warna teks pada bagian komponen ini
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors
                            .primaryOrange // Warna border atau garis tepi bagian komponen ini
                      : const Color(
                          0xFFD4D0C8,
                        ), // Warna border atau garis tepi bagian komponen ini
                  width: isSelected ? 5.0 : 1.5,
                ),
                color: Colors
                    .white, // Warna border atau garis tepi bagian komponen ini
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogPreviewCard() {
    final formattedPrice = CurrencyService.formatPrice(
      1650000,
      _selectedCurrency,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7), // Warna border atau garis tepi kartu
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEBE8E3), // Warna border atau garis tepi kartu
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(
                0xFFFFEDDF,
              ), // Warna ikon ikon untuk "TAMPILAN KATALOG"
            ),
            child: const Icon(
              Icons.remove_red_eye_outlined,
              size: 16,
              color: AppColors
                  .primaryOrange, // Warna ikon ikon untuk "TAMPILAN KATALOG"
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TAMPILAN KATALOG',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(
                      0xFF8E837D,
                    ), // Warna teks pada "TAMPILAN KATALOG"
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  formattedPrice,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(
                      0xFF7C2D12,
                    ), // Warna teks pada "TAMPILAN KATALOG"
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBE7), // Warna latar kotak atau kartu untuk "$_selectedCurrency Aktif"
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$_selectedCurrency Aktif',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(
                  0xFF5A524D,
                ), // Warna teks pada "$_selectedCurrency Aktif"
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoAndRegulationCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFAF9F7,
        ), // Warna border atau garis tepi untuk "$_selectedCurrency Aktif"
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(
            0xFFEBE8E3,
          ), // Warna border atau garis tepi untuk "$_selectedCurrency Aktif"
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Color(
                  0xFFB45309,
                ), // Warna ikon ikon untuk "$_selectedCurrency Aktif"
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mata uang yang dipilih digunakan untuk menampilkan estimasi harga produk di seluruh katalog aplikasi. Nilai konversi mengikuti kurs harian yang tersedia secara real-time dari backend service.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(
                      0xFF5A524D,
                    ), // Warna teks pada "$_selectedCurrency Aktif"
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Inner card Catatan Transaksi
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white, // Warna border atau garis tepi untuk "$_selectedCurrency Aktif"
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFEBE8E3), // Warna border atau garis tepi untuk "$_selectedCurrency Aktif"
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 13,
                      color: Color(
                        0xFF7E756F,
                      ), // Warna ikon ikon untuk "CATATAN TRANSAKSI"
                    ),
                    SizedBox(width: 5),
                    Text(
                      'CATATAN TRANSAKSI',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Color(
                          0xFF7E756F,
                        ), // Warna teks pada "CATATAN TRANSAKSI"
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3),
                Text(
                  'Transaksi Checkout dan pembayaran akhir tetap diproses dalam IDR (Rupiah) sesuai regulasi gerbang pembayaran nasional.',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(
                      0xFF6E6560,
                    ), // Warna teks pada "CATATAN TRANSAKSI"
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 5,
                    color: Color(
                      0xFF16A34A,
                    ), // Warna ikon ikon untuk "Status Kurs: Terkoneksi"
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Status Kurs: Terkoneksi',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(
                        0xFF15803D,
                      ), // Warna teks pada "Status Kurs: Terkoneksi"
                    ),
                  ),
                ],
              ),
              Text(
                'Bank Indonesia • 10m lalu',
                style: TextStyle(
                  fontSize: 8.5,
                  color: Color(
                    0xFF8E837D,
                  ), // Warna teks pada "Bank Indonesia • 10m lalu"
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange, // Warna visual pada tombol
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check,
              size: 16,
              color: Colors.white, // Warna ikon ikon untuk "Simpan Preferensi"
            ),
            SizedBox(width: 6),
            Text(
              'Simpan Preferensi',
              style: TextStyle(
                color: Colors.white, // Warna teks pada "Simpan Preferensi"
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef CurrencyPreferencesScreen = CurrencyPreferencesPage;
