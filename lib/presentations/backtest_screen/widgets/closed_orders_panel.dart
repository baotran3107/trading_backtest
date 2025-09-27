import 'package:flutter/material.dart';
import '../../../model/closed_order_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';

class ClosedOrdersPanel extends StatelessWidget {
  final List<ClosedOrder> closedOrders;
  final VoidCallback? onClear;

  const ClosedOrdersPanel({
    super.key,
    required this.closedOrders,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (closedOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: const Center(
          child: Text(
            'No closed orders yet',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    // Calculate total P&L
    final totalPnL =
        closedOrders.fold<double>(0.0, (sum, order) => sum + order.pnl);
    final profitableTrades =
        closedOrders.where((order) => order.isProfitable).length;
    final winRate = closedOrders.isNotEmpty
        ? (profitableTrades / closedOrders.length) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Closed Orders (${closedOrders.length})',
                style: AppTextStyles.titleMedium,
              ),
              if (onClear != null)
                TextButton(
                  onPressed: onClear,
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // P&L Summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total P&L',
                  totalPnL >= 0
                      ? '+${totalPnL.toStringAsFixed(2)}'
                      : totalPnL.toStringAsFixed(2),
                  totalPnL >= 0 ? AppColors.bullish : AppColors.bearish,
                ),
                _buildSummaryItem(
                  'Win Rate',
                  '${winRate.toStringAsFixed(1)}%',
                  AppColors.textPrimary,
                ),
                _buildSummaryItem(
                  'Trades',
                  '${closedOrders.length}',
                  AppColors.textPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.screenMargin),

          // Orders list
          Expanded(
            child: ListView.builder(
              itemCount: closedOrders.length,
              itemBuilder: (context, index) {
                final order = closedOrders[
                    closedOrders.length - 1 - index]; // Show newest first
                return _buildOrderItem(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: AppTextStyles.priceMedium.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildOrderItem(ClosedOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: order.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Order type and close reason
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: order.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              '${order.entryType} ${order.closeReason}',
              style: AppTextStyles.labelSmall.copyWith(
                color: order.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),

          // Price info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.entryPriceText} → ${order.exitPriceText}',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  '${order.lotSizeText} lots • ${_formatDuration(order.duration)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),

          // P&L
          Text(
            order.pnlText,
            style: AppTextStyles.priceSmall.copyWith(
              color: order.isProfitable ? AppColors.bullish : AppColors.bearish,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }
}
