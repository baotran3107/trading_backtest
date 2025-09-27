import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Performance'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Performance Overview Card
              _buildPerformanceOverviewCard(),
              const SizedBox(height: AppSpacing.xxxlg),

              // Performance Metrics
              _buildPerformanceMetrics(),
              const SizedBox(height: AppSpacing.xxxlg),

              // Recent Trades
              _buildRecentTrades(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxxlg),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          const Text(
            'Portfolio Performance',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Return',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    '+12.5%',
                    style: AppTextStyles.priceLarge,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Win Rate',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    '68%',
                    style: AppTextStyles.priceLarge,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Metrics',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Profit Factor',
                value: '1.85',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildMetricCard(
                title: 'Max Drawdown',
                value: '-8.2%',
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Sharpe Ratio',
                value: '1.42',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Trades',
                value: '156',
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xlg),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrades() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Trades',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildTradeRow('EUR/USD', '+2.5%', AppColors.success),
              _buildTradeRow('GBP/USD', '-1.2%', AppColors.error),
              _buildTradeRow('USD/JPY', '+0.8%', AppColors.success),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTradeRow(String pair, String pnl, Color color) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            pair,
            style: AppTextStyles.bodyMedium,
          ),
          Text(
            pnl,
            style: AppTextStyles.bodyMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
