import 'dart:async';
import 'package:flutter/material.dart';
import '../../model/candle_model.dart';
import '../../services/chart_data_loader.dart';
import 'chart_constants.dart';

/// Enhanced chart provider with optimized data loading
class EnhancedChartProvider extends ChangeNotifier {
  final ChartDataLoader _dataLoader = ChartDataLoader();
  final String _symbol;

  // Data state
  List<CandleStick> _candles = [];
  int _dataStartIndex = 0;
  int _dataEndIndex = 0;
  bool _hasMorePast = false;
  bool _hasMoreFuture = false;

  // Loading states
  DataLoadingState _loadingState = DataLoadingState.idle;
  String? _errorMessage;

  // Chart state (reuse from original ChartProvider)
  final ChartHoverState _hoverState = ChartHoverState();
  final ChartScaleState _scaleState = ChartScaleState();
  final ChartScrollState _scrollState = ChartScrollState();

  // Data loading optimization
  bool _isLoadingPast = false;
  bool _isLoadingFuture = false;
  Timer? _preloadTimer;
  Timer? _fastLoadTimer;
  double _lastScrollVelocity = 0.0;
  int _consecutiveScrollCount = 0;

  EnhancedChartProvider({required String symbol}) : _symbol = symbol {
    _initializeData();
  }

  // Public getters
  List<CandleStick> get candles => _candles;
  DataLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoadingPast => _isLoadingPast;
  bool get isLoadingFuture => _isLoadingFuture;
  bool get hasMorePast => _hasMorePast;
  bool get hasMoreFuture => _hasMoreFuture;

  // Chart state getters (delegate to internal states)
  CandleStick? get hoveredCandle => _hoverState.hoveredCandle;
  Offset? get hoverPosition => _hoverState.hoverPosition;
  double get timeScale => _scaleState.timeScale;
  double get priceScale => _scaleState.priceScale;
  double get scrollOffset => _scrollState.scrollOffset;
  int get visibleStartIndex => _scrollState.visibleStartIndex;
  int get visibleEndIndex => _scrollState.visibleEndIndex;
  bool get isScrollingToPast => _scrollState.isScrollingToPast;
  bool get isScrollingToFuture => _scrollState.isScrollingToFuture;
  double get scrollVelocity => _scrollState.velocity;
  bool get isScrolling => _scrollState.isScrolling;
  double get baseFocalPointX => _scaleState.baseFocalPointX;
  double get baseFocalPointY => _scaleState.baseFocalPointY;

