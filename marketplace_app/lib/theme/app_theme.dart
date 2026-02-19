import 'package:flutter/material.dart';

class AppColors {
  static const Color livingColor10 = Color(0xFFA3B18A);
  static const Color livingColor20 = Color(0xFFD5C0A8);
  static const Color livingColor30 = Color(0xFFF2D7D5);
  static const Color livingColor40 = Color(0xFFF2E9E4);
  
  static const Color primary = livingColor10;
  static const Color accent = Color.fromARGB(255, 10, 139, 38);
  static const Color background = livingColor40;
  static const Color surface = livingColor30;
  static const Color surfaceVariant = Color(0xFFFFFFFF);
  static const Color secondary = livingColor20;
  
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF2D2D2D);
  static const Color onSurface = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B7280);
  
  static const Color outline = Color(0xFFE5E7EB);
  static const Color outlineVariant = Color(0xFFF3F4F6);
  
  static const Color error = Color(0xFFEF4444);
}

class AppTheme {
  static final lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.onBackground),
      titleTextStyle: TextStyle(
        color: AppColors.onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.outlineVariant, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.7), width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.onBackground,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: AppColors.onBackground,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleLarge: TextStyle(
        color: AppColors.onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      titleMedium: TextStyle(
        color: AppColors.onBackground,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.onBackground, 
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppColors.onSurface, 
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.3,
      ),
      labelLarge: TextStyle(
        color: AppColors.onPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),

    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onBackground,
      background: AppColors.background,
      onBackground: AppColors.onBackground,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      surfaceVariant: AppColors.surfaceVariant,
    ),

    dividerTheme: DividerThemeData(
      color: AppColors.outlineVariant,
      thickness: 0.5,
      space: 1,
    ),
  );
}
