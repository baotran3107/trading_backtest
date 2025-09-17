import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../model/candle_model.dart';
import 'chart_provider.dart';

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
  final VoidCallback? onLoadPastData;
  final VoidCallback? onLoadFutureData;

  const StockChart({
    Key? key,
    required this.candles,
    this.height = 400.0,
    this.candleWidth = 8.0,
    this.candleSpacing = 2.0,
    this.bullishColor = const Color(0xFF26A69A), // Teal/green for bullish
    this.bearishColor = const Color(0xFFEF5350), // Red for bearish
    this.dojiColor = const Color(0xFF78909C), // Blue-grey for doji
    this.wickColor = const Color(0xFF90A4AE), // Light blue-grey for wicks
    this.backgroundColor = const Color(0xFF1E2328), // Dark background
    this.gridColor = const Color(0xFF2B3139), // Dark grid lines
    this.textColor = const Color(0xFFB7BDC6), // Light grey text
    this.showGrid = true,
    this.showVolume = false, // Disabled by default
    this.showPriceLabels = true,
    this.showTimeLabels = true,
    this.enableInteraction = true,
    this.volumeHeightRatio = 0.2,
    this.labelTextStyle,
    this.onLoadPastData,
    this.onLoadFutureData,
  }) : super(key: key);

  @override
  State<StockChart> createState() => _StockChartState();
}

