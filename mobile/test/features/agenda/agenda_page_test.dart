import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfridge_mobile/src/app.dart';
import 'package:smartfridge_mobile/src/core/auth/token_storage.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

void main() {
  testWidgets(
      'SmartHouseApp should navigate from home hub to agenda and render existing events',
      (
    WidgetTester tester,
  ) async {
    _setLargeViewport(tester);
    final api = _AgendaApiMock();

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

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').at(1));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Consulta medica'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Calendario da casa'), findsOneWidget);
    expect(find.text('Consulta medica'), findsOneWidget);
    expect(find.text('Levar exames'), findsOneWidget);
  });

  testWidgets('SmartHouseApp should return from agenda module to home hub',
      (WidgetTester tester) async {
    _setLargeViewport(tester);
    final api = _AgendaApiMock();

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

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voltar ao inicio'));
    await tester.pumpAndSettle();

    expect(find.text('SmartHouse'), findsWidgets);
    expect(find.text('Geladeira'), findsOneWidget);
  });

  testWidgets('SmartHouseApp should execute agenda CRUD and status filter flow',
      (
    WidgetTester tester,
  ) async {
    _setLargeViewport(tester);
    final api = _AgendaApiMock();

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

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Reuniao semanal');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'Alinhar tarefas da casa');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Reuniao semanal'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Reuniao semanal'), findsOneWidget);

    await tester.tap(find.text('Reuniao semanal'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextFormField).at(0), 'Reuniao semanal ajustada');
    await tester.tap(find.text('Agendado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluido').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Reuniao semanal ajustada'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Reuniao semanal ajustada'), findsOneWidget);
    expect(find.text('Concluido'), findsWidgets);

    await tester.tap(find.widgetWithText(FilterChip, 'Concluido'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Reuniao semanal ajustada'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Consulta medica'), findsNothing);
    expect(find.text('Reuniao semanal ajustada'), findsOneWidget);

    await tester.tap(find.text('Reuniao semanal ajustada'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Excluir evento'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Reuniao semanal ajustada'), findsNothing);
  });

  testWidgets(
      'SmartHouseApp should keep agenda events pinned to the correct calendar day',
      (WidgetTester tester) async {
    _setLargeViewport(tester);
    final api = _AgendaApiMock();

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

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir').at(1));
    await tester.pumpAndSettle();

    await _goToMonth(tester, DateTime(2026, 6));

    const eventDayKey = ValueKey('agenda-day-2026-06-12');

    expect(find.byKey(eventDayKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(eventDayKey),
        matching: find.text('1 evento'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(eventDayKey));
    await tester.pumpAndSettle();

    expect(find.text('Evento visual 12/06'), findsOneWidget);
    expect(find.text('Dia 12 com destaque'), findsOneWidget);
  });
}

Future<void> _goToMonth(WidgetTester tester, DateTime targetMonth) async {
  final currentMonth = DateTime.now();
  final monthDelta = (targetMonth.year - currentMonth.year) * 12 +
      (targetMonth.month - currentMonth.month);
  final icon = monthDelta < 0
      ? Icons.chevron_left_rounded
      : Icons.chevron_right_rounded;

  for (var index = 0; index < monthDelta.abs(); index++) {
    await tester.tap(find.byIcon(icon));
    await tester.pumpAndSettle();
  }
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

class _AgendaApiMock {
  _AgendaApiMock() {
    final today = DateTime.now();
    _events.add(
      _eventPayload(
        id: _nextId++,
        title: 'Consulta medica',
        description: 'Levar exames',
        startAt: DateTime(today.year, today.month, today.day, 9),
        endAt: DateTime(today.year, today.month, today.day, 10),
        status: 'SCHEDULED',
      ),
    );
    _events.add(
      _eventPayload(
        id: _nextId++,
        title: 'Evento visual 12/06',
        description: 'Dia 12 com destaque',
        startAt: DateTime(2026, 6, 12, 14),
        endAt: DateTime(2026, 6, 12, 15),
        status: 'SCHEDULED',
      ),
    );
  }

  final List<Map<String, dynamic>> _events = [];
  int _nextId = 1;

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
                data: {
                  'fridge': {
                    'total': 8,
                    'expired': 1,
                    'nearExpiration': 2,
                  },
                  'agenda': {
                    'implemented': true,
                    'total': _events.length,
                    'today': _events.where(_isTodayEvent).length,
                    'upcoming': _events.length,
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

          if (options.path == '/agenda/events' && method == 'GET') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: _filterEvents(options.queryParameters),
              ),
            );
            return;
          }

          if (options.path == '/agenda/events' && method == 'POST') {
            final data = Map<String, dynamic>.from(options.data as Map);
            final created = _eventPayload(
              id: _nextId++,
              title: data['title'] as String? ?? '',
              description: data['description'] as String? ?? '',
              startAt: DateTime.parse(data['startAt'] as String),
              endAt: DateTime.parse(data['endAt'] as String),
              status: data['status'] as String? ?? 'SCHEDULED',
            );
            _events.add(created);
            handler.resolve(Response(requestOptions: options, data: created));
            return;
          }

          if (options.path.startsWith('/agenda/events/') && method == 'PUT') {
            final id = int.parse(options.path.split('/').last);
            final index = _events.indexWhere((event) => event['id'] == id);
            final data = Map<String, dynamic>.from(options.data as Map);
            final updated = _eventPayload(
              id: id,
              title: data['title'] as String? ?? '',
              description: data['description'] as String? ?? '',
              startAt: DateTime.parse(data['startAt'] as String),
              endAt: DateTime.parse(data['endAt'] as String),
              status: data['status'] as String? ?? 'SCHEDULED',
              createdAt: DateTime.parse(_events[index]['createdAt'] as String),
            );
            _events[index] = updated;
            handler.resolve(Response(requestOptions: options, data: updated));
            return;
          }

          if (options.path.startsWith('/agenda/events/') &&
              method == 'DELETE') {
            final id = int.parse(options.path.split('/').last);
            _events.removeWhere((event) => event['id'] == id);
            handler.resolve(Response(requestOptions: options, statusCode: 204));
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

  bool _isTodayEvent(Map<String, dynamic> event) {
    final today = DateTime.now();
    final startAt = DateTime.parse(event['startAt'] as String);
    return startAt.year == today.year &&
        startAt.month == today.month &&
        startAt.day == today.day;
  }

  List<Map<String, dynamic>> _filterEvents(
      Map<String, dynamic> queryParameters) {
    final date = queryParameters['date'] as String?;
    final startDate = queryParameters['startDate'] as String?;
    final endDate = queryParameters['endDate'] as String?;
    final status = queryParameters['status'] as String?;

    final filtered = _events.where((event) {
      final startAt = DateTime.parse(event['startAt'] as String);

      if (status != null && event['status'] != status) {
        return false;
      }

      if (date != null) {
        final target = DateTime.parse('${date}T00:00:00');
        return startAt.year == target.year &&
            startAt.month == target.month &&
            startAt.day == target.day;
      }

      if (startDate != null) {
        final start = DateTime.parse('${startDate}T00:00:00');
        if (startAt.isBefore(start)) {
          return false;
        }
      }

      if (endDate != null) {
        final end = DateTime.parse('${endDate}T23:59:59');
        if (startAt.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final first = DateTime.parse(a['startAt'] as String);
        final second = DateTime.parse(b['startAt'] as String);
        return first.compareTo(second);
      });

    return filtered.map((event) => Map<String, dynamic>.from(event)).toList();
  }

  Map<String, dynamic> _eventPayload({
    required int id,
    required String title,
    required String description,
    required DateTime startAt,
    required DateTime endAt,
    required String status,
    DateTime? createdAt,
  }) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'status': status,
      'userId': 1,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
