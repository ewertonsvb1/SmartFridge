import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/auth/auth_session.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_sync_service.dart';
import 'package:smartfridge_mobile/src/features/auth/data/auth_repository.dart';
import 'package:smartfridge_mobile/src/features/dashboard/presentation/dashboard_controller.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>(
  (ref) => AuthController(ref, ref.watch(authRepositoryProvider)),
);

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._ref, this._repository) : super(const AsyncData(null));

  final Ref _ref;
  final AuthRepository _repository;

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _repository.login(email, password));
    state = result;
    if (!result.hasError) {
      _ref.invalidate(globalDashboardProvider);
      _ref.read(authSessionProvider).setAuthenticated(true);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _repository.register(name, email, password));
    state = result;
    if (!result.hasError) {
      _ref.invalidate(globalDashboardProvider);
      _ref.read(authSessionProvider).setAuthenticated(true);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    await _ref.read(notificationSyncServiceProvider).clearSessionState();
    _ref.invalidate(globalDashboardProvider);
    _ref.read(authSessionProvider).setAuthenticated(false);
  }
}
