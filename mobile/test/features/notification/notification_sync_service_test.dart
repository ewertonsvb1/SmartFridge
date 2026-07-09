import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_local_service.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_local_storage.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_sync_service.dart';
import 'package:smartfridge_mobile/src/features/notification/data/notification_repository.dart';

class _FakeNotificationRepository extends NotificationRepository {
  _FakeNotificationRepository(this._items) : super(Dio());

  final List<NotificationItem> _items;
  int? receivedAfterId;

  @override
  Future<List<NotificationItem>> list({int limit = 20, int? afterId}) async {
    receivedAfterId = afterId;
    return _items;
  }
}

class _FakeNotificationLocalStorage extends NotificationLocalStorage {
  _FakeNotificationLocalStorage({this.initialAfterId}) : super(_NoopTokenStorage());

  final int? initialAfterId;
  final Set<int> shownIds = {};
  int? persistedAfterId;

  @override
  Future<void> clearSessionState() async {
    shownIds.clear();
    persistedAfterId = null;
  }

  @override
  Future<bool> hasShownNotification(int notificationId) async {
    return shownIds.contains(notificationId);
  }

  @override
  Future<void> markNotificationAsShown(int notificationId) async {
    shownIds.add(notificationId);
  }

  @override
  Future<int?> readAfterId() async => persistedAfterId ?? initialAfterId;

  @override
  Future<void> writeAfterId(int afterId) async {
    persistedAfterId = afterId;
  }
}

class _FakeNotificationPlatformClient implements NotificationPlatformClient {
  final List<int> shownIds = [];

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    shownIds.add(id);
  }
}

class _NoopTokenStorage implements TokenStorage {
  @override
  Future<void> clearToken() async {}

  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> writeToken(String token) async {}
}

void main() {
  test('uses stored afterId and persists latest cursor after sync', () async {
    final repository = _FakeNotificationRepository([
      NotificationItem(
        id: 16,
        type: 'NEAR_EXPIRATION',
        eventDate: '2026-07-09',
        productName: 'Leite',
        productExpirationDate: '2026-07-10',
        createdAt: '2026-07-09T02:00:00Z',
      ),
      NotificationItem(
        id: 18,
        type: 'EXPIRED',
        eventDate: '2026-07-09',
        productName: 'Queijo',
        productExpirationDate: '2026-07-09',
        createdAt: '2026-07-09T02:05:00Z',
      ),
    ]);
    final storage = _FakeNotificationLocalStorage(initialAfterId: 15);
    final localService = NotificationLocalService(
      platformClient: _FakeNotificationPlatformClient(),
      localStorage: storage,
    );
    final service = NotificationSyncService(
      repository: repository,
      localStorage: storage,
      localService: localService,
    );

    final result = await service.syncNewNotifications();

    expect(repository.receivedAfterId, 15);
    expect(storage.persistedAfterId, 18);
    expect(result.fetchedCount, 2);
    expect(result.displayedCount, 2);
    expect(result.lastAfterId, 18);
  });

  test('does not display duplicate ids already shown locally', () async {
    final repository = _FakeNotificationRepository([
      NotificationItem(
        id: 22,
        type: 'NEAR_EXPIRATION',
        eventDate: '2026-07-09',
        productName: 'Conta de Energia',
        productExpirationDate: '2026-07-10',
        createdAt: '2026-07-09T02:00:00Z',
        sourceModule: 'HOUSE_BILL',
        sourceLabel: 'Conta de Energia',
        sourceDate: '2026-07-10',
      ),
    ]);
    final storage = _FakeNotificationLocalStorage(initialAfterId: 21)
      ..shownIds.add(22);
    final platform = _FakeNotificationPlatformClient();
    final localService = NotificationLocalService(
      platformClient: platform,
      localStorage: storage,
    );
    final service = NotificationSyncService(
      repository: repository,
      localStorage: storage,
      localService: localService,
    );

    final result = await service.syncNewNotifications();

    expect(platform.shownIds, isEmpty);
    expect(result.displayedCount, 0);
    expect(storage.persistedAfterId, 22);
  });
}
