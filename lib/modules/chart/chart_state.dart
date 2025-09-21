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
  bool _isInitialized = false;

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
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;

  void markAsInitialized() {
    _isInitialized = true;
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
