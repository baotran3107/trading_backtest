import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../model/candle_model.dart';

/// A comprehensive stock chart widget that displays candlestick data with advanced features
class StockChart extends StatefulWidget {
  final List<CandleStick> candles;
  final double height;
  final double candleWidth;
  final double candleSpacing;
  final Color bullishColor;
  final Color bearishColor;
  final Color dojiColor;
  final Color wickColor;
  final Color backgroundColor;
  final Color gridColor;
  final Color textColor;
  final bool showGrid;
  final bool showVolume;
  final bool showPriceLabels;
  final bool showTimeLabels;
  final bool enableInteraction;
  final double volumeHeightRatio;
  final TextStyle? labelTextStyle;
  final Function(CandleStick)? onCandleTap;

  const StockChart({
    Key? key,
    required this.candles,
    this.height = 400.0,
    this.candleWidth = 8.0,
    this.candleSpacing = 2.0,
    this.bullishColor = Colors.green,
    this.bearishColor = Colors.red,
    this.dojiColor = Colors.grey,
    this.wickColor = Colors.black87,
    this.backgroundColor = Colors.white,
    this.gridColor = const Color(0xFFE0E0E0),
    this.textColor = Colors.black87,
    this.showGrid = true,
    this.showVolume = true,
    this.showPriceLabels = true,
    this.showTimeLabels = true,
    this.enableInteraction = true,
    this.volumeHeightRatio = 0.2,
    this.labelTextStyle,
    this.onCandleTap,
  }) : super(key: key);

  @override
  State<StockChart> createState() => _StockChartState();
}

class _StockChartState extends State<StockChart> {
  final TransformationController _transformationController =
      TransformationController();
  CandleStick? _hoveredCandle;
  Offset? _hoverPosition;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return Container(
        height: widget.height,
        color: widget.backgroundColor,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: widget.textColor),
          ),
        ),
      );
    }

    final chartWidth =
        widget.candles.length * (widget.candleWidth + widget.candleSpacing);

    return Container(
      height: widget.height,
      color: widget.backgroundColor,
      child: widget.enableInteraction
          ? InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 5.0,
              child: _buildChart(chartWidth),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildChart(chartWidth),
            ),
    );
  }

  Widget _buildChart(double chartWidth) {
    return MouseRegion(
      onHover: widget.enableInteraction ? _onHover : null,
      onExit: widget.enableInteraction ? _onHoverExit : null,
      child: GestureDetector(
        onTapDown: widget.enableInteraction ? _onTapDown : null,
        child: CustomPaint(
          size: Size(chartWidth, widget.height),
          painter: StockChartPainter(
            candles: widget.candles,
            candleWidth: widget.candleWidth,
            candleSpacing: widget.candleSpacing,
            bullishColor: widget.bullishColor,
            bearishColor: widget.bearishColor,
            dojiColor: widget.dojiColor,
            wickColor: widget.wickColor,
            gridColor: widget.gridColor,
            textColor: widget.textColor,
            showGrid: widget.showGrid,
            showVolume: widget.showVolume,
            showPriceLabels: widget.showPriceLabels,
            showTimeLabels: widget.showTimeLabels,
            volumeHeightRatio: widget.volumeHeightRatio,
            labelTextStyle: widget.labelTextStyle ??
                TextStyle(color: widget.textColor, fontSize: 10),
            hoveredCandle: _hoveredCandle,
            hoverPosition: _hoverPosition,
          ),
        ),
      ),
    );
  }

  void _onHover(PointerHoverEvent event) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);

    // Calculate which candle is being hovered
    final candleIndex =
        (localPosition.dx / (widget.candleWidth + widget.candleSpacing))
            .floor();

    if (candleIndex >= 0 && candleIndex < widget.candles.length) {
      setState(() {
        _hoveredCandle = widget.candles[candleIndex];
        _hoverPosition = localPosition;
      });
    }
  }

  void _onHoverExit(PointerExitEvent event) {
    setState(() {
      _hoveredCandle = null;
      _hoverPosition = null;
    });
  }

  void _onTapDown(TapDownDetails details) {
    final candleIndex =
        (details.localPosition.dx / (widget.candleWidth + widget.candleSpacing))
            .floor();

    if (candleIndex >= 0 && candleIndex < widget.candles.length) {
      final tappedCandle = widget.candles[candleIndex];
      widget.onCandleTap?.call(tappedCandle);
    }
  }
}

