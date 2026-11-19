import 'package:flutter/material.dart';

/// Complete color palette for Cricket Hub mobile application.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand Colors
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFFFF6B00); // Vibrant Cricket Orange
  static const Color primaryLight = Color(0xFFFF8C00); // Bright Orange
  static const Color primaryDark = Color(0xFFE65100); // Deep Orange

  static const Color secondary = Color(0xFF1B2838); // Dark Navy Blue
  static const Color secondaryLight = Color(0xFF2C3E50); // Slate Navy
  static const Color secondaryDark = Color(0xFF0F1722); // Deep Navy

  static const Color accent = Color(0xFFFFAB40); // Amber Accent

  // ---------------------------------------------------------------------------
  // Backgrounds & Surfaces
  // ---------------------------------------------------------------------------
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF252525);

  // ---------------------------------------------------------------------------
  // Typography Colors
  // ---------------------------------------------------------------------------
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);

  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);

  static const Color textDisabledLight = Color(0xFFBDBDBD);
  static const Color textDisabledDark = Color(0xFF616161);

  // ---------------------------------------------------------------------------
  // Dividers & Borders
  // ---------------------------------------------------------------------------
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF373737);

  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);

  // ---------------------------------------------------------------------------
  // Status & Feedback Colors
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color info = Color(0xFF1E88E5);

  // ---------------------------------------------------------------------------
  // Cricket Specific Accent Colors
  // ---------------------------------------------------------------------------
  static const Color liveRed = Color(0xFFE53935);
  static const Color boundaryFour = Color(0xFF1E88E5);
  static const Color boundarySix = Color(0xFF8E24AA);
  static const Color wicket = Color(0xFFD32F2F);
  static const Color pitchGreen = Color(0xFF2E7D32);
  static const Color trophyGold = Color(0xFFFFD700);
  static const Color trophySilver = Color(0xFFC0C0C0);
  static const Color trophyBronze = Color(0xFFCD7F32);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------
  static const List<Color> gradientPrimary = [
    Color(0xFFFF6B00),
    Color(0xFFFF8C00),
  ];

  static const List<Color> gradientDark = [
    Color(0xFF1B2838),
    Color(0xFF2C3E50),
  ];

  static const List<Color> gradientAccent = [
    Color(0xFFFF8C00),
    Color(0xFFFFAB40),
  ];

  static const List<Color> gradientLive = [
    Color(0xFFE53935),
    Color(0xFFFF5252),
  ];

  static const LinearGradient primaryLinearGradient = LinearGradient(
    colors: gradientPrimary,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkLinearGradient = LinearGradient(
    colors: gradientDark,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liveLinearGradient = LinearGradient(
    colors: gradientLive,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
