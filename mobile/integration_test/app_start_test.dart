import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartfridge_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App should open login screen when there is no session', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Entrar'), findsOneWidget);
  });
}
