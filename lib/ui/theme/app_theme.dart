import 'package:flutter/material.dart';

/// Semantic color tokens for the "Serene Oasis" design system.
@immutable
class AwradColors extends ThemeExtension<AwradColors> {
  final Color emerald;
  final Color emeraldSoft;
  final Color amber;
  final Color amberSoft;
  final Color amberText;
  final Color cardBorder;
  final Color mutedText;
  final List<Color> heatmapLevels;

  const AwradColors({
    required this.emerald,
    required this.emeraldSoft,
    required this.amber,
    required this.amberSoft,
    required this.amberText,
    required this.cardBorder,
    required this.mutedText,
    required this.heatmapLevels,
  });

  static const light = AwradColors(
    emerald: Color(0xFF0D7A5F),
    emeraldSoft: Color(0xFFE6F4F0),
    amber: Color(0xFFD97706),
    amberSoft: Color(0xFFFEF3C7),
    amberText: Color(0xFFB45309),
    cardBorder: Color(0xFFE5EAE7),
    mutedText: Color(0xFF5A756C),
    heatmapLevels: [
      Color(0xFFE5EAE7), // Level 0 (0%)
      Color(0xFFA7E8D0), // Level 1 (1–39%)
      Color(0xFF45B893), // Level 2 (40–74%)
      Color(0xFF0D7A5F), // Level 3 (75–100%)
    ],
  );

  static const dark = AwradColors(
    emerald: Color(0xFF34D399),
    emeraldSoft: Color(0xFF133329),
    amber: Color(0xFFF59E0B),
    amberSoft: Color(0xFF3D2A0D),
    amberText: Color(0xFFFCD34D),
    cardBorder: Color(0xFF233A33),
    mutedText: Color(0xFF8CA89F),
    heatmapLevels: [
      Color(0xFF1E322B), // Level 0 (0%)
      Color(0xFF17523F), // Level 1 (1–39%)
      Color(0xFF1A8A68), // Level 2 (40–74%)
      Color(0xFF34D399), // Level 3 (75–100%)
    ],
  );

  @override
  AwradColors copyWith({
    Color? emerald,
    Color? emeraldSoft,
    Color? amber,
    Color? amberSoft,
    Color? amberText,
    Color? cardBorder,
    Color? mutedText,
    List<Color>? heatmapLevels,
  }) {
    return AwradColors(
      emerald: emerald ?? this.emerald,
      emeraldSoft: emeraldSoft ?? this.emeraldSoft,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      amberText: amberText ?? this.amberText,
      cardBorder: cardBorder ?? this.cardBorder,
      mutedText: mutedText ?? this.mutedText,
      heatmapLevels: heatmapLevels ?? this.heatmapLevels,
    );
  }

  @override
  AwradColors lerp(ThemeExtension<AwradColors>? other, double t) {
    if (other is! AwradColors) return this;
    return AwradColors(
      emerald: Color.lerp(emerald, other.emerald, t)!,
      emeraldSoft: Color.lerp(emeraldSoft, other.emeraldSoft, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      amberText: Color.lerp(amberText, other.amberText, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      heatmapLevels: List.generate(
        heatmapLevels.length,
        (i) => Color.lerp(heatmapLevels[i], other.heatmapLevels[i], t)!,
      ),
    );
  }
}

extension AwradThemeContext on BuildContext {
  AwradColors get awradColors =>
      Theme.of(this).extension<AwradColors>() ?? AwradColors.light;
}

/// Material 3 "Serene Oasis" light & dark theme definitions for Awrad.
class AppTheme {
  static ThemeData light() {
    const colors = AwradColors.light;
    const canvas = Color(0xFFF7FAF8);
    const surface = Color(0xFFFFFFFF);
    const onSurface = Color(0xFF122B24);

    final scheme = ColorScheme.fromSeed(
      seedColor: colors.emerald,
      brightness: Brightness.light,
      primary: colors.emerald,
      onPrimary: Colors.white,
      secondary: colors.amber,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      outlineVariant: colors.cardBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      extensions: const [colors],
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.emeraldSoft,
        elevation: 0,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.emerald, size: 24);
          }
          return IconThemeData(color: colors.mutedText, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colors.emerald,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: colors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.emerald,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.emerald, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const colors = AwradColors.dark;
    const canvas = Color(0xFF0D1815);
    const surface = Color(0xFF152520);
    const onSurface = Color(0xFFEAF4F0);

    final scheme = ColorScheme.fromSeed(
      seedColor: colors.emerald,
      brightness: Brightness.dark,
      primary: colors.emerald,
      onPrimary: const Color(0xFF062019),
      secondary: colors.amber,
      onSecondary: const Color(0xFF2B1800),
      surface: surface,
      onSurface: onSurface,
      outlineVariant: colors.cardBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      extensions: const [colors],
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.emeraldSoft,
        elevation: 0,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.emerald, size: 24);
          }
          return IconThemeData(color: colors.mutedText, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colors.emerald,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: colors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.emerald,
          foregroundColor: const Color(0xFF062019),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.emerald, width: 1.5),
        ),
      ),
    );
  }
}
