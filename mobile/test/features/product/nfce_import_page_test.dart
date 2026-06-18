import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfridge_mobile/src/app.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

void main() {
  testWidgets(
      'SmartHouseApp should import NFC-e items, allow review edits and refresh dashboards',
      (WidgetTester tester) async {
    final api = _NfceImportApiMock();
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

    await tester.tap(find.widgetWithText(FilledButton, 'Importar NFC-e'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('nfce-payload-field')),
      'https://nfce.example/preview?id=1001',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Buscar nota'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nota 1001'), findsOneWidget);
    expect(find.text('Leite Integral'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('nfce-item-name-0')),
      'Leite Zero Lactose',
    );
    await tester.enterText(
      find.byKey(const ValueKey('nfce-item-quantity-0')),
      '3',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar importacao'));
    await tester.pumpAndSettle();

    expect(find.text('Leite Zero Lactose'), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar ao inicio').first);
    await tester.pumpAndSettle();

    expect(
      find.text('1 itens, 0 vencidos e 0 proximos do vencimento'),
      findsOneWidget,
    );
  });

  testWidgets('SmartHouseApp should show preview error when NFC-e lookup fails',
      (WidgetTester tester) async {
    final api = _NfceImportApiMock();
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

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Importar NFC-e'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('nfce-payload-field')),
      'bad-payload',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Buscar nota'));
    await tester.pumpAndSettle();

    expect(find.text('Nota indisponivel para importacao.'), findsOneWidget);
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

class _NfceImportApiMock {
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

          if (options.path == '/products/nfce/preview' && method == 'POST') {
            final data = Map<String, dynamic>.from(options.data as Map);
            final payload = data['qrCodePayload'] as String? ?? '';

            if (payload == 'bad-payload') {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 400,
                    data: {
                      'status': 400,
                      'message': 'Nota indisponivel para importacao.',
                      'timestamp': '2026-06-15T12:00:00Z',
                    },
                  ),
                ),
              );
              return;
            }

            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'sourceUrl': payload,
                  'accessKey': '12345678901234567890123456789012345678901234',
                  'noteNumber': '1001',
                  'emissionDate': '2026-06-15',
                  'items': [
                    {
                      'lineNumber': 1,
                      'description': 'Leite Integral',
                      'quantity': 2,
                      'suggestedManufactureDate': '2026-06-15',
                      'suggestedExpirationDate': '2026-06-22',
                      'suggestedShelfLifeDays': 7,
                      'shelfLifeRuleCode': 'LEITE_7_DIAS',
                      'manualReviewRequired': false,
                    },
                  ],
                },
              ),
            );
            return;
          }

          if (options.path == '/products/nfce/confirm' && method == 'POST') {
            final data = Map<String, dynamic>.from(options.data as Map);
            final items = (data['items'] as List<dynamic>? ?? <dynamic>[])
                .cast<Map<dynamic, dynamic>>();

            final createdProducts = items.map((item) {
              final created = {
                'id': _nextId++,
                'name': item['name'] as String? ?? '',
                'quantity': item['quantity'] as int? ?? 0,
                'manufactureDate': item['manufactureDate'] as String? ?? '',
                'expirationDate': item['expirationDate'] as String? ?? '',
                'status': _statusFor(item['expirationDate'] as String? ?? ''),
              };
              _products.add(created);
              return created;
            }).toList();

            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'createdCount': createdProducts.length,
                  'products': createdProducts,
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
