import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF6200EE);
  static const backgroundColor = Color(0xFFF5F5F5);

  static final lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      foregroundColor: Colors.white, // Ensure app bar text is visible
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
    ),
  );

  static var textColor;
}