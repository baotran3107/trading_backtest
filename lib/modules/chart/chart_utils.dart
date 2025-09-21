import 'package:flutter/material.dart';
import '../../model/candle_model.dart';
import 'chart_state.dart';
import 'chart_constants.dart';

/// Common chart utilities and helper functions
class ChartUtils {
  /// Calculate candle unit width based on scale
  static double calculateCandleUnitWidth(
    double candleWidth,
    double candleSpacing,
    double timeScale,
  ) {
    return (candleWidth * timeScale) + (candleSpacing * timeScale);
  }

  /// Update visible indices for scrolling
  static void updateVisibleIndices(
    ChartScrollState scrollState,
    int totalDataLength,
    double candleUnitWidth,
    int maxVisibleCandles,
  ) {
    final startIndex = (scrollState.scrollOffset / candleUnitWidth)
        .floor()
        .clamp(0, totalDataLength);
    final endIndex = (startIndex + maxVisibleCandles).clamp(0, totalDataLength);
    scrollState.visibleStartIndex = startIndex;
    scrollState.visibleEndIndex = endIndex;

    // Use zoom-aware buffer size to prevent premature data loading when zoomed out
    // When zoomed out (small candleUnitWidth), use a smaller buffer to prevent jumping
    final baseBufferSize = (maxVisibleCandles * 0.1).ceil().clamp(5, 20);
    final zoomFactor = (candleUnitWidth / 10.0)
        .clamp(0.3, 3.0); // Normalize around default candleUnitWidth of 10
    final bufferSize = (baseBufferSize * zoomFactor).ceil().clamp(2, 50);

    scrollState.isScrollingToPast = startIndex <= bufferSize;
    scrollState.isScrollingToFuture = endIndex >= totalDataLength - bufferSize;
  }

  /// Get candle at position for hover/tooltip
  static CandleStick? getCandleAtPosition(
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

  /// Get visible candles with buffer
  static List<CandleStick> getVisibleCandles(
    List<CandleStick> allCandles,
    double chartWidth,
    double candleWidth,
    double candleSpacing,
    double timeScale,
    ChartScrollState scrollState,
  ) {
    if (allCandles.isEmpty) return [];

    final candleUnitWidth =
        calculateCandleUnitWidth(candleWidth, candleSpacing, timeScale);
    final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
    final totalCandles = allCandles.length;

    int startIndex = scrollState.visibleStartIndex;
    int endIndex = scrollState.visibleEndIndex;

    // If not initialized, start from the end (most recent data) instead of centering
    if (!scrollState.isInitialized) {
      final visibleCandleCount = maxVisibleCandles.clamp(1, totalCandles);
      // Start from the end (most recent data) instead of centering
      startIndex = (totalCandles - visibleCandleCount)
          .clamp(0, totalCandles - visibleCandleCount);
      endIndex = (startIndex + visibleCandleCount).clamp(0, totalCandles);
      scrollState.visibleStartIndex = startIndex;
      scrollState.visibleEndIndex = endIndex;
      // Set the scroll offset to match the position at the end
      scrollState.scrollOffset = startIndex * candleUnitWidth;
      // Mark as initialized to prevent re-initialization
      scrollState.markAsInitialized();
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

    return allCandles.sublist(bufferedStartIndex, bufferedEndIndex);
  }

  /// Apply momentum scrolling
  static void applyMomentum(
    ChartScrollState scrollState,
    int totalDataLength,
    double chartWidth,
    double candleWidth,
    double candleSpacing,
    double timeScale,
    VoidCallback notifyListeners,
  ) {
    if (!scrollState.isScrolling) return;

    scrollState.decayVelocity();

    if (scrollState.velocity.abs() > 0.1) {
      final candleUnitWidth =
          calculateCandleUnitWidth(candleWidth, candleSpacing, timeScale);
      final maxVisibleCandles = (chartWidth / candleUnitWidth).floor();
      final maxScrollOffset =
          ((totalDataLength - maxVisibleCandles) * candleUnitWidth)
              .clamp(0.0, double.infinity);

      // Apply zoom sensitivity to momentum scrolling
      final clampedTimeScale = timeScale.clamp(0.3, 3.0);
      // Use a more aggressive scaling for very small movements at minimum zoom
      final zoomSensitivity = clampedTimeScale < 0.5
          ? clampedTimeScale * clampedTimeScale
          : clampedTimeScale;
      final momentumDelta =
          (scrollState.velocity * 0.016) / zoomSensitivity; // ~60fps

      // Calculate new scroll offset
      double newScrollOffset = scrollState.scrollOffset - momentumDelta;

      // If there's no future data (maxScrollOffset is 0), prevent scrolling to future
      if (maxScrollOffset <= 0) {
        // Only allow scrolling to past, not to future
        // If trying to scroll to future (positive momentum), maintain current position
        if (momentumDelta < 0) {
          newScrollOffset = scrollState.scrollOffset; // Keep current position
        } else {
          newScrollOffset =
              newScrollOffset.clamp(0.0, scrollState.scrollOffset);
        }
      } else {
        // Normal clamping when there is future data
        newScrollOffset = newScrollOffset.clamp(0.0, maxScrollOffset);
      }

      if ((newScrollOffset - scrollState.scrollOffset).abs() > 0.1) {
        scrollState.scrollOffset = newScrollOffset;
        updateVisibleIndices(
            scrollState, totalDataLength, candleUnitWidth, maxVisibleCandles);
        notifyListeners();
      }
    }
  }
}
