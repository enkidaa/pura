import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/settings_service.dart';
import 'discover_screen.dart';
import 'lab_screen.dart';
import 'practices_screen.dart';
import 'profile_screen.dart';
import 'today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _screens = [
    TodayScreen(),
    LabScreen(),
    PracticesScreen(),
    DiscoverScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final settings = await SettingsService().loadSettings();
      themeModeNotifier.value = settings.themeMode;
    } catch (_) {
      // Keep default (system) theme if this fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), label: 'Oggi'),
          NavigationDestination(icon: Icon(Icons.science_outlined), label: 'Lab'),
          NavigationDestination(icon: Icon(Icons.self_improvement_outlined), label: 'Pratiche'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Scopri'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profilo'),
        ],
      ),
    );
  }
}
