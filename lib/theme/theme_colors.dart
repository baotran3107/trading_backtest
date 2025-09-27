import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware color helper that provides colors based on current theme mode
class ThemeColors {
  // Private constructor to prevent instantiation
  ThemeColors._();

  /// Get background color - always white for main theme
  static Color background(BuildContext context) {
    return AppColors.background; // Always white
  }

  /// Get secondary background color - always light for main theme
  static Color backgroundSecondary(BuildContext context) {
    return AppColors.backgroundSecondary; // Always light
  }

  /// Get tertiary background color - always light for main theme
  static Color backgroundTertiary(BuildContext context) {
    return AppColors.backgroundTertiary; // Always light
  }

  /// Get card background color - always white for main theme
  static Color backgroundCard(BuildContext context) {
    return AppColors.backgroundCard; // Always white
  }

  /// Get card hover background color - always light for main theme
  static Color backgroundCardHover(BuildContext context) {
    return AppColors.backgroundCardHover; // Always light
  }

  /// Get surface color based on theme mode
  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurface
        : AppColors.surface;
  }

  /// Get surface variant color based on theme mode
  static Color surfaceVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;
  }

  /// Get surface container color based on theme mode
  static Color surfaceContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainer;
  }

  /// Get primary text color - always black for main theme
  static Color textPrimary(BuildContext context) {
    return AppColors.textPrimary; // Always black
  }

  /// Get secondary text color based on theme mode
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
  }

  /// Get tertiary text color based on theme mode
  static Color textTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextTertiary
        : AppColors.textTertiary;
  }

  /// Get disabled text color based on theme mode
  static Color textDisabled(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextDisabled
        : AppColors.textDisabled;
  }

  /// Get hint text color based on theme mode
  static Color textHint(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextHint
        : AppColors.textHint;
  }

  /// Get border color based on theme mode
  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorder
        : AppColors.border;
  }

  /// Get light border color based on theme mode
  static Color borderLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorderLight
        : AppColors.borderLight;
  }

  /// Get dark border color based on theme mode
  static Color borderDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorderDark
        : AppColors.borderDark;
  }

  /// Get shadow color based on theme mode
  static Color shadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkShadow
        : AppColors.shadow;
  }

  /// Get light shadow color based on theme mode
  static Color shadowLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkShadowLight
        : AppColors.shadowLight;
  }

  /// Get dark shadow color based on theme mode
  static Color shadowDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkShadowDark
        : AppColors.shadowDark;
  }

  /// Get chart background color based on theme mode
  static Color chartBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkChartBackground
        : AppColors.chartBackground;
  }

  /// Get chart grid color based on theme mode
  static Color chartGrid(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkChartGrid
        : AppColors.chartGrid;
  }

  /// Get chart text color based on theme mode
  static Color chartText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkChartText
        : AppColors.chartText;
  }

  /// Get chart axis color based on theme mode
  static Color chartAxis(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkChartAxis
        : AppColors.chartAxis;
  }

  /// Get input background color based on theme mode
  static Color inputBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkInputBackground
        : AppColors.inputBackground;
  }

  /// Get input border color based on theme mode
  static Color inputBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkInputBorder
        : AppColors.inputBorder;
  }

  /// Get input border focus color based on theme mode
  static Color inputBorderFocus(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkInputBorderFocus
        : AppColors.inputBorderFocus;
  }

  /// Get input text color based on theme mode
  static Color inputText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkInputText
        : AppColors.inputText;
  }

  /// Get input placeholder color based on theme mode
  static Color inputPlaceholder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkInputPlaceholder
        : AppColors.inputPlaceholder;
  }

  /// Get overlay color based on theme mode
  static Color overlay(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkOverlay
        : AppColors.overlay;
  }

  /// Get light overlay color based on theme mode
  static Color overlayLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkOverlayLight
        : AppColors.overlayLight;
  }

  /// Get dark overlay color based on theme mode
  static Color overlayDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkOverlayDark
        : AppColors.overlayDark;
  }

  // White tone color helpers - always use light theme colors
  /// Get white tone color based on intensity (0-100) - always light theme
  static Color whiteTone(BuildContext context, int intensity) {
    switch (intensity) {
      case 100:
        return AppColors.white;
      case 95:
        return AppColors.white95;
      case 90:
        return AppColors.white90;
      case 85:
        return AppColors.white85;
      case 80:
        return AppColors.white80;
      case 75:
        return AppColors.white75;
      case 70:
        return AppColors.white70;
      case 65:
        return AppColors.white65;
      case 60:
        return AppColors.white60;
      case 55:
        return AppColors.white55;
      case 50:
        return AppColors.white50;
      case 45:
        return AppColors.white45;
      case 40:
        return AppColors.white40;
      case 35:
        return AppColors.white35;
      case 30:
        return AppColors.white30;
      case 25:
        return AppColors.white25;
      case 20:
        return AppColors.white20;
      case 15:
        return AppColors.white15;
      case 10:
        return AppColors.white10;
      case 5:
        return AppColors.white5;
      case 0:
        return AppColors.black;
      default:
        return AppColors.white50;
    }
  }

  /// Get white tone color with opacity based on theme mode and intensity (0-100)
  static Color whiteToneWithOpacity(
      BuildContext context, int intensity, double opacity) {
    return whiteTone(context, intensity).withOpacity(opacity);
  }

  /// Get a gradient of white tones based on theme mode
  static LinearGradient whiteToneGradient(
    BuildContext context,
    int startIntensity,
    int endIntensity, {
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        whiteTone(context, startIntensity),
        whiteTone(context, endIntensity),
      ],
    );
  }

  /// Get a gradient of white tones with opacity based on theme mode
  static LinearGradient whiteToneGradientWithOpacity(
    BuildContext context,
    int startIntensity,
    int endIntensity,
    double startOpacity,
    double endOpacity, {
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        whiteToneWithOpacity(context, startIntensity, startOpacity),
        whiteToneWithOpacity(context, endIntensity, endOpacity),
      ],
    );
  }
}
