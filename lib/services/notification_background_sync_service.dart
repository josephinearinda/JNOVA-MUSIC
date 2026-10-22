import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../core/config/app_config.dart';
import '../data/datasources/local/app_database.dart';
import '../data/datasources/remote/supabase_client_service.dart';
import 'notification_service.dart';

const _notificationSyncTask = 'jnova_notification_supabase_sync';
const _notificationSyncUniqueName = 'jnova_notification_supabase_periodic';

class NotificationBackgroundSyncService {
  NotificationBackgroundSyncService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!Platform.isAndroid || _initialized) return;
    await Workmanager().initialize(notificationSyncCallbackDispatcher);
    _initialized = true;
  }

  static Future<void> enable() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!Platform.isAndroid) return;
    await initialize();

    final preferences = await NotificationService.instance.loadPreferences();
    final user = SupabaseClientService.instance.currentUser;
    if (!preferences.pushEnabled || user == null) {
      await disable();
      return;
    }

    await syncNow();
    await Workmanager().registerPeriodicTask(
      _notificationSyncUniqueName,
      _notificationSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> disable() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!Platform.isAndroid) return;
    await initialize();
    await Workmanager().cancelByUniqueName(_notificationSyncUniqueName);
  }

  static Future<bool> syncNow() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    final client = SupabaseClientService.instance.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return true;

    try {
      final database = AppDatabase.instance;
      final previous = await database.getNotificationPollSnapshot(user.id);
      final orders = await _readUserRows(
        client,
        userId: user.id,
        table: 'orders',
        columns: 'id, order_number, status',
      );
      final points = await _readUserRows(
        client,
        userId: user.id,
        table: 'point_transactions',
        columns: 'id, title, points, category, transaction_type',
      );

      final ordersInitialized =
          previous?['ordersInitialized'] as bool? ?? false;
      final pointsInitialized =
          previous?['pointsInitialized'] as bool? ?? false;
      final previousOrders = _stringMap(previous?['orders']);
      final previousPoints = _stringMap(previous?['points']);
      final currentOrders = orders == null
          ? previousOrders
          : {
              for (final record in orders)
                if (record['id'] != null && record['status'] != null)
                  record['id'].toString(): record['status'].toString(),
            };
      final currentPoints = points == null
          ? previousPoints
          : {
              for (final record in points)
                if (record['id'] != null) record['id'].toString(): 'true',
            };

      if (orders != null && ordersInitialized) {
        for (final record in orders) {
          final id = record['id']?.toString();
          final status = record['status']?.toString();
          if (id == null || status == null || previousOrders[id] == status) {
            continue;
          }
          final orderNumber =
              record['order_number']?.toString() ?? 'Pesanan JNOVAMUSIC';
          await NotificationService.instance.showOrderUpdate(
            title: 'Status pesanan diperbarui',
            message: '$orderNumber: ${_readableStatus(status)}.',
            eventKey: 'order:$id:$status',
          );
        }
      }

      if (points != null && pointsInitialized) {
        for (final record in points) {
          final id = record['id']?.toString();
          if (id == null || previousPoints.containsKey(id)) continue;

          final title = record['title']?.toString() ?? 'Transaksi poin';
          final value = (record['points'] as num?)?.toInt() ?? 0;
          final isGame =
              record['transaction_type'] == 'game_bonus' ||
              record['category'] == 'Aktivitas Game';
          if (isGame) {
            await NotificationService.instance.showGameUpdate(
              title: 'Poin game ditambahkan',
              message: '+$value poin berhasil ditambahkan: $title.',
              eventKey: 'point:$id',
            );
          } else {
            await NotificationService.instance.showMembershipUpdate(
              title: 'Poin membership diperbarui',
              message: '$title: $value poin.',
              eventKey: 'point:$id',
            );
          }
        }
      }

      await database.saveNotificationPollSnapshot(user.id, {
        'orders': currentOrders,
        'points': currentPoints,
        'ordersInitialized': ordersInitialized || orders != null,
        'pointsInitialized': pointsInitialized || points != null,
      });
      return true;
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'while syncing Supabase notifications');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>?> _readUserRows(
    SupabaseClient client, {
    required String userId,
    required String table,
    required String columns,
  }) async {
    try {
      return await client.from(table).select(columns).eq('user_id', userId);
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST205') rethrow;
      final firstOccurrence = await AppDatabase.instance.claimNotificationEvent(
        'missing-supabase-table:$table',
      );
      if (firstOccurrence) {
        debugPrint(
          'Background notifications cannot read public.$table. '
          'Apply the JNOVAMUSIC Supabase schema migration to enable it.',
        );
      }
      return null;
    }
  }

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) return {};
    return value.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  static String _readableStatus(String status) {
    return switch (status) {
      'menunggu_pembayaran' => 'Menunggu pembayaran',
      'menunggu_verifikasi' => 'Pembayaran sedang diverifikasi',
      'siap_diambil' => 'Pesanan siap diambil',
      'diproses_luthier' => 'Pesanan sedang diproses',
      'dikirim' || 'dalam_pengiriman' => 'Pesanan sedang dikirim',
      'selesai' => 'Pesanan selesai',
      'dibatalkan' => 'Pesanan dibatalkan',
      _ => status.replaceAll('_', ' '),
    };
  }
}

@pragma('vm:entry-point')
void notificationSyncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _notificationSyncTask) return true;

    try {
      await AppConfig.initialize(clearLegacyGeminiApiKey: false);
      if (!dotenv.isInitialized || !AppConfig.isSupabaseConfigured) {
        return false;
      }

      await SupabaseClientService.instance.initialize();
      if (!SupabaseClientService.instance.isInitialized) return false;

      await NotificationService.instance.initialize();
      return await NotificationBackgroundSyncService.syncNow();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'in the background notification worker');
      return false;
    }
  });
}

void _reportError(Object error, StackTrace stackTrace, String context) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'JNOVAMUSIC background notifications',
      context: ErrorDescription(context),
    ),
  );
}
