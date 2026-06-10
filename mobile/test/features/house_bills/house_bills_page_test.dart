import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfridge_mobile/src/app.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

void main() {
  testWidgets(
      'SmartHouseApp should navigate from home hub to house bills and render dashboard',
      (WidgetTester tester) async {
    final api = _HouseBillsApiMock();
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

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').at(2));
    await tester.pumpAndSettle();

    expect(find.text('Contas da Casa'), findsWidgets);
    expect(find.text('Painel financeiro da casa'), findsOneWidget);
    expect(find.text('Internet'), findsOneWidget);
    expect(find.text('Agua'), findsOneWidget);
    expect(find.text('Energia'), findsOneWidget);
    expect(find.text('Vencida'), findsWidgets);
  });

  testWidgets('SmartHouseApp should filter house bills by status in read flow',
      (WidgetTester tester) async {
    final api = _HouseBillsApiMock();
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

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').at(2));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Vencida'));
    await tester.pumpAndSettle();

    expect(find.text('Agua'), findsOneWidget);
    expect(find.text('Internet'), findsNothing);
    expect(find.text('Energia'), findsNothing);
  });

  testWidgets(
      'SmartHouseApp should create and update house bills with refreshed dashboard',
      (WidgetTester tester) async {
    final api = _HouseBillsApiMock();
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

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').at(2));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('house-bills-total-count')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('house-bills-total-count')))
          .data,
      '3',
    );

    await tester.tap(find.byKey(const ValueKey('house-bills-add-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Condominio');
    await tester.enterText(find.byType(TextFormField).at(1), '150.25');
    await tester.enterText(find.byType(TextFormField).at(2), 'Moradia');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Condominio'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('house-bills-total-count')))
          .data,
      '4',
    );
    expect(
      tester
              .widget<Text>(
                  find.byKey(const ValueKey('house-bills-total-amount')))
              .data ??
          '',
      contains('395'),
    );

    await tester.scrollUntilVisible(
      find.text('Condominio'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Condominio'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Condominio torre A',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '155.75');
    await tester.enterText(find.byType(TextFormField).at(2), 'Residencial');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Condominio torre A'), findsOneWidget);
    expect(find.text('Condominio'), findsNothing);
    expect(
      tester
              .widget<Text>(
                  find.byKey(const ValueKey('house-bills-total-amount')))
              .data ??
          '',
      contains('401'),
    );
  });

  testWidgets(
      'SmartHouseApp should mark house bill as paid and refresh dashboards',
      (WidgetTester tester) async {
    final api = _HouseBillsApiMock();
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

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').at(2));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('house-bills-open-count')))
          .data,
      '1',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('house-bills-paid-count')))
          .data,
      '1',
    );

    await tester.tap(find.byKey(const ValueKey('house-bill-pay-button-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('house-bill-pay-button-1')), findsNothing);
    expect(find.text('Conta marcada como paga.'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('house-bills-open-count')))
          .data,
      '0',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('house-bills-paid-count')))
          .data,
      '2',
    );

    await tester.tap(find.byTooltip('Voltar ao inicio'));
    await tester.pumpAndSettle();

    expect(find.text('0 contas abertas e 1 vencidas'), findsOneWidget);
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

class _HouseBillsApiMock {
  int _nextId = 4;

  final List<Map<String, dynamic>> _bills = [
    {
      'id': 1,
      'description': 'Internet',
      'amount': 120.50,
      'dueDate': '2026-06-12',
      'category': 'Casa',
      'status': 'OPEN',
      'paidAt': null,
      'userId': 1,
      'createdAt': '2026-06-09T10:00:00Z',
    },
    {
      'id': 2,
      'description': 'Agua',
      'amount': 45.10,
      'dueDate': '2026-06-05',
      'category': 'Casa',
      'status': 'OVERDUE',
      'paidAt': null,
      'userId': 1,
      'createdAt': '2026-06-09T10:00:00Z',
    },
    {
      'id': 3,
      'description': 'Energia',
      'amount': 80.00,
      'dueDate': '2026-06-08',
      'category': 'Moradia',
      'status': 'PAID',
      'paidAt': '2026-06-08',
      'userId': 1,
      'createdAt': '2026-06-09T10:00:00Z',
    },
  ];

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

