import 'package:flutter/material.dart';
import '../../model/candle_model.dart';

/// Provider class to manage chart state and interactions
class ChartProvider extends ChangeNotifier {
  // Hover state
  CandleStick? _hoveredCandle;
  Offset? _hoverPosition;

  // Scaling factors for candles
  double _timeScale = 1.0; // X-axis scaling (candle width and spacing)
  double _priceScale =
      1.0; // Y-axis scaling (price range compression/expansion)

  // Scale constraints
  static const double _minTimeScale = 0.3;
  static const double _maxTimeScale = 3.0;
  static const double _minPriceScale = 0.5;
  static const double _maxPriceScale = 2.0;

  // Gesture state
  double _baseFocalPointX = 0.0;
  double _baseFocalPointY = 0.0;

  // Getters
  CandleStick? get hoveredCandle => _hoveredCandle;
  Offset? get hoverPosition => _hoverPosition;
  double get timeScale => _timeScale;
  double get priceScale => _priceScale;
  double get minTimeScale => _minTimeScale;
  double get maxTimeScale => _maxTimeScale;
  double get minPriceScale => _minPriceScale;
  double get maxPriceScale => _maxPriceScale;

  /// Set hover state for candle
  void setHover(CandleStick? candle, Offset? position) {
    if (_hoveredCandle != candle || _hoverPosition != position) {
      _hoveredCandle = candle;
      _hoverPosition = position;
      notifyListeners();
    }
  }

  /// Clear hover state
  void clearHover() {
    if (_hoveredCandle != null || _hoverPosition != null) {
      _hoveredCandle = null;
      _hoverPosition = null;
      notifyListeners();
    }
  }

  /// Start scale gesture
  void startScale(double focalPointX, double focalPointY) {
    _baseFocalPointX = focalPointX;
    _baseFocalPointY = focalPointY;
  }

  /// Update scale based on gesture
  void updateScale(double scale, double focalPointX, double focalPointY) {
    if (scale == 1.0) return;

    bool shouldNotify = false;
    final deltaX = (focalPointX - _baseFocalPointX).abs();
    final deltaY = (focalPointY - _baseFocalPointY).abs();

    if (deltaX > deltaY) {
      // Primarily horizontal gesture - adjust time scale
      final newTimeScale =
          (_timeScale * scale).clamp(_minTimeScale, _maxTimeScale);
      if (newTimeScale != _timeScale) {
        _timeScale = newTimeScale;
        shouldNotify = true;
      }
    } else {
      // Primarily vertical gesture - adjust price scale
      final newPriceScale =
          (_priceScale * scale).clamp(_minPriceScale, _maxPriceScale);
      if (newPriceScale != _priceScale) {
        _priceScale = newPriceScale;
        shouldNotify = true;
      }
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// Update price scale based on vertical pan
  void updatePriceScaleFromPan(double deltaY) {
    final scaleFactor = 1.0 - (deltaY * 0.01); // Adjust sensitivity
    final newPriceScale =
        (_priceScale * scaleFactor).clamp(_minPriceScale, _maxPriceScale);

    if (newPriceScale != _priceScale) {
      _priceScale = newPriceScale;
      notifyListeners();
    }
  }

  /// Update time scale based on horizontal pan
  void updateTimeScaleFromPan(double deltaX) {
    final scaleFactor = 1.0 + (deltaX * 0.01); // Adjust sensitivity
    final newTimeScale =
        (_timeScale * scaleFactor).clamp(_minTimeScale, _maxTimeScale);

    if (newTimeScale != _timeScale) {
      _timeScale = newTimeScale;
      notifyListeners();
    }
  }

  /// Reset all scaling to default values
  void resetScaling() {
    if (_timeScale != 1.0 || _priceScale != 1.0) {
      _timeScale = 1.0;
      _priceScale = 1.0;
      notifyListeners();
    }
  }

  /// Get visible candles based on current scaling and chart width
  List<CandleStick> getVisibleCandles(
    List<CandleStick> allCandles,
    double chartWidth,
    double candleWidth,
    double candleSpacing,
  ) {
    if (allCandles.isEmpty) return [];

    final baseCandleWidth = candleWidth * _timeScale;
    final baseCandleSpacing = candleSpacing * _timeScale;
    final candleUnitWidth = baseCandleWidth + baseCandleSpacing;

    // Calculate how many candles can fit in the chart width
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final totalCandles = allCandles.length;
    final visibleCandleCount = maxVisibleCandles.clamp(1, totalCandles);

    // Calculate start index to center the visible candles
    final startIndex = ((totalCandles - visibleCandleCount) / 2)
        .floor()
        .clamp(0, totalCandles - visibleCandleCount);
    final endIndex = (startIndex + visibleCandleCount).clamp(0, totalCandles);

    return allCandles.sublist(startIndex, endIndex);
  }

  /// Get scaled candle dimensions
  Map<String, double> getScaledDimensions(
      double candleWidth, double candleSpacing) {
    return {
      'candleWidth': candleWidth * _timeScale,
      'candleSpacing': candleSpacing * _timeScale,
    };
  }

  /// Calculate which candle is being hovered/tapped
  CandleStick? getCandleAtPosition(
    List<CandleStick> allCandles,
    double localX,
    double actualCandleWidth,
    double actualCandleSpacing,
    int startIndex,
  ) {
    final candleUnitWidth = actualCandleWidth + actualCandleSpacing;
    final visibleCandleIndex = (localX / candleUnitWidth).floor();
    final actualCandleIndex = startIndex + visibleCandleIndex;

    if (actualCandleIndex >= 0 && actualCandleIndex < allCandles.length) {
      return allCandles[actualCandleIndex];
    }
    return null;
  }
}
