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
}

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<void> clearToken() async {}

  @override
  Future<String?> readToken() async => 'fake-token';

  @override
  Future<void> writeToken(String token) async {}
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
