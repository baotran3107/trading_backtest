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

  // Scroll state for navigating through time
  double _scrollOffset = 0.0; // Horizontal scroll offset in pixels
  int _visibleStartIndex = 0; // Start index of currently visible data
  int _visibleEndIndex = 0; // End index of currently visible data
  bool _isScrollingToPast = false;
  bool _isScrollingToFuture = false;

  // Getters
  CandleStick? get hoveredCandle => _hoveredCandle;
  Offset? get hoverPosition => _hoverPosition;
  double get timeScale => _timeScale;
  double get priceScale => _priceScale;
  double get minTimeScale => _minTimeScale;
  double get maxTimeScale => _maxTimeScale;
  double get minPriceScale => _minPriceScale;
  double get maxPriceScale => _maxPriceScale;
  double get scrollOffset => _scrollOffset;
  int get visibleStartIndex => _visibleStartIndex;
  int get visibleEndIndex => _visibleEndIndex;
  bool get isScrollingToPast => _isScrollingToPast;
  bool get isScrollingToFuture => _isScrollingToFuture;

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

  /// Handle horizontal scroll for time navigation
  void updateScrollOffset(double deltaX, int totalDataLength, double chartWidth, double candleWidth, double candleSpacing) {
    final baseCandleWidth = candleWidth * _timeScale;
    final baseCandleSpacing = candleSpacing * _timeScale;
    final candleUnitWidth = baseCandleWidth + baseCandleSpacing;
    
    // Calculate maximum scroll offset based on data length
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final maxScrollOffset = (totalDataLength - maxVisibleCandles) * candleUnitWidth;
    
    // Update scroll offset with bounds checking
    final newScrollOffset = (_scrollOffset - deltaX).clamp(0.0, maxScrollOffset.toDouble());
    
    if (newScrollOffset != _scrollOffset) {
      _scrollOffset = newScrollOffset;
      
      // Update visible data indices
      final startIndex = (_scrollOffset / candleUnitWidth).floor();
      final endIndex = (startIndex + maxVisibleCandles).clamp(0, totalDataLength);
      
      _visibleStartIndex = startIndex;
      _visibleEndIndex = endIndex;
      
      // Check if we're scrolling to boundaries for data loading
      _isScrollingToPast = startIndex <= 5; // Near the beginning
      _isScrollingToFuture = endIndex >= totalDataLength - 5; // Near the end
      
      notifyListeners();
    }
  }

  /// Reset scroll position to center
  void resetScroll(int totalDataLength, double chartWidth, double candleWidth, double candleSpacing) {
    final baseCandleWidth = candleWidth * _timeScale;
    final baseCandleSpacing = candleSpacing * _timeScale;
    final candleUnitWidth = baseCandleWidth + baseCandleSpacing;
    
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final centerStartIndex = ((totalDataLength - maxVisibleCandles) / 2).floor().clamp(0, totalDataLength - maxVisibleCandles);
    
    _scrollOffset = centerStartIndex * candleUnitWidth;
    _visibleStartIndex = centerStartIndex;
    _visibleEndIndex = (centerStartIndex + maxVisibleCandles).clamp(0, totalDataLength);
    _isScrollingToPast = false;
    _isScrollingToFuture = false;
    
    notifyListeners();
  }

  /// Set scroll position to a specific time/index
  void scrollToIndex(int targetIndex, int totalDataLength, double chartWidth, double candleWidth, double candleSpacing) {
    final baseCandleWidth = candleWidth * _timeScale;
    final baseCandleSpacing = candleSpacing * _timeScale;
    final candleUnitWidth = baseCandleWidth + baseCandleSpacing;
    
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final centerIndex = (targetIndex - maxVisibleCandles / 2).floor().clamp(0, totalDataLength - maxVisibleCandles);
    
    _scrollOffset = centerIndex * candleUnitWidth;
    _visibleStartIndex = centerIndex;
    _visibleEndIndex = (centerIndex + maxVisibleCandles).clamp(0, totalDataLength);
    
    notifyListeners();
  }

  /// Get visible candles based on current scaling, scroll offset and chart width
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
    
    // Use scroll offset to determine visible range
    int startIndex;
    int endIndex;
    
    if (_scrollOffset == 0.0 && _visibleStartIndex == 0 && _visibleEndIndex == 0) {
      // Initial state - center the view
      final visibleCandleCount = maxVisibleCandles.clamp(1, totalCandles);
      startIndex = ((totalCandles - visibleCandleCount) / 2)
          .floor()
          .clamp(0, totalCandles - visibleCandleCount);
      endIndex = (startIndex + visibleCandleCount).clamp(0, totalCandles);
      
      // Update internal state
      _visibleStartIndex = startIndex;
      _visibleEndIndex = endIndex;
    } else {
      // Use current scroll position
      startIndex = _visibleStartIndex;
      endIndex = _visibleEndIndex;
    }

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
    final actualCandleIndex = _visibleStartIndex + visibleCandleIndex;

    if (actualCandleIndex >= 0 && actualCandleIndex < allCandles.length) {
      return allCandles[actualCandleIndex];
    }
    return null;
  }
}
