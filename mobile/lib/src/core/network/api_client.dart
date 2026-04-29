import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/network/app_environment.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(BaseOptions(baseUrl: resolveApiBaseUrl()));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
    if (options.path.startsWith('/auth')) {
      handler.next(options);
      return;
    }

    final token = await tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }));
  return dio;
});
