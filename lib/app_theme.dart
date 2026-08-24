import 'dart:ui';

import 'package:flutter/material.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

/// One continuous circadian scale, not three fixed themes: t=0 is wake-up
/// light, t=1 is night. "Automatico" reads the clock into this scale;
/// Chiaro/Scuro just pin t to an endpoint. Everything below is a lerp
/// between neighbouring states — see _tokensForT.
class _StateTokens {
  const _StateTokens({
    required this.bg,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.surf,
    required this.surfaceAlpha,
    required this.border,
    required this.borderAlpha,
    required this.hairlineAlpha,
    required this.accent,
    required this.accent2,
    required this.navOpacity,
    required this.glowOpacity,
    required this.grainOpacity,
    required this.grainBlend,
    required this.btn,
    required this.btnFg,
    required this.shadowAlpha,
    required this.shadowBlur,
    required this.shadowOffsetY,
    required this.phaseLabel,
  });

  final Color bg, ink, inkSoft, inkFaint, surf, border, accent, accent2, btn, btnFg;
  final double surfaceAlpha, borderAlpha, hairlineAlpha, navOpacity, glowOpacity, grainOpacity;
  final double shadowAlpha, shadowBlur, shadowOffsetY;
  final BlendMode grainBlend;
  final String phaseLabel;
}

const _morning = _StateTokens(
  bg: Color(0xFFF6F4FA),
  ink: Color(0xFF26252F),
  inkSoft: Color(0xFF565363),
  inkFaint: Color(0xFF8A8797),
  surf: Colors.white,
  surfaceAlpha: 0.55,
  border: Colors.white,
  borderAlpha: 0.72,
  hairlineAlpha: 0.09,
  accent: Color(0xFFA08DC3),
  accent2: Color(0xFF8AC4C3),
  navOpacity: 0.9,
  glowOpacity: 0.5,
  grainOpacity: 0.045,
  grainBlend: BlendMode.srcOver,
  btn: Color(0xFF26252F),
  btnFg: Colors.white,
  shadowAlpha: 0.07,
  shadowBlur: 14,
  shadowOffsetY: 8,
  phaseLabel: 'Luce',
);

const _afternoon = _StateTokens(
  bg: Color(0xFFE9E6EE),
  ink: Color(0xFF2A2934),
  inkSoft: Color(0xFF5C5969),
  inkFaint: Color(0xFF868394),
  surf: Color(0xFFFCFBFF),
  surfaceAlpha: 0.5,
  border: Colors.white,
  borderAlpha: 0.6,
  hairlineAlpha: 0.11,
  accent: Color(0xFF9280B4),
  accent2: Color(0xFF7A96A0),
  navOpacity: 0.9,
  glowOpacity: 0.46,
  grainOpacity: 0.05,
  grainBlend: BlendMode.srcOver,
  btn: Color(0xFF2A2934),
  btnFg: Color(0xFFFCFBFF),
  shadowAlpha: 0.1,
  shadowBlur: 14,
  shadowOffsetY: 8,
  phaseLabel: 'Sospeso',
);

const _evening = _StateTokens(
  bg: Color(0xFF17161C),
  ink: Color(0xFFEDEAF5),
  inkSoft: Color(0xFFB0ACBE),
  inkFaint: Color(0xFF807C8E),
  surf: Color(0xFF383544),
  surfaceAlpha: 0.42,
  border: Color(0xFFEDEAF5),
  borderAlpha: 0.1,
  hairlineAlpha: 0.09,
  accent: Color(0xFFB9A6D9),
  accent2: Color(0xFF6E9898),
  navOpacity: 0.92,
  glowOpacity: 0.42,
  grainOpacity: 0.06,
  grainBlend: BlendMode.srcOver,
  btn: Color(0xFFEDEAF5),
  btnFg: Color(0xFF17161C),
  shadowAlpha: 0.42,
  shadowBlur: 16,
  shadowOffsetY: 10,
  phaseLabel: 'Notte',
);

double _mixD(double a, double b, double k) => a + (b - a) * k;

