import 'package:flutter/material.dart';

/// Centralized color palette for the Lahjti app.
/// Designed with warm, friendly, premium educational tones.
class AppColors {
  AppColors._();

  // Primary brand colors (Warm Deep Teal)
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryContainer = Color(0xFFE6FFFA);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary brand colors (Warm Coral / Sunset Orange)
  static const Color secondary = Color(0xFFEA580C);
  static const Color secondaryLight = Color(0xFFFB923C);
  static const Color secondaryDark = Color(0xFFC2410C);
  static const Color secondaryContainer = Color(0xFFFFF7ED);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Accent / Gamification (Warm Amber)
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentContainer = Color(0xFFFEF3C7);

  // Neutral surfaces (Light Mode)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightVariant = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFE2E8F0);

  // Text colors (Light Mode)
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  // Dark Theme Palette (Ready for dark mode implementation)
  static const Color backgroundDark = Color(0xFF0B1320);
  static const Color surfaceDark = Color(0xFF152238);
  static const Color surfaceDarkVariant = Color(0xFF1E2D4A);
  static const Color borderDark = Color(0xFF283958);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // Status & Feedback colors
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFECFDF5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFEFF6FF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmHeroGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF064E3B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
