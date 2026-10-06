import 'package:flutter/material.dart';

/// Brand colors shared with the Cubanía web (landing and review panel).
class CubaniaColors {
  const CubaniaColors._();

  static const Color morado = Color(0xFF6B21C8);
  static const Color moradoDeep = Color(0xFF3D0D7A);
  static const Color amarillo = Color(0xFFF5C842);
  static const Color blanco = Color(0xFFF9F5FF);
  static const Color negro = Color(0xFF0A0010);
  static const Color gris = Color(0xFF1A1025);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
    ColorScheme.fromSeed(
      seedColor: CubaniaColors.morado,
      primary: CubaniaColors.morado,
      secondary: CubaniaColors.amarillo,
      surface: CubaniaColors.blanco,
    ),
  );

  static ThemeData get dark => _build(
    ColorScheme.fromSeed(
      seedColor: CubaniaColors.morado,
      brightness: Brightness.dark,
      primary: CubaniaColors.amarillo,
      onPrimary: CubaniaColors.negro,
      secondary: CubaniaColors.morado,
      surface: CubaniaColors.gris,
    ),
  );

  static ThemeData _build(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
