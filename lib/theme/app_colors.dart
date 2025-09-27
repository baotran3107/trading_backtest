import 'package:flutter/material.dart';

/// Centralized color definitions for the trading game app
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Secondary Colors
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFF34D399);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF8F9FA);
  static const Color backgroundTertiary = Color(0xFFF1F3F4);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundCardHover = Color(0xFFF1F3F4);

  // Surface Colors
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceVariant = Color(0xFFF1F3F4);
  static const Color surfaceContainer = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFF9CA3AF);

  // Trading Colors
  static const Color bullish = Color(0xFF26A69A);
  static const Color bullishLight = Color(0xFF4DD0E1);
  static const Color bullishDark = Color(0xFF00695C);
  static const Color bearish = Color(0xFFEF5350);
  static const Color bearishLight = Color(0xFFFF8A80);
  static const Color bearishDark = Color(0xFFC62828);
  static const Color doji = Color(0xFF78909C);
  static const Color wick = Color(0xFF90A4AE);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF065F46);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E40AF);

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);
  static const Color borderFocus = Color(0xFF3B82F6);

  // Shadow Colors
  static const Color shadow = Color(0x40000000);
  static const Color shadowLight = Color(0x20000000);
  static const Color shadowDark = Color(0x60000000);

  // Chart Colors
  static const Color chartBackground = Color(0xFFFFFFFF);
  static const Color chartGrid = Color(0xFFF3F4F6);
  static const Color chartText = Color(0xFF4B5563);
  static const Color chartAxis = Color(0xFF9CA3AF);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF3B82F6);
  static const Color buttonPrimaryHover = Color(0xFF2563EB);
  static const Color buttonSecondary = Color(0xFF6B7280);
  static const Color buttonSecondaryHover = Color(0xFF4B5563);
  static const Color buttonSuccess = Color(0xFF10B981);
  static const Color buttonSuccessHover = Color(0xFF059669);
  static const Color buttonDanger = Color(0xFFEF4444);
  static const Color buttonDangerHover = Color(0xFFDC2626);

  // Input Colors
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color inputBorderFocus = Color(0xFF3B82F6);
  static const Color inputText = Color(0xFF1F2937);
  static const Color inputPlaceholder = Color(0xFF9CA3AF);

  // Overlay Colors
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  static const Color overlayDark = Color(0xCC000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient infoGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkBackgroundSecondary = Color(0xFF1E1E1E);
  static const Color darkBackgroundTertiary = Color(0xFF2D2D2D);
  static const Color darkBackgroundCard = Color(0xFF1E1E1E);
  static const Color darkBackgroundCardHover = Color(0xFF2D2D2D);

  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);
  static const Color darkSurfaceContainer = Color(0xFF1E1E1E);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextTertiary = Color(0xFF808080);
  static const Color darkTextDisabled = Color(0xFF666666);
  static const Color darkTextHint = Color(0xFF666666);

  static const Color darkBorder = Color(0xFF333333);
  static const Color darkBorderLight = Color(0xFF2D2D2D);
  static const Color darkBorderDark = Color(0xFF404040);

  static const Color darkShadow = Color(0x80000000);
  static const Color darkShadowLight = Color(0x40000000);
  static const Color darkShadowDark = Color(0xCC000000);

  static const Color darkChartBackground = Color(0xFF1E1E1E);
  static const Color darkChartGrid = Color(0xFF2D2D2D);
  static const Color darkChartText = Color(0xFFB3B3B3);
  static const Color darkChartAxis = Color(0xFF666666);

  static const Color darkInputBackground = Color(0xFF2D2D2D);
  static const Color darkInputBorder = Color(0xFF404040);
  static const Color darkInputBorderFocus = Color(0xFF3B82F6);
  static const Color darkInputText = Color(0xFFFFFFFF);
  static const Color darkInputPlaceholder = Color(0xFF808080);

  static const Color darkOverlay = Color(0xCC000000);
  static const Color darkOverlayLight = Color(0x80000000);
  static const Color darkOverlayDark = Color(0xFF000000);

  // White Tone Colors for better contrast and visual hierarchy
  static const Color white = Color(0xFFFFFFFF);
  static const Color white95 = Color(0xFFF2F2F2);
  static const Color white90 = Color(0xFFE6E6E6);
  static const Color white85 = Color(0xFFD9D9D9);
  static const Color white80 = Color(0xFFCCCCCC);
  static const Color white75 = Color(0xFFBFBFBF);
  static const Color white70 = Color(0xFFB3B3B3);
  static const Color white65 = Color(0xFFA6A6A6);
  static const Color white60 = Color(0xFF999999);
  static const Color white55 = Color(0xFF8C8C8C);
  static const Color white50 = Color(0xFF808080);
  static const Color white45 = Color(0xFF737373);
  static const Color white40 = Color(0xFF666666);
  static const Color white35 = Color(0xFF595959);
  static const Color white30 = Color(0xFF4D4D4D);
  static const Color white25 = Color(0xFF404040);
  static const Color white20 = Color(0xFF333333);
  static const Color white15 = Color(0xFF262626);
  static const Color white10 = Color(0xFF1A1A1A);
  static const Color white5 = Color(0xFF0D0D0D);
  static const Color black = Color(0xFF000000);

  // Dark Mode White Tone Colors (inverted for dark backgrounds)
  static const Color darkWhite = Color(0xFF000000);
  static const Color darkWhite95 = Color(0xFF0D0D0D);
  static const Color darkWhite90 = Color(0xFF1A1A1A);
  static const Color darkWhite85 = Color(0xFF262626);
  static const Color darkWhite80 = Color(0xFF333333);
  static const Color darkWhite75 = Color(0xFF404040);
  static const Color darkWhite70 = Color(0xFF4D4D4D);
  static const Color darkWhite65 = Color(0xFF595959);
  static const Color darkWhite60 = Color(0xFF666666);
  static const Color darkWhite55 = Color(0xFF737373);
  static const Color darkWhite50 = Color(0xFF808080);
  static const Color darkWhite45 = Color(0xFF8C8C8C);
  static const Color darkWhite40 = Color(0xFF999999);
  static const Color darkWhite35 = Color(0xFFA6A6A6);
  static const Color darkWhite30 = Color(0xFFB3B3B3);
  static const Color darkWhite25 = Color(0xFFBFBFBF);
  static const Color darkWhite20 = Color(0xFFCCCCCC);
  static const Color darkWhite15 = Color(0xFFD9D9D9);
  static const Color darkWhite10 = Color(0xFFE6E6E6);
  static const Color darkWhite5 = Color(0xFFF2F2F2);
  static const Color darkBlack = Color(0xFFFFFFFF);

  // Utility methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color lerp(Color a, Color b, double t) {
    return Color.lerp(a, b, t)!;
  }
}
