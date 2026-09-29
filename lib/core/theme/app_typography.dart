import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized Typography system for Lahjti.
/// Optimized for Arabic readability and clean Latin rendering.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Cairo';

  /// Base TextTheme configured with Cairo
  static TextTheme getTextTheme({bool isDark = false}) {
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return TextTheme(
      // Display
      displayLarge: GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: primaryColor,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.3,
      ),
      displaySmall: GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.3,
      ),

      // Headline
      headlineLarge: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.35,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.35,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.35,
      ),

      // Title
      titleLarge: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        height: 1.4,
      ),

      // Body
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primaryColor,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.5,
      ),

      // Label
      labelLarge: GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.2,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        height: 1.2,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        height: 1.2,
      ),
    );
  }
}
