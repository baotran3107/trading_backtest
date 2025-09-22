import 'dart:async';
import 'package:flutter/material.dart';
import '../../model/candle_model.dart';
import '../../services/chart_data_loader.dart';
import 'chart_state.dart';
import 'chart_constants.dart';
import 'chart_utils.dart';

enum DataLoadingState { idle, loading, loaded, error }

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

    // Calculate max scroll offset, but ensure it's never negative
    final maxScrollOffset =
        ((_candles.length - maxVisibleCandles) * candleUnitWidth)
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

    // Be more conservative with data loading when zoomed out to prevent jumping
    final isZoomedOut = _scaleState.timeScale < 0.5;
    final loadingDelay = isZoomedOut
        ? ChartConstants.preloadDelayMs * 3
        : ChartConstants.preloadDelayMs;

    // Determine if we should use fast loading based on velocity
    final shouldUseFastLoading =
        _lastScrollVelocity > ChartConstants.scrollVelocityThreshold ||
            _consecutiveScrollCount > 3;

    if (shouldUseFastLoading && !isZoomedOut) {
      // Use fast loading for high velocity scrolling, but not when zoomed out
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
      _preloadTimer = Timer(Duration(milliseconds: loadingDelay), () {
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

    // If not initialized, start from the end (most recent data) instead of centering
    if (!_scrollState.isInitialized) {
      final visibleCandleCount = maxVisibleCandles.clamp(1, totalCandles);
      // Start from the end (most recent data) instead of centering
      startIndex = (totalCandles - visibleCandleCount)
          .clamp(0, totalCandles - visibleCandleCount);
      endIndex = (startIndex + visibleCandleCount).clamp(0, totalCandles);
      _scrollState.visibleStartIndex = startIndex;
      _scrollState.visibleEndIndex = endIndex;
      // Set the scroll offset to match the position at the end
      _scrollState.scrollOffset = startIndex * candleUnitWidth;
      // Mark as initialized to prevent re-initialization
      _scrollState.markAsInitialized();
    }

    // Ensure indices are within valid bounds
    startIndex = startIndex.clamp(0, totalCandles);
    endIndex = endIndex.clamp(startIndex, totalCandles);

    // Add buffer for smoother scrolling
    final bufferSize = (maxVisibleCandles * ChartConstants.scrollBufferRatio)
        .ceil()
        .clamp(ChartConstants.minScrollBuffer, ChartConstants.maxScrollBuffer);
    final bufferedStartIndex = (startIndex - bufferSize).clamp(0, totalCandles);
    final bufferedEndIndex = (endIndex + bufferSize).clamp(0, totalCandles);

    // Ensure we have a valid range for sublist
    if (bufferedStartIndex >= bufferedEndIndex ||
        bufferedStartIndex >= totalCandles) {
      // Return empty list if no valid range
      return [];
    }

    return _candles.sublist(bufferedStartIndex, bufferedEndIndex);
  }

  // Delegate methods to internal states
  void setHover(CandleStick? candle, Offset? position) {
    final hasChanged = _hoverState.hoveredCandle != candle ||
        _hoverState.hoverPosition != position;

    _hoverState.setHover(candle, position);

    if (hasChanged) {
      notifyListeners();
    }
  }

  void clearHover() {
    final hadHover = _hoverState.hasHover;
    _hoverState.clear();
    if (hadHover) {
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
    final startIndex = (_scrollState.scrollOffset / candleUnitWidth)
        .floor()
        .clamp(0, totalDataLength);
    final endIndex = (startIndex + maxVisibleCandles).clamp(0, totalDataLength);
    _scrollState.visibleStartIndex = startIndex;
    _scrollState.visibleEndIndex = endIndex;

    // Use zoom-aware buffer size to prevent premature data loading when zoomed out
    // When zoomed out (small candleUnitWidth), use a smaller buffer to prevent jumping
    final baseBufferSize = (maxVisibleCandles * 0.1).ceil().clamp(5, 20);
    final zoomFactor = (candleUnitWidth / 10.0)
        .clamp(0.3, 3.0); // Normalize around default candleUnitWidth of 10
    final bufferSize = (baseBufferSize * zoomFactor).ceil().clamp(2, 50);

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

  /// Normalize scroll state after zoom level changes to maintain current view position
  void _normalizeScrollStateAfterZoom(double oldScale, double newScale) {
    if (_candles.isEmpty) return;

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

    // Cancel any pending data loading operations to prevent conflicts
    _preloadTimer?.cancel();
    _fastLoadTimer?.cancel();
  }

  /// Normalize scroll state after zoom with focal point preservation
  void _normalizeScrollStateAfterZoomWithFocalPoint(
      double oldScale, double newScale, double focalPointX) {
    if (_candles.isEmpty) return;

    // Calculate the scale ratio
    final scaleRatio = newScale / oldScale;

    // Calculate the position of the focal point relative to the current view
    final currentScrollOffset = _scrollState.scrollOffset;
    final focalPointInData = currentScrollOffset + focalPointX;

    // Adjust the scroll offset to keep the focal point in the same screen position
    final newScrollOffset = (focalPointInData * scaleRatio) - focalPointX;

    _scrollState.scrollOffset = newScrollOffset.clamp(0.0, double.infinity);

    // Reset visible indices to be recalculated on next update
    _scrollState.visibleStartIndex = 0;
    _scrollState.visibleEndIndex = 0;

    // Stop any momentum scrolling to prevent conflicts
    _scrollState.stopMomentum();

    // Cancel any pending data loading operations to prevent conflicts
    _preloadTimer?.cancel();
    _fastLoadTimer?.cancel();
  }

  /// Normalize scroll state after zoom with focal point preservation and chart context
  void _normalizeScrollStateAfterZoomWithFocalPointAndContext(
      double oldScale,
      double newScale,
      double focalPointX,
      double chartWidth,
      double candleWidth,
      double candleSpacing) {
    if (_candles.isEmpty) return;

    // Calculate candle unit widths for both old and new scales
    final oldCandleUnitWidth = ChartUtils.calculateCandleUnitWidth(
        candleWidth, candleSpacing, oldScale);
    final newCandleUnitWidth = ChartUtils.calculateCandleUnitWidth(
        candleWidth, candleSpacing, newScale);

    // Calculate the current continuous data position of the focal point (in pixels)
    // Use continuous position instead of flooring to a candle index to avoid jumps/snaps
    final currentScrollOffset = _scrollState.scrollOffset;
    final focalPointInData = currentScrollOffset + focalPointX;

    // Convert continuous data position from old scale to new scale proportionally
    final scaledFocalPointInData =
        (focalPointInData / oldCandleUnitWidth) * newCandleUnitWidth;

    // Compute new scroll offset so the focal point remains under the same screen x
    final newScrollOffset = scaledFocalPointInData - focalPointX;

    // Calculate the maximum possible scroll offset based on data length
    final maxScrollOffset =
        ((_candles.length * newCandleUnitWidth) - chartWidth)
            .clamp(0.0, double.infinity);

    // Clamp the scroll offset to valid range
    _scrollState.scrollOffset = newScrollOffset.clamp(0.0, maxScrollOffset);

    // Immediately update visible indices to avoid empty renders during zoom
    final maxVisibleCandles = (chartWidth / newCandleUnitWidth).floor();
    final startIndex = (_scrollState.scrollOffset / newCandleUnitWidth)
        .floor()
        .clamp(0, _candles.length);
    final endIndex = (startIndex + maxVisibleCandles).clamp(0, _candles.length);
    _scrollState.visibleStartIndex = startIndex;
    _scrollState.visibleEndIndex = endIndex;

    // Update boundary flags with a zoom-aware buffer
    final baseBufferSize = (maxVisibleCandles * 0.1).ceil().clamp(5, 20);
    final zoomFactor = (newCandleUnitWidth / 10.0).clamp(0.3, 3.0);
    final bufferSize = (baseBufferSize * zoomFactor).ceil().clamp(2, 50);
    _scrollState.isScrollingToPast = startIndex <= bufferSize;
    _scrollState.isScrollingToFuture = endIndex >= _candles.length - bufferSize;

    // Stop any momentum scrolling to prevent conflicts
    _scrollState.stopMomentum();

    // Cancel any pending data loading operations to prevent conflicts
    _preloadTimer?.cancel();
    _fastLoadTimer?.cancel();
  }

  @override
  void dispose() {
    _preloadTimer?.cancel();
    _fastLoadTimer?.cancel();
    super.dispose();
  }
}