/// Custom painter for the stock chart
class StockChartPainter extends CustomPainter {
  final List<CandleStick> candles;
  final double candleWidth;
  final double candleSpacing;
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
  final CandleStick? hoveredCandle;
  final Offset? hoverPosition;

  StockChartPainter({
    required this.candles,
    required this.candleWidth,
    required this.candleSpacing,
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
    this.hoveredCandle,
    this.hoverPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // Calculate price and volume ranges
    final priceData = _calculatePriceRange();
    final volumeData = _calculateVolumeRange();

    // Calculate chart areas
    final priceChartHeight =
        showVolume ? size.height * (1 - volumeHeightRatio) : size.height;
    final volumeChartHeight =
        showVolume ? size.height * volumeHeightRatio : 0.0;
    final volumeChartTop = priceChartHeight;

    // Draw grid
    if (showGrid) {
      _drawGrid(
          canvas, size, priceChartHeight, volumeChartTop, volumeChartHeight);
    }

    // Draw price labels
    if (showPriceLabels) {
      _drawPriceLabels(canvas, size, priceData, priceChartHeight);
    }

    // Draw time labels
    if (showTimeLabels) {
      _drawTimeLabels(canvas, size);
    }

    // Draw candlesticks
    _drawCandlesticks(canvas, priceData, priceChartHeight);

    // Draw volume bars
    if (showVolume) {
      _drawVolumeBars(canvas, volumeData, volumeChartTop, volumeChartHeight);
    }

    // Draw hover tooltip
    if (hoveredCandle != null && hoverPosition != null) {
      _drawHoverTooltip(canvas, size);
    }
  }

  Map<String, double> _calculatePriceRange() {
    double minPrice = candles.first.low;
    double maxPrice = candles.first.high;

    for (final candle in candles) {
      if (candle.low < minPrice) minPrice = candle.low;
      if (candle.high > maxPrice) maxPrice = candle.high;
    }

    // Add padding
    final range = maxPrice - minPrice;
    final padding = range * 0.05;
    minPrice -= padding;
    maxPrice += padding;

    return {
      'min': minPrice,
      'max': maxPrice,
      'range': maxPrice - minPrice,
    };
  }

  Map<String, double> _calculateVolumeRange() {
    if (!showVolume) return {'min': 0, 'max': 0, 'range': 0};

    double minVolume = 0;
    double maxVolume = candles.first.volume;

    for (final candle in candles) {
      if (candle.volume > maxVolume) maxVolume = candle.volume;
    }

    return {
      'min': minVolume,
      'max': maxVolume,
      'range': maxVolume - minVolume,
    };
  }

  void _drawGrid(Canvas canvas, Size size, double priceChartHeight,
      double volumeChartTop, double volumeChartHeight) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontal grid lines for price chart
    const priceGridLines = 5;
    for (int i = 0; i <= priceGridLines; i++) {
      final y = (priceChartHeight / priceGridLines) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Horizontal grid lines for volume chart
    if (showVolume) {
      const volumeGridLines = 2;
      for (int i = 0; i <= volumeGridLines; i++) {
        final y = volumeChartTop + (volumeChartHeight / volumeGridLines) * i;
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          gridPaint,
        );
      }
    }

    // Vertical grid lines
    final candleStep = (candleWidth + candleSpacing) * 10;
    for (double x = 0; x < size.width; x += candleStep) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  void _drawPriceLabels(Canvas canvas, Size size, Map<String, double> priceData,
      double chartHeight) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const labelCount = 5;
    for (int i = 0; i <= labelCount; i++) {
      final price =
          priceData['min']! + (priceData['range']! * (1 - i / labelCount));
      final y = (chartHeight / labelCount) * i;

      textPainter.text = TextSpan(
        text: '\$${price.toStringAsFixed(2)}',
        style: labelTextStyle,
      );
      textPainter.layout();

      // Draw background for better readability
      final rect = Rect.fromLTWH(
        5,
        y - textPainter.height / 2,
        textPainter.width + 4,
        textPainter.height,
      );
      canvas.drawRect(
        rect,
        Paint()..color = Colors.white.withOpacity(0.8),
      );

      textPainter.paint(canvas, Offset(7, y - textPainter.height / 2));
    }
  }

