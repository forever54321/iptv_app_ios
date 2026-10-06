import 'package:flutter/material.dart';

import 'glass.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: AppColors.violet,
      // Screens paint their own GlossyBackground gradient on top of this.
      scaffoldBackgroundColor: AppColors.bgBottom,
      cardTheme: CardThemeData(
        color: AppColors.surfaceLo,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF151B2E),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Colors.white,
        ),
        shape: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        filled: true,
        fillColor: const Color(0xFF1B2138),
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.06), space: 1),
    );
  }
}
