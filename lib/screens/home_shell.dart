import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/settings_service.dart';
import '../widgets/ambient_background.dart';
import '../widgets/grain_overlay.dart';
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
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          const Positioned.fill(child: GrainTexture()),
          _screens[_currentIndex],
        ],
      ),
      bottomNavigationBar: _GlassNavBar(
        currentIndex: _currentIndex,
        onSelect: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.5 : 0.65),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.6),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              selectedIndex: currentIndex,
              onDestinationSelected: onSelect,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), label: 'Oggi'),
                NavigationDestination(icon: Icon(Icons.science_outlined), label: 'Lab'),
                NavigationDestination(icon: Icon(Icons.self_improvement_outlined), label: 'Pratiche'),
                NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Scopri'),
                NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profilo'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
