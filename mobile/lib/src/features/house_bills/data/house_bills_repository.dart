import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

enum HouseBillStatus {
  open('OPEN', 'Em aberto'),
  overdue('OVERDUE', 'Vencida'),
  paid('PAID', 'Paga');

  const HouseBillStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static HouseBillStatus fromApi(String value) {
    return HouseBillStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => HouseBillStatus.open,
    );
  }
}

class HouseBillModel {
  HouseBillModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.category,
    required this.status,
    required this.paidAt,
    required this.userId,
    required this.createdAt,
  });

  final int id;
  final String description;
  final double amount;
  final DateTime dueDate;
  final String category;
  final HouseBillStatus status;
  final DateTime? paidAt;
  final int userId;
  final DateTime createdAt;

  factory HouseBillModel.fromJson(Map<String, dynamic> json) {
    return HouseBillModel(
      id: json['id'] as int,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.parse(json['dueDate'] as String),
      category: json['category'] as String? ?? '',
      status: HouseBillStatus.fromApi(json['status'] as String? ?? 'OPEN'),
      paidAt: DateTime.tryParse(json['paidAt'] as String? ?? ''),
      userId: json['userId'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get dueDateLabel => DateFormat('dd/MM/yyyy').format(dueDate);
}

class HouseBillsDashboardDetailModel {
  HouseBillsDashboardDetailModel({
    required this.totalCount,
    required this.openCount,
    required this.overdueCount,
    required this.paidCount,
    required this.totalAmount,
    required this.openAmount,
    required this.overdueAmount,
    required this.paidAmount,
  });

  final int totalCount;
  final int openCount;
  final int overdueCount;
  final int paidCount;
  final double totalAmount;
  final double openAmount;
  final double overdueAmount;
  final double paidAmount;

  factory HouseBillsDashboardDetailModel.fromJson(Map<String, dynamic> json) {
    return HouseBillsDashboardDetailModel(
      totalCount: json['totalCount'] as int? ?? 0,
      openCount: json['openCount'] as int? ?? 0,
      overdueCount: json['overdueCount'] as int? ?? 0,
      paidCount: json['paidCount'] as int? ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      openAmount: (json['openAmount'] as num?)?.toDouble() ?? 0,
      overdueAmount: (json['overdueAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class HouseBillsRepository {
  HouseBillsRepository(this._dio);

  final Dio _dio;

  Future<List<HouseBillModel>> list({
    HouseBillStatus? status,
  }) async {
    final response = await _dio.get(
      '/house-bills',
      queryParameters: {
        if (status != null) 'status': status.apiValue,
      },
    );

    final data = response.data as List<dynamic>? ?? <dynamic>[];
    return data
        .map((bill) => HouseBillModel.fromJson(bill as Map<String, dynamic>))
        .toList();
  }

  Future<HouseBillsDashboardDetailModel> getDashboard() async {
    final response = await _dio.get('/house-bills/dashboard');
    return HouseBillsDashboardDetailModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<HouseBillModel> create({
    required String description,
    required double amount,
    required DateTime dueDate,
    required String category,
  }) async {
    final response = await _dio.post(
      '/house-bills',
      data: {
        'description': description,
        'amount': amount,
        'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
        'category': category,
      },
    );

    return HouseBillModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HouseBillModel> update({
    required int id,
    required String description,
    required double amount,
    required DateTime dueDate,
    required String category,
  }) async {
    final response = await _dio.put(
      '/house-bills/$id',
      data: {
        'description': description,
        'amount': amount,
        'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
        'category': category,
      },
    );

    return HouseBillModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HouseBillModel> markAsPaid(int id) async {
    final response = await _dio.patch('/house-bills/$id/payment');
    return HouseBillModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final houseBillsRepositoryProvider = Provider<HouseBillsRepository>((ref) {
  return HouseBillsRepository(ref.watch(dioProvider));
});
