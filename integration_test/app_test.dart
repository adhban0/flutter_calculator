import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_flutter/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and exposes core controls', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calc_mode_dropdown')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme_toggle_btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('history_btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('display_text')), findsOneWidget);
  });
}
