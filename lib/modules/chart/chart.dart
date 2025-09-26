import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../model/candle_model.dart';
import 'chart_provider.dart';
import 'chart_constants.dart';
import 'stock_chart_painter.dart';
import 'optimized_chart.dart';

enum _DragType { none, sl, tp }

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
  final bool useProvidedCandlesDirectly;
  final bool autoFollowLatest;
  final bool isPlaying;
  final int futurePaddingCandles;
  final List<double> buyEntryPrices;
  final List<double> sellEntryPrices;
  final List<double> stopLossPrices;
  final List<double> takeProfitPrices;
  final ValueChanged<List<double>>? onStopLossPricesChanged;
  final ValueChanged<List<double>>? onTakeProfitPricesChanged;
  final List<double> Function()? getStopLossPnL;
  final List<double> Function()? getTakeProfitPnL;
  final VoidCallback? onPriceUpdate;

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
    this.useProvidedCandlesDirectly = false,
    this.autoFollowLatest = false,
    this.isPlaying = false,
    this.futurePaddingCandles = 0,
    this.buyEntryPrices = const [],
    this.sellEntryPrices = const [],
    this.stopLossPrices = const [],
    this.takeProfitPrices = const [],
    this.onStopLossPricesChanged,
    this.onTakeProfitPricesChanged,
    this.getStopLossPnL,
    this.getTakeProfitPnL,
    this.onPriceUpdate,
  }) : super(key: key);

  @override
  State<StockChart> createState() => _StockChartState();
}

class _StockChartState extends State<StockChart> with TickerProviderStateMixin {
  late AnimationController _momentumController;
  late Animation<double> _momentumAnimation;
  bool _userInteracted = false;
  late final ChartProvider _chartProvider;
  bool _isDraggingLine = false;

