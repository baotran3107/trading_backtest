import 'package:flutter/material.dart';
import '../../model/candle_model.dart';
import 'chart_state.dart';
import 'chart_constants.dart';
import 'chart_utils.dart';

/// Provider for managing chart state, scaling, scrolling, and hover interactions.
class ChartProvider extends ChangeNotifier {
  final ChartHoverState _hoverState = ChartHoverState();
  final ChartScaleState _scaleState = ChartScaleState();
  final ChartScrollState _scrollState = ChartScrollState();

  List<CandleStick> _allCandles = [];

  void setCandles(List<CandleStick> candles) {
    final bool lengthChanged = _allCandles.length != candles.length;
    final bool identityChanged = !identical(_allCandles, candles);
    _allCandles = candles;
    if (lengthChanged || identityChanged) {
      notifyListeners();
    }
  }

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
  double get baseFocalPointX => _scaleState.baseFocalPointX;
  double get baseFocalPointY => _scaleState.baseFocalPointY;

  /// Set the hovered candle and position (for tooltip display)
  void setHover(CandleStick? candle, Offset? position) {
    final hasChanged = _hoverState.hoveredCandle != candle ||
        _hoverState.hoverPosition != position;

    _hoverState.setHover(candle, position);

    if (hasChanged) {
      notifyListeners();
    }
  }

