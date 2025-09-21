import 'package:flutter/material.dart';
import '../../model/candle_model.dart';
import 'chart_constants.dart';

/// Manages hover state for the chart
class ChartHoverState {
  CandleStick? hoveredCandle;
  Offset? hoverPosition;

  bool get hasHover => hoveredCandle != null && hoverPosition != null;

  void setHover(CandleStick? candle, Offset? position) {
    hoveredCandle = candle;
    hoverPosition = position;
  }

  void clear() {
    hoveredCandle = null;
    hoverPosition = null;
  }

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartHoverState &&
        other.hoveredCandle == hoveredCandle &&
        other.hoverPosition == hoverPosition;
  }

  @override
  int get hashCode => Object.hash(hoveredCandle, hoverPosition);
}

/// Manages scaling state for the chart
class ChartScaleState {
  double timeScale = 1.0;
  double priceScale = 1.0;
  double baseFocalPointX = 0.0;
  double baseFocalPointY = 0.0;

  void setTimeScale(double value) {
    timeScale =
        value.clamp(ChartConstants.minTimeScale, ChartConstants.maxTimeScale);
  }

  void setPriceScale(double value) {
    priceScale =
        value.clamp(ChartConstants.minPriceScale, ChartConstants.maxPriceScale);
  }

  void reset() {
    timeScale = 1.0;
    priceScale = 1.0;
  }

  bool get isAtDefault => timeScale == 1.0 && priceScale == 1.0;
}

/// Manages scrolling state for the chart
class ChartScrollState {
  double scrollOffset = 0.0;
  int visibleStartIndex = 0;
  int visibleEndIndex = 0;
  bool isScrollingToPast = false;
  bool isScrollingToFuture = false;

  // Smooth scrolling state
  double _velocity = 0.0;
  double _lastScrollTime = 0.0;

  void reset() {
    scrollOffset = 0.0;
    visibleStartIndex = 0;
    visibleEndIndex = 0;
    isScrollingToPast = false;
    isScrollingToFuture = false;
    _velocity = 0.0;
    _lastScrollTime = 0.0;
  }

  void updateVelocity(double deltaX) {
    final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();
    if (_lastScrollTime > 0) {
      final deltaTime =
          (currentTime - _lastScrollTime) / 1000.0; // Convert to seconds
      if (deltaTime > 0) {
        _velocity = (deltaX / deltaTime)
            .clamp(-ChartConstants.maxVelocity, ChartConstants.maxVelocity);
      }
    }
    _lastScrollTime = currentTime;
  }

  void decayVelocity() {
    _velocity *= ChartConstants.velocityDecay;
    if (_velocity.abs() < ChartConstants.scrollThreshold) {
      _velocity = 0.0;
    }
  }

  double get velocity => _velocity;
  bool get isScrolling => _velocity.abs() > ChartConstants.scrollThreshold;

  void stopMomentum() {
    _velocity = 0.0;
    _lastScrollTime = 0.0;
  }
}

/// Provider for managing chart state, scaling, scrolling, and hover interactions.
class ChartProvider extends ChangeNotifier {
  final ChartHoverState _hoverState = ChartHoverState();
  final ChartScaleState _scaleState = ChartScaleState();
  final ChartScrollState _scrollState = ChartScrollState();

  // Public getters
  CandleStick? get hoveredCandle => _hoverState.hoveredCandle;
  Offset? get hoverPosition => _hoverState.hoverPosition;
  double get timeScale => _scaleState.timeScale;
  double get priceScale => _scaleState.priceScale;
  double get minTimeScale => ChartConstants.minTimeScale;
  double get maxTimeScale => ChartConstants.maxTimeScale;
  double get minPriceScale => ChartConstants.minPriceScale;
  double get maxPriceScale => ChartConstants.maxPriceScale;
  double get scrollOffset => _scrollState.scrollOffset;
  int get visibleStartIndex => _scrollState.visibleStartIndex;
  int get visibleEndIndex => _scrollState.visibleEndIndex;
  bool get isScrollingToPast => _scrollState.isScrollingToPast;
  bool get isScrollingToFuture => _scrollState.isScrollingToFuture;
  double get scrollVelocity => _scrollState.velocity;
  bool get isScrolling => _scrollState.isScrolling;

  /// Set the hovered candle and position (for tooltip display)
  void setHover(CandleStick? candle, Offset? position) {
    final previousState = _hoverState.hoveredCandle != candle ||
        _hoverState.hoverPosition != position;

    _hoverState.setHover(candle, position);

    if (previousState) {
      notifyListeners();
    }
  }

  /// Clear the hover state
  void clearHover() {
    if (_hoverState.hasHover) {
      _hoverState.clear();
      notifyListeners();
    }
  }

