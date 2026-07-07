import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartfridge_mobile/src/app.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

void main() {
  testWidgets(
      'SmartHouseApp should render the global dashboard in the home hub',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
          dioProvider.overrideWithValue(_buildMockDio()),
        ],
        child: const SmartHouseApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SmartHouse'), findsWidgets);
    expect(find.text('Geladeira'), findsOneWidget);
    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Contas da Casa'), findsWidgets);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('2 proximos'), findsOneWidget);
  });

  testWidgets('SmartHouseApp should navigate from home hub to fridge module',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
          dioProvider.overrideWithValue(_buildMockDio()),
        ],
        child: const SmartHouseApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').first);
    await tester.pumpAndSettle();

    expect(find.text('Seus itens'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
  });

  testWidgets('SmartHouseApp should return from fridge module to home hub',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
          dioProvider.overrideWithValue(_buildMockDio()),
        ],
        child: const SmartHouseApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voltar ao inicio'));
    await tester.pumpAndSettle();

    expect(find.text('Geladeira'), findsOneWidget);
    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Contas da Casa'), findsWidgets);
  });

  testWidgets('SmartHouseApp should return from product form to home hub',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
          dioProvider.overrideWithValue(_buildMockDio()),
        ],
        child: const SmartHouseApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voltar ao inicio'));
    await tester.pumpAndSettle();

    expect(find.text('SmartHouse'), findsWidgets);
    expect(find.text('Geladeira'), findsOneWidget);
  });

  testWidgets(
      'SmartHouseApp should refresh fridge count on home hub after creating a product',
      (WidgetTester tester) async {
    final api = _FridgeCountsApiMock();
    final now = DateTime.now();
    final manufactureDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 2));
    final expirationDate = manufactureDate.add(const Duration(days: 10));
    _setLargeViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
          dioProvider.overrideWithValue(api.buildDio()),
        ],
        child: const SmartHouseApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('0 itens, 0 vencidos e 0 proximos do vencimento'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('product-name-field')), 'Iogurte');
    await tester.enterText(find.byKey(const ValueKey('product-quantity-field')), '2');

    final manufactureField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-manufacture-field')),
    );
    manufactureField.controller!.text = _formatIsoDate(manufactureDate);

    final expirationField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-expiration-field')),
    );
    expirationField.controller!.text = _formatIsoDate(expirationDate);

    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Voltar ao inicio').first);
    await tester.pumpAndSettle();

    expect(
      find.text('1 itens, 0 vencidos e 0 proximos do vencimento'),
      findsOneWidget,
    );
  });

}

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<void> clearToken() async {}

  @override
  Future<String?> readToken() async => 'fake-token';

  @override
  Future<void> writeToken(String token) async {}
}

void _setLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

String _formatIsoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

Dio _buildMockDio() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path == '/dashboard') {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'fridge': {
                  'total': 8,
                  'expired': 1,
                  'nearExpiration': 2,
                },
                'agenda': {
                  'implemented': false,
                  'total': 0,
                  'today': 0,
                  'upcoming': 0,
                },
                'houseBills': {
                  'implemented': false,
                  'totalOpen': 0,
                  'overdue': 0,
                  'paid': 0,
                },
              },
            ),
          );
          return;
        }

        if (options.path == '/products/dashboard') {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'total': 0,
                'expired': 0,
                'nearExpiration': 0,
              },
            ),
          );
          return;
        }

        if (options.path == '/products') {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'content': <Map<String, dynamic>>[],
              },
            ),
          );
          return;
        }

        if (options.path == '/products/catalog/search') {
          handler.resolve(
            Response(
              requestOptions: options,
              data: <Map<String, dynamic>>[],
            ),
          );
          return;
        }

        if (options.path.startsWith('/products/catalog/barcode/')) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 404,
              data: {
                'status': 404,
                'message': 'Barcode not found',
                'timestamp': DateTime.now().toIso8601String(),
              },
            ),
          );
          return;
        }

        if (options.path == '/shopping-list' ||
            options.path == '/notifications') {
          handler.resolve(
            Response(
              requestOptions: options,
              data: <Map<String, dynamic>>[],
            ),
          );
          return;
        }

        handler.reject(
          DioException(
            requestOptions: options,
            error: 'Unexpected path: ${options.path}',
          ),
        );
      },
    ),
  );
  return dio;
}

class _FridgeCountsApiMock {
  int _nextId = 1;
  final List<Map<String, dynamic>> _products = [];

  Dio buildDio() {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final method = options.method.toUpperCase();

          if (options.path == '/dashboard') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: _buildGlobalDashboard(),
              ),
            );
            return;
          }

          if (options.path == '/products/dashboard') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: _buildProductDashboard(),
              ),
            );
            return;
          }

          if (options.path == '/products' && method == 'GET') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'content': _products.reversed
                      .map((product) => Map<String, dynamic>.from(product))
                      .toList(),
                },
              ),
            );
            return;
          }

          if (options.path == '/products' && method == 'POST') {
            final data = Map<String, dynamic>.from(options.data as Map);
            _products.add({
              'id': _nextId++,
              'name': data['name'] as String? ?? '',
              'quantity': data['quantity'] as int? ?? 0,
              'manufactureDate': data['manufactureDate'] as String? ?? '',
              'expirationDate': data['expirationDate'] as String? ?? '',
              'status': _statusFor(data['expirationDate'] as String? ?? ''),
            });
            handler.resolve(
              Response(
                requestOptions: options,
                data: _products.last,
              ),
            );
            return;
          }

          if (options.path == '/products/catalog/search') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: <Map<String, dynamic>>[],
              ),
            );
            return;
          }

          if (options.path.startsWith('/products/catalog/barcode/')) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 404,
                data: {
                  'status': 404,
                  'message': 'Barcode not found',
                  'timestamp': DateTime.now().toIso8601String(),
                },
              ),
            );
            return;
          }

          if (options.path == '/shopping-list' ||
              options.path == '/notifications' ||
              options.path == '/agenda/events' ||
              options.path == '/house-bills') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: <Map<String, dynamic>>[],
              ),
            );
            return;
          }

          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Unexpected path: ${options.path}',
            ),
          );
        },
      ),
    );
    return dio;
  }

  Map<String, dynamic> _buildGlobalDashboard() {
    final dashboard = _buildProductDashboard();
    return {
      'fridge': dashboard,
      'agenda': {
        'implemented': true,
        'total': 0,
        'today': 0,
        'upcoming': 0,
      },
      'houseBills': {
        'implemented': true,
        'totalOpen': 0,
        'overdue': 0,
        'paid': 0,
      },
    };
  }

  Map<String, dynamic> _buildProductDashboard() {
    final expired =
        _products.where((product) => product['status'] == 'EXPIRED').length;
    final nearExpiration = _products
        .where((product) => product['status'] == 'NEAR_EXPIRATION')
        .length;

    return {
      'total': _products.length,
      'expired': expired,
      'nearExpiration': nearExpiration,
    };
  }

  String _statusFor(String expirationDate) {
    final expiration = DateTime.parse('${expirationDate}T00:00:00');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threshold = today.add(const Duration(days: 3));

    if (expiration.isBefore(today)) {
      return 'EXPIRED';
    }
    if (!expiration.isAfter(threshold)) {
      return 'NEAR_EXPIRATION';
    }
    return 'OK';
  }
}
