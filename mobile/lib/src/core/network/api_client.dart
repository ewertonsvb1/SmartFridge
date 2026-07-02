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
    final isProtectedRoute =
        !error.requestOptions.path.startsWith('/auth');

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
        final token = await tokenStorage.readToken();

        if (!options.path.startsWith('/auth') &&
            token != null &&
            token.isNotEmpty) {
          options.headers['Authorization'] =
              'Bearer $token';
        }

        print('========================');
        print('HTTP ${options.method}');
        print('URL: ${options.baseUrl}${options.path}');
        print('HEADERS: ${options.headers}');
        print('BODY: ${options.data}');
        print('========================');

        handler.next(options);
      },

      onResponse: (response, handler) {
        print('========================');
        print('RESPOSTA');
        print('STATUS: ${response.statusCode}');
        print('URL: ${response.requestOptions.uri}');
        print('DATA: ${response.data}');
        print('========================');

        handler.next(response);
      },

      onError: (error, handler) async {
        print('========================');
        print('ERRO DIO');
        print('URL: ${error.requestOptions.uri}');
        print('STATUS: ${error.response?.statusCode}');
        print('MESSAGE: ${error.message}');
        print('DATA: ${error.response?.data}');
        print('========================');

        await authFailureSessionGuard.handle(error);

        handler.next(error);
      },
    ),
  );

  return dio;
});