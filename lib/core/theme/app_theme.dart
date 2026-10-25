import 'package:flutter/material.dart';

/// Brand colors, taken from the Cubanía logo.
class CubaniaColors {
  const CubaniaColors._();

  /// The logo's purple.
  static const Color morado = Color(0xFF52056F);
  static const Color moradoDeep = Color(0xFF36034A);

  /// Light tint of the logo purple, for accents on dark surfaces.
  static const Color lila = Color(0xFFD9B3EE);
  static const Color lavanda = Color(0xFFF4EAF9);
  static const Color blanco = Color(0xFFFCF9FD);
  static const Color negro = Color(0xFF12051A);
  static const Color gris = Color(0xFF1C0F24);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
    ColorScheme.fromSeed(
      seedColor: CubaniaColors.morado,
      primary: CubaniaColors.morado,
      onPrimary: Colors.white,
      primaryContainer: CubaniaColors.lavanda,
      onPrimaryContainer: CubaniaColors.moradoDeep,
      secondary: CubaniaColors.moradoDeep,
      surface: CubaniaColors.blanco,
    ),
  );

  static ThemeData get dark => _build(
    ColorScheme.fromSeed(
      seedColor: CubaniaColors.morado,
      brightness: Brightness.dark,
      primary: CubaniaColors.lila,
      onPrimary: CubaniaColors.moradoDeep,
      primaryContainer: CubaniaColors.morado,
      onPrimaryContainer: Colors.white,
      secondary: CubaniaColors.lila,
      surface: CubaniaColors.gris,
    ),
  );

  static ThemeData _build(ColorScheme colorScheme) {
    const radius = BorderRadius.all(Radius.circular(16));

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colorScheme.primary,
          selectedForegroundColor: colorScheme.onPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }
}
