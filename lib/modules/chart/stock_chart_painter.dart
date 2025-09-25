import 'package:flutter/material.dart';
import '../../model/candle_model.dart';
import 'chart_constants.dart';

/// Custom painter for the stock chart
class StockChartPainter extends CustomPainter {
  final List<CandleStick> candles;
  final double candleWidth;
  final double candleSpacing;
  final double timeScale;
  final double priceScale;
  final double chartWidth;
  final Color bullishColor;
  final Color bearishColor;
  final Color dojiColor;
  final Color wickColor;
  final Color gridColor;
  final Color textColor;
  final bool showGrid;
  final bool showVolume;
  final bool showPriceLabels;
  final bool showTimeLabels;
  final double volumeHeightRatio;
  final TextStyle labelTextStyle;
  final List<double> buyEntryPrices;
  final List<double> sellEntryPrices;
  final List<double> stopLossPrices;
  final List<double> takeProfitPrices;

  StockChartPainter({
    required this.candles,
    required this.candleWidth,
    required this.candleSpacing,
    required this.timeScale,
    required this.priceScale,
    required this.chartWidth,
    required this.bullishColor,
    required this.bearishColor,
    required this.dojiColor,
    required this.wickColor,
    required this.gridColor,
    required this.textColor,
    required this.showGrid,
    required this.showVolume,
    required this.showPriceLabels,
    required this.showTimeLabels,
    required this.volumeHeightRatio,
    required this.labelTextStyle,
    this.buyEntryPrices = const [],
    this.sellEntryPrices = const [],
    this.stopLossPrices = const [],
    this.takeProfitPrices = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // Calculate price range
    final priceData = _calculatePriceRange();

    // Reserve space for price labels on the right and time labels at bottom
    final priceLabelsWidth =
        showPriceLabels ? ChartConstants.priceLabelsWidth : 0.0;
    final timeLabelsHeight =
        showTimeLabels ? ChartConstants.timeLabelsHeight : 0.0;

    // Calculate effective chart dimensions
    final effectiveChartWidth = size.width - priceLabelsWidth;
    final effectiveChartHeight = size.height - timeLabelsHeight;

    // Draw candlesticks first (behind other elements) in the reserved area
    _drawCandlesticks(
        canvas, priceData, effectiveChartHeight, effectiveChartWidth);

    // Draw grid
    if (showGrid) {
      _drawGrid(canvas, size, effectiveChartHeight, effectiveChartWidth);
    }

    // Draw price labels (on top of candlesticks)
    if (showPriceLabels) {
      _drawPriceLabels(canvas, size, priceData, effectiveChartHeight);
    }

    // Draw time labels (on top of candlesticks)
    if (showTimeLabels) {
      _drawTimeLabels(canvas, size, effectiveChartWidth);
    }

    // Draw current price line and label box on the price axis
    _drawCurrentPrice(
        canvas, size, priceData, effectiveChartHeight, effectiveChartWidth);

    // Draw order entry lines on top
    _drawOrderEntryLines(
        canvas, size, priceData, effectiveChartHeight, effectiveChartWidth);

    // Draw SL/TP lines
    _drawRiskManagementLines(
        canvas, size, priceData, effectiveChartHeight, effectiveChartWidth);

    // Tooltip removed per requirement: no hover-to-candle tooltip rendering
  }

  void _drawOrderEntryLines(
    Canvas canvas,
    Size size,
    Map<String, double> priceData,
    double chartHeight,
    double effectiveChartWidth,
  ) {
    if (candles.isEmpty) return;

    final double minPrice = priceData['min']!;
    final double priceRange = priceData['range']!;

    void drawLine(double price, Color color) {
      final double y =
          (chartHeight - ((price - minPrice) / priceRange) * chartHeight)
              .clamp(0.0, chartHeight);

      final Paint linePaint = Paint()
        ..color = color.withOpacity(0.9)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      // Solid line across effective chart area
      canvas.drawLine(Offset(0, y), Offset(effectiveChartWidth, y), linePaint);

      // Label box with side + price on the right price axis area
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      final String text =
          '${color == bullishColor ? 'BUY' : 'SELL'} ${price.toStringAsFixed(3)}';
      textPainter.text = TextSpan(
        text: text,
        style: labelTextStyle.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();

      const double hPad = 6.0;
      const double vPad = 3.0;
      final double boxWidth = textPainter.width + hPad * 2;
      final double boxHeight = textPainter.height + vPad * 2;
      final double boxLeft = size.width - ChartConstants.priceLabelsWidth + 4.0;
      final double boxTop =
          (y - boxHeight / 2).clamp(0.0, chartHeight - boxHeight);
      final Rect rect = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);

      // Background with entry color
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
        Paint()..color = color.withOpacity(0.95),
      );

      // Thin border for contrast
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
        Paint()
          ..color = Colors.black.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      // Text inside box
      textPainter.paint(
        canvas,
        Offset(rect.left + hPad, rect.top + vPad),
      );
    }

    for (final p in buyEntryPrices) {
      drawLine(p, bullishColor);
    }
    for (final p in sellEntryPrices) {
      drawLine(p, bearishColor);
    }
  }

