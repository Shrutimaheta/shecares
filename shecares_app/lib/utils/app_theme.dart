import 'package:flutter/material.dart';

class AppColors {
  static const rose = Color(0xFFC84C7A);
  static const roseDeep = Color(0xFF8C274E);
  static const blush = Color(0xFFFBE3EB);
  static const sand = Color(0xFFF8F2ED);
  static const ink = Color(0xFF2A1F24);
  static const slate = Color(0xFF75666C);
  static const mint = Color(0xFF4C9B7A);
  static const amber = Color(0xFFE6A23C);
  static const berry = Color(0xFFA23F5B);
  static const cloud = Color(0xFFFFFCFA);
  static const danger = Color(0xFFB84747);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.rose,
      primary: AppColors.rose,
      secondary: AppColors.mint,
      surface: Colors.white,
      error: AppColors.danger,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cloud,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF0E6E0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5D6D9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5D6D9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.rose, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.rose,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          side: const BorderSide(color: Color(0xFFE2CDD4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.blush,
        side: const BorderSide(color: Color(0xFFE6D7DB)),
        labelStyle: const TextStyle(color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFF0E7E0)),
    );
  }
}
