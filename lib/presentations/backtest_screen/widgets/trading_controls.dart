import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';

class TradingControls extends StatelessWidget {
  final double currentPrice;
  final double lotSize;
  final List<double> availableLotSizes;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final ValueChanged<double> onLotSizeChanged;

  const TradingControls({
    super.key,
    required this.currentPrice,
    required this.lotSize,
    required this.availableLotSizes,
    required this.onBuy,
    required this.onSell,
    required this.onLotSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sellPrice = currentPrice - 0.05;
    final buyPrice = currentPrice + 0.05;

    return Container(
      height: AppSpacing.buttonHeightLarge,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: AppSpacing.buttonHeightLarge,
            child: _buildTradeButton(
              label: 'SELL',
              price: sellPrice,
              color: AppColors.bearish,
              textColor: AppColors.bearishLight,
              onTap: onSell,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: _buildLotSizeStepper(context),
          ),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: 84,
            height: AppSpacing.buttonHeightLarge,
            child: _buildTradeButton(
              label: 'BUY',
              price: buyPrice,
              color: AppColors.bullish,
              textColor: AppColors.bullishLight,
              onTap: onBuy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeButton({
    required String label,
    required double price,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    final Color darker = AppColors.lerp(color, Colors.black, 0.25);
    final bool isBuy = label.toUpperCase() == 'BUY';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [darker, color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isBuy
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: AppColors.textPrimary,
                size: AppSpacing.iconSmall,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLotSizeStepper(BuildContext context) {
    int currentIndex = availableLotSizes.indexOf(lotSize);
    if (currentIndex == -1 && availableLotSizes.isNotEmpty) {
      // Fallback to the closest value if current lot size isn't in the list
      double closest = availableLotSizes.first;
      double minDiff = (lotSize - closest).abs();
      for (final size in availableLotSizes) {
        final diff = (lotSize - size).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closest = size;
        }
      }
      currentIndex = availableLotSizes.indexOf(closest);
    }

    void decrement() {
      if (availableLotSizes.isEmpty) return;
      final nextIndex =
          (currentIndex - 1).clamp(0, availableLotSizes.length - 1);
      onLotSizeChanged(availableLotSizes[nextIndex]);
    }

    void increment() {
      if (availableLotSizes.isEmpty) return;
      final nextIndex =
          (currentIndex + 1).clamp(0, availableLotSizes.length - 1);
      onLotSizeChanged(availableLotSizes[nextIndex]);
    }

    return Container(
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
      child: Row(
        children: [
          _buildStepperButton(icon: Icons.remove, onPressed: decrement),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'LOT SIZE',
                  style: AppTextStyles.overline,
                ),
                Text(
                  lotSize.toString(),
                  style: AppTextStyles.priceSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildStepperButton(icon: Icons.add, onPressed: increment),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 44,
      height: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.textPrimary,
              size: AppSpacing.iconMedium,
            ),
          ),
        ),
      ),
    );
  }
}
