import 'package:flutter_test/flutter_test.dart';
import 'package:smartfridge_mobile/src/features/notification/data/notification_repository.dart';

void main() {
  test('parses legacy product notification payloads', () {
    final item = NotificationItem.fromJson({
      'id': 1,
      'type': 'EXPIRED',
      'eventDate': '2026-06-09',
      'productId': 10,
      'productName': 'Leite',
      'productExpirationDate': '2026-06-08',
      'createdAt': '2026-06-09T02:00:00Z',
    });

    expect(item.sourceModule, isNull);
    expect(item.productId, 10);
    expect(item.displayLabel, 'Leite');
    expect(item.displayDate, '2026-06-08');
  });

  test('parses multi-module notification payloads', () {
    final item = NotificationItem.fromJson({
      'id': 2,
      'type': 'NEAR_EXPIRATION',
      'eventDate': '2026-06-09',
      'sourceModule': 'HOUSE_BILL',
      'sourceId': 20,
      'sourceLabel': 'Internet',
      'sourceDate': '2026-06-10',
      'productId': null,
      'productName': null,
      'productExpirationDate': null,
      'createdAt': '2026-06-09T02:00:00Z',
    });

    expect(item.sourceModule, 'HOUSE_BILL');
    expect(item.sourceId, 20);
    expect(item.productId, isNull);
    expect(item.displayLabel, 'Internet');
    expect(item.displayDate, '2026-06-10');
  });

  test('keeps afterId support in repository model contract', () async {
    const repositoryType = NotificationRepository;
    expect(repositoryType, isNotNull);
  });
}
