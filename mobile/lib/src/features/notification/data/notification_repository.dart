import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.type,
    required this.eventDate,
    required this.productName,
    required this.productExpirationDate,
    required this.createdAt,
    this.sourceModule,
    this.sourceId,
    this.sourceLabel,
    this.sourceDate,
    this.productId,
  });

  final int id;
  final String type;
  final String eventDate;
  final String productName;
  final String productExpirationDate;
  final String createdAt;
  final String? sourceModule;
  final int? sourceId;
  final String? sourceLabel;
  final String? sourceDate;
  final int? productId;

  String get displayLabel => sourceLabel ?? productName;

  String get displayDate => sourceDate ?? productExpirationDate;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      type: json['type'] as String,
      eventDate: json['eventDate'] as String,
      productName: (json['productName'] ?? json['sourceLabel'] ?? 'Notificacao')
          as String,
      productExpirationDate: (json['productExpirationDate'] ??
          json['sourceDate'] ??
          json['eventDate']) as String,
      createdAt: json['createdAt'] as String,
      sourceModule: json['sourceModule'] as String?,
      sourceId: (json['sourceId'] as num?)?.toInt(),
      sourceLabel: json['sourceLabel'] as String?,
      sourceDate: json['sourceDate'] as String?,
      productId: (json['productId'] as num?)?.toInt(),
    );
  }
}

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<List<NotificationItem>> list({int limit = 20, int? afterId}) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (afterId != null) {
      queryParameters['afterId'] = afterId;
    }

    final response = await _dio.get(
      '/notifications',
      queryParameters: queryParameters,
    );
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

final notificationsProvider =
    FutureProvider<List<NotificationItem>>((ref) async {
  return ref.watch(notificationRepositoryProvider).list();
});
