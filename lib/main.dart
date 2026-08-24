import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_theme.dart';
import 'l10n/app_locale.dart';
import 'l10n/app_strings.dart';
import 'screens/auth/auth_gate.dart';
import 'services/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  runApp(const PuraApp());
}

class PuraApp extends StatefulWidget {
  const PuraApp({super.key});

  @override
  State<PuraApp> createState() => _PuraAppState();
}

class _PuraAppState extends State<PuraApp> with WidgetsBindingObserver {
  Timer? _clockTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // "Automatico" depends on wall-clock time, not just the persisted
    // preference — re-evaluate periodically so a long-lived session drifts
    // along the circadian curve on its own.
    _clockTicker = Timer.periodic(const Duration(minutes: 15), (_) => setState(() {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, preference, _) {
        return MaterialApp(
          title: 'Pura',
          theme: AppTheme.resolve(preference),
          // We resolve the actual palette ourselves (including the
          // circadian "Automatico" curve) — forcing light here just stops
          // MaterialApp from also applying the OS dark-mode toggle on top.
          themeMode: ThemeMode.light,
          builder: (context, child) => LocaleScope(notifier: appLocaleNotifier, child: child!),
          home: const AuthGate(),
        );
      },
    );
  }
}
