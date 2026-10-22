import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/notification_background_sync_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_bottom_nav.dart';

class NotificationItem {
  final String id;
  final String title;
  final String time;
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.time,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isRead = false,
  });
}

/// Halaman NOTIFIKASI JNOVAMUSIC sesuai desain Figma 8
class NotificationSettingsPage extends StatefulWidget {
  final VoidCallback? onBack;

  const NotificationSettingsPage({super.key, this.onBack});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // Toggle Preferensi Notifikasi
  bool _pushNotifications = true;
  bool _promoOffers = true;
  bool _orderUpdates = true;
  bool _membershipPoints = true;
  bool _gameActivities = false;

  // Filter riwayat tab
  int _activeFilterIndex = 0; // 0: Semua, 1: Belum Dibaca

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final preferences = await NotificationService.instance.loadPreferences();
    if (!mounted) return;

    setState(() {
      _pushNotifications = preferences.pushEnabled;
      _promoOffers = preferences.promoOffers;
      _orderUpdates = preferences.orderUpdates;
      _membershipPoints = preferences.membershipPoints;
      _gameActivities = preferences.gameActivities;
    });

    if (preferences.pushEnabled) {
      try {
        final isGranted = await NotificationService.instance
            .requestPermission();
        if (!isGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izinkan notifikasi JNOVAMUSIC melalui pengaturan perangkat.',
              ),
            ),
          );
        }
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Izin notifikasi gagal diminta: $error')),
        );
      }
    }
  }

  Future<void> _updatePreferences({
    bool? pushEnabled,
    bool? promoOffers,
    bool? orderUpdates,
    bool? membershipPoints,
    bool? gameActivities,
  }) async {
    final previous = NotificationPreferences(
      pushEnabled: _pushNotifications,
      promoOffers: _promoOffers,
      orderUpdates: _orderUpdates,
      membershipPoints: _membershipPoints,
      gameActivities: _gameActivities,
    );
    var updated = previous.copyWith(
      pushEnabled: pushEnabled,
      promoOffers: promoOffers,
      orderUpdates: orderUpdates,
      membershipPoints: membershipPoints,
      gameActivities: gameActivities,
    );

    if (pushEnabled == true) {
      try {
        final isGranted = await NotificationService.instance
            .requestPermission();
        if (!isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Notifikasi belum diizinkan di pengaturan perangkat.',
                ),
              ),
            );
          }
          return;
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Izin notifikasi gagal diminta: $error')),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _pushNotifications = updated.pushEnabled;
      _promoOffers = updated.promoOffers;
      _orderUpdates = updated.orderUpdates;
      _membershipPoints = updated.membershipPoints;
      _gameActivities = updated.gameActivities;
    });

    try {
      await NotificationService.instance.savePreferences(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pushNotifications = previous.pushEnabled;
        _promoOffers = previous.promoOffers;
        _orderUpdates = previous.orderUpdates;
        _membershipPoints = previous.membershipPoints;
        _gameActivities = previous.gameActivities;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferensi notifikasi gagal disimpan: $error')),
      );
      return;
    }

    try {
      if (updated.pushEnabled) {
        await NotificationBackgroundSyncService.enable();
      } else {
        await NotificationBackgroundSyncService.disable();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Preferensi tersimpan, tetapi sinkronisasi background gagal: $error',
            ),
          ),
        );
      }
    }
  }

  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Pesanan Siap Diambil di Toko',
      time: '10 mnt lalu',
      message: 'Fender Player Stratocaster (INV/2026/04/JNV-BB21) sudah siap di Toko Galeri Yogyakarta.',
      icon: Icons.storefront_rounded,
      iconColor: AppColors.primaryOrange,
      iconBg: const Color(0xFFFFEDDF),
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Poin Pembelian Ditambahkan',
      time: '2 jam lalu',
      message: '+165 Poin berhasil masuk dari pembelian Yamaha F310 Folk. Total poin: 2.400.',
      icon: Icons.stars_rounded,
      iconColor: const Color(0xFFB45309),
      iconBg: const Color(0xFFFEF3C7),
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Flash Sale Weekend Gear Audio',
      time: '5 jam lalu',
      message: 'Dapatkan cashback s.d Rp250.000 untuk pembelian senar & gitar pilihan.',
      icon: Icons.percent_rounded,
      iconColor: const Color(0xFF0284C7),
      iconBg: const Color(0xFFE0F2FE),
      isRead: false,
    ),
    NotificationItem(
      id: '4',
      title: 'Pembayaran Berhasil Dikonfirmasi',
      time: 'Kemarin, 14:20',
      message: 'Pembayaran sebesar Rp1.650.000 via BCA Virtual Account telah terkonfirmasi.',
      icon: Icons.check_circle_outline_rounded,
      iconColor: const Color(0xFF15803D),
      iconBg: const Color(0xFFDCFCE7),
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      title: 'Jackpot Hujan Poin Dibuka!',
      time: '2 hari lalu',
      message: 'Event baru JNova Rhythm telah dimulai. Kumpulkan skor dan rebut 500 Poin.',
      icon: Icons.sports_esports_rounded,
      iconColor: const Color(0xFF7E756F),
      iconBg: const Color(0xFFECEAE6),
      isRead: true,
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

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai sudah dibaca.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final filteredNotifications = _activeFilterIndex == 0
        ? _notifications
        : _notifications.where((n) => !n.isRead).toList();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub Header
                    _buildSubHeader(),

                    const SizedBox(height: 12),

                    // Audio Alert Live Banner
                    _buildAudioAlertBanner(),

                    const SizedBox(height: 14),

                    // Preferensi Notifikasi
                    _buildPreferencesCard(),

                    const SizedBox(height: 16),

                    // Riwayat Notifikasi
                    _buildNotificationHistorySection(
                      unreadCount,
                      filteredNotifications,
                    ),

                    const SizedBox(height: 24),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            icon: const Icon(Icons.notifications_rounded, size: 22),
            onPressed: () {},
            color: AppColors.primaryOrange,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
                  'Notifikasi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  'Kelola preferensi & riwayat pemberitahuan',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8E837D)),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEBE8E3)),
            ),
            child: const Center(
              child: Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioAlertBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              size: 18,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AUDIO ALERT LIVE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pemberitahuan real-time untuk stok gear & promo studio musik.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF6E6560)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBE8E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: AppColors.primaryOrange,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Preferensi Notifikasi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Aktif di perangkat',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5A524D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildToggleItem(
            'Notifikasi Push',
            'Terima pemberitahuan langsung di perangkat.',
            _pushNotifications,
            (v) => _updatePreferences(pushEnabled: v),
          ),
          _buildToggleItem(
            'Promo dan Penawaran',
            'Info promo gear musik, diskon, & instrumen baru.',
            _promoOffers,
            (v) => _updatePreferences(promoOffers: v),
          ),
          _buildToggleItem(
            'Pembaruan Pesanan',
            'Informasi pembayaran, resi pengiriman, & ambil di toko.',
            _orderUpdates,
            (v) => _updatePreferences(orderUpdates: v),
          ),
          _buildToggleItem(
            'Membership dan Poin',
            'Informasi perolehan poin, naik tier, & voucher reward.',
            _membershipPoints,
            (v) => _updatePreferences(membershipPoints: v),
          ),
          _buildToggleItem(
            'Aktivitas Game',
            'Info hadiah Jackpot Poin & event JNova Rhythm.',
            _gameActivities,
            (v) => _updatePreferences(gameActivities: v),
          ),

          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(
                Icons.cloud_done_outlined,
                size: 13,
                color: Color(0xFF8E837D),
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Preferensi notifikasi tersimpan di perangkat ini',
                  style: TextStyle(fontSize: 9, color: Color(0xFF8E837D)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    String desc,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF7E756F),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryOrange,
            activeTrackColor: AppColors.primaryOrange.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationHistorySection(
    int unreadCount,
    List<NotificationItem> items,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Notifikasi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              InkWell(
                onTap: _markAllAsRead,
                child: const Row(
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                      size: 13,
                      color: AppColors.primaryOrange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tandai Sudah Dibaca',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tabs: Semua & Belum Dibaca
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _activeFilterIndex = 0),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _activeFilterIndex == 0
                        ? AppColors.primaryOrange
                        : const Color(0xFFF2F0ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Semua',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _activeFilterIndex == 0
                          ? Colors.white
                          : const Color(0xFF6E6560),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _activeFilterIndex = 1),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _activeFilterIndex == 1
                        ? AppColors.primaryOrange
                        : const Color(0xFFF2F0ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Belum Dibaca',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _activeFilterIndex == 1
                              ? Colors.white
                              : const Color(0xFF6E6560),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _activeFilterIndex == 1
                                ? Colors.white
                                : AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: _activeFilterIndex == 1
                                  ? AppColors.primaryOrange
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Daftar Kartu Notifikasi
          ...items.map((item) => _buildNotificationCard(item)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 16, color: item.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          item.time,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF8E837D),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 5),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 10,
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
