import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pura/screens/home_shell.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
    );
  });

  testWidgets('Home shell shows the five tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));

    expect(find.text('Oggi'), findsWidgets);
    expect(find.text('Lab'), findsWidgets);
    expect(find.text('Pratiche'), findsWidgets);
    expect(find.text('Scopri'), findsWidgets);
    expect(find.text('Profilo'), findsWidgets);
  });

  testWidgets('Tapping a tab switches screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));

    await tester.tap(find.text('Lab'));
    await tester.pumpAndSettle();

    expect(find.byType(Center), findsWidgets);
  });
}