  void _drawRiskManagementLines(
    Canvas canvas,
    Size size,
    Map<String, double> priceData,
    double chartHeight,
    double effectiveChartWidth,
  ) {
    if (candles.isEmpty) return;

    final double minPrice = priceData['min']!;
    final double priceRange = priceData['range']!;

    void drawLine(double price, Color color, String label) {
      final double y =
          (chartHeight - ((price - minPrice) / priceRange) * chartHeight)
              .clamp(0.0, chartHeight);

      final Paint linePaint = Paint()
        ..color = color.withOpacity(0.9)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(0, y), Offset(effectiveChartWidth, y), linePaint);

      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: '$label ${price.toStringAsFixed(3)}',
        style: labelTextStyle.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();

      const double hPad = 6.0;
      const double vPad = 3.0;
      final double boxWidth = textPainter.width + hPad * 2;
      final double boxHeight = textPainter.height + vPad * 2;
      final double boxLeft = size.width - ChartConstants.priceLabelsWidth + 4.0;
      final double boxTop =
          (y - boxHeight / 2).clamp(0.0, chartHeight - boxHeight);
      final Rect rect = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
        Paint()..color = color.withOpacity(0.95),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
        Paint()
          ..color = Colors.black.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      textPainter.paint(
        canvas,
        Offset(boxLeft + hPad, boxTop + vPad),
      );
    }

