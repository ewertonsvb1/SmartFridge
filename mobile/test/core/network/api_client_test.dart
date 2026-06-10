import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfridge_mobile/src/core/auth/auth_session.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart'
    show AuthFailureSessionGuard;

void main() {
  test('AuthFailureSessionGuard should clear stale token on 403', () async {
    final tokenStorage = _MutableFakeTokenStorage();
    final session = AuthSession(tokenStorage: tokenStorage);
    final guard = AuthFailureSessionGuard(tokenStorage, session);
    await session.restore();

    expect(session.authenticated, isTrue);

    await guard.handle(
      DioException.badResponse(
        statusCode: 403,
        requestOptions: RequestOptions(path: '/dashboard'),
        response: Response(
          requestOptions: RequestOptions(path: '/dashboard'),
          statusCode: 403,
          data: {
            'status': 403,
            'message': 'Forbidden',
          },
        ),
      ),
    );

    expect(tokenStorage.token, isNull);
    expect(session.authenticated, isFalse);
  });

  test('AuthFailureSessionGuard should ignore auth endpoint failures', () async {
    final tokenStorage = _MutableFakeTokenStorage();
    final session = AuthSession(tokenStorage: tokenStorage);
    final guard = AuthFailureSessionGuard(tokenStorage, session);
    await session.restore();

    await guard.handle(
      DioException.badResponse(
        statusCode: 403,
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 403,
        ),
      ),
    );

    expect(tokenStorage.token, 'stale-token');
    expect(session.authenticated, isTrue);
  });
}

class _MutableFakeTokenStorage implements TokenStorage {
  String? token = 'stale-token';

  @override
  Future<void> clearToken() async {
    token = null;
  }

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async {
    this.token = token;
  }
}
