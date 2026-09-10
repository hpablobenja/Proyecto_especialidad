// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // ===== LIGHT THEME COLORS =====

  // Primary Colors (Soft and accessible)
  static const Color primaryBlue = Color(0xFF4A6FA5); // Soft blue
  static const Color primaryBlueLight = Color(0xFF89A7C7); // Lighter blue
  static const Color primaryBlueDark = Color(0xFF2C4D7A); // Darker blue

  // Accent Colors (Soft and accessible)
  static const Color accentOrange = Color(0xFFF4A261); // Soft orange
  static const Color accentGreen = Color(0xFF2A9D8F); // Muted teal
  static const Color accentPurple = Color(0xFF9B5DE5); // Soft purple

  // Neutral Colors (Soft and accessible)
  static const Color backgroundLight = Color(
    0xFFF8F9FC,
  ); // Very light blue-gray
  static const Color surfaceLight = Color(
    0xFFF1F4F8,
  ); // Light blue-gray surface
  static const Color textFieldLight = Color.fromARGB(255, 244, 243, 243);
  static const Color cardLight = Color(0xFFFFFFFF); // Pure white cards
  static const Color textPrimary = Color(0xFF2D3748); // Dark blue-gray text
  static const Color textSecondary = Color(0xFF4A5568); // Medium blue-gray text
  static const Color textMuted = Color(0xFFA0AEC0); // Light blue-gray text
  static const Color borderLight = Color(0xFFE2E8F0); // Soft blue-gray border

  // Status Colors
  static const Color success = Color(0xFF28A745); // Success green
  static const Color warning = Color(0xFFFFC107); // Warning yellow
  static const Color error = Color(0xFFFF4D4D); // Error red (softer)
  static const Color info = Color(0xFF17A2B8); // Info blue

  // ===== DARK THEME COLORS =====

  static const Color backgroundDark = Color(
    0xFF0F172A,
  ); // Deep slate blue background
  static const Color surfaceDark = Color(0xFF1E293B); // Dark slate blue surface
  static const Color cardDark = Color(0xFF1E293B); // Dark slate blue card
  static const Color textPrimaryDark = Color(
    0xFFF8FAFC,
  ); // Very light gray-blue text
  static const Color textSecondaryDark = Color(
    0xFFCBD5E1,
  ); // Medium light gray-blue text
  static const Color textMutedDark = Color(0xFF94A3B8); // Muted gray-blue text
  static const Color borderDark = Color(0xFF334155); // Dark slate border
  static const Color textFieldDark = Color.fromARGB(255, 37, 42, 62);

  // ===== GRADIENT COLORS =====

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentOrange, Color(0xFFFF8533)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [accentGreen, Color(0xFF00D4B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== LEGACY SUPPORT (for existing code) =====

  // Keep old color names for backward compatibility
  static const Color primaryColor = primaryBlue;
  static const Color accentColor = accentOrange;
  static const Color backgroundColor = backgroundLight;
  static const Color textColor = textPrimary;
  static const Color successColor = success;
  static const Color errorColor = error;

  // ===== UTILITY METHODS =====

  static Color getBackgroundColor(bool isDark) =>
      isDark ? backgroundDark : backgroundLight;

  static Color getSurfaceColor(bool isDark) =>
      isDark ? surfaceDark : surfaceLight;

  static Color getCardColor(bool isDark) => isDark ? cardDark : cardLight;

  static Color getTextPrimaryColor(bool isDark) =>
      isDark ? textPrimaryDark : textPrimary;

  static Color getTextSecondaryColor(bool isDark) =>
      isDark ? textSecondaryDark : textSecondary;

  static Color getTextMutedColor(bool isDark) =>
      isDark ? textMutedDark : textMuted;

  static Color getBorderColor(bool isDark) => isDark ? borderDark : borderLight;

  // ===== ACCESSIBILITY HELPERS =====

  // Ensure WCAG 2.1 AA compliance (4.5:1 contrast ratio)
  static Color getAccessibleTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textPrimaryDark;
  }

  // Get accessible contrast color for any background
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
