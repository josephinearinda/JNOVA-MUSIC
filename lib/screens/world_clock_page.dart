import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../widgets/app_bottom_nav.dart';

/// Halaman JAM DUNIA JNOVAMUSIC sesuai desain Figma 7
class WorldClockPage extends StatefulWidget {
  final VoidCallback? onBack;

  const WorldClockPage({super.key, this.onBack});

  @override
  State<WorldClockPage> createState() => _WorldClockPageState();
}

class _WorldClockPageState extends State<WorldClockPage> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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

  String _formatTime(DateTime time, {int offsetHours = 0}) {
    final utc = time.toUtc();
    final adjusted = utc.add(
      Duration(hours: 7 + offsetHours),
    ); // Base UTC+7 (WIB)
    final h = adjusted.hour.toString().padLeft(2, '0');
    final m = adjusted.minute.toString().padLeft(2, '0');
    final s = adjusted.second.toString().padLeft(2, '0');
    return '$h.$m.$s';
  }

  String _formatDate(DateTime time, {int offsetHours = 0}) {
    final utc = time.toUtc();
    final adjusted = utc.add(Duration(hours: 7 + offsetHours));

    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dayName = days[adjusted.weekday - 1];
    final monthName = months[adjusted.month - 1];
    return '$dayName, ${adjusted.day} $monthName ${adjusted.year}';
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
                      // Sub Header
                      _buildSubHeader(),

                      const SizedBox(height: 12),

                      // Status NTP Atomik Bar
                      _buildNtpStatusBadge(),

                      const SizedBox(height: 12),

                      // Hero Card Jam WIB Sentral
                      _buildMainClockHero(),

                      const SizedBox(height: 16),

                      // Zona Terdistribusi (WITA, WIT, London)
                      _buildDistributedZonesSection(),

                      const SizedBox(height: 14),

                      // Card Jadwal Rilis Vinyl Abbey Road
                      _buildVinylReleaseScheduleCard(),

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
                  'Jam Dunia',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  'Sinkronisasi ritme audio antar wilayah',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF8E837D),
          ),
        ],
      ),
    );
  }

  Widget _buildNtpStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEBE8E3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 6, color: AppColors.primaryOrange),
              SizedBox(width: 6),
              Text(
                'NTP ATOMIK AKTIF • LATENSI 12MS',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Color(0xFF7E756F),
                ),
              ),
            ],
          ),
          Text(
            'PRESISI TINGGI',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF9A3412),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainClockHero() {
    final timeStr = _formatTime(_currentTime, offsetHours: 0);
    final dateStr = _formatDate(_currentTime, offsetHours: 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEDD5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDDF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.radio_button_checked_rounded,
                      size: 11,
                      color: AppColors.primaryOrange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Zona Waktu Utama',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'UTC+07:00',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A524D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Location
          const Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 13,
                color: AppColors.primaryOrange,
              ),
              SizedBox(width: 4),
              Text(
                'Yogyakarta, Indonesia • Studio Sentral',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5A524D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Big Digital Clock
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 2),

          // Date
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E6560),
            ),
          ),

          const SizedBox(height: 12),

          // Storefront status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE0C2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 13,
                  color: AppColors.primaryOrange,
                ),
                SizedBox(width: 5),
                Text(
                  'Toko Pusat & Pengiriman JNOVAMUSIC',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A403A),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Buka',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributedZonesSection() {
    final witaTime = _formatTime(_currentTime, offsetHours: 1);
    final witaDate = _formatDate(_currentTime, offsetHours: 1);

    final witTime = _formatTime(_currentTime, offsetHours: 2);
    final witDate = _formatDate(_currentTime, offsetHours: 2);

    final londonTime = _formatTime(_currentTime, offsetHours: -6);
    final londonDate = _formatDate(_currentTime, offsetHours: -6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Zona Terdistribusi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            Text(
              '3 Wilayah Operasional',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E837D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // WITA
        _buildZoneCard(
          icon: Icons.schedule_rounded,
          zoneName: 'WITA — Indonesia',
          utcTag: 'UTC+8',
          cities: 'Makassar, Denpasar & Balikpapan',
          date: witaDate,
          time: witaTime,
          diff: '+1 jam dari WIB',
          diffColor: AppColors.primaryOrange,
        ),
        const SizedBox(height: 8),

        // WIT
        _buildZoneCard(
          icon: Icons.wb_sunny_outlined,
          zoneName: 'WIT — Indonesia',
          utcTag: 'UTC+9',
          cities: 'Jayapura, Ambon & Sorong',
          date: witDate,
          time: witTime,
          diff: '+2 jam dari WIB',
          diffColor: AppColors.primaryOrange,
        ),
        const SizedBox(height: 8),

        // London
        _buildZoneCard(
          icon: Icons.public_rounded,
          zoneName: 'London — Britania',
          utcTag: 'GMT+1',
          cities: 'Mastering Lab & Lisensi Vinyl',
          date: londonDate,
          time: londonTime,
          diff: '-6 jam dari WIB',
          diffColor: const Color(0xFF7E756F),
        ),
      ],
    );
  }

  Widget _buildZoneCard({
    required IconData icon,
    required String zoneName,
    required String utcTag,
    required String cities,
    required String date,
    required String time,
    required String diff,
    required Color diffColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF5A524D)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      zoneName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEAE6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        utcTag,
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5A524D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  cities,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF6E6560),
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF8E837D),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                diff,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: diffColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVinylReleaseScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEDDF),
            ),
            child: const Icon(
              Icons.album_outlined,
              size: 16,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal Rilis Piringan Hitam & Master',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pemesanan pre-order rilisan fisik internasional disinkronkan otomatis mengikuti jam buka Abbey Road & partner kurasi London.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF6E6560),
                    height: 1.3,
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
