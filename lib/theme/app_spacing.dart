/// Centralized spacing definitions for the trading game app
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // Base spacing unit (4px)
  static const double base = 4.0;

  // Micro spacing (2px)
  static const double micro = base * 0.5;

  // Small spacing (4px)
  static const double small = base;

  // Medium spacing (8px)
  static const double medium = base * 2;

  // Large spacing (12px)
  static const double large = base * 3;

  // Extra large spacing (16px)
  static const double xl = base * 4;

  // Extra extra large spacing (20px)
  static const double xxl = base * 5;

  // Extra extra extra large spacing (24px)
  static const double xxxl = base * 6;

  // Huge spacing (32px)
  static const double huge = base * 8;

  // Massive spacing (48px)
  static const double massive = base * 12;

  // Specific spacing values
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xlg = 16.0;
  static const double xxlg = 20.0;
  static const double xxxlg = 24.0;
  static const double xxxxlg = 32.0;
  static const double xxxxxlg = 48.0;
  static const double xxxxxxlg = 64.0;

  // Component specific spacing
  static const double cardPadding = 16.0;
  static const double cardMargin = 8.0;
  static const double buttonPadding = 12.0;
  static const double inputPadding = 12.0;
  static const double sectionSpacing = 24.0;
  static const double widgetSpacing = 16.0;
  static const double listItemSpacing = 8.0;
  static const double gridSpacing = 12.0;

  // Border radius values
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 20.0;
  static const double radiusRound = 50.0;

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;
  static const double iconXXLarge = 48.0;

  // Button heights
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;
  static const double buttonHeightXLarge = 56.0;

  // Input heights
  static const double inputHeightSmall = 32.0;
  static const double inputHeightMedium = 40.0;
  static const double inputHeightLarge = 48.0;

  // Chart specific spacing
  static const double chartPadding = 16.0;
  static const double chartMargin = 8.0;
  static const double priceLabelWidth = 80.0;
  static const double timeLabelHeight = 30.0;

  // App bar and navigation
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;
  static const double tabBarHeight = 48.0;

  // Screen margins
  static const double screenMargin = 16.0;
  static const double screenMarginSmall = 8.0;
  static const double screenMarginLarge = 24.0;

  // Utility methods
  static double multiply(double base, double multiplier) {
    return base * multiplier;
  }

  static double divide(double base, double divisor) {
    return base / divisor;
  }
}
