import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../model/candle_model.dart';
import 'chart_provider.dart';
import 'chart_constants.dart';
import 'stock_chart_painter.dart';
import 'optimized_chart.dart';

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
    this.height = ChartConstants.defaultChartHeight,
    this.candleWidth = ChartConstants.defaultCandleWidth,
    this.candleSpacing = ChartConstants.defaultCandleSpacing,
    this.bullishColor = const Color(ChartConstants.defaultBullishColor),
    this.bearishColor = const Color(ChartConstants.defaultBearishColor),
    this.dojiColor = const Color(ChartConstants.defaultDojiColor),
    this.wickColor = const Color(ChartConstants.defaultWickColor),
    this.backgroundColor = const Color(ChartConstants.defaultBackgroundColor),
    this.gridColor = const Color(ChartConstants.defaultGridColor),
    this.textColor = const Color(ChartConstants.defaultTextColor),
    this.showGrid = true,
    this.showVolume = false,
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

class _StockChartState extends State<StockChart> with TickerProviderStateMixin {
  late AnimationController _momentumController;
  late Animation<double> _momentumAnimation;

  @override
  void initState() {
    super.initState();
    _momentumController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _momentumAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _momentumController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _momentumController.dispose();
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
      create: (context) => ChartProvider()..setCandles(widget.candles),
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
        // Add momentum animation listener
        _momentumAnimation.addListener(() {
          if (chartProvider.isScrolling) {
            final layoutBuilder = context.findRenderObject() as RenderBox?;
            if (layoutBuilder != null) {
              final fullChartWidth = layoutBuilder.size.width;
              final effectiveChartWidth = fullChartWidth -
                  (widget.showPriceLabels
                      ? ChartConstants.priceLabelsWidth
                      : 0.0);
              chartProvider.applyMomentum(
                widget.candles.length,
                effectiveChartWidth,
                widget.candleWidth,
                widget.candleSpacing,
              );
            }
          }
        });
        // Calculate effective chart width (reserve space for price labels)
        final effectiveChartWidth = chartWidth -
            (widget.showPriceLabels ? ChartConstants.priceLabelsWidth : 0.0);

        // Calculate actual candle width based on time scale
        final scaledDimensions = chartProvider.getScaledDimensions(
            widget.candleWidth, widget.candleSpacing);
        final baseCandleWidth = scaledDimensions['candleWidth']!;
        final baseCandleSpacing = scaledDimensions['candleSpacing']!;

        // Get the visible candles using the provider with effective width
        final visibleCandles = chartProvider.getVisibleCandles(
          effectiveChartWidth,
          widget.candleWidth,
          widget.candleSpacing,
        );

        // Define gesture handlers within the Consumer context
        void onScaleStart(ScaleStartDetails details) {
          chartProvider.startScale(
              details.focalPoint.dx, details.focalPoint.dy);
        }

        void onScaleUpdate(ScaleUpdateDetails details) {
          if (details.scale == 1.0 && details.focalPointDelta != Offset.zero) {
            // This is a pan gesture, handle horizontal scrolling
            final layoutBuilder = context.findRenderObject() as RenderBox?;
            if (layoutBuilder != null) {
              final fullChartWidth = layoutBuilder.size.width;
              final effectiveChartWidth = fullChartWidth -
                  (widget.showPriceLabels
                      ? ChartConstants.priceLabelsWidth
                      : 0.0);
              chartProvider.updateScrollOffset(
                details.focalPointDelta.dx,
                widget.candles.length,
                effectiveChartWidth,
                widget.candleWidth,
                widget.candleSpacing,
              );

              // Check if we need to load more data
              if (chartProvider.isScrollingToPast &&
                  widget.onLoadPastData != null) {
                widget.onLoadPastData!();
              } else if (chartProvider.isScrollingToFuture &&
                  widget.onLoadFutureData != null) {
                widget.onLoadFutureData!();
              }
            }
          } else if (details.scale != 1.0) {
            // This is a scale gesture - only handle horizontal scaling (zoom)
            // Calculate the gesture direction to determine if it's horizontal
            final deltaX =
                (details.focalPoint.dx - chartProvider.baseFocalPointX).abs();
            final deltaY =
                (details.focalPoint.dy - chartProvider.baseFocalPointY).abs();

            // Only apply scaling if the gesture is primarily horizontal (zoom)
            if (deltaX > deltaY) {
              chartProvider.updateHorizontalScale(details.scale);
            }
            // Vertical scaling is handled by the price axis pan gestures
          }
        }

        void _startMomentumScrolling(ChartProvider chartProvider) {
          _momentumController.forward().then((_) {
            if (chartProvider.isScrolling) {
              _momentumController.reset();
              _startMomentumScrolling(chartProvider);
            }
          });
        }

        void onScaleEnd(ScaleEndDetails details) {
          // Start momentum scrolling when gesture ends
          if (chartProvider.isScrolling) {
            _startMomentumScrolling(chartProvider);
          }
        }

        void onDoubleTap() {
          chartProvider.resetScaling();
        }

        void onPricePanUpdate(DragUpdateDetails details) {
          // Convert vertical pan delta to scale factor for price scaling
          final scaleFactor =
              1.0 - (details.delta.dy * ChartConstants.panSensitivity);
          chartProvider.updateVerticalScale(scaleFactor);
        }

        void onTimePanUpdate(DragUpdateDetails details) {
          // Convert horizontal pan delta to scale factor for time scaling
          final scaleFactor =
              1.0 + (details.delta.dx * ChartConstants.panSensitivity);
          chartProvider.updateHorizontalScale(scaleFactor);
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
              onPointerSignal:
                  widget.enableInteraction ? _onPointerSignal : null,
              child: MouseRegion(
                onHover: widget.enableInteraction ? onHover : null,
                onExit: widget.enableInteraction ? onHoverExit : null,
                child: widget.enableInteraction
                    ? GestureDetector(
                        onScaleStart: onScaleStart,
                        onScaleUpdate: onScaleUpdate,
                        onScaleEnd: onScaleEnd,
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
                                TextStyle(
                                    color: widget.textColor, fontSize: 10),
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
                bottom:
                    widget.showTimeLabels ? ChartConstants.timeLabelsHeight : 0,
                width: ChartConstants.priceLabelsWidth,
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
                    ? ChartConstants.priceLabelsWidth
                    : 0,
                bottom: 0,
                height: ChartConstants.timeLabelsHeight,
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
    this.bullishColor = const Color(ChartConstants.defaultBullishColor),
    this.bearishColor = const Color(ChartConstants.defaultBearishColor),
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

/// An optimized stock chart widget with enhanced data loading performance
class OptimizedStockChartWidget extends StatelessWidget {
  final String symbol;
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

  const OptimizedStockChartWidget({
    Key? key,
    required this.symbol,
    this.height = ChartConstants.defaultChartHeight,
    this.candleWidth = ChartConstants.defaultCandleWidth,
    this.candleSpacing = ChartConstants.defaultCandleSpacing,
    this.bullishColor = const Color(ChartConstants.defaultBullishColor),
    this.bearishColor = const Color(ChartConstants.defaultBearishColor),
    this.dojiColor = const Color(ChartConstants.defaultDojiColor),
    this.wickColor = const Color(ChartConstants.defaultWickColor),
    this.backgroundColor = const Color(ChartConstants.defaultBackgroundColor),
    this.gridColor = const Color(ChartConstants.defaultGridColor),
    this.textColor = const Color(ChartConstants.defaultTextColor),
    this.showGrid = true,
    this.showVolume = false,
    this.showPriceLabels = true,
    this.showTimeLabels = true,
    this.enableInteraction = true,
    this.volumeHeightRatio = 0.2,
    this.labelTextStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OptimizedStockChart(
      symbol: symbol,
      height: height,
      candleWidth: candleWidth,
      candleSpacing: candleSpacing,
      bullishColor: bullishColor,
      bearishColor: bearishColor,
      dojiColor: dojiColor,
      wickColor: wickColor,
      backgroundColor: backgroundColor,
      gridColor: gridColor,
      textColor: textColor,
      showGrid: showGrid,
      showVolume: showVolume,
      showPriceLabels: showPriceLabels,
      showTimeLabels: showTimeLabels,
      enableInteraction: enableInteraction,
      volumeHeightRatio: volumeHeightRatio,
      labelTextStyle: labelTextStyle,
    );
  }
}
