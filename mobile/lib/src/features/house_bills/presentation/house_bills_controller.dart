import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smartfridge_mobile/src/features/house_bills/data/house_bills_repository.dart';

final houseBillsStatusFilterProvider =
    StateProvider<HouseBillStatus?>((ref) => null);

final houseBillsListProvider =
    FutureProvider<List<HouseBillModel>>((ref) async {
  final status = ref.watch(houseBillsStatusFilterProvider);
  return ref.watch(houseBillsRepositoryProvider).list(status: status);
});

final houseBillsDashboardProvider =
    FutureProvider<HouseBillsDashboardDetailModel>((ref) async {
  return ref.watch(houseBillsRepositoryProvider).getDashboard();
});

final houseBillsMutationProvider =
    AutoDisposeNotifierProvider<HouseBillsMutationController, AsyncValue<void>>(
  HouseBillsMutationController.new,
);

class HouseBillsMutationController
    extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> create({
    required String description,
    required double amount,
    required DateTime dueDate,
    required String category,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(houseBillsRepositoryProvider).create(
            description: description,
            amount: amount,
            dueDate: dueDate,
            category: category,
          );
      _invalidate();
    });
  }

  Future<void> update({
    required int id,
    required String description,
    required double amount,
    required DateTime dueDate,
    required String category,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(houseBillsRepositoryProvider).update(
            id: id,
            description: description,
            amount: amount,
            dueDate: dueDate,
            category: category,
          );
      _invalidate();
    });
  }

  Future<void> markAsPaid(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(houseBillsRepositoryProvider).markAsPaid(id);
      _invalidate();
    });
  }

  void _invalidate() {
    ref.invalidate(houseBillsListProvider);
    ref.invalidate(houseBillsDashboardProvider);
    ref.invalidate(globalDashboardProvider);
  }
}

void invalidateHouseBillsProviders(WidgetRef ref) {
  ref.invalidate(houseBillsListProvider);
  ref.invalidate(houseBillsDashboardProvider);
  ref.invalidate(globalDashboardProvider);
}
