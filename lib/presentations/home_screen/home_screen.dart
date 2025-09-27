import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../backtest_screen/backtest_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: AppSpacing.xxxlg),
              _buildActionButtonsSection(context),
              const SizedBox(height: AppSpacing.xxxlg),
              _buildRecentBacktestsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xlg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundCard,
            AppColors.backgroundCard.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting with animation
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const Text(
                      '👋',
                      style: TextStyle(fontSize: 28),
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Xin chào, Bảo',
                style: AppTextStyles.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Balance and Last Test Row
          Row(
            children: [
              // Balance Card
              Expanded(
                child: _buildInfoCard(
                  title: 'Balance',
                  value: '\$10,000',
                  icon: '💰',
                  color: AppColors.primary,
                  delay: 0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Last Test Card
              Expanded(
                child: _buildInfoCard(
                  title: 'Last Test',
                  value: 'EURUSD +250\$',
                  icon: '📈',
                  color: AppColors.success,
                  delay: 200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String icon,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        title,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtonsSection(BuildContext context) {
    return Row(
      children: [
        // Run Backtest Button
        Expanded(
          child: _buildActionButton(
            context: context,
            title: 'Run Backtest',
            icon: '🔄',
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackTestScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // View Dashboard Button
        Expanded(
          child: _buildActionButton(
            context: context,
            title: 'View Dashboard',
            icon: '📊',
            color: AppColors.secondary,
            onTap: () {
              // TODO: Navigate to dashboard
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundCard,
            AppColors.backgroundCard.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBacktestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '📊',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Recent Backtests',
              style: AppTextStyles.headlineLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Backtest Items with staggered animations
        _buildAnimatedBacktestItem(
          pair: 'EURUSD M15',
          result: '+250\$',
          date: '26/09/2025',
          isPositive: true,
          delay: 0,
        ),
        const SizedBox(height: AppSpacing.md),

        _buildAnimatedBacktestItem(
          pair: 'GBPUSD H1',
          result: '-120\$',
          date: '24/09/2025',
          isPositive: false,
          delay: 100,
        ),
        const SizedBox(height: AppSpacing.md),

        _buildAnimatedBacktestItem(
          pair: 'XAUUSD H4',
          result: '+540\$',
          date: '20/09/2025',
          isPositive: true,
          delay: 200,
        ),
      ],
    );
  }

  Widget _buildAnimatedBacktestItem({
    required String pair,
    required String result,
    required String date,
    required bool isPositive,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + delay),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: _buildBacktestItem(
              pair: pair,
              result: result,
              date: date,
              isPositive: isPositive,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBacktestItem({
    required String pair,
    required String result,
    required String date,
    required bool isPositive,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundCard,
            AppColors.backgroundCard.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: isPositive
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.error.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: (isPositive ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pair name with icon
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  isPositive ? '📈' : '📉',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  pair,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Result with enhanced styling
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: (isPositive ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                border: Border.all(
                  color: (isPositive ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                result,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Date
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
