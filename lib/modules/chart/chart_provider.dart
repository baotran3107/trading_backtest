import 'package:flutter/material.dart';
import '../../model/candle_model.dart';

class ChartProvider extends ChangeNotifier {
  CandleStick? _hoveredCandle;
  Offset? _hoverPosition;

  double _timeScale = 1.0;
  double _priceScale = 1.0;

  static const double _minTimeScale = 0.3;
  static const double _maxTimeScale = 3.0;
  static const double _minPriceScale = 0.1;
  static const double _maxPriceScale = 2.0;

  double _baseFocalPointX = 0.0;
  double _baseFocalPointY = 0.0;

  double _scrollOffset = 0.0;
  int _visibleStartIndex = 0;
  int _visibleEndIndex = 0;
  bool _isScrollingToPast = false;
  bool _isScrollingToFuture = false;

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

  void setHover(CandleStick? candle, Offset? position) {
    if (_hoveredCandle != candle || _hoverPosition != position) {
      _hoveredCandle = candle;
      _hoverPosition = position;
      notifyListeners();
    }
  }

  void clearHover() {
    if (_hoveredCandle != null || _hoverPosition != null) {
      _hoveredCandle = null;
      _hoverPosition = null;
      notifyListeners();
    }
  }

  void startScale(double focalPointX, double focalPointY) {
    _baseFocalPointX = focalPointX;
    _baseFocalPointY = focalPointY;
  }

  void updateScale(double scale, double focalPointX, double focalPointY) {
    if (scale == 1.0) return;

    bool shouldNotify = false;
    final deltaX = (focalPointX - _baseFocalPointX).abs();
    final deltaY = (focalPointY - _baseFocalPointY).abs();

    if (deltaX > deltaY) {
      final newTimeScale =
          (_timeScale * scale).clamp(_minTimeScale, _maxTimeScale);
      if (newTimeScale != _timeScale) {
        _timeScale = newTimeScale;
        shouldNotify = true;
      }
    } else {
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

  void updatePriceScaleFromPan(double deltaY) {
    final scaleFactor = 1.0 - (deltaY * 0.01);
    final newPriceScale =
        (_priceScale * scaleFactor).clamp(_minPriceScale, _maxPriceScale);

    if (newPriceScale != _priceScale) {
      _priceScale = newPriceScale;
      notifyListeners();
    }
  }

  void updateTimeScaleFromPan(double deltaX) {
    final scaleFactor = 1.0 + (deltaX * 0.01);
    final newTimeScale =
        (_timeScale * scaleFactor).clamp(_minTimeScale, _maxTimeScale);

    if (newTimeScale != _timeScale) {
      _timeScale = newTimeScale;
      notifyListeners();
    }
  }

  void resetScaling() {
    if (_timeScale != 1.0 || _priceScale != 1.0) {
      _timeScale = 1.0;
      _priceScale = 1.0;
      notifyListeners();
    }
  }

  void updateScrollOffset(double deltaX, int totalDataLength, double chartWidth, double candleWidth, double candleSpacing) {
    final baseCandleWidth = candleWidth * _timeScale;
    final baseCandleSpacing = candleSpacing * _timeScale;
    final candleUnitWidth = baseCandleWidth + baseCandleSpacing;
    
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final maxScrollOffset = (totalDataLength - maxVisibleCandles) * candleUnitWidth;
    
    final newScrollOffset = (_scrollOffset - deltaX).clamp(0.0, maxScrollOffset.toDouble());
    
    if (newScrollOffset != _scrollOffset) {
      _scrollOffset = newScrollOffset;
      
      final startIndex = (_scrollOffset / candleUnitWidth).floor();
      final endIndex = (startIndex + maxVisibleCandles).clamp(0, totalDataLength);
      
      _visibleStartIndex = startIndex;
      _visibleEndIndex = endIndex;
      
      _isScrollingToPast = startIndex <= 5;
      _isScrollingToFuture = endIndex >= totalDataLength - 5;
      
      notifyListeners();
    }
  }

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

    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final totalCandles = allCandles.length;
    
    int startIndex;
    int endIndex;
    
    if (_scrollOffset == 0.0 && _visibleStartIndex == 0 && _visibleEndIndex == 0) {
      final visibleCandleCount = maxVisibleCandles.clamp(1, totalCandles);
      startIndex = ((totalCandles - visibleCandleCount) / 2)
          .floor()
          .clamp(0, totalCandles - visibleCandleCount);
      endIndex = (startIndex + visibleCandleCount).clamp(0, totalCandles);
      
      _visibleStartIndex = startIndex;
      _visibleEndIndex = endIndex;
    } else {
      startIndex = _visibleStartIndex;
      endIndex = _visibleEndIndex;
    }

    return allCandles.sublist(startIndex, endIndex);
  }

  Map<String, double> getScaledDimensions(
      double candleWidth, double candleSpacing) {
    return {
      'candleWidth': candleWidth * _timeScale,
      'candleSpacing': candleSpacing * _timeScale,
    };
  }

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
