import 'package:flutter/material.dart';

class AppColors {
  // Couleurs primaires (même que l'app client AfriLyft)
  static const Color primary = Color(0xFFFF6B5B);
  static const Color primaryDark = Color(0xFFE85A4A);
  static const Color primaryLight = Color(0xFFFFD0C8);
  static const Color primaryFaint = Color(0xFFFFF0EE);
  static const Color secondary = Color(0xFF1A0E2A);

  // Couleurs d'accent
  static const Color accent = Color(0xFF4A90E2);

  // Couleurs neutres
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF9F9F9);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFFADADAD);
  static const Color darkGrey = Color(0xFF555555);
  static const Color grey = Color(0xFF999999);

  // Couleurs fonctionnelles
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color gold = Color(0xFFFFC107);

  // Couleurs spécifiques chauffeur (pour compatibilité)
  static const Color driverPrimary =
      primary; // Utilise la couleur primaire AfriLyft
  static const Color driverSecondary =
      secondary; // Utilise la couleur secondaire AfriLyft
  static const Color driverAccent =
      accent; // Utilise la couleur d'accent AfriLyft
}
