import 'package:flutter/material.dart';
import '../../model/candle_model.dart';

/// A widget that displays a single candlestick using CustomPaint
class CandleStickWidget extends StatelessWidget {
  final CandleStick candle;
  final double width;
  final double height;
  final Color? bullishColor;
  final Color? bearishColor;
  final Color? dojiColor;
  final Color? wickColor;
  final double wickWidth;

  const CandleStickWidget({
    Key? key,
    required this.candle,
    this.width = 8.0,
    this.height = 100.0,
    this.bullishColor,
    this.bearishColor,
    this.dojiColor,
    this.wickColor,
    this.wickWidth = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: CandleStickPainter(
        candle: candle,
        bullishColor: bullishColor ?? Colors.green,
        bearishColor: bearishColor ?? Colors.red,
        dojiColor: dojiColor ?? Colors.grey,
        wickColor: wickColor ?? Colors.black,
        wickWidth: wickWidth,
      ),
    );
  }
}

/// A widget that displays multiple candlesticks as a chart
class CandleStickChart extends StatelessWidget {
  final List<CandleStick> candles;
  final double candleWidth;
  final double candleSpacing;
  final double chartHeight;
  final Color? bullishColor;
  final Color? bearishColor;
  final Color? dojiColor;
  final Color? wickColor;
  final double wickWidth;
  final bool showGrid;
  final Color? gridColor;
  final bool showPriceLabels;
  final TextStyle? priceLabelStyle;

  const CandleStickChart({
    Key? key,
    required this.candles,
    this.candleWidth = 8.0,
    this.candleSpacing = 2.0,
    this.chartHeight = 300.0,
    this.bullishColor,
    this.bearishColor,
    this.dojiColor,
    this.wickColor,
    this.wickWidth = 1.0,
    this.showGrid = true,
    this.gridColor,
    this.showPriceLabels = true,
    this.priceLabelStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return Container(
        height: chartHeight,
        child: const Center(
          child: Text('No data available'),
        ),
      );
    }

    final chartWidth = candles.length * (candleWidth + candleSpacing);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: CustomPaint(
        size: Size(chartWidth, chartHeight),
        painter: CandleStickChartPainter(
          candles: candles,
          candleWidth: candleWidth,
          candleSpacing: candleSpacing,
          bullishColor: bullishColor ?? Colors.green,
          bearishColor: bearishColor ?? Colors.red,
          dojiColor: dojiColor ?? Colors.grey,
          wickColor: wickColor ?? Colors.black,
          wickWidth: wickWidth,
          showGrid: showGrid,
          gridColor: gridColor ?? Colors.grey.withOpacity(0.3),
          showPriceLabels: showPriceLabels,
          priceLabelStyle: priceLabelStyle ?? const TextStyle(fontSize: 10),
        ),
      ),
    );
  }
}

/// Custom painter for drawing a single candlestick
class CandleStickPainter extends CustomPainter {
  final CandleStick candle;
  final Color bullishColor;
  final Color bearishColor;
  final Color dojiColor;
  final Color wickColor;
  final double wickWidth;

