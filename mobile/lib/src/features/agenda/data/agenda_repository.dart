import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

enum AgendaEventStatus {
  scheduled('SCHEDULED', 'Agendado'),
  completed('COMPLETED', 'Concluido'),
  canceled('CANCELED', 'Cancelado');

  const AgendaEventStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AgendaEventStatus fromApi(String value) {
    return AgendaEventStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => AgendaEventStatus.scheduled,
    );
  }
}

class AgendaEventModel {
  AgendaEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.userId,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final AgendaEventStatus status;
  final int userId;
  final DateTime createdAt;

  factory AgendaEventModel.fromJson(Map<String, dynamic> json) {
    return AgendaEventModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      status:
          AgendaEventStatus.fromApi(json['status'] as String? ?? 'SCHEDULED'),
      userId: json['userId'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get timeRangeLabel {
    final formatter = DateFormat('HH:mm');
    return '${formatter.format(startAt)} - ${formatter.format(endAt)}';
  }
}

class AgendaRepository {
  AgendaRepository(this._dio);

  final Dio _dio;

  Future<List<AgendaEventModel>> list({
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    AgendaEventStatus? status,
  }) async {
    final formatter = DateFormat('yyyy-MM-dd');
    final response = await _dio.get(
      '/agenda/events',
      queryParameters: {
        if (date != null) 'date': formatter.format(date),
        if (startDate != null) 'startDate': formatter.format(startDate),
        if (endDate != null) 'endDate': formatter.format(endDate),
        if (status != null) 'status': status.apiValue,
      },
    );

    final data = response.data as List<dynamic>? ?? <dynamic>[];
    return data
        .map(
            (event) => AgendaEventModel.fromJson(event as Map<String, dynamic>))
        .toList();
  }

  Future<AgendaEventModel> create({
    required String title,
    required String description,
    required DateTime startAt,
    required DateTime endAt,
    required AgendaEventStatus status,
  }) async {
    final response = await _dio.post(
      '/agenda/events',
      data: {
        'title': title,
        'description': description,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'status': status.apiValue,
      },
    );

    return AgendaEventModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AgendaEventModel> update({
    required int id,
    required String title,
    required String description,
    required DateTime startAt,
    required DateTime endAt,
    required AgendaEventStatus status,
  }) async {
    final response = await _dio.put(
      '/agenda/events/$id',
      data: {
        'title': title,
        'description': description,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'status': status.apiValue,
      },
    );

    return AgendaEventModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/agenda/events/$id');
  }
}

final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  return AgendaRepository(ref.watch(dioProvider));
});
