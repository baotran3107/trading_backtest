import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Demo widget showcasing theme-aware colors and white tone colors
class ThemeDemoWidget extends StatelessWidget {
  const ThemeDemoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.backgroundSecondary(context),
      appBar: AppBar(
        title: Text(
          'Theme Demo',
          style: TextStyle(color: ThemeColors.textPrimary(context)),
        ),
        backgroundColor: ThemeColors.background(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'White Tone Colors'),
            const SizedBox(height: AppSpacing.lg),
            _buildWhiteToneGrid(context),
            const SizedBox(height: AppSpacing.xxxlg),
            _buildSectionTitle(context, 'Theme-Aware Backgrounds'),
            const SizedBox(height: AppSpacing.lg),
            _buildBackgroundDemo(context),
            const SizedBox(height: AppSpacing.xxxlg),
            _buildSectionTitle(context, 'Theme-Aware Text Colors'),
            const SizedBox(height: AppSpacing.lg),
            _buildTextDemo(context),
            const SizedBox(height: AppSpacing.xxxlg),
            _buildSectionTitle(context, 'Gradient Examples'),
            const SizedBox(height: AppSpacing.lg),
            _buildGradientDemo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ThemeColors.textPrimary(context),
      ),
    );
  }

  Widget _buildWhiteToneGrid(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(21, (index) {
        final intensity = index * 5; // 0, 5, 10, ..., 100
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: ThemeColors.whiteTone(context, intensity),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            border: Border.all(
              color: ThemeColors.border(context),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '$intensity',
              style: TextStyle(
                color: intensity > 50
                    ? ThemeColors.whiteTone(context, 100)
                    : ThemeColors.whiteTone(context, 0),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBackgroundDemo(BuildContext context) {
    return Column(
      children: [
        _buildBackgroundCard(
          context,
          'Primary Background',
          ThemeColors.background(context),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildBackgroundCard(
          context,
          'Secondary Background',
          ThemeColors.backgroundSecondary(context),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildBackgroundCard(
          context,
          'Card Background',
          ThemeColors.backgroundCard(context),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildBackgroundCard(
          context,
          'Surface',
          ThemeColors.surface(context),
        ),
      ],
    );
  }

  Widget _buildBackgroundCard(BuildContext context, String title, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: ThemeColors.border(context),
          width: 1,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: ThemeColors.textPrimary(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextDemo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Text',
          style: TextStyle(
            color: ThemeColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Secondary Text',
          style: TextStyle(
            color: ThemeColors.textSecondary(context),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tertiary Text',
          style: TextStyle(
            color: ThemeColors.textTertiary(context),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Disabled Text',
          style: TextStyle(
            color: ThemeColors.textDisabled(context),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Hint Text',
          style: TextStyle(
            color: ThemeColors.textHint(context),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientDemo(BuildContext context) {
    return Column(
      children: [
        _buildGradientCard(
          context,
          'White Tone Gradient (100-80)',
          ThemeColors.whiteToneGradient(context, 100, 80),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildGradientCard(
          context,
          'White Tone Gradient with Opacity (100-60)',
          ThemeColors.whiteToneGradientWithOpacity(context, 100, 60, 1.0, 0.7),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildGradientCard(
          context,
          'White Tone Gradient (90-50)',
          ThemeColors.whiteToneGradient(context, 90, 50),
        ),
      ],
    );
  }

  Widget _buildGradientCard(
      BuildContext context, String title, LinearGradient gradient) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: ThemeColors.border(context),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: ThemeColors.textPrimary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
