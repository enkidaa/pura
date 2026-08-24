import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../l10n/app_locale.dart';
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
      appLocaleNotifier.value = localeFromCode(settings.language);
    } catch (_) {
      // Keep defaults (system theme, Italian) if this fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: RepaintBoundary(child: AmbientBackground())),
          const Positioned.fill(child: RepaintBoundary(child: GrainTexture())),
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

/// Thin, quiet nav — text labels only, the active item read through color
/// and a small breathing dot rather than an icon or a filled indicator.
class _GlassNavBar extends StatefulWidget {
  const _GlassNavBar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const labels = ['Oggi', 'Lab', 'Pratiche', 'Scopri', 'Profilo'];

  @override
  State<_GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<_GlassNavBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))
      ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<CircadianTokens>()!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // No BackdropFilter here anymore — this bar is always on screen, so a
    // real blur would have to re-sample its backdrop on every scroll frame
    // of whatever's underneath it, forever. A flat translucent fill reads
    // almost the same and costs nothing.
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: tokens.navOpacity),
        border: Border(top: BorderSide(color: tokens.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_GlassNavBar.labels.length, (i) {
              final active = i == widget.currentIndex;
              return _NavTarget(
                label: _GlassNavBar.labels[i],
                active: active,
                color: active ? scheme.primary : scheme.outline,
                pulse: _pulse,
                reduceMotion: reduceMotion,
                onTap: () => widget.onSelect(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTarget extends StatelessWidget {
  const _NavTarget({
    required this.label,
    required this.active,
    required this.color,
    required this.pulse,
    required this.reduceMotion,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color color;
  final Animation<double> pulse;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                letterSpacing: 0.5,
                color: color,
                fontVariations: const [FontVariation('wght', 500)],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 3,
              height: 3,
              // RepaintBoundary is load-bearing here, not decorative: this
              // dot is the only thing in the whole app still animating
              // every frame, and it lives inside the nav bar's own
              // BackdropFilter (blur 30, always on screen). Without the
              // boundary, every tick forces that blur to recomposite too —
              // a permanent 60fps cost on every screen in the app.
              child: active
                  ? RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: pulse,
                        builder: (context, _) {
                          final opacity = reduceMotion
                              ? 0.7
                              : 0.35 + 0.65 * (0.5 - 0.5 * math.cos(pulse.value * 2 * math.pi));
                          return Opacity(
                            opacity: opacity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                          );
                        },
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