  /// Clear the hover state
  void clearHover() {
    final hadHover = _hoverState.hasHover;
    _hoverState.clear();
    if (hadHover) {
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

  /// Update only horizontal scaling (time scale/zoom)
  void updateHorizontalScale(double scale) {
    if (scale == 1.0) return;

    final oldScale = _scaleState.timeScale;
    // Apply scale factor with smoothing to prevent jumpy behavior
    final newScale = _scaleState.timeScale * scale;
    _scaleState.setTimeScale(newScale);

    if (oldScale != _scaleState.timeScale) {
      // Normalize scroll state when zoom level changes to prevent jumping
      _normalizeScrollStateAfterZoom(oldScale, _scaleState.timeScale);
      notifyListeners();
    }
  }

  /// Update horizontal scaling with focal point preservation
  void updateHorizontalScaleWithFocalPoint(double scale, double focalPointX) {
    if (scale == 1.0) return;

    final oldScale = _scaleState.timeScale;
    final newScale = _scaleState.timeScale * scale;
    _scaleState.setTimeScale(newScale);

    if (oldScale != _scaleState.timeScale) {
      // Preserve the focal point during zoom
      _normalizeScrollStateAfterZoomWithFocalPoint(
          oldScale, _scaleState.timeScale, focalPointX);
      notifyListeners();
    }
  }

  /// Update horizontal scaling with focal point preservation and chart context
  void updateHorizontalScaleWithFocalPointAndContext(
      double scale,
      double focalPointX,
      double chartWidth,
      double candleWidth,
      double candleSpacing) {
    if (scale == 1.0) return;

    // Apply controlled zoom sensitivity
    final controlledScale = _calculateControlledZoomScale(scale);
    if (controlledScale == 1.0) return;

    final oldScale = _scaleState.timeScale;
    final newScale = _scaleState.timeScale * controlledScale;

    // Only apply zoom if the change is significant enough
    if (!_shouldApplyZoomChange(newScale, oldScale)) return;

    // Ensure the chart is properly initialized before zooming
    if (!_scrollState.isInitialized) return;

    _scaleState.setTimeScale(newScale);

    if (oldScale != _scaleState.timeScale) {
      // Preserve the focal point during zoom with proper context
      _normalizeScrollStateAfterZoomWithFocalPointAndContext(
          oldScale,
          _scaleState.timeScale,
          focalPointX,
          chartWidth,
          candleWidth,
          candleSpacing);
      notifyListeners();
    }
  }

  /// Calculate controlled zoom scale with sensitivity limits
  double _calculateControlledZoomScale(double rawScale) {
    // Apply zoom sensitivity to reduce the scale change
    final sensitivity = ChartConstants.zoomSensitivity;
    final scaleChange = (rawScale - 1.0) * sensitivity;
    final controlledScale = 1.0 + scaleChange;

    // Clamp the scale change to prevent too aggressive zooming
    return controlledScale.clamp(
        ChartConstants.minZoomScale, ChartConstants.maxZoomScale);
  }

  /// Check if zoom change is significant enough to apply
  bool _shouldApplyZoomChange(double newScale, double currentScale) {
    // Only apply zoom if the change is significant enough
    final scaleDifference = (newScale - currentScale).abs();
    return scaleDifference >= 0.001; // Minimum 0.1% change
  }

  /// Update only vertical scaling (price scale)
  void updateVerticalScale(double scale) {
    if (scale == 1.0) return;

    final oldScale = _scaleState.priceScale;
    _scaleState.setPriceScale(_scaleState.priceScale * scale);

    if (oldScale != _scaleState.priceScale) {
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
    return ChartUtils.getCandleAtPosition(
      allCandles,
      localX,
      actualCandleWidth,
      actualCandleSpacing,
      startIndex,
    );
  }

  /// Apply momentum scrolling for smooth deceleration
  void applyMomentum(
    int totalDataLength,
    double chartWidth,
    double candleWidth,
    double candleSpacing,
  ) {
    ChartUtils.applyMomentum(
      _scrollState,
      totalDataLength,
      chartWidth,
      candleWidth,
      candleSpacing,
      _scaleState.timeScale,
      notifyListeners,
    );
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

  /// Get the currently visible candles for the chart
  List<CandleStick> getVisibleCandles(
    double chartWidth,
    double candleWidth,
    double candleSpacing,
  ) {
    return ChartUtils.getVisibleCandles(
      _allCandles,
      chartWidth,
      candleWidth,
      candleSpacing,
      _scaleState.timeScale,
      _scrollState,
    );
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

    final candleUnitWidth = ChartUtils.calculateCandleUnitWidth(
        candleWidth, candleSpacing, _scaleState.timeScale);
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();

    // Calculate max scroll offset, but ensure it's never negative
    final maxScrollOffset =
        ((totalDataLength - maxVisibleCandles) * candleUnitWidth)
            .clamp(0.0, double.infinity);

    // Apply smooth scrolling with momentum
    final momentumFactor =
        _scrollState.isScrolling ? ChartConstants.momentumFactor : 1.0;

    // Scale the delta based on the current zoom level to prevent jumping
    // When zoomed out (small timeScale), reduce the scroll sensitivity more aggressively
    final timeScale = _scaleState.timeScale.clamp(0.3, 3.0);
    // Use a more aggressive scaling for very small movements at minimum zoom
    final zoomSensitivity = timeScale < 0.5 ? timeScale * timeScale : timeScale;
    final adjustedDeltaX = (deltaX * momentumFactor) / zoomSensitivity;

    // Calculate new scroll offset
    double newScrollOffset = _scrollState.scrollOffset - adjustedDeltaX;

    // If there's no future data (maxScrollOffset is 0), prevent scrolling to future
    if (maxScrollOffset <= 0) {
      // Only allow scrolling to past, not to future
      // If trying to scroll to future (negative delta), maintain current position
      if (adjustedDeltaX > 0) {
        newScrollOffset = _scrollState.scrollOffset; // Keep current position
      } else {
        newScrollOffset = newScrollOffset.clamp(0.0, _scrollState.scrollOffset);
      }
    } else {
      // Normal clamping when there is future data
      newScrollOffset = newScrollOffset.clamp(0.0, maxScrollOffset);
    }

    // Use adaptive threshold based on zoom level to prevent micro-movements from causing updates
    final updateThreshold = timeScale < 0.5 ? 0.01 : 0.1;
    if ((newScrollOffset - _scrollState.scrollOffset).abs() > updateThreshold) {
      _scrollState.scrollOffset = newScrollOffset;
      ChartUtils.updateVisibleIndices(
          _scrollState, totalDataLength, candleUnitWidth, maxVisibleCandles);
      notifyListeners();
    }
  }

  /// Center the scroll to show the middle of the data
  void resetScroll(
    int totalDataLength,
    double chartWidth,
    double candleWidth,
    double candleSpacing,
  ) {
    final candleUnitWidth = ChartUtils.calculateCandleUnitWidth(
        candleWidth, candleSpacing, _scaleState.timeScale);
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final maxStartIndex = totalDataLength - maxVisibleCandles;
    final safeMaxStartIndex = maxStartIndex < 0 ? 0 : maxStartIndex;
    final centerStartIndex = ((totalDataLength - maxVisibleCandles) / 2)
        .floor()
        .clamp(0, safeMaxStartIndex);

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
    final candleUnitWidth = ChartUtils.calculateCandleUnitWidth(
        candleWidth, candleSpacing, _scaleState.timeScale);
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    // Prevent negative upper bound for clamp when the view can show more candles than data
    final maxStartIndex = totalDataLength - maxVisibleCandles;
    final safeMaxStartIndex = maxStartIndex < 0 ? 0 : maxStartIndex;
    final centerIndex = (targetIndex - maxVisibleCandles / 2)
        .floor()
        .clamp(0, safeMaxStartIndex);

    _scrollState.scrollOffset = centerIndex * candleUnitWidth;
    _scrollState.visibleStartIndex = centerIndex;
    _scrollState.visibleEndIndex =
        (centerIndex + maxVisibleCandles).clamp(0, totalDataLength);
    notifyListeners();
  }

  /// Normalize scroll state after zoom level changes to maintain current view position
  void _normalizeScrollStateAfterZoom(double oldScale, double newScale) {
    if (_allCandles.isEmpty) return;

    // Calculate the scale ratio
    final scaleRatio = newScale / oldScale;

    // Adjust scroll offset to maintain the same relative position
    // Use a more conservative approach to prevent jumping
    final adjustedOffset = _scrollState.scrollOffset * scaleRatio;
    _scrollState.scrollOffset = adjustedOffset.clamp(0.0, double.infinity);

    // Reset visible indices to be recalculated on next update
    _scrollState.visibleStartIndex = 0;
    _scrollState.visibleEndIndex = 0;

    // Stop any momentum scrolling to prevent conflicts
    _scrollState.stopMomentum();
  }

  /// Normalize scroll state after zoom with focal point preservation
  void _normalizeScrollStateAfterZoomWithFocalPoint(
      double oldScale, double newScale, double focalPointX) {
    if (_allCandles.isEmpty) return;

    // Calculate the scale ratio
    final scaleRatio = newScale / oldScale;

    // Calculate the position of the focal point relative to the current view
    // The focalPointX is already in the effective chart coordinates
    final currentScrollOffset = _scrollState.scrollOffset;
    final focalPointInData = currentScrollOffset + focalPointX;

    // Adjust the scroll offset to keep the focal point in the same screen position
    // This ensures the focal point stays at the same screen location after zoom
    final newScrollOffset = (focalPointInData * scaleRatio) - focalPointX;

    // Clamp the scroll offset to valid range
    _scrollState.scrollOffset = newScrollOffset.clamp(0.0, double.infinity);

    // Reset visible indices to be recalculated on next update
    _scrollState.visibleStartIndex = 0;
    _scrollState.visibleEndIndex = 0;

    // Stop any momentum scrolling to prevent conflicts
    _scrollState.stopMomentum();
  }

  /// Normalize scroll state after zoom with focal point preservation and chart context
  void _normalizeScrollStateAfterZoomWithFocalPointAndContext(
      double oldScale,
      double newScale,
      double focalPointX,
      double chartWidth,
      double candleWidth,
      double candleSpacing) {
    if (_allCandles.isEmpty) return;

    // Calculate candle unit widths for both old and new scales
    final oldCandleUnitWidth = ChartUtils.calculateCandleUnitWidth(
        candleWidth, candleSpacing, oldScale);
    final newCandleUnitWidth = ChartUtils.calculateCandleUnitWidth(
        candleWidth, candleSpacing, newScale);

    // Calculate the current continuous data position of the focal point (in pixels)
    final currentScrollOffset = _scrollState.scrollOffset;
    final focalPointInData = currentScrollOffset + focalPointX;

    // Convert continuous data position proportionally between scales
    final scaledFocalPointInData =
        (focalPointInData / oldCandleUnitWidth) * newCandleUnitWidth;

    // Compute new scroll offset so the focal point remains at the same screen x
    final newScrollOffset = scaledFocalPointInData - focalPointX;

    // Calculate the maximum possible scroll offset based on data length
    final maxScrollOffset =
        ((_allCandles.length * newCandleUnitWidth) - chartWidth)
            .clamp(0.0, double.infinity);

    // Clamp the scroll offset to valid range
    _scrollState.scrollOffset = newScrollOffset.clamp(0.0, maxScrollOffset);

    // Immediately update visible indices to prevent flicker/empty ranges
    final maxVisibleCandles = (chartWidth / newCandleUnitWidth).floor();
    final startIndex = (_scrollState.scrollOffset / newCandleUnitWidth)
        .floor()
        .clamp(0, _allCandles.length);
    final endIndex =
        (startIndex + maxVisibleCandles).clamp(0, _allCandles.length);
    _scrollState.visibleStartIndex = startIndex;
    _scrollState.visibleEndIndex = endIndex;

    // Stop any momentum scrolling to prevent conflicts
    _scrollState.stopMomentum();
  }
}
