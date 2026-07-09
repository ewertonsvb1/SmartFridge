import 'package:flutter_test/flutter_test.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_local_service.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_local_storage.dart';
import 'package:smartfridge_mobile/src/features/notification/data/notification_repository.dart';

class _FakePlatformClient implements NotificationPlatformClient {
  int initializeCalls = 0;
  int requestPermissionsCalls = 0;
  int cancelAllCalls = 0;
  final List<(int, String, String)> shown = [];

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> requestPermissions() async {
    requestPermissionsCalls++;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    shown.add((id, title, body));
  }
}

class _FakeLocalStorage extends NotificationLocalStorage {
  _FakeLocalStorage() : super(_NoopTokenStorage());

  final Set<int> shownIds = {};
  bool cleared = false;

  @override
  Future<void> clearSessionState() async {
    cleared = true;
    shownIds.clear();
  }

  @override
  Future<bool> hasShownNotification(int notificationId) async {
    return shownIds.contains(notificationId);
  }

  @override
  Future<void> markNotificationAsShown(int notificationId) async {
    shownIds.add(notificationId);
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
  test('shows only unseen notifications and persists ids locally', () async {
    final platform = _FakePlatformClient();
    final storage = _FakeLocalStorage();
    final service = NotificationLocalService(
      platformClient: platform,
      localStorage: storage,
    );

    final item = NotificationItem(
      id: 11,
      type: 'NEAR_EXPIRATION',
      eventDate: '2026-07-09',
      productName: 'Leite Italac',
      productExpirationDate: '2026-07-10',
      createdAt: '2026-07-09T02:00:00Z',
    );

    expect(await service.showIfNew(item), isTrue);
    expect(await service.showIfNew(item), isFalse);
    expect(platform.shown, hasLength(1));
    expect(storage.shownIds, {11});
  });

  test('clears local notifications and local state on logout', () async {
    final platform = _FakePlatformClient();
    final storage = _FakeLocalStorage();
    final service = NotificationLocalService(
      platformClient: platform,
      localStorage: storage,
    );

    await service.clearSessionState();

    expect(platform.cancelAllCalls, 1);
    expect(storage.cleared, isTrue);
  });
}
