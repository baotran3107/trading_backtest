import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';

class PriceDisplayPanel extends StatelessWidget {
  final double? currentPrice;
  final double? previousPrice;
  final String symbol;
  final String? description;
  final bool isLoading;
  final double totalPnL;
  final int totalTrades;
  final double winRate;

  const PriceDisplayPanel({
    super.key,
    this.currentPrice,
    this.previousPrice,
    required this.symbol,
    this.description,
    this.isLoading = false,
    this.totalPnL = 0.0,
    this.totalTrades = 0,
    this.winRate = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final priceChange = currentPrice != null && previousPrice != null
        ? currentPrice! - previousPrice!
        : 0.0;
    final priceChangePercent = previousPrice != null && previousPrice! > 0
        ? (priceChange / previousPrice!) * 100
        : 0.0;

    final isPositive = priceChange >= 0;
    final changeColor = isPositive ? AppColors.bullish : AppColors.bearish;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Price information row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: AppTextStyles.headlineSmall,
                    ),
                    if (description != null) ...[
                      const SizedBox(height: AppSpacing.micro),
                      Text(
                        description!,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: AppSpacing.iconMedium,
                        height: AppSpacing.iconMedium,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.bullish,
                        ),
                      )
                    else if (currentPrice != null) ...[
                      Text(
                        currentPrice!.toStringAsFixed(2),
                        style: AppTextStyles.priceLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: changeColor,
                            size: AppSpacing.iconSmall,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${isPositive ? '+' : ''}${priceChange.toStringAsFixed(2)}',
                            style: isPositive
                                ? AppTextStyles.changePositive
                                : AppTextStyles.changeNegative,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '(${isPositive ? '+' : ''}${priceChangePercent.toStringAsFixed(2)}%)',
                            style: isPositive
                                ? AppTextStyles.changePositive
                                : AppTextStyles.changeNegative,
                          ),
                        ],
                      ),
                    ] else
                      Text(
                        '--',
                        style: AppTextStyles.priceLarge.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // P&L Summary row
          if (totalTrades > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.borderLight, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPnLItem(
                    'Total P&L',
                    totalPnL >= 0
                        ? '+${totalPnL.toStringAsFixed(2)}'
                        : totalPnL.toStringAsFixed(2),
                    totalPnL >= 0 ? AppColors.bullish : AppColors.bearish,
                  ),
                  _buildPnLItem(
                    'Win Rate',
                    '${winRate.toStringAsFixed(1)}%',
                    AppColors.textPrimary,
                  ),
                  _buildPnLItem(
                    'Trades',
                    '$totalTrades',
                    AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPnLItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.captionBold,
        ),
        const SizedBox(height: AppSpacing.micro),
        Text(
          value,
          style: AppTextStyles.priceSmall.copyWith(color: color),
        ),
      ],
    );
  }
}