  CandleStickPainter({
    required this.candle,
    required this.bullishColor,
    required this.bearishColor,
    required this.dojiColor,
    required this.wickColor,
    required this.wickWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final wickPaint = Paint()
      ..color = wickColor
      ..strokeWidth = wickWidth
      ..style = PaintingStyle.stroke;

    // Calculate positions relative to the canvas size
    final centerX = size.width / 2;
    final candleBodyWidth = size.width * 0.8;

    // Normalize prices to fit the canvas height
    final priceRange = candle.high - candle.low;
    if (priceRange == 0) return; // Avoid division by zero

    final topY = size.height * 0.1; // 10% margin from top
    final bottomY = size.height * 0.9; // 10% margin from bottom
    final availableHeight = bottomY - topY;

    final highY =
        topY + ((candle.high - candle.high) / priceRange) * availableHeight;
    final lowY =
        topY + ((candle.high - candle.low) / priceRange) * availableHeight;
    final openY =
        topY + ((candle.high - candle.open) / priceRange) * availableHeight;
    final closeY =
        topY + ((candle.high - candle.close) / priceRange) * availableHeight;

    // Draw upper wick
    canvas.drawLine(
      Offset(centerX, highY),
      Offset(centerX, candle.isBullish ? closeY : openY),
      wickPaint,
    );

    // Draw lower wick
    canvas.drawLine(
      Offset(centerX, candle.isBullish ? openY : closeY),
      Offset(centerX, lowY),
      wickPaint,
    );

    // Draw candle body
    final bodyTop = candle.isBullish ? closeY : openY;
    final bodyBottom = candle.isBullish ? openY : closeY;
    final bodyHeight = (bodyBottom - bodyTop).abs();

    if (candle.isDoji) {
      paint.color = dojiColor;
      // Draw a thin line for doji
      canvas.drawLine(
        Offset(centerX - candleBodyWidth / 2, bodyTop),
        Offset(centerX + candleBodyWidth / 2, bodyTop),
        Paint()
          ..color = dojiColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
    } else {
      paint.color = candle.getColor(
        bullishColor: bullishColor,
        bearishColor: bearishColor,
        dojiColor: dojiColor,
      );

      final rect = Rect.fromLTWH(
        centerX - candleBodyWidth / 2,
        bodyTop,
        candleBodyWidth,
        bodyHeight,
      );

      if (candle.isBullish) {
        // Draw hollow body for bullish candles
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2.0;
        canvas.drawRect(rect, paint);
      } else {
        // Draw filled body for bearish candles
        paint.style = PaintingStyle.fill;
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for drawing multiple candlesticks as a chart
class CandleStickChartPainter extends CustomPainter {
  final List<CandleStick> candles;
  final double candleWidth;
  final double candleSpacing;
  final Color bullishColor;
  final Color bearishColor;
  final Color dojiColor;
  final Color wickColor;
  final double wickWidth;
  final bool showGrid;
  final Color gridColor;
  final bool showPriceLabels;
  final TextStyle priceLabelStyle;

  CandleStickChartPainter({
    required this.candles,
    required this.candleWidth,
    required this.candleSpacing,
    required this.bullishColor,
    required this.bearishColor,
    required this.dojiColor,
    required this.wickColor,
    required this.wickWidth,
    required this.showGrid,
    required this.gridColor,
    required this.showPriceLabels,
    required this.priceLabelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // Find price range
    double minPrice = candles.first.low;
    double maxPrice = candles.first.high;

    for (final candle in candles) {
      if (candle.low < minPrice) minPrice = candle.low;
      if (candle.high > maxPrice) maxPrice = candle.high;
    }

    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return;

    // Add some padding to the price range
    final padding = priceRange * 0.05;
    minPrice -= padding;
    maxPrice += padding;
    final adjustedRange = maxPrice - minPrice;

    // Draw grid if enabled
    if (showGrid) {
      _drawGrid(canvas, size, minPrice, maxPrice);
    }

    // Draw price labels if enabled
    if (showPriceLabels) {
      _drawPriceLabels(canvas, size, minPrice, maxPrice);
    }

    // Draw candlesticks
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = i * (candleWidth + candleSpacing) + candleWidth / 2;

      _drawSingleCandle(
        canvas,
        candle,
        x,
        size.height,
        minPrice,
        adjustedRange,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size, double minPrice, double maxPrice) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines
    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = (size.height / gridLines) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw vertical grid lines
    final candleStep = (candleWidth + candleSpacing) * 10; // Every 10 candles
    for (double x = 0; x < size.width; x += candleStep) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  void _drawPriceLabels(
      Canvas canvas, Size size, double minPrice, double maxPrice) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const labelCount = 5;
    for (int i = 0; i <= labelCount; i++) {
      final price = minPrice + (maxPrice - minPrice) * (1 - i / labelCount);
      final y = (size.height / labelCount) * i;

      textPainter.text = TextSpan(
        text: price.toStringAsFixed(2),
        style: priceLabelStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }
  }

  void _drawSingleCandle(
    Canvas canvas,
    CandleStick candle,
    double x,
    double chartHeight,
    double minPrice,
    double priceRange,
  ) {
    final paint = Paint();
    final wickPaint = Paint()
      ..color = wickColor
      ..strokeWidth = wickWidth
      ..style = PaintingStyle.stroke;

    // Calculate Y positions
    final highY =
        chartHeight - ((candle.high - minPrice) / priceRange) * chartHeight;
    final lowY =
        chartHeight - ((candle.low - minPrice) / priceRange) * chartHeight;
    final openY =
        chartHeight - ((candle.open - minPrice) / priceRange) * chartHeight;
    final closeY =
        chartHeight - ((candle.close - minPrice) / priceRange) * chartHeight;

    // Draw wicks
    canvas.drawLine(
      Offset(x, highY),
      Offset(x, candle.isBullish ? closeY : openY),
      wickPaint,
    );
    canvas.drawLine(
      Offset(x, candle.isBullish ? openY : closeY),
      Offset(x, lowY),
      wickPaint,
    );

    // Draw candle body
    final bodyTop = candle.isBullish ? closeY : openY;
    final bodyBottom = candle.isBullish ? openY : closeY;
    final bodyHeight = (bodyBottom - bodyTop).abs();

    if (candle.isDoji) {
      paint.color = dojiColor;
      paint.strokeWidth = 2.0;
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x - candleWidth / 2, bodyTop),
        Offset(x + candleWidth / 2, bodyTop),
        paint,
      );
    } else {
      paint.color = candle.getColor(
        bullishColor: bullishColor,
        bearishColor: bearishColor,
        dojiColor: dojiColor,
      );

      final rect = Rect.fromLTWH(
        x - candleWidth / 2,
        bodyTop,
        candleWidth,
        bodyHeight,
      );

      if (candle.isBullish) {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2.0;
        canvas.drawRect(rect, paint);
      } else {
        paint.style = PaintingStyle.fill;
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
