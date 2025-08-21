import 'package:flutter/material.dart';
import '../modules/chart/chart.dart';
import '../model/candle_model.dart';

/// Demo page showing how to use the StockChart widget
class StockChartDemo extends StatefulWidget {
  const StockChartDemo({Key? key}) : super(key: key);

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
        title: const Text('Stock Chart Demo'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interactive Stock Chart',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Features: Zoom, Pan, Hover tooltips, Volume bars, Grid lines',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: StockChart(
                candles: sampleData,
                height: 400,
                candleWidth: 10,
                candleSpacing: 2,
                bullishColor: Colors.green[600]!,
                bearishColor: Colors.red[600]!,
                backgroundColor: Colors.white,
                showVolume: true,
                showGrid: true,
                showPriceLabels: true,
                showTimeLabels: true,
                enableInteraction: true,
                onCandleTap: (candle) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tapped: ${candle.time.month}/${candle.time.day} - Close: \$${candle.close.toStringAsFixed(2)}',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Simple Stock Chart',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Simplified version without volume or interaction',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SimpleStockChart(
                candles: sampleData,
                height: 250,
                bullishColor: Colors.blue[600]!,
                bearishColor: Colors.orange[600]!,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Dark Theme Chart',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[800]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: StockChart(
                candles: sampleData,
                height: 350,
                candleWidth: 8,
                candleSpacing: 1,
                bullishColor: Colors.greenAccent,
                bearishColor: Colors.redAccent,
                backgroundColor: Colors.grey[900]!,
                gridColor: Colors.grey[700]!,
                textColor: Colors.white,
                wickColor: Colors.grey[400]!,
                showVolume: true,
                showGrid: true,
                enableInteraction: false,
                labelTextStyle:
                    const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
