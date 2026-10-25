import 'package:flutter/material.dart';

/// The Cubanía logo: purple on light themes, white on dark ones.
class CubaniaLogo extends StatelessWidget {
  const CubaniaLogo({super.key, this.height = 160});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Image.asset(
      isDark ? 'assets/images/logo_white.png' : 'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Cubanía',
    );
  }
}