  /// Start a scaling gesture (pinch zoom)
  void startScale(double focalPointX, double focalPointY) {
    _scaleState.baseFocalPointX = focalPointX;
    _scaleState.baseFocalPointY = focalPointY;
  }

  /// Update scaling based on gesture direction (horizontal = time, vertical = price)
  void updateScale(double scale, double focalPointX, double focalPointY) {
    if (scale == 1.0) return;

    final deltaX = (focalPointX - _scaleState.baseFocalPointX).abs();
    final deltaY = (focalPointY - _scaleState.baseFocalPointY).abs();

    bool hasChanges = false;
    if (deltaX > deltaY) {
      final oldScale = _scaleState.timeScale;
      _scaleState.setTimeScale(_scaleState.timeScale * scale);
      hasChanges = oldScale != _scaleState.timeScale;
    } else {
      final oldScale = _scaleState.priceScale;
      _scaleState.setPriceScale(_scaleState.priceScale * scale);
      hasChanges = oldScale != _scaleState.priceScale;
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Pan vertically to adjust price scale
  void updatePriceScaleFromPan(double deltaY) {
    final oldScale = _scaleState.priceScale;
    _scaleState.setPriceScale(_scaleState.priceScale *
        (1.0 - (deltaY * ChartConstants.panSensitivity)));

    if (oldScale != _scaleState.priceScale) {
      notifyListeners();
    }
  }

  /// Pan horizontally to adjust time scale
  void updateTimeScaleFromPan(double deltaX) {
    final oldScale = _scaleState.timeScale;
    _scaleState.setTimeScale(_scaleState.timeScale *
        (1.0 + (deltaX * ChartConstants.panSensitivity)));

    if (oldScale != _scaleState.timeScale) {
      notifyListeners();
    }
  }

  /// Reset both time and price scaling to default
  void resetScaling() {
    if (!_scaleState.isAtDefault) {
      _scaleState.reset();
      notifyListeners();
    }
  }

  /// Update scroll offset for horizontal panning with smooth scrolling
  void updateScrollOffset(
    double deltaX,
    int totalDataLength,
    double chartWidth,
    double candleWidth,
    double candleSpacing,
  ) {
    // Update velocity for smooth scrolling
    _scrollState.updateVelocity(deltaX);

    final candleUnitWidth =
        _calculateCandleUnitWidth(candleWidth, candleSpacing);
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final maxScrollOffset =
        (totalDataLength - maxVisibleCandles) * candleUnitWidth;

    // Apply smooth scrolling with momentum
    final momentumFactor =
        _scrollState.isScrolling ? ChartConstants.momentumFactor : 1.0;
    final adjustedDeltaX = deltaX * momentumFactor;
    final newScrollOffset = (_scrollState.scrollOffset - adjustedDeltaX)
        .clamp(0.0, maxScrollOffset.toDouble());

    if ((newScrollOffset - _scrollState.scrollOffset).abs() > 0.1) {
      _scrollState.scrollOffset = newScrollOffset;
      _updateVisibleIndices(
          totalDataLength, candleUnitWidth, maxVisibleCandles);
      notifyListeners();
    }
  }

  void _updateVisibleIndices(
      int totalDataLength, double candleUnitWidth, int maxVisibleCandles) {
    final startIndex = (_scrollState.scrollOffset / candleUnitWidth).floor();
    final endIndex = (startIndex + maxVisibleCandles).clamp(0, totalDataLength);
    _scrollState.visibleStartIndex = startIndex;
    _scrollState.visibleEndIndex = endIndex;

    // Use dynamic buffer based on chart size for smoother past/future detection
    final bufferSize = (maxVisibleCandles * 0.1).ceil().clamp(5, 20);
    _scrollState.isScrollingToPast = startIndex <= bufferSize;
    _scrollState.isScrollingToFuture = endIndex >= totalDataLength - bufferSize;
  }

  double _calculateCandleUnitWidth(double candleWidth, double candleSpacing) {
    return (candleWidth * _scaleState.timeScale) +
        (candleSpacing * _scaleState.timeScale);
  }

  /// Center the scroll to show the middle of the data
  void resetScroll(
    int totalDataLength,
    double chartWidth,
    double candleWidth,
    double candleSpacing,
  ) {
    final candleUnitWidth =
        _calculateCandleUnitWidth(candleWidth, candleSpacing);
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final centerStartIndex = ((totalDataLength - maxVisibleCandles) / 2)
        .floor()
        .clamp(0, totalDataLength - maxVisibleCandles);

    _scrollState.scrollOffset = centerStartIndex * candleUnitWidth;
    _scrollState.visibleStartIndex = centerStartIndex;
    _scrollState.visibleEndIndex =
        (centerStartIndex + maxVisibleCandles).clamp(0, totalDataLength);
    _scrollState.isScrollingToPast = false;
    _scrollState.isScrollingToFuture = false;
    notifyListeners();
  }

  /// Scroll to a specific candle index, centering it in view
  void scrollToIndex(
    int targetIndex,
    int totalDataLength,
    double chartWidth,
    double candleWidth,
    double candleSpacing,
  ) {
    final candleUnitWidth =
        _calculateCandleUnitWidth(candleWidth, candleSpacing);
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final centerIndex = (targetIndex - maxVisibleCandles / 2)
        .floor()
        .clamp(0, totalDataLength - maxVisibleCandles);

    _scrollState.scrollOffset = centerIndex * candleUnitWidth;
    _scrollState.visibleStartIndex = centerIndex;
    _scrollState.visibleEndIndex =
        (centerIndex + maxVisibleCandles).clamp(0, totalDataLength);
    notifyListeners();
  }

  /// Get the currently visible candles for the chart
  List<CandleStick> getVisibleCandles(
    List<CandleStick> allCandles,
    double chartWidth,
    double candleWidth,
    double candleSpacing,
  ) {
    if (allCandles.isEmpty) return [];

    final candleUnitWidth =
        _calculateCandleUnitWidth(candleWidth, candleSpacing);
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final totalCandles = allCandles.length;

    int startIndex = _scrollState.visibleStartIndex;
    int endIndex = _scrollState.visibleEndIndex;

    // If not initialized, center the view
    if (_scrollState.scrollOffset == 0.0 &&
        _scrollState.visibleStartIndex == 0 &&
        _scrollState.visibleEndIndex == 0) {
      final visibleCandleCount = maxVisibleCandles.clamp(1, totalCandles);
      startIndex = ((totalCandles - visibleCandleCount) / 2)
          .floor()
          .clamp(0, totalCandles - visibleCandleCount);
      endIndex = (startIndex + visibleCandleCount).clamp(0, totalCandles);
      _scrollState.visibleStartIndex = startIndex;
      _scrollState.visibleEndIndex = endIndex;
    }

    // Add buffer for smoother scrolling (render slightly more candles than visible)
    final bufferSize = (maxVisibleCandles * ChartConstants.scrollBufferRatio)
        .ceil()
        .clamp(ChartConstants.minScrollBuffer, ChartConstants.maxScrollBuffer);
    final bufferedStartIndex = (startIndex - bufferSize).clamp(0, totalCandles);
    final bufferedEndIndex = (endIndex + bufferSize).clamp(0, totalCandles);

    return allCandles.sublist(bufferedStartIndex, bufferedEndIndex);
  }

  /// Get the scaled candle width and spacing for current time scale
  Map<String, double> getScaledDimensions(
      double candleWidth, double candleSpacing) {
    return {
      'candleWidth': candleWidth * _scaleState.timeScale,
      'candleSpacing': candleSpacing * _scaleState.timeScale,
    };
  }

  /// Get the candle at a given X position (for hover/tooltip)
  CandleStick? getCandleAtPosition(
    List<CandleStick> allCandles,
    double localX,
    double actualCandleWidth,
    double actualCandleSpacing,
    int startIndex,
  ) {
    final candleUnitWidth = actualCandleWidth + actualCandleSpacing;
    final visibleCandleIndex = (localX / candleUnitWidth).floor();
    final actualCandleIndex =
        _scrollState.visibleStartIndex + visibleCandleIndex;
    if (actualCandleIndex >= 0 && actualCandleIndex < allCandles.length) {
      return allCandles[actualCandleIndex];
    }
    return null;
  }

  /// Apply momentum scrolling for smooth deceleration
  void applyMomentum(
    int totalDataLength,
    double chartWidth,
    double candleWidth,
    double candleSpacing,
  ) {
    if (!_scrollState.isScrolling) return;

    _scrollState.decayVelocity();

    if (_scrollState.velocity.abs() > 0.1) {
      final candleUnitWidth =
          _calculateCandleUnitWidth(candleWidth, candleSpacing);
      final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
      final maxScrollOffset =
          (totalDataLength - maxVisibleCandles) * candleUnitWidth;

      final momentumDelta = _scrollState.velocity * 0.016; // ~60fps
      final newScrollOffset = (_scrollState.scrollOffset - momentumDelta)
          .clamp(0.0, maxScrollOffset.toDouble());

      if ((newScrollOffset - _scrollState.scrollOffset).abs() > 0.1) {
        _scrollState.scrollOffset = newScrollOffset;
        _updateVisibleIndices(
            totalDataLength, candleUnitWidth, maxVisibleCandles);
        notifyListeners();
      }
    }
  }

  /// Stop momentum scrolling immediately
  void stopMomentum() {
    _scrollState.stopMomentum();
  }

  /// Reset all chart state to default values
  void resetAll() {
    _hoverState.clear();
    _scaleState.reset();
    _scrollState.reset();
    notifyListeners();
  }
}
