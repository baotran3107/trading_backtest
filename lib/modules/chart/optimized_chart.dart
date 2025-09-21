import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'enhanced_chart_provider.dart';
import 'chart_constants.dart';
import 'stock_chart_painter.dart';

/// Optimized stock chart widget with enhanced data loading
class OptimizedStockChart extends StatefulWidget {
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

  const OptimizedStockChart({
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
  State<OptimizedStockChart> createState() => _OptimizedStockChartState();
}

class _OptimizedStockChartState extends State<OptimizedStockChart>
    with TickerProviderStateMixin {
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
    return ChangeNotifierProvider(
      create: (context) => EnhancedChartProvider(symbol: widget.symbol),
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
    return Consumer<EnhancedChartProvider>(
      builder: (context, chartProvider, child) {
        // Handle loading states
        if (chartProvider.loadingState == DataLoadingState.loading) {
          return _buildLoadingWidget();
        }

        if (chartProvider.loadingState == DataLoadingState.error) {
          return _buildErrorWidget(chartProvider.errorMessage);
        }

        if (chartProvider.candles.isEmpty) {
          return _buildEmptyWidget();
        }

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
              chartProvider.updateScrollOffset(
                0.0, // No delta for momentum
                effectiveChartWidth,
                widget.candleWidth,
                widget.candleSpacing,
              );
            }
          }
        });

        // Calculate effective chart width
        final effectiveChartWidth = chartWidth -
            (widget.showPriceLabels ? ChartConstants.priceLabelsWidth : 0.0);

        // Calculate actual candle width based on time scale
        final scaledDimensions = chartProvider.getScaledDimensions(
            widget.candleWidth, widget.candleSpacing);
        final baseCandleWidth = scaledDimensions['candleWidth']!;
        final baseCandleSpacing = scaledDimensions['candleSpacing']!;

        // Get the visible candles using the provider
        final visibleCandles = chartProvider.getVisibleCandles(
          effectiveChartWidth,
          widget.candleWidth,
          widget.candleSpacing,
        );

        // Define gesture handlers
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
                effectiveChartWidth,
                widget.candleWidth,
                widget.candleSpacing,
              );
            }
          } else if (details.scale != 1.0) {
            // This is a scale gesture - only handle horizontal scaling (zoom)
            final deltaX =
                (details.focalPoint.dx - chartProvider.baseFocalPointX).abs();
            final deltaY =
                (details.focalPoint.dy - chartProvider.baseFocalPointY).abs();

            // Only apply scaling if the gesture is primarily horizontal (zoom)
            if (deltaX > deltaY) {
              chartProvider.updateHorizontalScale(details.scale);
            }
          }
        }

        void _startMomentumScrolling(EnhancedChartProvider chartProvider) {
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
            chartProvider.candles,
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

            // Loading indicators with better positioning
            if (chartProvider.isLoadingPast)
              Positioned(
                top: 10,
                left: 10,
                child: _buildLoadingIndicator('Loading past data...', true),
              ),

            if (chartProvider.isLoadingFuture)
              Positioned(
                top: 10,
                right: 10,
                child: _buildLoadingIndicator('Loading future data...', false),
              ),

            // Scroll velocity indicator (for debugging)
            if (chartProvider.scrollVelocity.abs() >
                ChartConstants.scrollVelocityThreshold)
              Positioned(
                top: 50,
                left: 10,
                child: _buildVelocityIndicator(chartProvider.scrollVelocity),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: widget.textColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading chart data...',
            style: TextStyle(
              color: widget.textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String? errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: widget.textColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load chart data',
            style: TextStyle(
              color: widget.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                color: widget.textColor.withOpacity(0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Retry loading
              final provider = context.read<EnhancedChartProvider>();
              provider.clearCache();
              setState(() {});
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Text(
        'No data available',
        style: TextStyle(
          color: widget.textColor,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(String message, bool isPast) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.backgroundColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPast
              ? widget.bullishColor.withOpacity(0.5)
              : widget.bearishColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isPast ? widget.bullishColor : widget.bearishColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityIndicator(double velocity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.backgroundColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.gridColor.withOpacity(0.3)),
      ),
      child: Text(
        'Velocity: ${velocity.toStringAsFixed(1)}',
        style: TextStyle(
          color: widget.textColor.withOpacity(0.7),
          fontSize: 10,
        ),
      ),
    );
  }

  void _onPointerSignal(PointerSignalEvent event) {
    // Disable pointer signal for now since we're using pinch-to-zoom
    // Can be re-enabled for mouse wheel support if needed
  }
}
