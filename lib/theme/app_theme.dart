import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color background = Color(0xFF080C14);
  static const Color surface = Color(0xFF0F172A);
  static const Color surfaceCard = Color(0xFF131D31);
  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x28FFFFFF);

  // Neon Accents
  static const Color primaryCyan = Color(0xFF00F0FF);
  static const Color primaryViolet = Color(0xFF8B5CF6);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentYellow = Color(0xFFFFB703);
  static const Color accentRose = Color(0xFFFF0055);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, primaryViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient radarGradient = RadialGradient(
    colors: [
      Color(0x2500F0FF),
      Color(0x0D00F0FF),
      Colors.transparent,
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryCyan,
      canvasColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: primaryViolet,
        surface: surface,
        error: accentRose,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryCyan,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