// Background/accent/glow are fine as a plain crossfade — they're just
// shifting hue, nothing depends on them staying legible against each
// other. Text/surface/border are different: they only work because they
// contrast against bg, and a plain lerp walks both ends toward the same
// mid-gray at once, right around the point that matters most (afternoon
// "Sospeso" -> evening "Notte" flips from a light bg to a dark one).
//
// So ink/surf/border/btn are pinned to whichever endpoint currently
// contrasts with bg's *actual* rendered luminance, not the raw time
// fraction — flipping once bg crosses the midpoint rather than bleeding
// through gray-on-gray. The flip has no visible seam in practice: the
// real app recomputes this every 15 minutes (see main.dart), never live
// mid-frame, so there's no animation to jar.
_StateTokens _mix(_StateTokens a, _StateTokens b, double k) {
  final bg = Color.lerp(a.bg, b.bg, k)!;
  final contrastK = bg.computeLuminance() >= 0.5 ? 0.0 : 1.0;

  return _StateTokens(
    bg: bg,
    ink: Color.lerp(a.ink, b.ink, contrastK)!,
    inkSoft: Color.lerp(a.inkSoft, b.inkSoft, contrastK)!,
    inkFaint: Color.lerp(a.inkFaint, b.inkFaint, contrastK)!,
    surf: Color.lerp(a.surf, b.surf, contrastK)!,
    surfaceAlpha: _mixD(a.surfaceAlpha, b.surfaceAlpha, k),
    border: Color.lerp(a.border, b.border, contrastK)!,
    borderAlpha: _mixD(a.borderAlpha, b.borderAlpha, k),
    hairlineAlpha: _mixD(a.hairlineAlpha, b.hairlineAlpha, k),
    accent: Color.lerp(a.accent, b.accent, k)!,
    accent2: Color.lerp(a.accent2, b.accent2, k)!,
    navOpacity: _mixD(a.navOpacity, b.navOpacity, k),
    glowOpacity: _mixD(a.glowOpacity, b.glowOpacity, k),
    grainOpacity: _mixD(a.grainOpacity, b.grainOpacity, k),
    grainBlend: contrastK < 0.5 ? a.grainBlend : b.grainBlend,
    btn: Color.lerp(a.btn, b.btn, contrastK)!,
    btnFg: Color.lerp(a.btnFg, b.btnFg, contrastK)!,
    shadowAlpha: _mixD(a.shadowAlpha, b.shadowAlpha, k),
    shadowBlur: _mixD(a.shadowBlur, b.shadowBlur, k),
    shadowOffsetY: _mixD(a.shadowOffsetY, b.shadowOffsetY, k),
    phaseLabel: k < 0.5 ? a.phaseLabel : b.phaseLabel,
  );
}

_StateTokens _tokensForT(double t) {
  final clamped = t.clamp(0.0, 1.0);
  if (clamped < 0.5) return _mix(_morning, _afternoon, clamped / 0.5);
  return _mix(_afternoon, _evening, (clamped - 0.5) / 0.5);
}

double _autoT() {
  final now = DateTime.now();
  final hour = now.hour + now.minute / 60.0;
  return ((hour - 6) / 17).clamp(0.0, 1.0);
}

/// The extra semantic tokens ThemeData/ColorScheme have no slot for —
/// glass surface/border alpha, ambient-glow and grain intensity, the
/// hairline-divider color, the current phase name. Widgets read these via
/// `Theme.of(context).extension<CircadianTokens>()` instead of hardcoding
/// a color or opacity number.
class CircadianTokens extends ThemeExtension<CircadianTokens> {
  const CircadianTokens({
    required this.accent2,
    required this.surfaceAlpha,
    required this.borderAlpha,
    required this.hairline,
    required this.glowOpacity,
    required this.grainOpacity,
    required this.grainBlend,
    required this.navOpacity,
    required this.shadowColor,
    required this.shadowBlur,
    required this.shadowOffsetY,
    required this.phaseLabel,
  });

  final Color accent2;
  final double surfaceAlpha;
  final double borderAlpha;
  final Color hairline;
  final double glowOpacity;
  final double grainOpacity;
  final BlendMode grainBlend;
  final double navOpacity;
  final Color shadowColor;
  final double shadowBlur;
  final double shadowOffsetY;
  final String phaseLabel;

  @override
  CircadianTokens copyWith() => this;

