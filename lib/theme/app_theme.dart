import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

/// Centralized theme configuration for the trading game app
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        background: AppColors.background,
        onBackground: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textPrimary,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      cardTheme: _buildCardTheme(),
      dividerTheme: _buildDividerTheme(),
      scaffoldBackgroundColor: AppColors.background,
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.darkTextPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.darkTextPrimary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkTextPrimary,
        error: AppColors.error,
        onError: AppColors.darkTextPrimary,
      ),
      textTheme: _buildDarkTextTheme(),
      appBarTheme: _buildDarkAppBarTheme(),
      elevatedButtonTheme: _buildDarkElevatedButtonTheme(),
      textButtonTheme: _buildDarkTextButtonTheme(),
      outlinedButtonTheme: _buildDarkOutlinedButtonTheme(),
      inputDecorationTheme: _buildDarkInputDecorationTheme(),
      cardTheme: _buildDarkCardTheme(),
      dividerTheme: _buildDarkDividerTheme(),
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
  }

  /// Build text theme using app text styles
  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    );
  }

  /// Build app bar theme
  static AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.titleLarge,
      toolbarHeight: AppSpacing.appBarHeight,
    );
  }

  /// Build elevated button theme
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 2,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.medium,
        ),
        textStyle: AppTextStyles.buttonMedium,
        minimumSize: const Size(0, AppSpacing.buttonHeightMedium),
      ),
    );
  }

  /// Build text button theme
  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.buttonMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
      ),
    );
  }

  /// Build outlined button theme
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        textStyle: AppTextStyles.buttonMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        minimumSize: const Size(0, AppSpacing.buttonHeightMedium),
      ),
    );
  }

  /// Build input decoration theme
  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.inputBorderFocus),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.inputPadding,
        vertical: AppSpacing.medium,
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.inputPlaceholder,
      ),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  /// Build card theme
  static CardTheme _buildCardTheme() {
    return CardTheme(
      color: AppColors.backgroundCard,
      elevation: 2,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.all(AppSpacing.cardMargin),
    );
  }

  /// Build divider theme
  static DividerThemeData _buildDividerTheme() {
    return const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: AppSpacing.medium,
    );
  }

  // Dark theme helper methods
  static TextTheme _buildDarkTextTheme() {
    return const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    );
  }

  static AppBarTheme _buildDarkAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.titleLarge,
      toolbarHeight: AppSpacing.appBarHeight,
    );
  }

  static ElevatedButtonThemeData _buildDarkElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonPrimary,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 2,
        shadowColor: AppColors.darkShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.medium,
        ),
        textStyle: AppTextStyles.buttonMedium,
        minimumSize: const Size(0, AppSpacing.buttonHeightMedium),
      ),
    );
  }

  static TextButtonThemeData _buildDarkTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.buttonMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildDarkOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.darkBorder),
        textStyle: AppTextStyles.buttonMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        minimumSize: const Size(0, AppSpacing.buttonHeightMedium),
      ),
    );
  }

  static InputDecorationTheme _buildDarkInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkInputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.darkInputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.darkInputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.darkInputBorderFocus),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.inputPadding,
        vertical: AppSpacing.medium,
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.darkInputPlaceholder,
      ),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: AppColors.darkTextSecondary,
      ),
    );
  }

  static CardTheme _buildDarkCardTheme() {
    return CardTheme(
      color: AppColors.darkBackgroundCard,
      elevation: 2,
      shadowColor: AppColors.darkShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      margin: const EdgeInsets.all(AppSpacing.cardMargin),
    );
  }

  static DividerThemeData _buildDarkDividerTheme() {
    return const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: AppSpacing.medium,
    );
  }
}
