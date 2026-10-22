import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final SecureStorageService _storage = SecureStorageService.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    final settings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
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

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
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

  Future<void> _show({
    required NotificationCategory category,
    required String title,
    required String message,
    String? eventKey,
  }) async {
    if (!_initialized || kIsWeb) return;

    final preferences = await loadPreferences();
    if (!preferences.isEnabled(category)) return;

    try {
      if (eventKey != null &&
          !await AppDatabase.instance.claimNotificationEvent(eventKey)) {
        return;
      }
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        title: title,
        body: message,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'jnova_updates',
            'Pembaruan JNOVAMUSIC',
            channelDescription:
                'Pembaruan pesanan, membership, dan aktivitas JNOVAMUSIC.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
    } catch (error, stackTrace) {
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
}