  @override
  CircadianTokens lerp(ThemeExtension<CircadianTokens>? other, double t) {
    if (other is! CircadianTokens) return this;
    return CircadianTokens(
      accent2: Color.lerp(accent2, other.accent2, t)!,
      surfaceAlpha: lerpDouble(surfaceAlpha, other.surfaceAlpha, t)!,
      borderAlpha: lerpDouble(borderAlpha, other.borderAlpha, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      glowOpacity: lerpDouble(glowOpacity, other.glowOpacity, t)!,
      grainOpacity: lerpDouble(grainOpacity, other.grainOpacity, t)!,
      grainBlend: t < 0.5 ? grainBlend : other.grainBlend,
      navOpacity: lerpDouble(navOpacity, other.navOpacity, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      shadowBlur: lerpDouble(shadowBlur, other.shadowBlur, t)!,
      shadowOffsetY: lerpDouble(shadowOffsetY, other.shadowOffsetY, t)!,
      phaseLabel: t < 0.5 ? phaseLabel : other.phaseLabel,
    );
  }
}

/// Fraunces is a variable font (weight, optical size, and the SOFT/WONK
/// axes for warmth/character). Bundled locally as a single variable file —
/// using FontVariation instead of the discrete FontWeight enum is what
/// makes the type feel custom rather than "default Google Fonts".
TextStyle _fraunces({
  required double fontSize,
  double weight = 380,
  double opticalSize = 48,
  double soft = 10,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Fraunces',
    fontSize: fontSize,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontVariations: [
      FontVariation('wght', weight),
      FontVariation('opsz', opticalSize),
      FontVariation('SOFT', soft),
      FontVariation('WONK', 0),
    ],
  );
}

TextStyle _inter({
  required double fontSize,
  double weight = 400,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Inter',
    fontSize: fontSize,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontVariations: [FontVariation('wght', weight)],
  );
}

class AppTheme {
  const AppTheme._();

  /// "Automatico" (ThemeMode.system in storage/UI) reads the clock into the
  /// circadian scale. Chiaro/Scuro pin it to the wake/night endpoints —
  /// manual overrides, unaffected by time.
  static ThemeData resolve(ThemeMode preference) {
    final t = switch (preference) {
      ThemeMode.light => 0.0,
      ThemeMode.dark => 1.0,
      ThemeMode.system => _autoT(),
    };
    return _build(_tokensForT(t));
  }

  static ThemeData _build(_StateTokens s) {
    final brightness = ThemeData.estimateBrightnessForColor(s.bg);
    final onAccent = ThemeData.estimateBrightnessForColor(s.accent) == Brightness.dark
        ? Colors.white
        : Colors.black;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: s.accent,
      onPrimary: onAccent,
      secondary: s.accent2,
      onSecondary: s.ink,
      error: const Color(0xFFD65C4F),
      onError: Colors.white,
      surface: s.surf,
      onSurface: s.ink,
      onSurfaceVariant: s.inkSoft,
      outline: s.inkFaint,
      outlineVariant: s.border,
    );

    // Titles/values sit close to full ink; running body copy sits a notch
    // softer (inkSoft) — the editorial brief is explicit that body text is
    // never full-strength ink, only headings and numbers are.
    final textTheme = TextTheme(
      displayLarge: _fraunces(fontSize: 42, weight: 320, opticalSize: 144, color: s.ink),
      displayMedium: _fraunces(fontSize: 36, weight: 320, opticalSize: 144, color: s.ink),
      displaySmall: _fraunces(fontSize: 30, weight: 330, opticalSize: 96, color: s.ink),
      headlineLarge: _fraunces(fontSize: 26, weight: 330, opticalSize: 96, color: s.ink),
      headlineMedium: _fraunces(fontSize: 23, weight: 350, opticalSize: 96, color: s.ink),
      headlineSmall: _fraunces(fontSize: 20, weight: 350, opticalSize: 72, color: s.ink),
      titleLarge: _fraunces(fontSize: 18, weight: 360, opticalSize: 72, color: s.ink),
      titleMedium: _fraunces(fontSize: 16, weight: 360, opticalSize: 72, color: s.ink),
      titleSmall: _inter(fontSize: 13, weight: 500, color: s.ink),
      bodyLarge: _inter(fontSize: 15, weight: 400, color: s.inkSoft, height: 1.55),
      bodyMedium: _inter(fontSize: 13, weight: 400, color: s.inkSoft, height: 1.55),
      bodySmall: _inter(fontSize: 12, weight: 400, color: s.inkSoft, height: 1.45),
      labelLarge: _inter(fontSize: 13, weight: 500, color: s.ink, letterSpacing: 0.2),
      labelMedium: _inter(fontSize: 12.5, weight: 450, color: s.inkFaint, letterSpacing: 1.8),
      labelSmall: _inter(fontSize: 11, weight: 450, color: s.inkFaint, letterSpacing: 2),
    );

    const pillShape = StadiumBorder();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: s.bg,
      fontFamily: 'Inter',
      textTheme: textTheme,
      extensions: [
        CircadianTokens(
          accent2: s.accent2,
          surfaceAlpha: s.surfaceAlpha,
          borderAlpha: s.borderAlpha,
          hairline: s.ink.withValues(alpha: s.hairlineAlpha),
          glowOpacity: s.glowOpacity,
          grainOpacity: s.grainOpacity,
          grainBlend: s.grainBlend,
          navOpacity: s.navOpacity,
          shadowColor: Colors.black.withValues(alpha: s.shadowAlpha),
          shadowBlur: s.shadowBlur,
          shadowOffsetY: s.shadowOffsetY,
          phaseLabel: s.phaseLabel,
        ),
      ],
      // AppCard (lib/widgets/app_card.dart) replaces Material's Card
      // everywhere for the glass-panel look; this theme just keeps a plain
      // Card invisible in case one slips through.
      cardTheme: const CardThemeData(elevation: 0, color: Colors.transparent, shadowColor: Colors.transparent),
      appBarTheme: AppBarTheme(
        backgroundColor: s.bg,
        foregroundColor: s.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      // Buttons are ink-monochrome, not accent-filled — the lilac/teal
      // accent is reserved for small signals (active nav, links, glow),
      // never a big block of color. Keeps the "quiet luxury" restraint.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: s.btn,
          foregroundColor: s.btnFg,
          shape: pillShape,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: _fraunces(fontSize: 15, weight: 450, opticalSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: s.inkSoft,
          side: BorderSide(color: s.border.withValues(alpha: s.borderAlpha)),
          shape: pillShape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: _fraunces(fontSize: 15, weight: 430, opticalSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: s.accent,
          textStyle: _inter(fontSize: 13, weight: 500),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pillShape),
          side: WidgetStatePropertyAll(BorderSide(color: s.border.withValues(alpha: s.borderAlpha))),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected) ? s.btn : s.surf.withValues(alpha: s.surfaceAlpha);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected) ? s.btnFg : s.ink;
          }),
          textStyle: WidgetStatePropertyAll(
            _fraunces(fontSize: 13, weight: 460, opticalSize: 13),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: s.surf.withValues(alpha: s.surfaceAlpha),
        labelStyle: _fraunces(fontSize: 12.5, weight: 450, opticalSize: 12, color: s.ink),
        shape: pillShape,
        side: BorderSide(color: s.border.withValues(alpha: s.borderAlpha)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surf.withValues(alpha: s.surfaceAlpha),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: s.border.withValues(alpha: s.borderAlpha)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: s.border.withValues(alpha: s.borderAlpha)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: s.accent, width: 1.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: s.inkFaint,
        textColor: s.ink,
        titleTextStyle: _fraunces(fontSize: 16, weight: 400, opticalSize: 16, color: s.ink),
        subtitleTextStyle: _inter(fontSize: 13, weight: 400, color: s.inkSoft),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? s.accent : Colors.transparent;
        }),
        side: BorderSide(color: s.border.withValues(alpha: s.borderAlpha * 1.4), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(s.btnFg == Colors.white ? Colors.white : s.surf),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? s.accent
              : s.ink.withValues(alpha: s.hairlineAlpha * 1.6);
        }),
      ),
      dividerTheme: DividerThemeData(color: s.ink.withValues(alpha: s.hairlineAlpha), space: 1),
    );
  }
}
