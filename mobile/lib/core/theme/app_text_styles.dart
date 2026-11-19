import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography definitions for Cricket Hub.
/// Uses 'Poppins' for prominent headings/titles and clean typography for body and labels.
class AppTextStyles {
  AppTextStyles._();

  // ---------------------------------------------------------------------------
  // Headings (Poppins) - Light Theme
  // ---------------------------------------------------------------------------
  static TextStyle get headlineLargeLight => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimaryLight,
        height: 1.25,
      );

  static TextStyle get headlineMediumLight => GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimaryLight,
        height: 1.3,
      );

  static TextStyle get headlineSmallLight => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: AppColors.textPrimaryLight,
        height: 1.35,
      );

  // ---------------------------------------------------------------------------
  // Headings (Poppins) - Dark Theme
  // ---------------------------------------------------------------------------
  static TextStyle get headlineLargeDark => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimaryDark,
        height: 1.25,
      );

  static TextStyle get headlineMediumDark => GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimaryDark,
        height: 1.3,
      );

  static TextStyle get headlineSmallDark => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: AppColors.textPrimaryDark,
        height: 1.35,
      );

  // ---------------------------------------------------------------------------
  // Titles (Poppins) - Light Theme
  // ---------------------------------------------------------------------------
  static TextStyle get titleLargeLight => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textPrimaryLight,
        height: 1.3,
      );

  static TextStyle get titleMediumLight => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: AppColors.textPrimaryLight,
        height: 1.35,
      );

  static TextStyle get titleSmallLight => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textPrimaryLight,
        height: 1.4,
      );

  // ---------------------------------------------------------------------------
  // Titles (Poppins) - Dark Theme
  // ---------------------------------------------------------------------------
  static TextStyle get titleLargeDark => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textPrimaryDark,
        height: 1.3,
      );

  static TextStyle get titleMediumDark => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: AppColors.textPrimaryDark,
        height: 1.35,
      );

  static TextStyle get titleSmallDark => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textPrimaryDark,
        height: 1.4,
      );

  // ---------------------------------------------------------------------------
  // Body (System / Inter) - Light Theme
  // ---------------------------------------------------------------------------
  static const TextStyle bodyLargeLight = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.textPrimaryLight,
    height: 1.5,
  );

  static const TextStyle bodyMediumLight = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.textSecondaryLight,
    height: 1.45,
  );

  static const TextStyle bodySmallLight = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.textSecondaryLight,
    height: 1.4,
  );

  // ---------------------------------------------------------------------------
  // Body (System / Inter) - Dark Theme
  // ---------------------------------------------------------------------------
  static const TextStyle bodyLargeDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.textPrimaryDark,
    height: 1.5,
  );

  static const TextStyle bodyMediumDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.textSecondaryDark,
    height: 1.45,
  );

  static const TextStyle bodySmallDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.textSecondaryDark,
    height: 1.4,
  );

  // ---------------------------------------------------------------------------
  // Labels - Light Theme
  // ---------------------------------------------------------------------------
  static const TextStyle labelLargeLight = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimaryLight,
    height: 1.35,
  );

  static const TextStyle labelMediumLight = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textSecondaryLight,
    height: 1.3,
  );

  static const TextStyle labelSmallLight = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textSecondaryLight,
    height: 1.25,
  );

  // ---------------------------------------------------------------------------
  // Labels - Dark Theme
  // ---------------------------------------------------------------------------
  static const TextStyle labelLargeDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimaryDark,
    height: 1.35,
  );

  static const TextStyle labelMediumDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textSecondaryDark,
    height: 1.3,
  );

  static const TextStyle labelSmallDark = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textSecondaryDark,
    height: 1.25,
  );

  // ---------------------------------------------------------------------------
  // Cricket Specific Styles
  // ---------------------------------------------------------------------------
  static TextStyle get scoreLargeLight => GoogleFonts.poppins(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.textPrimaryLight,
      );

  static TextStyle get scoreLargeDark => GoogleFonts.poppins(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.textPrimaryDark,
      );

  static TextStyle get scoreMediumLight => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimaryLight,
      );

  static TextStyle get scoreMediumDark => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimaryDark,
      );

  // ---------------------------------------------------------------------------
  // TextTheme Bundles for ThemeData
  // ---------------------------------------------------------------------------
  static TextTheme get lightTextTheme => TextTheme(
        headlineLarge: headlineLargeLight,
        headlineMedium: headlineMediumLight,
        headlineSmall: headlineSmallLight,
        titleLarge: titleLargeLight,
        titleMedium: titleMediumLight,
        titleSmall: titleSmallLight,
        bodyLarge: bodyLargeLight,
        bodyMedium: bodyMediumLight,
        bodySmall: bodySmallLight,
        labelLarge: labelLargeLight,
        labelMedium: labelMediumLight,
        labelSmall: labelSmallLight,
      );

  static TextTheme get darkTextTheme => TextTheme(
        headlineLarge: headlineLargeDark,
        headlineMedium: headlineMediumDark,
        headlineSmall: headlineSmallDark,
        titleLarge: titleLargeDark,
        titleMedium: titleMediumDark,
        titleSmall: titleSmallDark,
        bodyLarge: bodyLargeDark,
        bodyMedium: bodyMediumDark,
        bodySmall: bodySmallDark,
        labelLarge: labelLargeDark,
        labelMedium: labelMediumDark,
        labelSmall: labelSmallDark,
      );
}
