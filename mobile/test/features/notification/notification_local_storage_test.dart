import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_local_storage.dart';

class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage(this._token);

  final String _token;

  @override
  Future<void> clearToken() async {}

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists afterId scoped by authenticated subject', () async {
    final storage = NotificationLocalStorage(
      _FakeTokenStorage(
        'eyJhbGciOiJub25lIn0.eyJzdWIiOiJ1c2VyQGV4YW1wbGUuY29tIn0.',
      ),
    );

    await storage.writeAfterId(42);

    expect(await storage.readAfterId(), 42);
  });

  test('stores shown notification ids without duplicates', () async {
    final storage = NotificationLocalStorage(
      _FakeTokenStorage(
        'eyJhbGciOiJub25lIn0.eyJzdWIiOiJ1c2VyQGV4YW1wbGUuY29tIn0.',
      ),
    );

    await storage.markNotificationAsShown(7);
    await storage.markNotificationAsShown(7);
    await storage.markNotificationAsShown(9);

    expect(await storage.hasShownNotification(7), isTrue);
    expect(await storage.readShownNotificationIds(), {7, 9});
  });
}
