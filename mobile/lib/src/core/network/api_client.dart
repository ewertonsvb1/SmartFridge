import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/auth/auth_session.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/network/app_environment.dart';

class AuthFailureSessionGuard {
  AuthFailureSessionGuard(this._tokenStorage, this._authSession);

  final TokenStorage _tokenStorage;
  final AuthSession _authSession;
  bool _invalidatingSession = false;

  Future<void> handle(DioException error) async {
    final statusCode = error.response?.statusCode;
    final isProtectedRoute = !error.requestOptions.path.startsWith('/auth');

    if (!isProtectedRoute ||
        (statusCode != 401 && statusCode != 403) ||
        _invalidatingSession) {
      return;
    }

    _invalidatingSession = true;
    await _tokenStorage.clearToken();
    _authSession.setAuthenticated(false);
  }
}

final dioFactoryProvider = Provider<Dio Function()>((_) {
  return () => Dio(BaseOptions(baseUrl: resolveApiBaseUrl()));
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final authSession = ref.watch(authSessionProvider);
  final dio = ref.watch(dioFactoryProvider)();
  final authFailureSessionGuard = AuthFailureSessionGuard(
    tokenStorage,
    authSession,
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.path.startsWith('/auth')) {
          handler.next(options);
          return;
        }

        final token = await tokenStorage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        await authFailureSessionGuard.handle(error);
        handler.next(error);
      },
    ),
  );
  return dio;
});
