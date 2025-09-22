/// Constants for chart configuration and styling
class ChartConstants {
  // Scaling limits
  static const double minTimeScale = 0.1;
  static const double maxTimeScale = 5.0;
  static const double minPriceScale = 0.1;
  static const double maxPriceScale = 3.0;

  // Default dimensions
  static const double defaultCandleWidth = 8.0;
  static const double defaultCandleSpacing = 2.0;
  static const double defaultChartHeight = 400.0;

  // UI dimensions
  static const double priceLabelsWidth = 80.0;
  static const double timeLabelsHeight = 30.0;
  static const double gridLinesCount = 8;

  // Colors
  static const int defaultBackgroundColor = 0xFF1E2328;
  static const int defaultGridColor = 0xFF2B3139;
  static const int defaultTextColor = 0xFFB7BDC6;
  static const int defaultBullishColor = 0xFF26A69A;
  static const int defaultBearishColor = 0xFFEF5350;
  static const int defaultDojiColor = 0xFF78909C;
  static const int defaultWickColor = 0xFF90A4AE;

  // Interaction settings
  static const double panSensitivity = 0.01;
  static const double minVisibleRange = 0.01; // 1% of original range
  static const double maxVisibleRange = 10.0; // 10x original range
  static const double basePadding = 0.05; // 5% padding around price range

  // Zoom sensitivity settings
  static const double zoomSensitivity =
      0.1; // Reduce zoom sensitivity even more (0.1 = very slow, 1.0 = normal)
  static const double mouseWheelZoomSensitivity =
      0.02; // Even slower for mouse wheel
  static const double minZoomScale = 0.99; // Minimum scale change per gesture
  static const double maxZoomScale = 1.01; // Maximum scale change per gesture

  // Zoom animation settings
  static const Duration zoomAnimationDuration = Duration(milliseconds: 150);

  // Scroll optimization settings
  static const double scrollThreshold =
      0.1; // Minimum movement to trigger scroll
  static const double velocityDecay = 0.95; // Velocity decay factor
  static const double maxVelocity = 50.0; // Maximum scroll velocity
  static const double momentumFactor = 1.2; // Momentum multiplier
  static const double scrollBufferRatio =
      0.2; // Buffer ratio for visible candles
  static const int minScrollBuffer = 2; // Minimum buffer size
  static const int maxScrollBuffer = 10; // Maximum buffer size

  // Data loading optimization settings
  static const int defaultChunkSize = 2000; // Default data chunk size
  static const int maxCacheSize = 20000; // Maximum candles to keep in memory
  static const int preloadBuffer =
      1000; // Preload this many candles ahead/behind
  static const int preloadDelayMs = 50; // Reduced delay for faster response
  static const double dataLoadingThreshold =
      0.05; // Reduced threshold for earlier data loading
  static const int fastLoadSize = 100; // Size for fast loading during scroll
  static const int aggressivePreloadBuffer =
      200; // Buffer for aggressive preloading
  static const double scrollVelocityThreshold =
      2.0; // Velocity threshold for fast loading

  // Tooltip settings
  static const double tooltipPadding = 10.0;
  static const double tooltipOffset = 15.0;
  static const double tooltipBorderRadius = 6.0;

  // Grid settings
  static const double gridSpacingMultiplier = 8.0;
  static const double minGridSpacingRatio = 0.1; // 10% of chart width
  static const double maxGridSpacingRatio = 0.25; // 25% of chart width
}
