import 'package:flutter/material.dart';
import '../../modules/chart/chart.dart';
import '../../model/candle_model.dart';

/// Demo page showing how to use the StockChart widget
class StockChartDemo extends StatefulWidget {
  const StockChartDemo({super.key});

  @override
  State<StockChartDemo> createState() => _StockChartDemoState();
}

class _StockChartDemoState extends State<StockChartDemo> {
  List<CandleStick> _generateSampleData() {
    final List<CandleStick> candles = [];
    final basePrice = 100.0;
    final random = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < 50; i++) {
      final time = DateTime.now().subtract(Duration(days: 50 - i));

      // Generate realistic-looking price movements
      final priceVariation = (random + i * 123) % 20 - 10; // -10 to +10
      final open = basePrice + (i * 0.5) + priceVariation;

      final highVariation = (random + i * 456) % 8; // 0 to 8
      final lowVariation = (random + i * 789) % 8; // 0 to 8
      final closeVariation = (random + i * 321) % 16 - 8; // -8 to +8

      final high = open + highVariation;
      final low = open - lowVariation;
      final close = open + closeVariation;

      final volume = 1000000 + ((random + i * 654) % 2000000); // 1M to 3M

      candles.add(CandleStick(
        open: open,
        high: high,
        low: low < open && low < close
            ? low
            : (open < close ? open : close) - 0.5,
        close: close,
        volume: volume.toDouble(),
        time: time,
      ));
    }

    return candles;
  }

  @override
  Widget build(BuildContext context) {
    final sampleData = _generateSampleData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Chart'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[900],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stock Chart',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Interactive dark theme trading chart with volume',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: StockChart(
                  candles: sampleData,
                  height: double.infinity,
                  candleWidth: 10,
                  candleSpacing: 2,
                  bullishColor: Colors.greenAccent,
                  bearishColor: Colors.redAccent,
                  backgroundColor: Colors.grey[900]!,
                  gridColor: Colors.grey[700]!,
                  textColor: Colors.white,
                  wickColor: Colors.grey[400]!,
                  showVolume: true,
                  showGrid: true,
                  showPriceLabels: true,
                  showTimeLabels: true,
                  enableInteraction: true,
                  labelTextStyle:
                      const TextStyle(color: Colors.white, fontSize: 10),
                  onCandleTap: (candle) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.grey[800],
                        content: Text(
                          'Tapped: ${candle.time.month}/${candle.time.day} - Close: \$${candle.close.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
