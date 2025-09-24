import 'package:flutter/material.dart';

class AppTheme {
  // Modern color palette
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color secondaryColor = Color(0xFFA29BFE);
  static const Color accentColor = Color(0xFF74B9FF);
  static const Color backgroundLight = Color(0xFFFDFCFF);
  static const Color backgroundDark = Color(0xFF2D3436);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF636E72);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color mutedTextColor = Color(0xFF95A3B0);
  static const Color successColor = Color(0xFF00B894);
  static const Color warningColor = Color(0xFFE17055);
  static const Color errorColor = Color(0xFFE84393);
  
  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF6C5CE7),
    Color(0xFFA29BFE),
  ];
  
  static const List<Color> accentGradient = [
    Color(0xFF74B9FF),
    Color(0xFF0984E3),
  ];
  
  static const List<Color> backgroundGradient = [
    Color(0xFFFDFCFF),
    Color(0xFFF8F9FA),
  ];

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration slowAnimation = Duration(milliseconds: 600);

  // Border radius
  static const double smallRadius = 12.0;
  static const double mediumRadius = 20.0;
  static const double largeRadius = 28.0;

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceLight,
        background: backgroundLight,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(largeRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
        ),
        color: surfaceLight,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: mutedTextColor,
          fontSize: 12,
        ),
      ),
    );
  }
}