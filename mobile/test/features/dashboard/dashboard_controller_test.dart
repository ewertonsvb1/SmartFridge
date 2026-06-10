import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfridge_mobile/src/features/dashboard/data/dashboard_repository.dart';
import 'package:smartfridge_mobile/src/features/dashboard/presentation/dashboard_controller.dart';

void main() {
  test('globalDashboardProvider should refetch after disposal', () async {
    final responses = <GlobalDashboardModel>[
      GlobalDashboardModel(
        fridge: FridgeDashboardModel(total: 1, expired: 0, nearExpiration: 0),
        agenda: AgendaDashboardModel(
          implemented: true,
          total: 0,
          today: 0,
          upcoming: 0,
        ),
        houseBills: HouseBillsDashboardModel(
          implemented: true,
          totalOpen: 0,
          overdue: 0,
          paid: 0,
        ),
      ),
      GlobalDashboardModel(
        fridge: FridgeDashboardModel(total: 9, expired: 1, nearExpiration: 2),
        agenda: AgendaDashboardModel(
          implemented: true,
          total: 3,
          today: 1,
          upcoming: 2,
        ),
        houseBills: HouseBillsDashboardModel(
          implemented: true,
          totalOpen: 4,
          overdue: 1,
          paid: 5,
        ),
      ),
    ];
    var calls = 0;

    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          _FakeDashboardRepository(() async => responses[calls++]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final sub1 = container.listen<AsyncValue<GlobalDashboardModel>>(
      globalDashboardProvider,
      (_, __) {},
      fireImmediately: true,
    );

    await container.read(globalDashboardProvider.future);
    expect(container.read(globalDashboardProvider).value?.fridge.total, 1);

    sub1.close();
    await Future<void>.delayed(Duration.zero);

    final sub2 = container.listen<AsyncValue<GlobalDashboardModel>>(
      globalDashboardProvider,
      (_, __) {},
      fireImmediately: true,
    );

    await container.read(globalDashboardProvider.future);
    expect(container.read(globalDashboardProvider).value?.fridge.total, 9);

    sub2.close();
    expect(calls, 2);
  });
}

class _FakeDashboardRepository extends DashboardRepository {
  _FakeDashboardRepository(this._loader) : super(Dio());

  final Future<GlobalDashboardModel> Function() _loader;

  @override
  Future<GlobalDashboardModel> getDashboard() => _loader();
}