          if (options.path == '/house-bills/dashboard') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: _buildDashboard(),
              ),
            );
            return;
          }

          if (options.path == '/house-bills' && method == 'POST') {
            final data = Map<String, dynamic>.from(options.data as Map);
            final created = {
              'id': _nextId++,
              'description': data['description'] as String? ?? '',
              'amount': double.parse(data['amount'].toString()),
              'dueDate': data['dueDate'] as String,
              'category': data['category'] as String? ?? '',
              'status': _statusFor(
                dueDate: data['dueDate'] as String,
                paidAt: null,
              ),
              'paidAt': null,
              'userId': 1,
              'createdAt': '2026-06-09T10:00:00Z',
            };
            _bills.add(created);
            handler.resolve(Response(requestOptions: options, data: created));
            return;
          }

          if (options.path == '/house-bills' && method == 'GET') {
            final status = options.queryParameters['status'] as String?;
            final filtered = status == null
                ? _bills
                : _bills.where((bill) => bill['status'] == status).toList();
            handler.resolve(
              Response(
                requestOptions: options,
                data: filtered,
              ),
            );
            return;
          }

          if (options.path.startsWith('/house-bills/') && method == 'PUT') {
            final id = int.parse(options.path.split('/').last);
            final index = _bills.indexWhere((bill) => bill['id'] == id);
            final current = _bills[index];
            final data = Map<String, dynamic>.from(options.data as Map);

            final updated = {
              ...current,
              'description': data['description'] as String? ?? '',
              'amount': double.parse(data['amount'].toString()),
              'dueDate': data['dueDate'] as String,
              'category': data['category'] as String? ?? '',
              'status': _statusFor(
                dueDate: data['dueDate'] as String,
                paidAt: current['paidAt'] as String?,
              ),
            };
            _bills[index] = updated;
            handler.resolve(Response(requestOptions: options, data: updated));
            return;
          }

          if (options.path.endsWith('/payment') && method == 'PATCH') {
            final segments = options.path.split('/');
            final id = int.parse(segments[segments.length - 2]);
            final index = _bills.indexWhere((bill) => bill['id'] == id);
            final current = _bills[index];
            final paidAt = DateTime.now().toIso8601String().split('T').first;

            final updated = {
              ...current,
              'status': 'PAID',
              'paidAt': paidAt,
            };
            _bills[index] = updated;
            handler.resolve(Response(requestOptions: options, data: updated));
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

          if (options.path == '/shopping-list' ||
              options.path == '/notifications' ||
              options.path == '/agenda/events') {
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

  Map<String, dynamic> _buildDashboard() {
    double sumAmount(Iterable<Map<String, dynamic>> bills) {
      return bills.fold<double>(
        0,
        (total, bill) => total + double.parse(bill['amount'].toString()),
      );
    }

    final open = _bills.where((bill) => bill['status'] == 'OPEN').toList();
    final overdue =
        _bills.where((bill) => bill['status'] == 'OVERDUE').toList();
    final paid = _bills.where((bill) => bill['status'] == 'PAID').toList();

    return {
      'totalCount': _bills.length,
      'openCount': open.length,
      'overdueCount': overdue.length,
      'paidCount': paid.length,
      'totalAmount': sumAmount(_bills),
      'openAmount': sumAmount(open),
      'overdueAmount': sumAmount(overdue),
      'paidAmount': sumAmount(paid),
    };
  }

  Map<String, dynamic> _buildGlobalDashboard() {
    final dashboard = _buildDashboard();

    return {
      'fridge': {
        'total': 8,
        'expired': 1,
        'nearExpiration': 2,
      },
      'agenda': {
        'implemented': true,
        'total': 1,
        'today': 1,
        'upcoming': 0,
      },
      'houseBills': {
        'implemented': true,
        'totalOpen': dashboard['openCount'],
        'overdue': dashboard['overdueCount'],
        'paid': dashboard['paidCount'],
      },
    };
  }

  String _statusFor({
    required String dueDate,
    required String? paidAt,
  }) {
    if (paidAt != null && paidAt.isNotEmpty) {
      return 'PAID';
    }

    final due = DateTime.parse('${dueDate}T00:00:00');
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day);
    return due.isBefore(cutoff) ? 'OVERDUE' : 'OPEN';
  }
}