  /// Initialize data loading
  Future<void> _initializeData() async {
    _setLoadingState(DataLoadingState.loading);

    try {
      final result = await _dataLoader.loadInitialData(_symbol);

      if (result.isSuccess) {
        _candles = result.data;
        _dataStartIndex = result.startIndex;
        _dataEndIndex = result.endIndex;
        _hasMorePast = result.hasMorePast;
        _hasMoreFuture = result.hasMoreFuture;
        _setLoadingState(DataLoadingState.loaded);
        _errorMessage = null;
      } else {
        _setLoadingState(DataLoadingState.error);
        _errorMessage = result.error;
      }
    } catch (e) {
      _setLoadingState(DataLoadingState.error);
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Load past data when scrolling to past
  Future<void> loadPastData() async {
    if (_isLoadingPast || !_hasMorePast) return;

    _isLoadingPast = true;
    notifyListeners();

    try {
      final result = await _dataLoader.loadPastData(_symbol, _dataStartIndex);

      if (result.isSuccess) {
        _candles = result.data;
        _dataStartIndex = result.startIndex;
        _hasMorePast = result.hasMorePast;
        _hasMoreFuture = result.hasMoreFuture;
        _errorMessage = null;
      } else {
        _errorMessage = result.error;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoadingPast = false;
    notifyListeners();
  }

  /// Load future data when scrolling to future
  Future<void> loadFutureData() async {
    if (_isLoadingFuture || !_hasMoreFuture) return;

    _isLoadingFuture = true;
    notifyListeners();

    try {
      final result = await _dataLoader.loadFutureData(_symbol, _dataEndIndex);

      if (result.isSuccess) {
        _candles = result.data;
        _dataEndIndex = result.endIndex;
        _hasMorePast = result.hasMorePast;
        _hasMoreFuture = result.hasMoreFuture;
        _errorMessage = null;
      } else {
        _errorMessage = result.error;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoadingFuture = false;
    notifyListeners();
  }

  /// Fast load past data for smooth scrolling
  Future<void> fastLoadPastData() async {
    if (_isLoadingPast || !_hasMorePast) return;

    _isLoadingPast = true;
    notifyListeners();

    try {
      final loadSize = _calculateOptimalLoadSize();
      final result = await _dataLoader.fastLoadPastData(
          _symbol, _dataStartIndex, loadSize);

      if (result.isSuccess) {
        _candles = result.data;
        _dataStartIndex = result.startIndex;
        _hasMorePast = result.hasMorePast;
        _hasMoreFuture = result.hasMoreFuture;
        _errorMessage = null;
      } else {
        _errorMessage = result.error;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoadingPast = false;
    notifyListeners();
  }

  /// Fast load future data for smooth scrolling
  Future<void> fastLoadFutureData() async {
    if (_isLoadingFuture || !_hasMoreFuture) return;

    _isLoadingFuture = true;
    notifyListeners();

    try {
      final loadSize = _calculateOptimalLoadSize();
      final result = await _dataLoader.fastLoadFutureData(
          _symbol, _dataEndIndex, loadSize);

      if (result.isSuccess) {
        _candles = result.data;
        _dataEndIndex = result.endIndex;
        _hasMorePast = result.hasMorePast;
        _hasMoreFuture = result.hasMoreFuture;
        _errorMessage = null;
      } else {
        _errorMessage = result.error;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoadingFuture = false;
    notifyListeners();
  }

  /// Optimized scroll update with smart data loading
  void updateScrollOffset(
    double deltaX,
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
        (_candles.length - maxVisibleCandles) * candleUnitWidth;

    // Apply smooth scrolling with momentum
    final momentumFactor =
        _scrollState.isScrolling ? ChartConstants.momentumFactor : 1.0;
    final adjustedDeltaX = deltaX * momentumFactor;
    final newScrollOffset = (_scrollState.scrollOffset - adjustedDeltaX)
        .clamp(0.0, maxScrollOffset.toDouble());

    if ((newScrollOffset - _scrollState.scrollOffset).abs() > 0.1) {
      _scrollState.scrollOffset = newScrollOffset;
      _updateVisibleIndices(
          _candles.length, candleUnitWidth, maxVisibleCandles);

      // Smart data loading based on scroll position
      _handleSmartDataLoading();

      notifyListeners();
    }
  }

  /// Smart data loading based on scroll position
  void _handleSmartDataLoading() {
    // Cancel previous timers
    _preloadTimer?.cancel();
    _fastLoadTimer?.cancel();

    // Track scroll velocity for optimization
    _lastScrollVelocity = _scrollState.velocity.abs();
    _consecutiveScrollCount++;

    // Determine if we should use fast loading based on velocity
    final shouldUseFastLoading =
        _lastScrollVelocity > ChartConstants.scrollVelocityThreshold ||
            _consecutiveScrollCount > 3;

    if (shouldUseFastLoading) {
      // Use fast loading for high velocity scrolling
      _fastLoadTimer = Timer(const Duration(milliseconds: 20), () {
        if (_scrollState.isScrollingToPast && _hasMorePast && !_isLoadingPast) {
          fastLoadPastData();
        } else if (_scrollState.isScrollingToFuture &&
            _hasMoreFuture &&
            !_isLoadingFuture) {
          fastLoadFutureData();
        }
      });
    } else {
      // Use regular loading for normal scrolling
      _preloadTimer = Timer(
          const Duration(milliseconds: ChartConstants.preloadDelayMs), () {
        if (_scrollState.isScrollingToPast && _hasMorePast && !_isLoadingPast) {
          loadPastData();
        } else if (_scrollState.isScrollingToFuture &&
            _hasMoreFuture &&
            !_isLoadingFuture) {
          loadFutureData();
        }

        // Preload data for smoother scrolling
        _preloadData();
      });
    }

    // Reset consecutive scroll count after a delay
    Timer(const Duration(milliseconds: 500), () {
      _consecutiveScrollCount = 0;
    });
  }

  /// Preload data around current position
  void _preloadData() {
    if (_candles.isEmpty) return;

    final currentStart = _scrollState.visibleStartIndex;
    final currentEnd = _scrollState.visibleEndIndex;

    _dataLoader.preloadData(_symbol, currentStart, currentEnd);
  }

  /// Get visible candles with optimization
  List<CandleStick> getVisibleCandles(
    double chartWidth,
    double candleWidth,
    double candleSpacing,
  ) {
    if (_candles.isEmpty) return [];

    final candleUnitWidth =
        _calculateCandleUnitWidth(candleWidth, candleSpacing);
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final totalCandles = _candles.length;

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

    // Add buffer for smoother scrolling
    final bufferSize = (maxVisibleCandles * ChartConstants.scrollBufferRatio)
        .ceil()
        .clamp(ChartConstants.minScrollBuffer, ChartConstants.maxScrollBuffer);
    final bufferedStartIndex = (startIndex - bufferSize).clamp(0, totalCandles);
    final bufferedEndIndex = (endIndex + bufferSize).clamp(0, totalCandles);

    return _candles.sublist(bufferedStartIndex, bufferedEndIndex);
  }

  // Delegate methods to internal states
  void setHover(CandleStick? candle, Offset? position) {
    final previousState = _hoverState.hoveredCandle != candle ||
        _hoverState.hoverPosition != position;

    _hoverState.setHover(candle, position);

    if (previousState) {
      notifyListeners();
    }
  }

  void clearHover() {
    if (_hoverState.hasHover) {
      _hoverState.clear();
      notifyListeners();
    }
  }

  void startScale(double focalPointX, double focalPointY) {
    _scaleState.baseFocalPointX = focalPointX;
    _scaleState.baseFocalPointY = focalPointY;
  }

  void updateHorizontalScale(double scale) {
    if (scale == 1.0) return;

    final oldScale = _scaleState.timeScale;
    _scaleState.setTimeScale(_scaleState.timeScale * scale);

    if (oldScale != _scaleState.timeScale) {
      notifyListeners();
    }
  }

  void updateVerticalScale(double scale) {
    if (scale == 1.0) return;

    final oldScale = _scaleState.priceScale;
    _scaleState.setPriceScale(_scaleState.priceScale * scale);

    if (oldScale != _scaleState.priceScale) {
      notifyListeners();
    }
  }

  void resetScaling() {
    if (!_scaleState.isAtDefault) {
      _scaleState.reset();
      notifyListeners();
    }
  }

  Map<String, double> getScaledDimensions(
      double candleWidth, double candleSpacing) {
    return {
      'candleWidth': candleWidth * _scaleState.timeScale,
      'candleSpacing': candleSpacing * _scaleState.timeScale,
    };
  }

  CandleStick? getCandleAtPosition(
    double localX,
    double actualCandleWidth,
    double actualCandleSpacing,
  ) {
    final candleUnitWidth = actualCandleWidth + actualCandleSpacing;
    final visibleCandleIndex = (localX / candleUnitWidth).floor();
    final actualCandleIndex =
        _scrollState.visibleStartIndex + visibleCandleIndex;
    if (actualCandleIndex >= 0 && actualCandleIndex < _candles.length) {
      return _candles[actualCandleIndex];
    }
    return null;
  }

  void resetAll() {
    _hoverState.clear();
    _scaleState.reset();
    _scrollState.reset();
    notifyListeners();
  }

  void clearCache() {
    _dataLoader.clearCache(_symbol);
  }

  // Private helper methods
  void _setLoadingState(DataLoadingState state) {
    _loadingState = state;
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

  /// Calculate optimal load size based on scroll velocity and data availability
  int _calculateOptimalLoadSize() {
    if (_lastScrollVelocity > ChartConstants.scrollVelocityThreshold * 2) {
      // Very high velocity - load more data
      return ChartConstants.fastLoadSize * 2;
    } else if (_lastScrollVelocity > ChartConstants.scrollVelocityThreshold) {
      // High velocity - load standard fast size
      return ChartConstants.fastLoadSize;
    } else {
      // Normal velocity - load smaller chunks
      return ChartConstants.fastLoadSize ~/ 2;
    }
  }

  @override
  void dispose() {
    _preloadTimer?.cancel();
    _fastLoadTimer?.cancel();
    super.dispose();
  }
}

// Reuse the state classes from the original ChartProvider
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
      final deltaTime = (currentTime - _lastScrollTime) / 1000.0;
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
