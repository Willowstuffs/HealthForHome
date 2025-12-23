import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0C403B); //ciemny background
  static const Color background = Color(0xFFF9F5EE); //grdient
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFF6EEE7); //pola tektowe
  static const Color onBackground = Color(0xFF1EA69A); //gradient
  static const Color onSurface = Color(0xFF043B36); //tekst, przyciski
  static const Color secondary = Color(0xFF8AA39B);
  static const Color outline = Color(0xFFD1D5DB);
}

class AppTheme {
  static final lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.onBackground),
      titleTextStyle: TextStyle(
        color: AppColors.onBackground,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.secondary,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      hintStyle: TextStyle(color: AppColors.secondary),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.onBackground,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: AppColors.onBackground,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: AppColors.onBackground, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.onSurface, fontSize: 14),
      labelLarge: TextStyle(
        color: AppColors.onPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
    ),
  );
}