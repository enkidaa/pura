import 'package:flutter/material.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

// Colors: soft-tech pastel lavender/mauve — the palette current wellness-app
// design research (2026) converges on for this category. Originally matched
// the Lovable prototype's oklch tokens; dark variant is hand-picked since
// the prototype only ships light.
class AppColors {
  const AppColors._();

  static const lightBackground = Color(0xFFF4F2FB);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightForeground = Color(0xFF20202D);
  static const lightMuted = Color(0xFF636171);
  static const lightPrimary = Color(0xFFA08DC3);
  static const lightAccentTeal = Color(0xFF8AC4C3);
  static const lightBorder = Color(0xFFDEDCE7);
  static const lightSecondary = Color(0xFFEDEBF5);

  static const darkBackground = Color(0xFF17161C);
  static const darkCard = Color(0xFF201F27);
  static const darkForeground = Color(0xFFEDEAF5);
  static const darkMuted = Color(0xFFA39FB0);
  static const darkPrimary = Color(0xFFB9A6D9);
  static const darkAccentTeal = Color(0xFF7FB8B7);
  static const darkBorder = Color(0xFF322F3D);
  static const darkSecondary = Color(0xFF262530);
}

/// Fraunces is a variable font (weight, optical size, and the SOFT/WONK
/// axes for warmth/character). Bundled locally as a single variable file —
/// using FontVariation instead of the discrete FontWeight enum is what
/// makes the type feel custom rather than "default Google Fonts".
TextStyle _fraunces({
  required double fontSize,
  double weight = 400,
  double opticalSize = 48,
  double soft = 20,
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

  static ThemeData light() => _build(
        background: AppColors.lightBackground,
        card: AppColors.lightCard,
        foreground: AppColors.lightForeground,
        muted: AppColors.lightMuted,
        primary: AppColors.lightPrimary,
        accentTeal: AppColors.lightAccentTeal,
        border: AppColors.lightBorder,
        secondary: AppColors.lightSecondary,
        brightness: Brightness.light,
      );

  static ThemeData dark() => _build(
        background: AppColors.darkBackground,
        card: AppColors.darkCard,
        foreground: AppColors.darkForeground,
        muted: AppColors.darkMuted,
        primary: AppColors.darkPrimary,
        accentTeal: AppColors.darkAccentTeal,
        border: AppColors.darkBorder,
        secondary: AppColors.darkSecondary,
        brightness: Brightness.dark,
      );

  static ThemeData _build({
    required Color background,
    required Color card,
    required Color foreground,
    required Color muted,
    required Color primary,
    required Color accentTeal,
    required Color border,
    required Color secondary,
    required Brightness brightness,
  }) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isLight ? Colors.white : AppColors.darkBackground,
      secondary: accentTeal,
      onSecondary: foreground,
      error: const Color(0xFFD65C4F),
      onError: Colors.white,
      surface: card,
      onSurface: foreground,
      outline: muted,
      outlineVariant: border,
    );

    final textTheme = TextTheme(
      // Big editorial greeting/page titles — light weight, gently soft
      // Fraunces for warmth without tipping into whimsy.
      displayLarge: _fraunces(fontSize: 40, weight: 380, opticalSize: 72, color: foreground),
      displayMedium: _fraunces(fontSize: 36, weight: 380, opticalSize: 64, color: foreground),
      displaySmall: _fraunces(fontSize: 32, weight: 380, opticalSize: 56, color: foreground),
      headlineLarge: _fraunces(fontSize: 28, weight: 420, opticalSize: 40, color: foreground),
      headlineMedium: _fraunces(fontSize: 24, weight: 420, opticalSize: 32, color: foreground),
      headlineSmall: _fraunces(fontSize: 20, weight: 500, opticalSize: 24, color: foreground),
      // Card/list titles — heavier weight, small optical size, minimal soft.
      titleLarge: _fraunces(fontSize: 18, weight: 600, opticalSize: 18, soft: 8, color: foreground),
      titleMedium: _fraunces(fontSize: 16, weight: 600, opticalSize: 16, soft: 8, color: foreground),
      titleSmall: _inter(fontSize: 14, weight: 600, color: foreground),
      bodyLarge: _inter(fontSize: 16, weight: 400, color: foreground, height: 1.45),
      bodyMedium: _inter(fontSize: 14, weight: 400, color: foreground, height: 1.45),
      bodySmall: _inter(fontSize: 12, weight: 400, color: muted, height: 1.4),
      labelLarge: _inter(fontSize: 14, weight: 600, color: foreground, letterSpacing: 0.3),
      labelMedium: _inter(fontSize: 12, weight: 600, color: muted, letterSpacing: 1.2),
      labelSmall: _inter(fontSize: 11, weight: 600, color: muted, letterSpacing: 1.5),
    );

    const pillShape = StadiumBorder();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      textTheme: textTheme,
      // AppCard (lib/widgets/app_card.dart) replaces Material's Card
      // everywhere for the layered soft-shadow squircle look; this theme
      // just keeps a plain Card invisible in case one slips through.
      cardTheme: const CardThemeData(elevation: 0, color: Colors.transparent, shadowColor: Colors.transparent),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return _inter(
            fontSize: 11,
            weight: 600,
            letterSpacing: 1,
            color: selected ? primary : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : muted, size: 24);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: pillShape,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: _fraunces(fontSize: 15, weight: 560, opticalSize: 15, soft: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: border),
          shape: pillShape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: _fraunces(fontSize: 15, weight: 520, opticalSize: 15, soft: 10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: _fraunces(fontSize: 15, weight: 520, opticalSize: 15, soft: 10),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pillShape),
          side: WidgetStatePropertyAll(BorderSide(color: border)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected) ? foreground : card;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected) ? card : foreground;
          }),
          textStyle: WidgetStatePropertyAll(
            _fraunces(fontSize: 14, weight: 560, opticalSize: 14, soft: 8),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondary,
        labelStyle: _fraunces(fontSize: 13, weight: 500, opticalSize: 13, color: foreground),
        shape: pillShape,
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: foreground,
        titleTextStyle: _fraunces(fontSize: 16, weight: 500, opticalSize: 16, soft: 10, color: foreground),
        subtitleTextStyle: _inter(fontSize: 13, weight: 400, color: muted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primary : Colors.transparent;
        }),
        side: BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primary : border;
        }),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1),
    );
  }
}
