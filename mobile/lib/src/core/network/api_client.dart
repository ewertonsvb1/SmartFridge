import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/auth/auth_session.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';

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
  return () => Dio(
        BaseOptions(
          baseUrl: 'https://smartfridge-backend-c27p.onrender.com',
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final authSession = ref.watch(authSessionProvider);
  final dio = ref.watch(dioFactoryProvider)();
  print('API URL: ${dio.options.baseUrl}');
  final authFailureSessionGuard = AuthFailureSessionGuard(
    tokenStorage,
    authSession,
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('HTTP ${options.method} ${options.baseUrl}${options.path}');
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
        print(
          'HTTP ERROR ${error.requestOptions.method} '
          '${error.requestOptions.baseUrl}${error.requestOptions.path} '
          'status=${error.response?.statusCode} message=${error.message}',
        );
        await authFailureSessionGuard.handle(error);
        handler.next(error);
      },
    ),
  );
  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
    ),
  );
  return dio;
});
