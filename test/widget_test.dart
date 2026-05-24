import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_flutter/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Calculator supports redesigned basic flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    expect(find.byKey(const ValueKey('calc_mode_dropdown')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme_toggle_btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('history_btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('display_text')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('btn_7')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('btn_%')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('btn_8')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('btn_÷')));
    await tester.pump();

    expect(find.text('7'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('calc_mode_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scientific').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sci_sin')), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('btn_C')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('btn_9')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sci_sin')).first);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('btn_=')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('history_btn')));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    expect(find.textContaining('sin('), findsWidgets);
  });
}
