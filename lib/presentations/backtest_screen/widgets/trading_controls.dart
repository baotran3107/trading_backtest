import 'package:flutter/material.dart';

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
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 48,
            child: _buildTradeButton(
              label: 'SELL',
              price: sellPrice,
              color: Colors.red[600]!,
              textColor: Colors.redAccent,
              onTap: onSell,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildLotSizeStepper(context),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            height: 48,
            child: _buildTradeButton(
              label: 'BUY',
              price: buyPrice,
              color: Colors.green[600]!,
              textColor: Colors.greenAccent,
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
    final Color darker = Color.lerp(color, Colors.black, 0.25)!;
    final bool isBuy = label.toUpperCase() == 'BUY';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [darker, color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isBuy
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[600]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  lotSize.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
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
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