  @override
  void initState() {
    super.initState();
    _chartProvider = ChartProvider()..setCandles(widget.candles);
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
  void didUpdateWidget(covariant StockChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool candlesIdentityChanged =
        !identical(oldWidget.candles, widget.candles);
    final bool candlesLengthChanged =
        oldWidget.candles.length != widget.candles.length;
    // Reset user interaction lock when (re)starting play
    if (oldWidget.isPlaying != widget.isPlaying && widget.isPlaying) {
      _userInteracted = false;
    }
    if (candlesIdentityChanged || candlesLengthChanged) {
      try {
        _chartProvider.setCandles(widget.candles);
        // Auto follow latest candle when new candle appears (even when not playing),
        // unless the user has interacted (panned/zoomed)
        if (widget.autoFollowLatest &&
            !_userInteracted &&
            widget.candles.isNotEmpty &&
            candlesLengthChanged) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final layoutBuilder = context.findRenderObject() as RenderBox?;
            if (layoutBuilder != null) {
              final fullChartWidth = layoutBuilder.size.width;
              final effectiveChartWidth = fullChartWidth -
                  (widget.showPriceLabels
                      ? ChartConstants.priceLabelsWidth
                      : 0.0);
              final targetIndex = widget.candles.length - 1;
              _chartProvider.scrollToIndex(
                targetIndex,
                widget.candles.length + widget.futurePaddingCandles,
                effectiveChartWidth,
                widget.candleWidth,
                widget.candleSpacing,
              );
            }
          });
        }
      } catch (_) {
        // Provider might not be available yet in rare rebuild orders; ignore
      }
    }

    // Check for order crossings when price data changes
    if (candlesLengthChanged && widget.onPriceUpdate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onPriceUpdate?.call();
      });
    }
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

    return ChangeNotifierProvider<ChartProvider>.value(
      value: _chartProvider,
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
    if (widget.useProvidedCandlesDirectly) {
      // Bypass provider visibility logic: render all provided candles as-is
      return Container(
        height: widget.height,
        color: widget.backgroundColor,
        child: CustomPaint(
          size: Size(chartWidth, widget.height),
          painter: StockChartPainter(
            candles: widget.candles,
            candleWidth: widget.candleWidth,
            candleSpacing: widget.candleSpacing,
            timeScale: 1.0,
            priceScale: 1.0,
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
            buyEntryPrices: widget.buyEntryPrices,
            sellEntryPrices: widget.sellEntryPrices,
            stopLossPrices: widget.stopLossPrices,
            takeProfitPrices: widget.takeProfitPrices,
            stopLossPnL: widget.getStopLossPnL?.call() ?? [],
            takeProfitPnL: widget.getTakeProfitPnL?.call() ?? [],
          ),
        ),
      );
    }

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
                widget.candles.length + widget.futurePaddingCandles,
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
          // Detect line-drag start near SL/TP lines
          final layoutBox = context.findRenderObject() as RenderBox?;
          if (layoutBox != null) {
            final local = layoutBox.globalToLocal(details.focalPoint);
            final containerHeight = layoutBox.size.height;
            final chartHeight = containerHeight -
                (widget.showTimeLabels ? ChartConstants.timeLabelsHeight : 0.0);
            if (local.dy >= 0 && local.dy <= chartHeight) {
              // compute price mapping like painter
              double minPrice = visibleCandles.first.low;
              double maxPrice = visibleCandles.first.high;
              for (final c in visibleCandles) {
                if (c.low < minPrice) minPrice = c.low;
                if (c.high > maxPrice) maxPrice = c.high;
              }
              final baseRange = maxPrice - minPrice;
              final basePadding = baseRange * ChartConstants.basePadding;
              final paddedMinPrice = minPrice - basePadding;
              final paddedMaxPrice = maxPrice + basePadding;
              final paddedRange = paddedMaxPrice - paddedMinPrice;
              final center = (paddedMinPrice + paddedMaxPrice) / 2;
              final scaledRange = paddedRange / chartProvider.priceScale;
              final minVisibleRange =
                  baseRange * ChartConstants.minVisibleRange;
              final constrainedRange = scaledRange.clamp(minVisibleRange,
                  paddedRange * ChartConstants.maxVisibleRange);
              final scaledMinPrice = center - (constrainedRange / 2);

              double priceToY(double price) {
                return (chartHeight -
                        ((price - scaledMinPrice) / constrainedRange) *
                            chartHeight)
                    .clamp(0.0, chartHeight);
              }

              const tolerance = 24.0; // easier to tap/drag SL/TP lines
              for (int i = 0; i < widget.stopLossPrices.length; i++) {
                final ly = priceToY(widget.stopLossPrices[i]);
                if ((ly - local.dy).abs() <= tolerance) {
                  _dragType = _DragType.sl;
                  _dragIndex = i;
                  _isDraggingLine = true;
                  return;
                }
              }
              for (int i = 0; i < widget.takeProfitPrices.length; i++) {
                final ly = priceToY(widget.takeProfitPrices[i]);
                if ((ly - local.dy).abs() <= tolerance) {
                  _dragType = _DragType.tp;
                  _dragIndex = i;
                  _isDraggingLine = true;
                  return;
                }
              }
            }
          }
          // Otherwise start normal chart interaction
          chartProvider.startScale(
              details.focalPoint.dx, details.focalPoint.dy);
        }

        void onScaleUpdate(ScaleUpdateDetails details) {
          if (_isDraggingLine &&
              _dragIndex != null &&
              _dragType != _DragType.none) {
            final layoutBox = context.findRenderObject() as RenderBox?;
            if (layoutBox != null) {
              final local = layoutBox.globalToLocal(details.focalPoint);
              final containerHeight = layoutBox.size.height;
              final chartHeight = containerHeight -
                  (widget.showTimeLabels
                      ? ChartConstants.timeLabelsHeight
                      : 0.0);
              final clampedY = local.dy.clamp(0.0, chartHeight);

              double minPrice = visibleCandles.first.low;
              double maxPrice = visibleCandles.first.high;
              for (final c in visibleCandles) {
                if (c.low < minPrice) minPrice = c.low;
                if (c.high > maxPrice) maxPrice = c.high;
              }
              final baseRange = maxPrice - minPrice;
              final basePadding = baseRange * ChartConstants.basePadding;
              final paddedMinPrice = minPrice - basePadding;
              final paddedMaxPrice = maxPrice + basePadding;
              final paddedRange = paddedMaxPrice - paddedMinPrice;
              final center = (paddedMinPrice + paddedMaxPrice) / 2;
              final scaledRange = paddedRange / chartProvider.priceScale;
              final minVisibleRange =
                  baseRange * ChartConstants.minVisibleRange;
              final constrainedRange = scaledRange.clamp(minVisibleRange,
                  paddedRange * ChartConstants.maxVisibleRange);
              final scaledMinPrice = center - (constrainedRange / 2);

              final ratio = (chartHeight - clampedY) / chartHeight;
              final newPrice = scaledMinPrice + ratio * constrainedRange;

              if (_dragType == _DragType.sl &&
                  widget.onStopLossPricesChanged != null) {
                final updated = List<double>.from(widget.stopLossPrices);
                updated[_dragIndex!] = newPrice;
                widget.onStopLossPricesChanged!(updated);
              } else if (_dragType == _DragType.tp &&
                  widget.onTakeProfitPricesChanged != null) {
                final updated = List<double>.from(widget.takeProfitPrices);
                updated[_dragIndex!] = newPrice;
                widget.onTakeProfitPricesChanged!(updated);
              }
            }
            return; // swallow chart interactions while dragging a line
          }

          if (details.scale == 1.0 && details.focalPointDelta != Offset.zero) {
            // This is a pan gesture, handle horizontal scrolling
            _userInteracted = true;
            final layoutBuilder = context.findRenderObject() as RenderBox?;
            if (layoutBuilder != null) {
              final fullChartWidth = layoutBuilder.size.width;
              final effectiveChartWidth = fullChartWidth -
                  (widget.showPriceLabels
                      ? ChartConstants.priceLabelsWidth
                      : 0.0);
              chartProvider.updateScrollOffset(
                details.focalPointDelta.dx,
                widget.candles.length + widget.futurePaddingCandles,
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
            // This is a scale gesture - handle zoom with focal point preservation
            _userInteracted = true;
            // Calculate effective chart width for proper focal point calculation
            final layoutBuilder = context.findRenderObject() as RenderBox?;
            if (layoutBuilder != null) {
              final fullChartWidth = layoutBuilder.size.width;
              final effectiveChartWidth = fullChartWidth -
                  (widget.showPriceLabels
                      ? ChartConstants.priceLabelsWidth
                      : 0.0);

              // Use the focal point from the gesture, but ensure it's within chart bounds
              final focalPointX =
                  details.focalPoint.dx.clamp(0.0, effectiveChartWidth);

              // Use context-aware focal point preservation for zoom
              chartProvider.updateHorizontalScaleWithFocalPointAndContext(
                  details.scale,
                  focalPointX,
                  effectiveChartWidth,
                  widget.candleWidth,
                  widget.candleSpacing);
            } else {
              // Fallback to regular focal point preservation
              chartProvider.updateHorizontalScaleWithFocalPoint(
                  details.scale, details.focalPoint.dx);
            }
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
          _isDraggingLine = false;
          _dragType = _DragType.none;
          _dragIndex = null;
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

        // Hover-to-candle tooltip removed per requirement

        return Stack(
          children: [
            // Main chart area with scroll handling
            Listener(
              onPointerSignal:
                  widget.enableInteraction ? _onPointerSignal : null,
              child: MouseRegion(
                onHover: null,
                onExit: null,
                child: widget.enableInteraction
                    ? GestureDetector(
                        onScaleStart: onScaleStart,
                        onScaleUpdate: onScaleUpdate,
                        onScaleEnd: onScaleEnd,
                        onDoubleTap: onDoubleTap,
                        child: _buildInteractiveChartLayer(
                            chartWidth,
                            visibleCandles,
                            baseCandleWidth,
                            baseCandleSpacing,
                            chartProvider),
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
                          buyEntryPrices: widget.buyEntryPrices,
                          sellEntryPrices: widget.sellEntryPrices,
                          stopLossPrices: widget.stopLossPrices,
                          takeProfitPrices: widget.takeProfitPrices,
                          stopLossPnL: widget.getStopLossPnL?.call() ?? [],
                          takeProfitPnL: widget.getTakeProfitPnL?.call() ?? [],
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

  _DragType _dragType = _DragType.none;
  int? _dragIndex;
  bool _hoverOverLine = false;

  Widget _buildInteractiveChartLayer(
    double chartWidth,
    List<CandleStick> visibleCandles,
    double baseCandleWidth,
    double baseCandleSpacing,
    ChartProvider chartProvider,
  ) {
    // Helper to compute price range like painter
    Map<String, double> computePriceRange() {
      if (visibleCandles.isEmpty) {
        return {'min': 0, 'max': 1, 'range': 1};
      }
      double minPrice = visibleCandles.first.low;
      double maxPrice = visibleCandles.first.high;
      for (final c in visibleCandles) {
        if (c.low < minPrice) minPrice = c.low;
        if (c.high > maxPrice) maxPrice = c.high;
      }
      final baseRange = maxPrice - minPrice;
      final basePadding = baseRange * ChartConstants.basePadding;
      final paddedMinPrice = minPrice - basePadding;
      final paddedMaxPrice = maxPrice + basePadding;
      final paddedRange = paddedMaxPrice - paddedMinPrice;
      final center = (paddedMinPrice + paddedMaxPrice) / 2;
      final scaledRange = paddedRange / chartProvider.priceScale;
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

    double getEffectiveChartHeight() {
      final renderBox = context.findRenderObject() as RenderBox?;
      final actualHeight = renderBox?.size.height ?? widget.height;
      return actualHeight -
          (widget.showTimeLabels ? ChartConstants.timeLabelsHeight : 0.0);
    }

    double priceToY(double price, Map<String, double> priceData) {
      final chartHeight = getEffectiveChartHeight();
      final min = priceData['min']!;
      final range = priceData['range']!;
      return (chartHeight - ((price - min) / range) * chartHeight)
          .clamp(0.0, chartHeight);
    }

    // yToPrice helper not used after gesture refactor; remove if unused

    void handleHover(PointerHoverEvent event) {
      if (!widget.enableInteraction) return;
      final priceData = computePriceRange();
      final y = event.localPosition.dy;
      final chartHeight = getEffectiveChartHeight();
      bool newHover = false;
      if (y >= 0 && y <= chartHeight) {
        const tolerance = 24.0; // match drag hit tolerance for consistent UX
        for (final sl in widget.stopLossPrices) {
          final ly = priceToY(sl, priceData);
          if ((ly - y).abs() <= tolerance) {
            newHover = true;
            break;
          }
        }
        if (!newHover) {
          for (final tp in widget.takeProfitPrices) {
            final ly = priceToY(tp, priceData);
            if ((ly - y).abs() <= tolerance) {
              newHover = true;
              break;
            }
          }
        }
      }
      if (newHover != _hoverOverLine) {
        setState(() {
          _hoverOverLine = newHover;
        });
      }
    }

    return MouseRegion(
      onHover: handleHover,
      cursor: _hoverOverLine
          ? SystemMouseCursors.resizeUpDown
          : SystemMouseCursors.basic,
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
          buyEntryPrices: widget.buyEntryPrices,
          sellEntryPrices: widget.sellEntryPrices,
          stopLossPrices: widget.stopLossPrices,
          takeProfitPrices: widget.takeProfitPrices,
          stopLossPnL: widget.getStopLossPnL?.call() ?? [],
          takeProfitPnL: widget.getTakeProfitPnL?.call() ?? [],
        ),
      ),
    );
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Handle mouse wheel zoom with center focal point and controlled sensitivity
      final rawScaleFactor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
      final chartProvider = context.read<ChartProvider>();

      // Apply mouse wheel specific sensitivity for even more controlled zooming
      final sensitivity = ChartConstants.mouseWheelZoomSensitivity;
      final scaleChange = (rawScaleFactor - 1.0) * sensitivity;
      final controlledScaleFactor = 1.0 + scaleChange;

      // Use center of chart as focal point for mouse wheel zoom
      final layoutBuilder = context.findRenderObject() as RenderBox?;
      if (layoutBuilder != null) {
        final chartWidth = layoutBuilder.size.width;
        final effectiveChartWidth = chartWidth -
            (widget.showPriceLabels ? ChartConstants.priceLabelsWidth : 0.0);
        final centerX = effectiveChartWidth / 2;

        chartProvider.updateHorizontalScaleWithFocalPointAndContext(
            controlledScaleFactor,
            centerX,
            effectiveChartWidth,
            widget.candleWidth,
            widget.candleSpacing);
      } else {
        chartProvider.updateHorizontalScale(controlledScaleFactor);
      }
    }
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
