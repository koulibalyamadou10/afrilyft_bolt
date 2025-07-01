import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Thème clair (même que l'app client AfriLyft)
  static ThemeData get lightTheme {
    return ThemeData(
      // Couleurs de base
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.darkGrey,
        onBackground: AppColors.darkGrey,
        onError: AppColors.white,
        brightness: Brightness.light,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Texte
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.darkGrey),
        displayMedium: TextStyle(color: AppColors.darkGrey),
        displaySmall: TextStyle(color: AppColors.darkGrey),
        headlineLarge: TextStyle(color: AppColors.darkGrey),
        headlineMedium: TextStyle(color: AppColors.darkGrey),
        headlineSmall: TextStyle(color: AppColors.darkGrey),
        titleLarge: TextStyle(color: AppColors.darkGrey),
        titleMedium: TextStyle(color: AppColors.darkGrey),
        titleSmall: TextStyle(color: AppColors.darkGrey),
        bodyLarge: TextStyle(color: AppColors.darkGrey),
        bodyMedium: TextStyle(color: AppColors.darkGrey),
        bodySmall: TextStyle(color: AppColors.mediumGrey),
        labelLarge: TextStyle(color: AppColors.darkGrey),
        labelMedium: TextStyle(color: AppColors.darkGrey),
        labelSmall: TextStyle(color: AppColors.darkGrey),
      ),

      // Cartes
      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.lightGrey,
        thickness: 1,
      ),
    );
  }

  // Thème chauffeur (pour compatibilité)
  static ThemeData get driverTheme => lightTheme;
}