class _StockChartState extends State<StockChart> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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

    return ChangeNotifierProvider(
      create: (context) => ChartProvider(),
      child: Container(
        height: widget.height,
        color: widget.backgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final chartWidth = constraints.maxWidth;
            return _buildChart(chartWidth);
          },
        ),
      ),
    );
  }

  Widget _buildChart(double chartWidth) {
    return Consumer<ChartProvider>(
      builder: (context, chartProvider, child) {
        // Calculate effective chart width (reserve space for price labels)
        final effectiveChartWidth = chartWidth - (widget.showPriceLabels ? 80.0 : 0.0);
        
        // Calculate actual candle width based on time scale
        final scaledDimensions = chartProvider.getScaledDimensions(widget.candleWidth, widget.candleSpacing);
        final baseCandleWidth = scaledDimensions['candleWidth']!;
        final baseCandleSpacing = scaledDimensions['candleSpacing']!;

        // Get the visible candles using the provider with effective width
        final visibleCandles = chartProvider.getVisibleCandles(
          widget.candles,
          effectiveChartWidth, // Use effective width instead of full width
          widget.candleWidth,
          widget.candleSpacing,
        );

        // Define gesture handlers within the Consumer context
        void onScaleStart(ScaleStartDetails details) {
          chartProvider.startScale(details.focalPoint.dx, details.focalPoint.dy);
        }

        void onScaleUpdate(ScaleUpdateDetails details) {
          if (details.scale == 1.0 && details.focalPointDelta != Offset.zero) {
            // This is a pan gesture, handle horizontal scrolling
            final layoutBuilder = context.findRenderObject() as RenderBox?;
            if (layoutBuilder != null) {
              final fullChartWidth = layoutBuilder.size.width;
              final effectiveChartWidth = fullChartWidth - (widget.showPriceLabels ? 80.0 : 0.0);
              chartProvider.updateScrollOffset(
                details.focalPointDelta.dx,
                widget.candles.length,
                effectiveChartWidth, // Use effective width for scroll calculations
                widget.candleWidth,
                widget.candleSpacing,
              );
              
              // Check if we need to load more data
              if (chartProvider.isScrollingToPast && widget.onLoadPastData != null) {
                widget.onLoadPastData!();
              } else if (chartProvider.isScrollingToFuture && widget.onLoadFutureData != null) {
                widget.onLoadFutureData!();
              }
            }
          } else if (details.scale != 1.0) {
            // This is a scale gesture, handle zooming
            chartProvider.updateScale(details.scale, details.focalPoint.dx, details.focalPoint.dy);
          }
        }

        void onDoubleTap() {
          chartProvider.resetScaling();
        }

        void onPricePanUpdate(DragUpdateDetails details) {
          chartProvider.updatePriceScaleFromPan(details.delta.dy);
        }

        void onTimePanUpdate(DragUpdateDetails details) {
          chartProvider.updateTimeScaleFromPan(details.delta.dx);
        }

        void onHover(PointerHoverEvent event) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(event.position);

          final hoveredCandle = chartProvider.getCandleAtPosition(
            widget.candles,
            localPosition.dx,
            baseCandleWidth,
            baseCandleSpacing,
            chartProvider.visibleStartIndex,
          );

          chartProvider.setHover(hoveredCandle, localPosition);
        }

        void onHoverExit(PointerExitEvent event) {
          chartProvider.clearHover();
        }

        return Stack(
          children: [
            // Main chart area with scroll handling
            Listener(
              onPointerSignal: widget.enableInteraction ? _onPointerSignal : null,
              child: MouseRegion(
                onHover: widget.enableInteraction ? onHover : null,
                onExit: widget.enableInteraction ? onHoverExit : null,
                child: widget.enableInteraction
                    ? GestureDetector(
                        onScaleStart: onScaleStart,
                        onScaleUpdate: onScaleUpdate,
                        onDoubleTap: onDoubleTap,
                        child: CustomPaint(
                          size: Size(chartWidth, widget.height),
                          painter: StockChartPainter(
                            candles: visibleCandles,
                            candleWidth: baseCandleWidth,
                            candleSpacing: baseCandleSpacing,
                            timeScale: chartProvider.timeScale,
                            priceScale: chartProvider.priceScale,
                            chartWidth: chartWidth,
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
                            hoveredCandle: chartProvider.hoveredCandle,
                            hoverPosition: chartProvider.hoverPosition,
                          ),
                        ),
                      )
                    : CustomPaint(
                        size: Size(chartWidth, widget.height),
                        painter: StockChartPainter(
                          candles: visibleCandles,
                          candleWidth: baseCandleWidth,
                          candleSpacing: baseCandleSpacing,
                          timeScale: chartProvider.timeScale,
                          priceScale: chartProvider.priceScale,
                          chartWidth: chartWidth,
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
                          hoveredCandle: chartProvider.hoveredCandle,
                          hoverPosition: chartProvider.hoverPosition,
                        ),
                      ),
              ),
            ),

            // Price labels gesture area (right side)
            if (widget.enableInteraction && widget.showPriceLabels)
              Positioned(
                right: 0,
                top: 0,
                bottom: widget.showTimeLabels
                    ? 30
                    : 0, // Account for time labels at bottom
                width: 80, // Width of the price label area
                child: GestureDetector(
                  onPanUpdate: onPricePanUpdate,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: widget.gridColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.swap_vert,
                        color: widget.textColor.withOpacity(0.3),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),

            // Time labels gesture area (bottom)
            if (widget.enableInteraction && widget.showTimeLabels)
              Positioned(
                left: 0,
                right: widget.showPriceLabels
                    ? 80
                    : 0, // Account for price labels on right
                bottom: 0,
                height: 30, // Height of the time label area
                child: GestureDetector(
                  onPanUpdate: onTimePanUpdate,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(
                        top: BorderSide(
                          color: widget.gridColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.swap_horiz,
                        color: widget.textColor.withOpacity(0.3),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onPointerSignal(PointerSignalEvent event) {
    // Disable pointer signal for now since we're using pinch-to-zoom
    // Can be re-enabled for mouse wheel support if needed
  }
}

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
  final CandleStick? hoveredCandle;
  final Offset? hoverPosition;

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
    this.hoveredCandle,
    this.hoverPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // Calculate price range
    final priceData = _calculatePriceRange();

    // Reserve space for price labels on the right and time labels at bottom
    final priceLabelsWidth = showPriceLabels ? 80.0 : 0.0;
    final timeLabelsHeight = showTimeLabels ? 30.0 : 0.0;
    
    // Calculate effective chart dimensions
    final effectiveChartWidth = size.width - priceLabelsWidth;
    final effectiveChartHeight = size.height - timeLabelsHeight;

    // Draw candlesticks first (behind other elements) in the reserved area
    _drawCandlesticks(canvas, priceData, effectiveChartHeight, effectiveChartWidth);

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

    // Draw hover tooltip (on top of everything)
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

    // Add base padding
    final baseRange = maxPrice - minPrice;
    final basePadding = baseRange * 0.05;
    final paddedMinPrice = minPrice - basePadding;
    final paddedMaxPrice = maxPrice + basePadding;
    final paddedRange = paddedMaxPrice - paddedMinPrice;

    // Apply price scaling with intelligent bounds
    final center = (paddedMinPrice + paddedMaxPrice) / 2;

    final scaledRange = paddedRange / priceScale;

    // Allow much smaller visible range for better zoom out capability
    final minVisibleRange = baseRange * 0.01; // Minimum 1% of original range (was 10%)
    final constrainedRange =
        scaledRange.clamp(minVisibleRange, paddedRange * 10); // Increased max range for better zoom out

    final scaledMinPrice = center - (constrainedRange / 2);
    final scaledMaxPrice = center + (constrainedRange / 2);

    return {
      'min': scaledMinPrice,
      'max': scaledMaxPrice,
      'range': constrainedRange,
    };
  }

  void _drawGrid(Canvas canvas, Size size, double priceChartHeight, double effectiveChartWidth) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0 // Increased for better visibility
      ..style = PaintingStyle.stroke;

    // Horizontal grid lines for price chart - more evenly distributed
    const priceGridLines = 8; // Increased number of lines for better separation
    for (int i = 0; i <= priceGridLines; i++) {
      final y = (priceChartHeight / priceGridLines) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(effectiveChartWidth, y), // Use effective width instead of full width
        gridPaint,
      );
    }

    // Vertical grid lines - more evenly spaced like in trading apps
    final effectiveCandleWidth = (candleWidth + candleSpacing) * timeScale;
    final gridSpacing = effectiveCandleWidth * 8; // More consistent spacing
    
    // Ensure we have at least some vertical lines based on effective width
    final minGridSpacing = effectiveChartWidth / 10;
    final actualGridSpacing = gridSpacing.clamp(minGridSpacing, effectiveChartWidth / 4);
    
    for (double x = 0; x <= effectiveChartWidth; x += actualGridSpacing) {
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

    const labelCount = 8; // Match the grid lines for better alignment
    for (int i = 0; i <= labelCount; i++) {
      final price =
          priceData['min']! + (priceData['range']! * (1 - i / labelCount));
      final y = (chartHeight / labelCount) * i;

      textPainter.text = TextSpan(
        text: price.toStringAsFixed(3), // More precision like in trading apps
        style: labelTextStyle.copyWith(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();

      // Position labels in the reserved right area
      final rightX = size.width - 75; // Position within the reserved 80px area

      // Draw solid background for better readability - no more transparency issues
      final rect = Rect.fromLTWH(
        rightX - 4,
        y - textPainter.height / 2 - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      
      // Use a solid background for clear visibility
      canvas.drawRect(
        rect,
        Paint()..color = const Color(0xFF2B3139), // Solid background - no transparency
      );

      // Draw border around price label for better definition
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
    
    // Draw a vertical separator line between chart and price labels for better visual separation
    canvas.drawLine(
      Offset(size.width - 80, 0),
      Offset(size.width - 80, chartHeight),
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

      textPainter.text = TextSpan(
        text: '${time.month}/${time.day}',
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
        Paint()..color = const Color(0xFF2B3139).withOpacity(0.8), // Slightly less transparent for better readability
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
        Offset(x - textPainter.width / 2,
            size.height - textPainter.height - 3),
      );
    }
  }

  void _drawCandlesticks(
      Canvas canvas, Map<String, double> priceData, double chartHeight, double effectiveChartWidth) {
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
      ..strokeWidth = 1.5 // Slightly thicker wicks for better visibility
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
    final bodyHeight = (bodyBottom - bodyTop).abs().clamp(1.5, double.infinity); // Minimum height for visibility

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

  void _drawHoverTooltip(Canvas canvas, Size size) {
    if (hoveredCandle == null || hoverPosition == null) return;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final tooltipPaint = Paint()
      ..color = const Color(0xFF2B3139) // Dark background matching the theme
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = gridColor // Use grid color for consistency
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Tooltip content - formatted like trading apps
    final tooltipText = '''
Time: ${hoveredCandle!.time.day}/${hoveredCandle!.time.month}/${hoveredCandle!.time.year}
O: ${hoveredCandle!.open.toStringAsFixed(3)}
H: ${hoveredCandle!.high.toStringAsFixed(3)}
L: ${hoveredCandle!.low.toStringAsFixed(3)}
C: ${hoveredCandle!.close.toStringAsFixed(3)}
Vol: ${hoveredCandle!.volume.toStringAsFixed(0)}
''';

    textPainter.text = TextSpan(
      text: tooltipText,
      style: TextStyle(
        color: textColor, // Use theme text color
        fontSize: 11,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace', // Monospace for better alignment
      ),
    );
    textPainter.layout();

    // Position tooltip
    const padding = 10.0;
    final tooltipWidth = textPainter.width + padding * 2;
    final tooltipHeight = textPainter.height + padding * 2;

    double tooltipX = hoverPosition!.dx + 15;
    double tooltipY = hoverPosition!.dy - tooltipHeight - 15;

    // Adjust position if tooltip goes off screen
    if (tooltipX + tooltipWidth > size.width) {
      tooltipX = hoverPosition!.dx - tooltipWidth - 15;
    }
    if (tooltipY < 0) {
      tooltipY = hoverPosition!.dy + 15;
    }

    // Draw tooltip background with shadow effect
    final shadowRect = Rect.fromLTWH(tooltipX + 2, tooltipY + 2, tooltipWidth, tooltipHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(6)),
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    final tooltipRect = Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tooltipRect, const Radius.circular(6)),
      tooltipPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tooltipRect, const Radius.circular(6)),
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
