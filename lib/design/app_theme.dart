import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const ink = Color(0xFF0D0A0A);
  static const canvas = Color(0xFF17100E);
  static const surface = Color(0xFF221713);
  static const surfaceRaised = Color(0xFF302019);
  static const parchment = Color(0xFFFFF6E7);
  static const mutedParchment = Color(0xFFD8C9B6);
  static const gold = Color(0xFFE6B968);
  static const goldBright = Color(0xFFFFD789);
  static const ember = Color(0xFFEF8B5C);
  static const sky = Color(0xFF82B8F4);

  static const pageGradient = LinearGradient(
    colors: [Color(0xFF2B1A14), ink],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, .58],
  );

  static const panelGradient = LinearGradient(
    colors: [Color(0xFF3A271E), surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

abstract final class AppTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppPalette.gold,
      onPrimary: Color(0xFF25170D),
      secondary: AppPalette.sky,
      onSecondary: AppPalette.ink,
      surface: AppPalette.surface,
      onSurface: AppPalette.parchment,
      error: AppPalette.ember,
      onError: AppPalette.ink,
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppPalette.ink,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppPalette.parchment,
          fontWeight: FontWeight.w900,
          letterSpacing: -.6,
        ),
        titleLarge: TextStyle(
          color: AppPalette.parchment,
          fontWeight: FontWeight.w800,
          letterSpacing: -.3,
        ),
        titleMedium: TextStyle(
          color: AppPalette.parchment,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: TextStyle(color: AppPalette.mutedParchment, height: 1.4),
        labelLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: rounded,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.gold,
          foregroundColor: const Color(0xFF25170D),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: rounded,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.parchment,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: Color(0x44FFE4B8)),
          shape: rounded,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.surfaceRaised,
        contentTextStyle: const TextStyle(color: AppPalette.parchment),
        behavior: SnackBarBehavior.floating,
        shape: rounded,
      ),
      dividerTheme: const DividerThemeData(color: Color(0x1AFFF6E7)),
    );
  }
}