  void _drawTimeLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Show time labels for every 10th candle
    for (int i = 0; i < candles.length; i += 10) {
      final x = i * (candleWidth + candleSpacing);
      final time = candles[i].time;

      textPainter.text = TextSpan(
        text: '${time.month}/${time.day}',
        style: labelTextStyle,
      );
      textPainter.layout();

      // Draw background
      final rect = Rect.fromLTWH(
        x - textPainter.width / 2,
        size.height - textPainter.height - 2,
        textPainter.width + 4,
        textPainter.height,
      );
      canvas.drawRect(
        rect,
        Paint()..color = Colors.white.withOpacity(0.8),
      );

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2 + 2,
            size.height - textPainter.height - 2),
      );
    }
  }

  void _drawCandlesticks(
      Canvas canvas, Map<String, double> priceData, double chartHeight) {
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = i * (candleWidth + candleSpacing) + candleWidth / 2;

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
      ..strokeWidth = 1.0
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
    final bodyHeight = (bodyBottom - bodyTop).abs().clamp(1.0, double.infinity);

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
        paint.strokeWidth = 1.5;
        canvas.drawRect(rect, paint);
      } else {
        paint.style = PaintingStyle.fill;
        canvas.drawRect(rect, paint);
      }
    }
  }

  void _drawVolumeBars(
    Canvas canvas,
    Map<String, double> volumeData,
    double volumeChartTop,
    double volumeChartHeight,
  ) {
    final paint = Paint();

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = i * (candleWidth + candleSpacing);

      final volumeHeight =
          (candle.volume / volumeData['max']!) * volumeChartHeight;
      final barY = volumeChartTop + volumeChartHeight - volumeHeight;

      paint.color = candle.isBullish
          ? bullishColor.withOpacity(0.6)
          : bearishColor.withOpacity(0.6);

      canvas.drawRect(
        Rect.fromLTWH(x, barY, candleWidth, volumeHeight),
        paint,
      );
    }
  }

  void _drawHoverTooltip(Canvas canvas, Size size) {
    if (hoveredCandle == null || hoverPosition == null) return;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final tooltipPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Tooltip content
    final tooltipText = '''
Time: ${hoveredCandle!.time.month}/${hoveredCandle!.time.day}/${hoveredCandle!.time.year}
Open: \$${hoveredCandle!.open.toStringAsFixed(2)}
High: \$${hoveredCandle!.high.toStringAsFixed(2)}
Low: \$${hoveredCandle!.low.toStringAsFixed(2)}
Close: \$${hoveredCandle!.close.toStringAsFixed(2)}
Volume: ${hoveredCandle!.volume.toStringAsFixed(0)}
''';

    textPainter.text = TextSpan(
      text: tooltipText,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    );
    textPainter.layout();

    // Position tooltip
    const padding = 8.0;
    final tooltipWidth = textPainter.width + padding * 2;
    final tooltipHeight = textPainter.height + padding * 2;

    double tooltipX = hoverPosition!.dx + 10;
    double tooltipY = hoverPosition!.dy - tooltipHeight - 10;

    // Adjust position if tooltip goes off screen
    if (tooltipX + tooltipWidth > size.width) {
      tooltipX = hoverPosition!.dx - tooltipWidth - 10;
    }
    if (tooltipY < 0) {
      tooltipY = hoverPosition!.dy + 10;
    }

    // Draw tooltip background
    final tooltipRect =
        Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tooltipRect, const Radius.circular(4)),
      tooltipPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tooltipRect, const Radius.circular(4)),
      borderPaint,
    );

    // Draw tooltip text
    textPainter.paint(canvas, Offset(tooltipX + padding, tooltipY + padding));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// A simplified stock chart widget for basic use cases
class SimpleStockChart extends StatelessWidget {
  final List<CandleStick> candles;
  final double height;
  final Color bullishColor;
  final Color bearishColor;

  const SimpleStockChart({
    Key? key,
    required this.candles,
    this.height = 300.0,
    this.bullishColor = Colors.green,
    this.bearishColor = Colors.red,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StockChart(
      candles: candles,
      height: height,
      bullishColor: bullishColor,
      bearishColor: bearishColor,
      showVolume: false,
      enableInteraction: false,
      showTimeLabels: false,
    );
  }
}
