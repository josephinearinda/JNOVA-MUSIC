import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/storage/secure_storage_service.dart';
import '../data/datasources/local/app_database.dart';

enum NotificationCategory { promo, order, membership, game }

class NotificationPreferences {
  final bool pushEnabled;
  final bool promoOffers;
  final bool orderUpdates;
  final bool membershipPoints;
  final bool gameActivities;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.promoOffers = true,
    this.orderUpdates = true,
    this.membershipPoints = true,
    this.gameActivities = false,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    const defaults = NotificationPreferences();
    return NotificationPreferences(
      pushEnabled: map?['pushEnabled'] as bool? ?? defaults.pushEnabled,
      promoOffers: map?['promoOffers'] as bool? ?? defaults.promoOffers,
      orderUpdates: map?['orderUpdates'] as bool? ?? defaults.orderUpdates,
      membershipPoints:
          map?['membershipPoints'] as bool? ?? defaults.membershipPoints,
      gameActivities:
          map?['gameActivities'] as bool? ?? defaults.gameActivities,
    );
  }

  Map<String, bool> toMap() => {
    'pushEnabled': pushEnabled,
    'promoOffers': promoOffers,
    'orderUpdates': orderUpdates,
    'membershipPoints': membershipPoints,
    'gameActivities': gameActivities,
  };

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? promoOffers,
    bool? orderUpdates,
    bool? membershipPoints,
    bool? gameActivities,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      promoOffers: promoOffers ?? this.promoOffers,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      membershipPoints: membershipPoints ?? this.membershipPoints,
      gameActivities: gameActivities ?? this.gameActivities,
    );
  }

  bool isEnabled(NotificationCategory category) {
    if (!pushEnabled) return false;
    return switch (category) {
      NotificationCategory.promo => promoOffers,
      NotificationCategory.order => orderUpdates,
      NotificationCategory.membership => membershipPoints,
      NotificationCategory.game => gameActivities,
    };
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String channelId = 'jnova_updates_v2';
  static const String legacyChannelId = 'jnova_updates';
  static const String channelName = 'Pembaruan JNOVAMUSIC';
  static const String channelDescription =
      'Pembaruan pesanan, membership, promo, dan aktivitas JNOVAMUSIC.';

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static const int dailyGameReminderNotificationId = 77718;
  static String? pendingRoute;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final SecureStorageService _storage = SecureStorageService.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    // Inisialisasi database zona waktu perangkat untuk penjadwalan harian pukul 11:30 AM
    try {
      tz_data.initializeTimeZones();
      final localLoc = _resolveLocalLocation();
      tz.setLocalLocation(localLoc);
    } catch (e) {
      debugPrint('[NotificationService] Inisialisasi timezone error: $e');
    }

    final settings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: const DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: const DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      linux: const LinuxInitializationSettings(
        defaultActionName: 'Buka notifikasi',
      ),
      windows: const WindowsInitializationSettings(
        appName: 'JNOVAMUSIC',
        appUserModelId: 'com.example.jnova',
        guid: '2f70b14c-b969-4d38-b1d3-7ff624f66105',
      ),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Tangani jika aplikasi dibuka dari kondisi mati / cold start lewat ketukan notifikasi
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.startsWith('route:')) {
        pendingRoute = payload.substring('route:'.length);
      }
    }

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        // Hapus channel lama 'jnova_updates' agar preferensi lama di Android OS
        // tidak menghambat munculnya popup/banner heads-up di Android Emulator.
        try {
          await android.deleteNotificationChannel(channelId: legacyChannelId);
        } catch (_) {}

        // Buat notification channel Android dengan tingkat kepentingan tertinggi (Importance.max)
        // agar dapat tampil sebagai Heads-Up Notification (popup/banner) di semua perangkat.
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
        );
        await android.createNotificationChannel(channel);
      }
    }

    _initialized = true;

    // Otomatis sinkronisasi jadwal pengingat game jika izin notifikasi sudah aktif
    if (await areNotificationsEnabled()) {
      await scheduleDailyGameReminder();
    }
  }

  static void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.startsWith('route:')) {
      final route = payload.substring('route:'.length);
      navigateToRoute(route);
    }
  }

  static void navigateToRoute(String route) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState?.pushNamed(route);
    } else {
      pendingRoute = route;
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      final isAllowed =
          granted ?? await android?.areNotificationsEnabled() ?? true;
      if (isAllowed) {
        await scheduleDailyGameReminder();
      }
      return isAllowed;
    }
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    if (Platform.isMacOS) {
      final macOS = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      return await macOS?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? true;
    }
    return true;
  }

  Future<bool> openNotificationSettings() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.openAppNotificationSettings() ?? false;
    }
    return false;
  }

  Future<NotificationPreferences> loadPreferences() async {
    return NotificationPreferences.fromMap(
      await _storage.getNotificationPreferences(),
    );
  }

  Future<void> savePreferences(NotificationPreferences preferences) {
    return _storage.saveNotificationPreferences(preferences.toMap());
  }

  Future<void> showOrderUpdate({
    required String title,
    required String message,
    String? eventKey,
  }) {
    return _show(
      category: NotificationCategory.order,
      title: title,
      message: message,
      eventKey: eventKey,
    );
  }

  Future<void> showMembershipUpdate({
    required String title,
    required String message,
    String? eventKey,
  }) {
    return _show(
      category: NotificationCategory.membership,
      title: title,
      message: message,
      eventKey: eventKey,
    );
  }

  Future<void> showGameUpdate({
    required String title,
    required String message,
    String? eventKey,
  }) {
    return _show(
      category: NotificationCategory.game,
      title: title,
      message: message,
      eventKey: eventKey,
    );
  }

  Future<void> showPromoNotification({
    required String title,
    required String message,
    String? eventKey,
  }) {
    return _show(
      category: NotificationCategory.promo,
      title: title,
      message: message,
      eventKey: eventKey,
    );
  }

  Future<void> showTestNotification({
    String title = 'Pembaruan JNOVAMUSIC',
    String message =
        'Notifikasi otomatis popup/banner berhasil ditampilkan di perangkat!',
  }) {
    return _show(
      category: NotificationCategory.promo,
      title: title,
      message: message,
      eventKey: 'test_notification_${DateTime.now().millisecondsSinceEpoch}',
      bypassPreferences: true,
    );
  }

  Future<void> showGameReminderNowForTesting() async {
    await _show(
      category: NotificationCategory.game,
      title: '💗 Yuk, tambahkan poinmu!',
      message:
          'Ayo bermain game di JNOVA MUSIC dan kumpulkan lebih banyak poin untuk mendapatkan keuntungan menarik! Jangan lewatkan kesempatan menambah poinmu hari ini. 💕',
      eventKey: 'game_reminder_test_${DateTime.now().millisecondsSinceEpoch}',
      payload: 'route:/game-home',
      bypassPreferences: true,
    );
  }

  /// Menjadwalkan pengingat harian pukul 18.00 waktu lokal perangkat.
  /// Pengingat ini berulang 1 kali sehari dan tetap berjalan meski aplikasi ditutup.
  Future<void> scheduleDailyGameReminder() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!_initialized) {
      await initialize();
    }
    if (kIsWeb) return;

    final preferences = await loadPreferences();
    if (!preferences.pushEnabled) {
      await cancelDailyGameReminder();
      return;
    }

    final isAllowed = await areNotificationsEnabled();
    if (!isAllowed) {
      debugPrint(
        '[NotificationService] Izin notifikasi belum diberikan, penjadwalan pengingat game dilewati.',
      );
      return;
    }

    try {
      // Selalu batalkan alarm sebelumnya dengan ID yang sama agar jadwal TIDAK PERNAH terduplikasi
      await _plugin.cancel(id: dailyGameReminderNotificationId);

      final scheduledDate = _nextInstanceOf1130AM();

      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.inexactAllowWhileIdle;
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final canExact =
            await android?.canScheduleExactNotifications() ?? false;
        if (canExact) {
          scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        }
      }

      await _plugin.zonedSchedule(
        id: dailyGameReminderNotificationId,
        title: '💗 Yuk, tambahkan poinmu!',
        body:
            'Ayo bermain game di JNOVA MUSIC dan kumpulkan lebih banyak poin untuk mendapatkan keuntungan menarik! Jangan lewatkan kesempatan menambah poinmu hari ini. 💕',
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            importance: Importance.max,
            priority: Priority.max,
            ticker: '💗 Yuk, tambahkan poinmu!',
            playSound: true,
            enableVibration: true,
            enableLights: true,
            channelShowBadge: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'route:/game-home',
      );

      debugPrint(
        '[NotificationService] Pengingat harian game berhasil dijadwalkan pukul 11:30 AM (Next: $scheduledDate, mode: $scheduleMode).',
      );
    } catch (error) {
      debugPrint('[NotificationService] Gagal menjadwalkan pengingat game: $error');
    }
  }

  /// Membatalkan jadwal pengingat harian game
  Future<void> cancelDailyGameReminder() async {
    try {
      await _plugin.cancel(id: dailyGameReminderNotificationId);
      debugPrint('[NotificationService] Pengingat harian game dibatalkan.');
    } catch (_) {}
  }

  static tz.TZDateTime _nextInstanceOf1130AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 11, 30, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static tz.Location _resolveLocalLocation() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final name = now.timeZoneName;

    if (tz.timeZoneDatabase.locations.containsKey(name)) {
      return tz.getLocation(name);
    }

    if (offset.inHours == 7 &&
        tz.timeZoneDatabase.locations.containsKey('Asia/Jakarta')) {
      return tz.getLocation('Asia/Jakarta');
    } else if (offset.inHours == 8 &&
        tz.timeZoneDatabase.locations.containsKey('Asia/Makassar')) {
      return tz.getLocation('Asia/Makassar');
    } else if (offset.inHours == 9 &&
        tz.timeZoneDatabase.locations.containsKey('Asia/Jayapura')) {
      return tz.getLocation('Asia/Jayapura');
    }

    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.currentTimeZone.offset == offset) {
        return loc;
      }
    }

    return tz.Location(
      'DeviceLocal',
      [tz.minTime],
      [0],
      [
        tz.TimeZone(
          offset,
          isDst: false,
          abbreviation: name.isNotEmpty ? name : 'LOCAL',
        ),
      ],
    );
  }

  Future<void> _show({
    required NotificationCategory category,
    required String title,
    required String message,
    String? eventKey,
    String? payload,
    bool bypassPreferences = false,
  }) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized || kIsWeb) return;

    if (!bypassPreferences) {
      final preferences = await loadPreferences();
      if (!preferences.isEnabled(category)) {
        debugPrint(
          '[NotificationService] Notifikasi $category diabaikan (dinonaktifkan di preferensi).',
        );
        return;
      }
    }

    try {
      if (eventKey != null &&
          !await AppDatabase.instance.claimNotificationEvent(eventKey)) {
        debugPrint(
          '[NotificationService] Event $eventKey sudah pernah dikirim sebelumnya.',
        );
        return;
      }
      debugPrint('[NotificationService] Mengirim notifikasi: $title - $message');
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        title: title,
        body: message,
        payload: payload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            importance: Importance.max,
            priority: Priority.max,
            ticker: title,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            channelShowBadge: true,
            visibility: NotificationVisibility.public,
            category: _androidCategory(category),
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('[NotificationService] Notifikasi berhasil dikirim!');
    } catch (error, stackTrace) {
      debugPrint('[NotificationService] Gagal menampilkan notifikasi: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'JNOVAMUSIC notifications',
          context: ErrorDescription('while showing a local notification'),
        ),
      );
    }
  }

  static AndroidNotificationCategory _androidCategory(
    NotificationCategory category,
  ) {
    return switch (category) {
      NotificationCategory.order => AndroidNotificationCategory.status,
      NotificationCategory.membership => AndroidNotificationCategory.reminder,
      NotificationCategory.game => AndroidNotificationCategory.event,
      NotificationCategory.promo => AndroidNotificationCategory.promo,
    };
  }
}
