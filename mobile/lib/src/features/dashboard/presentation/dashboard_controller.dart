import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/features/dashboard/data/dashboard_repository.dart';

final globalDashboardProvider =
    FutureProvider.autoDispose<GlobalDashboardModel>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});
