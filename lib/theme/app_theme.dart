import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Premium Palette
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color glassFill = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0xFFE2E8F0);

  // Modern Accents
  static const Color primaryCyan = Color(0xFF2563EB); // Royal Sapphire
  static const Color primaryViolet = Color(0xFF7C3AED); // Modern Violet
  static const Color accentGreen = Color(0xFF059669); // Emerald
  static const Color accentYellow = Color(0xFFD97706); // Amber
  static const Color accentRose = Color(0xFFDC2626); // Crimson

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, primaryViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient radarGradient = RadialGradient(
    colors: [
      Color(0x152563EB),
      Color(0x082563EB),
      Colors.transparent,
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primaryCyan,
      canvasColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryCyan,
        secondary: primaryViolet,
        surface: surface,
        error: accentRose,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryCyan,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerColor: glassBorder,
    );
  }
}
