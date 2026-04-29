import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartfridge_mobile/src/app.dart';

void main() {
  testWidgets('SmartFridgeApp should open auth flow', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartFridgeApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final hasLoginButton = find.text('Entrar').evaluate().isNotEmpty;
    final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    expect(hasLoginButton || hasLoading, isTrue);
  });
}
