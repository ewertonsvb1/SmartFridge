import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

class GlobalDashboardModel {
  GlobalDashboardModel({
    required this.fridge,
    required this.agenda,
    required this.houseBills,
  });

  final FridgeDashboardModel fridge;
  final AgendaDashboardModel agenda;
  final HouseBillsDashboardModel houseBills;

  factory GlobalDashboardModel.fromJson(Map<String, dynamic> json) {
    return GlobalDashboardModel(
      fridge: FridgeDashboardModel.fromJson(json['fridge'] as Map<String, dynamic>),
      agenda: AgendaDashboardModel.fromJson(json['agenda'] as Map<String, dynamic>),
      houseBills: HouseBillsDashboardModel.fromJson(json['houseBills'] as Map<String, dynamic>),
    );
  }
}

class FridgeDashboardModel {
  FridgeDashboardModel({
    required this.total,
    required this.expired,
    required this.nearExpiration,
  });

  final int total;
  final int expired;
  final int nearExpiration;

  factory FridgeDashboardModel.fromJson(Map<String, dynamic> json) {
    return FridgeDashboardModel(
      total: json['total'] as int? ?? 0,
      expired: json['expired'] as int? ?? 0,
      nearExpiration: json['nearExpiration'] as int? ?? 0,
    );
  }
}

class AgendaDashboardModel {
  AgendaDashboardModel({
    required this.implemented,
    required this.total,
    required this.today,
    required this.upcoming,
  });

  final bool implemented;
  final int total;
  final int today;
  final int upcoming;

  factory AgendaDashboardModel.fromJson(Map<String, dynamic> json) {
    return AgendaDashboardModel(
      implemented: json['implemented'] as bool? ?? false,
      total: json['total'] as int? ?? 0,
      today: json['today'] as int? ?? 0,
      upcoming: json['upcoming'] as int? ?? 0,
    );
  }
}

class HouseBillsDashboardModel {
  HouseBillsDashboardModel({
    required this.implemented,
    required this.totalOpen,
    required this.overdue,
    required this.paid,
  });

  final bool implemented;
  final int totalOpen;
  final int overdue;
  final int paid;

  factory HouseBillsDashboardModel.fromJson(Map<String, dynamic> json) {
    return HouseBillsDashboardModel(
      implemented: json['implemented'] as bool? ?? false,
      totalOpen: json['totalOpen'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      paid: json['paid'] as int? ?? 0,
    );
  }
}

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<GlobalDashboardModel> getDashboard() async {
    final response = await _dio.get('/dashboard');
    return GlobalDashboardModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});
