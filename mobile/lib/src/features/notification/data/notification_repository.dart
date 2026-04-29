import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.type,
    required this.eventDate,
    required this.productId,
    required this.productName,
    required this.productExpirationDate,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String eventDate;
  final int productId;
  final String productName;
  final String productExpirationDate;
  final String createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      type: json['type'] as String,
      eventDate: json['eventDate'] as String,
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      productExpirationDate: json['productExpirationDate'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<List<NotificationItem>> list({int limit = 20}) async {
    final response = await _dio.get('/notifications', queryParameters: {'limit': limit});
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async {
  return ref.watch(notificationRepositoryProvider).list();
});
