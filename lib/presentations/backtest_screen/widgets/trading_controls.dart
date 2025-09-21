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
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildTradeButton(
              label: 'SELL',
              price: sellPrice,
              color: Colors.red[600]!,
              textColor: Colors.redAccent,
              onTap: onSell,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildLotSizeSelector(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
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
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLotSizeSelector() {
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: lotSize,
          isExpanded: true,
          dropdownColor: Colors.grey[800],
          icon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.expand_more, color: Colors.grey[400], size: 20),
          ),
          style: const TextStyle(color: Colors.white),
          selectedItemBuilder: (BuildContext context) {
            return availableLotSizes.map<Widget>((double value) {
              return Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      value.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          onChanged: (double? newValue) {
            if (newValue != null) {
              onLotSizeChanged(newValue);
            }
          },
          items: availableLotSizes.map<DropdownMenuItem<double>>((double value) {
            return DropdownMenuItem<double>(
              value: value,
              child: Center(
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}