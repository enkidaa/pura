import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pura/app_theme.dart';
import 'package:pura/screens/home_shell.dart';

// A bare MaterialApp has no CircadianTokens ThemeExtension registered, so
// every themed widget in this app (AppCard, the nav bar, ...) crashes on
// `Theme.of(context).extension<CircadianTokens>()!`. Real app code never
// hits this because main.dart always builds via AppTheme.resolve — tests
// need to do the same. ThemeMode.light (not .system) pins the circadian
// curve to a fixed point instead of the wall clock, so the test behaves
// the same regardless of what time of day it's run.
Widget _wrapWithAppTheme(Widget child) {
  return MaterialApp(theme: AppTheme.resolve(ThemeMode.light), home: child);
}

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
    await tester.pumpWidget(_wrapWithAppTheme(const HomeShell()));

    expect(find.text('Oggi'), findsWidgets);
    expect(find.text('Lab'), findsWidgets);
    expect(find.text('Pratiche'), findsWidgets);
    expect(find.text('Scopri'), findsWidgets);
    expect(find.text('Profilo'), findsWidgets);
  });

  testWidgets('Tapping a tab switches screen', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapWithAppTheme(const HomeShell()));

    await tester.tap(find.text('Lab'));
    // Not pumpAndSettle: LabScreen kicks off real Supabase queries in
    // initState, which never resolve against the fake test project (no
    // backend here) — their loading spinner keeps animating forever, so
    // pumpAndSettle would time out waiting for a steady state that never
    // arrives. A few bounded frames are enough to prove the tab actually
    // switched and rendered the destination screen.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Integratori'), findsOneWidget);
  });
}
