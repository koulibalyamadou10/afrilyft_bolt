import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get driverTheme {
    return ThemeData(
      primaryColor: AppColors.driverPrimary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme(
        primary: AppColors.driverPrimary,
        secondary: AppColors.driverSecondary,
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
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.driverPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.driverPrimary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}