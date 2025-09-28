import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/theme_colors.dart';

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
              context,
              label: 'SELL',
              price: sellPrice,
              color: ThemeColors.buttonLightBearish(context),
              textColor: ThemeColors.textPrimary(context),
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
              context,
              label: 'BUY',
              price: buyPrice,
              color: ThemeColors.buttonLightBullish(context),
              textColor: ThemeColors.textPrimary(context),
              onTap: onBuy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeButton(
    BuildContext context, {
    required String label,
    required double price,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    final bool isBuy = label.toUpperCase() == 'BUY';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: ThemeColors.border(context),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: ThemeColors.shadow(context),
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
                color: color,
                size: AppSpacing.iconSmall,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: color,
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
        color: ThemeColors.backgroundCard(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: ThemeColors.border(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.shadowDark(context),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepperButton(context,
              icon: Icons.remove, onPressed: decrement),
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
          _buildStepperButton(context, icon: Icons.add, onPressed: increment),
        ],
      ),
    );
  }

  Widget _buildStepperButton(
    BuildContext context, {
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
              color: ThemeColors.textPrimary(context),
              size: AppSpacing.iconMedium,
            ),
          ),
        ),
      ),
    );
  }
}
