import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/network/app_environment.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_local_service.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_local_storage.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_sync_service.dart';
import 'package:smartfridge_mobile/src/features/notification/data/notification_repository.dart';
import 'package:workmanager/workmanager.dart';

const notificationSyncTaskUniqueName = 'smarthouse-notification-sync';
const notificationSyncTaskName = 'smarthouse.notification.sync';
const notificationSyncIosIdentifier = 'com.smartfridge.mobile.notification.sync';

@pragma('vm:entry-point')
void notificationSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final runner = BackgroundNotificationSyncRunner();
      await runner.run();
      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}

class BackgroundNotificationSyncRunner {
  BackgroundNotificationSyncRunner();

  Future<void> run() async {
    if (kIsWeb) {
      return;
    }

    final tokenStorage = HybridTokenStorage(const FlutterSecureStorage());
    final token = await tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: resolveApiBaseUrl(),
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final localStorage = NotificationLocalStorage(tokenStorage);
    final localService = NotificationLocalService(
      platformClient: FlutterNotificationPlatformClient(
        FlutterLocalNotificationsPlugin(),
      ),
      localStorage: localStorage,
    );
    await localService.initialize();

    final syncService = NotificationSyncService(
      repository: NotificationRepository(dio),
      localStorage: localStorage,
      localService: localService,
    );
    await syncService.syncNewNotifications();
  }
}
