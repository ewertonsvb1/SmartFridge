import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfridge_mobile/src/core/network/api_error.dart';

void main() {
  test('formatApiError should return backend message when present', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/products'),
      response: Response(
        requestOptions: RequestOptions(path: '/products'),
        statusCode: 400,
        data: {'message': 'Quantity must be positive'},
      ),
    );

    expect(formatApiError(error), 'Quantity must be positive');
  });

  test('formatApiError should return fallback for unknown errors', () {
    expect(
      formatApiError(Exception('boom')),
      'Ocorreu um erro inesperado. Tente novamente.',
    );
  });
}