    for (final sl in stopLossPrices) {
      drawLine(sl, Colors.orange, 'SL');
    }
    for (final tp in takeProfitPrices) {
      drawLine(tp, Colors.blue, 'TP');
    }
  }

  Map<String, double> _calculatePriceRange() {
    double minPrice = candles.first.low;
    double maxPrice = candles.first.high;

    for (final candle in candles) {
      if (candle.low < minPrice) minPrice = candle.low;
      if (candle.high > maxPrice) maxPrice = candle.high;
    }

    // Add base padding
    final baseRange = maxPrice - minPrice;
    final basePadding = baseRange * ChartConstants.basePadding;
    final paddedMinPrice = minPrice - basePadding;
    final paddedMaxPrice = maxPrice + basePadding;
    final paddedRange = paddedMaxPrice - paddedMinPrice;

    // Apply price scaling with intelligent bounds
    final center = (paddedMinPrice + paddedMaxPrice) / 2;
    final scaledRange = paddedRange / priceScale;

    // Allow much smaller visible range for better zoom out capability
    final minVisibleRange = baseRange * ChartConstants.minVisibleRange;
    final constrainedRange = scaledRange.clamp(
        minVisibleRange, paddedRange * ChartConstants.maxVisibleRange);

    final scaledMinPrice = center - (constrainedRange / 2);
    final scaledMaxPrice = center + (constrainedRange / 2);

    return {
      'min': scaledMinPrice,
      'max': scaledMaxPrice,
      'range': constrainedRange,
    };
  }

  void _drawGrid(Canvas canvas, Size size, double priceChartHeight,
      double effectiveChartWidth) {
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double dashWidth = 6.0;
    const double dashGap = 4.0;

    // Horizontal grid lines for price chart
    for (int i = 0; i <= ChartConstants.gridLinesCount; i++) {
      final y = (priceChartHeight / ChartConstants.gridLinesCount) * i;
      _drawDashedLine(
        canvas,
        Offset(0, y),
        Offset(effectiveChartWidth, y),
        gridPaint,
        dashWidth,
        dashGap,
      );
    }

    // Vertical grid lines
    final effectiveCandleWidth = (candleWidth + candleSpacing) * timeScale;
    final gridSpacing =
        effectiveCandleWidth * ChartConstants.gridSpacingMultiplier;

    // Ensure we have at least some vertical lines based on effective width
    final minGridSpacing =
        effectiveChartWidth * ChartConstants.minGridSpacingRatio;
    final maxGridSpacing =
        effectiveChartWidth * ChartConstants.maxGridSpacingRatio;
    final actualGridSpacing = gridSpacing.clamp(minGridSpacing, maxGridSpacing);

    for (double x = 0; x <= effectiveChartWidth; x += actualGridSpacing) {
      _drawDashedLine(
        canvas,
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
        dashWidth,
        dashGap,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashGap,
  ) {
    final double totalLength = (end - start).distance;
    final Offset direction = (end - start) / totalLength;
    double current = 0.0;
    while (current < totalLength) {
      final double next = (current + dashWidth).clamp(0.0, totalLength);
      final Offset p1 = start + direction * current;
      final Offset p2 = start + direction * next;
      canvas.drawLine(p1, p2, paint);
      current = next + dashGap;
    }
  }

  void _drawPriceLabels(Canvas canvas, Size size, Map<String, double> priceData,
      double chartHeight) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= ChartConstants.gridLinesCount; i++) {
      final price = priceData['min']! +
          (priceData['range']! * (1 - i / ChartConstants.gridLinesCount));
      final y = (chartHeight / ChartConstants.gridLinesCount) * i;

      textPainter.text = TextSpan(
        text: price.toStringAsFixed(3),
        style: labelTextStyle.copyWith(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();

      // Position labels in the reserved right area
      final rightX = size.width - 75;

      // Draw solid background for better readability
      final rect = Rect.fromLTWH(
        rightX - 4,
        y - textPainter.height / 2 - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      canvas.drawRect(
        rect,
        Paint()..color = const Color(ChartConstants.defaultGridColor),
      );

      // Draw border around price label
      canvas.drawRect(
        rect,
        Paint()
          ..color = gridColor.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      // Add a subtle shadow effect for depth
      canvas.drawRect(
        Rect.fromLTWH(rect.left + 1, rect.top + 1, rect.width, rect.height),
        Paint()..color = Colors.black.withOpacity(0.1),
      );

      textPainter.paint(canvas, Offset(rightX, y - textPainter.height / 2));
    }

    // Draw a vertical separator line between chart and price labels
    canvas.drawLine(
      Offset(size.width - ChartConstants.priceLabelsWidth, 0),
      Offset(size.width - ChartConstants.priceLabelsWidth, chartHeight),
      Paint()
        ..color = gridColor.withOpacity(0.6)
        ..strokeWidth = 1.0,
    );
  }

  void _drawTimeLabels(Canvas canvas, Size size, double effectiveChartWidth) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Show time labels for visible candles based on their actual spacing
    final labelStep = (candles.length / 6).ceil().clamp(1, candles.length);

    for (int i = 0; i < candles.length; i += labelStep) {
      // Position time labels based on actual candle positions
      final x = i * (candleWidth + candleSpacing) + candleWidth / 2;

      // Only draw labels that are within the effective chart area
      if (x > effectiveChartWidth) break;

      final time = candles[i].time;

      // For 1-minute timeframe, show time labels as HH:mm instead of MM/DD
      final String hh = time.hour.toString().padLeft(2, '0');
      final String mm = time.minute.toString().padLeft(2, '0');
      textPainter.text = TextSpan(
        text: '$hh:$mm',
        style: labelTextStyle.copyWith(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      );
      textPainter.layout();

      // Draw semi-transparent background matching the theme
      final rect = Rect.fromLTWH(
        x - textPainter.width / 2 - 2,
        size.height - textPainter.height - 4,
        textPainter.width + 4,
        textPainter.height + 2,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color =
              const Color(ChartConstants.defaultGridColor).withOpacity(0.8),
      );

      // Draw border
      canvas.drawRect(
        rect,
        Paint()
          ..color = gridColor.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - textPainter.height - 3),
      );
    }
  }

  void _drawCandlesticks(Canvas canvas, Map<String, double> priceData,
      double chartHeight, double effectiveChartWidth) {
    // Position candles using their actual scaled widths within the effective chart area
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      // Position candles based on actual width and spacing, constrained to effective width
      final x = i * (candleWidth + candleSpacing) + candleWidth / 2;

      // Only draw candles that are within the effective chart area
      if (x <= effectiveChartWidth) {
        _drawSingleCandle(
          canvas,
          candle,
          x,
          chartHeight,
          priceData['min']!,
          priceData['range']!,
        );
      }
    }
  }

  void _drawCurrentPrice(
    Canvas canvas,
    Size size,
    Map<String, double> priceData,
    double chartHeight,
    double effectiveChartWidth,
  ) {
    if (candles.isEmpty) return;

    final double minPrice = priceData['min']!;
    final double priceRange = priceData['range']!;

    final CandleStick last = candles.last;
    final double currentPrice = last.close;
    final double y =
        (chartHeight - ((currentPrice - minPrice) / priceRange) * chartHeight)
            .clamp(0.0, chartHeight);

    // Determine color based on change vs previous close
    Color lineColor = dojiColor;
    if (candles.length >= 2) {
      final prevClose = candles[candles.length - 2].close;
      if (currentPrice > prevClose) {
        lineColor = bullishColor;
      } else if (currentPrice < prevClose) {
        lineColor = bearishColor;
      } else {
        lineColor = dojiColor;
      }
    }

    // Draw horizontal price line across effective chart area
    final Paint linePaint = Paint()
      ..color = lineColor.withOpacity(0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw dashed line for current price
    const double dashWidth = 6.0;
    const double dashGap = 4.0;
    _drawDashedLine(
      canvas,
      Offset(0, y),
      Offset(effectiveChartWidth, y),
      linePaint,
      dashWidth,
      dashGap,
    );

    // Draw the price label box on the right price axis area
    final String priceText = currentPrice.toStringAsFixed(3);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: priceText,
      style: labelTextStyle.copyWith(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout();

    // Box dimensions and position within reserved price axis area
    const double horizontalPadding = 6.0;
    const double verticalPadding = 3.0;
    final double boxWidth = textPainter.width + horizontalPadding * 2;
    final double boxHeight = textPainter.height + verticalPadding * 2;
    final double boxLeft = size.width - ChartConstants.priceLabelsWidth + 4.0;
    final double boxTop =
        (y - boxHeight / 2).clamp(0.0, chartHeight - boxHeight);
    final Rect rect = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);

    // Background uses grid color as base with line color overlay
    final Paint boxPaint = Paint()
      ..color = lineColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
      boxPaint,
    );

    // Border for contrast
    final Paint borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4.0)),
      borderPaint,
    );

    // Text inside box
    textPainter.paint(
      canvas,
      Offset(rect.left + horizontalPadding, rect.top + verticalPadding),
    );

    // Small connector from box to the line within price axis area
    final double connectorStartX = rect.left - 6.0;
    final Paint connectorPaint = Paint()
      ..color = lineColor.withOpacity(0.9)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(connectorStartX, y),
      Offset(rect.left, y),
      connectorPaint,
    );
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
      ..strokeWidth = 1.5
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
    final bodyHeight = (bodyBottom - bodyTop).abs().clamp(1.5, double.infinity);

    if (candle.isDoji) {
      paint.color = dojiColor;
      paint.strokeWidth = 2.5;
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
        // Bullish candles: filled with border for better contrast
        paint.style = PaintingStyle.fill;
        canvas.drawRect(rect, paint);
        // Add border
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1.0;
        canvas.drawRect(rect, paint);
      } else {
        // Bearish candles: solid fill
        paint.style = PaintingStyle.fill;
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
