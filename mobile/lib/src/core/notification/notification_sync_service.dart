import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_local_service.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_local_storage.dart';
import 'package:smartfridge_mobile/src/features/notification/data/notification_repository.dart';

class NotificationSyncResult {
  const NotificationSyncResult({
    required this.fetchedCount,
    required this.displayedCount,
    this.lastAfterId,
  });

  final int fetchedCount;
  final int displayedCount;
  final int? lastAfterId;
}

class NotificationSyncService {
  NotificationSyncService({
    required NotificationRepository repository,
    required NotificationLocalStorage localStorage,
    required NotificationLocalService localService,
  })  : _repository = repository,
        _localStorage = localStorage,
        _localService = localService;

  final NotificationRepository _repository;
  final NotificationLocalStorage _localStorage;
  final NotificationLocalService _localService;

  Future<void> activate() async {
    await _localService.initialize();
    await _localService.requestPermissions();
  }

  Future<NotificationSyncResult> syncNewNotifications({int limit = 100}) async {
    final afterId = await _localStorage.readAfterId();
    final items = await _repository.list(limit: limit, afterId: afterId);

    if (items.isEmpty) {
      return NotificationSyncResult(
        fetchedCount: 0,
        displayedCount: 0,
        lastAfterId: afterId,
      );
    }

    var latestAfterId = afterId ?? 0;
    var displayedCount = 0;

    for (final item in items) {
      if (item.id > latestAfterId) {
        latestAfterId = item.id;
      }
      if (await _localService.showIfNew(item)) {
        displayedCount++;
      }
    }

    await _localStorage.writeAfterId(latestAfterId);

    return NotificationSyncResult(
      fetchedCount: items.length,
      displayedCount: displayedCount,
      lastAfterId: latestAfterId,
    );
  }

  Future<void> clearSessionState() async {
    await _localService.clearSessionState();
  }
}

final notificationSyncServiceProvider = Provider<NotificationSyncService>((ref) {
  return NotificationSyncService(
    repository: ref.watch(notificationRepositoryProvider),
    localStorage: ref.watch(notificationLocalStorageProvider),
    localService: ref.watch(notificationLocalServiceProvider),
  );
});

bool isWidgetTestEnvironment() {
  return WidgetsBinding.instance.runtimeType.toString().contains(
    'TestWidgetsFlutterBinding',
  );
}
