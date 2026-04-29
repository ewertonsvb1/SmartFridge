import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);
  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<void> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['token'] as String;
    await _tokenStorage.writeToken(token);
  }

  Future<void> register(String name, String email, String password) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final token = response.data['token'] as String;
    await _tokenStorage.writeToken(token);
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});
