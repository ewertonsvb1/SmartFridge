import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_local_storage.dart';
import 'package:smartfridge_mobile/src/features/notification/data/notification_repository.dart';

abstract class NotificationPlatformClient {
  Future<void> initialize();

  Future<void> requestPermissions();

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  Future<void> cancelAll();
}

class FlutterNotificationPlatformClient implements NotificationPlatformClient {
  FlutterNotificationPlatformClient([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'smarthouse_notifications';
  static const _channelName = 'Notificacoes SmartHouse';
  static const _channelDescription =
      'Alertas locais para geladeira, agenda e contas da casa.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  @override
  Future<void> requestPermissions() async {
    if (kIsWeb) {
      return;
    }

    await initialize();

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      return;
    }

    await initialize();

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  @override
  Future<void> cancelAll() async {
    if (kIsWeb) {
      return;
    }

    await initialize();
    await _plugin.cancelAll();
  }
}

class NotificationLocalService {
  NotificationLocalService({
    required NotificationPlatformClient platformClient,
    required NotificationLocalStorage localStorage,
  })  : _platformClient = platformClient,
        _localStorage = localStorage;

  final NotificationPlatformClient _platformClient;
  final NotificationLocalStorage _localStorage;

  Future<void> initialize() {
    return _platformClient.initialize();
  }

  Future<void> requestPermissions() {
    return _platformClient.requestPermissions();
  }

  Future<bool> showIfNew(NotificationItem item) async {
    if (await _localStorage.hasShownNotification(item.id)) {
      return false;
    }

    await _platformClient.show(
      id: item.id,
      title: item.displayLabel,
      body: _buildBody(item),
      payload: item.id.toString(),
    );
    await _localStorage.markNotificationAsShown(item.id);
    return true;
  }

  Future<void> clearSessionState() async {
    await _platformClient.cancelAll();
    await _localStorage.clearSessionState();
  }

  String _buildBody(NotificationItem item) {
    final eventDate = DateTime.tryParse(item.displayDate);
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    final targetDay = eventDate == null
        ? null
        : DateTime(eventDate.year, eventDate.month, eventDate.day);
    final diffDays = targetDay?.difference(currentDay).inDays;

    final isAgenda = item.sourceModule == 'AGENDA';
    final nearPrefix = isAgenda ? 'Acontece' : 'Vence';
    final expiredPrefix = isAgenda ? 'Aconteceu' : 'Venceu';

    if (item.type == 'EXPIRED') {
      if (diffDays == null || diffDays == 0) {
        return '$nearPrefix hoje.';
      }
      if (diffDays > 0) {
        return '$nearPrefix em $diffDays dias.';
      }
      final elapsedDays = diffDays.abs();
      return elapsedDays == 1
          ? '$expiredPrefix ontem.'
          : '$expiredPrefix ha $elapsedDays dias.';
    }

    if (diffDays == null) {
      return isAgenda ? 'Evento proximo.' : 'Vence em breve.';
    }
    if (diffDays == 0) {
      return '$nearPrefix hoje.';
    }
    if (diffDays == 1) {
      return '$nearPrefix amanha.';
    }
    if (diffDays < 0) {
      return '$expiredPrefix ha ${diffDays.abs()} dias.';
    }
    return '$nearPrefix em $diffDays dias.';
  }
}

final notificationPlatformClientProvider =
    Provider<NotificationPlatformClient>((_) {
  return FlutterNotificationPlatformClient();
});

final notificationLocalStorageProvider =
    Provider<NotificationLocalStorage>((ref) {
  return NotificationLocalStorage(ref.watch(tokenStorageProvider));
});

final notificationLocalServiceProvider = Provider<NotificationLocalService>((
  ref,
) {
  return NotificationLocalService(
    platformClient: ref.watch(notificationPlatformClientProvider),
    localStorage: ref.watch(notificationLocalStorageProvider),
  );
});
