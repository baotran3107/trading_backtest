import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../model/candle_model.dart';

/// Loading states for data operations
enum DataLoadingState {
  idle,
  loading,
  loaded,
  error,
}

/// Result of a data loading operation
class DataLoadResult {
  final List<CandleStick> data;
  final int startIndex;
  final int endIndex;
  final bool hasMorePast;
  final bool hasMoreFuture;
  final String? error;

  const DataLoadResult({
    required this.data,
    required this.startIndex,
    required this.endIndex,
    required this.hasMorePast,
    required this.hasMoreFuture,
    this.error,
  });

  bool get isSuccess => error == null;
}

/// Optimized data loader for chart with caching and pagination
class ChartDataLoader {
  static const int _defaultChunkSize = 2000; // Increased for better performance
  static const int _maxCacheSize = 20000; // Increased cache size
  static const int _preloadBuffer =
      1000; // Increased preload buffer for smoother scrolling
  static const int _fastLoadThreshold = 100; // Fast load for small chunks

  // Cache management
  final Map<String, List<CandleStick>> _dataCache = {};
  final Map<String, Map<String, dynamic>> _metadataCache = {};
  final Map<String, int> _totalDataCounts = {};

  // Loading states
  final Map<String, DataLoadingState> _loadingStates = {};
  final Map<String, Completer<DataLoadResult>> _loadingCompleters = {};

  // Raw JSON data cache
  Map<String, dynamic>? _rawJsonCache;

  /// Get the current loading state for a symbol
  DataLoadingState getLoadingState(String symbol) {
    return _loadingStates[symbol] ?? DataLoadingState.idle;
  }

  /// Load initial data for the chart
  Future<DataLoadResult> loadInitialData(String symbol) async {
    if (_loadingStates[symbol] == DataLoadingState.loading) {
      return await _loadingCompleters[symbol]!.future;
    }

    _loadingStates[symbol] = DataLoadingState.loading;
    final completer = Completer<DataLoadResult>();
    _loadingCompleters[symbol] = completer;

    try {
      // Load raw JSON data if not cached
      if (_rawJsonCache == null) {
        await _loadRawJsonData();
      }

      // Get total data count
      final totalCount = _getTotalDataCount();
      _totalDataCounts[symbol] = totalCount;

      // Calculate initial chunk (center of data)
      final centerIndex = totalCount ~/ 2;
      final halfChunk = _defaultChunkSize ~/ 2;
      final startIndex = (centerIndex - halfChunk).clamp(0, totalCount);
      final endIndex = (centerIndex + halfChunk).clamp(0, totalCount);

      // Load initial data
      final data = await _loadDataRange(startIndex, endIndex);
      _dataCache[symbol] = data;

      final result = DataLoadResult(
        data: data,
        startIndex: startIndex,
        endIndex: endIndex,
        hasMorePast: startIndex > 0,
        hasMoreFuture: endIndex < totalCount,
      );

      _loadingStates[symbol] = DataLoadingState.loaded;
      completer.complete(result);
      return result;
    } catch (e) {
      final result = DataLoadResult(
        data: [],
        startIndex: 0,
        endIndex: 0,
        hasMorePast: false,
        hasMoreFuture: false,
        error: e.toString(),
      );

      _loadingStates[symbol] = DataLoadingState.error;
      completer.complete(result);
      return result;
    }
  }

  /// Load past data (historical data)
  Future<DataLoadResult> loadPastData(
      String symbol, int currentStartIndex) async {
    if (_loadingStates[symbol] == DataLoadingState.loading) {
      return await _loadingCompleters[symbol]!.future;
    }

    _loadingStates[symbol] = DataLoadingState.loading;
    final completer = Completer<DataLoadResult>();
    _loadingCompleters[symbol] = completer;

    try {
      final totalCount = _totalDataCounts[symbol] ?? 0;
      if (currentStartIndex <= 0) {
        final result = DataLoadResult(
          data: [],
          startIndex: currentStartIndex,
          endIndex: currentStartIndex,
          hasMorePast: false,
          hasMoreFuture: true,
        );
        _loadingStates[symbol] = DataLoadingState.loaded;
        completer.complete(result);
        return result;
      }

      // Calculate new range
      final newStartIndex =
          (currentStartIndex - _defaultChunkSize).clamp(0, totalCount);
      final newEndIndex = currentStartIndex;

      // Load past data
      final pastData = await _loadDataRange(newStartIndex, newEndIndex);

      // Merge with existing data
      final existingData = _dataCache[symbol] ?? [];
      final mergedData = [...pastData, ...existingData];

      // Trim cache if too large
      if (mergedData.length > _maxCacheSize) {
        final trimAmount = mergedData.length - _maxCacheSize;
        _dataCache[symbol] = mergedData.sublist(trimAmount);
      } else {
        _dataCache[symbol] = mergedData;
      }

      final result = DataLoadResult(
        data: _dataCache[symbol]!,
        startIndex: newStartIndex,
        endIndex: newEndIndex + (existingData.length),
        hasMorePast: newStartIndex > 0,
        hasMoreFuture: true,
      );

      _loadingStates[symbol] = DataLoadingState.loaded;
      completer.complete(result);
      return result;
    } catch (e) {
      final result = DataLoadResult(
        data: _dataCache[symbol] ?? [],
        startIndex: currentStartIndex,
        endIndex: currentStartIndex,
        hasMorePast: currentStartIndex > 0,
        hasMoreFuture: true,
        error: e.toString(),
      );

      _loadingStates[symbol] = DataLoadingState.error;
      completer.complete(result);
      return result;
    }
  }

  /// Load future data (more recent data)
  Future<DataLoadResult> loadFutureData(
      String symbol, int currentEndIndex) async {
    if (_loadingStates[symbol] == DataLoadingState.loading) {
      return await _loadingCompleters[symbol]!.future;
    }

    _loadingStates[symbol] = DataLoadingState.loading;
    final completer = Completer<DataLoadResult>();
    _loadingCompleters[symbol] = completer;

    try {
      final totalCount = _totalDataCounts[symbol] ?? 0;
      if (currentEndIndex >= totalCount) {
        final result = DataLoadResult(
          data: _dataCache[symbol] ?? [],
          startIndex: 0,
          endIndex: currentEndIndex,
          hasMorePast: true,
          hasMoreFuture: false,
        );
        _loadingStates[symbol] = DataLoadingState.loaded;
        completer.complete(result);
        return result;
      }

      // Calculate new range
      final newStartIndex = currentEndIndex;
      final newEndIndex =
          (currentEndIndex + _defaultChunkSize).clamp(0, totalCount);

      if (newEndIndex <= newStartIndex) {
        final result = DataLoadResult(
          data: _dataCache[symbol] ?? [],
          startIndex: 0,
          endIndex: currentEndIndex,
          hasMorePast: true,
          hasMoreFuture: false,
        );
        _loadingStates[symbol] = DataLoadingState.loaded;
        completer.complete(result);
        return result;
      }

      // Load future data
      final futureData = await _loadDataRange(newStartIndex, newEndIndex);

      // Merge with existing data
      final existingData = _dataCache[symbol] ?? [];
      final mergedData = [...existingData, ...futureData];

      // Trim cache if too large
      if (mergedData.length > _maxCacheSize) {
        final trimAmount = mergedData.length - _maxCacheSize;
        _dataCache[symbol] = mergedData.sublist(trimAmount);
      } else {
        _dataCache[symbol] = mergedData;
      }

      final result = DataLoadResult(
        data: _dataCache[symbol]!,
        startIndex: 0,
        endIndex: newEndIndex,
        hasMorePast: true,
        hasMoreFuture: newEndIndex < totalCount,
      );

      _loadingStates[symbol] = DataLoadingState.loaded;
      completer.complete(result);
      return result;
    } catch (e) {
      final result = DataLoadResult(
        data: _dataCache[symbol] ?? [],
        startIndex: 0,
        endIndex: currentEndIndex,
        hasMorePast: true,
        hasMoreFuture: currentEndIndex < (_totalDataCounts[symbol] ?? 0),
        error: e.toString(),
      );

      _loadingStates[symbol] = DataLoadingState.error;
      completer.complete(result);
      return result;
    }
  }

  /// Preload data around current position for smoother scrolling
  Future<void> preloadData(
      String symbol, int currentStartIndex, int currentEndIndex) async {
    if (_loadingStates[symbol] == DataLoadingState.loading) return;

    final totalCount = _totalDataCounts[symbol] ?? 0;

    // Preload past data if close to beginning
    if (currentStartIndex < _preloadBuffer && currentStartIndex > 0) {
      loadPastData(symbol, currentStartIndex);
    }

    // Preload future data if close to end
    if (currentEndIndex > totalCount - _preloadBuffer &&
        currentEndIndex < totalCount) {
      loadFutureData(symbol, currentEndIndex);
    }
  }

  /// Fast load for small data chunks (optimized for scrolling)
  Future<DataLoadResult> fastLoadPastData(
      String symbol, int currentStartIndex, int loadSize) async {
    if (_loadingStates[symbol] == DataLoadingState.loading) {
      return await _loadingCompleters[symbol]!.future;
    }

    _loadingStates[symbol] = DataLoadingState.loading;
    final completer = Completer<DataLoadResult>();
    _loadingCompleters[symbol] = completer;

    try {
      final totalCount = _totalDataCounts[symbol] ?? 0;
      if (currentStartIndex <= 0) {
        final result = DataLoadResult(
          data: [],
          startIndex: currentStartIndex,
          endIndex: currentStartIndex,
          hasMorePast: false,
          hasMoreFuture: true,
        );
        _loadingStates[symbol] = DataLoadingState.loaded;
        completer.complete(result);
        return result;
      }

      // Use smaller chunk size for faster loading
      final chunkSize = loadSize.clamp(50, _fastLoadThreshold);
      final newStartIndex =
          (currentStartIndex - chunkSize).clamp(0, totalCount);
      final newEndIndex = currentStartIndex;

      // Load past data
      final pastData = await _loadDataRange(newStartIndex, newEndIndex);

      // Merge with existing data
      final existingData = _dataCache[symbol] ?? [];
      final mergedData = [...pastData, ...existingData];

      // Trim cache if too large
      if (mergedData.length > _maxCacheSize) {
        final trimAmount = mergedData.length - _maxCacheSize;
        _dataCache[symbol] = mergedData.sublist(trimAmount);
      } else {
        _dataCache[symbol] = mergedData;
      }

      final result = DataLoadResult(
        data: _dataCache[symbol]!,
        startIndex: newStartIndex,
        endIndex: newEndIndex + (existingData.length),
        hasMorePast: newStartIndex > 0,
        hasMoreFuture: true,
      );

      _loadingStates[symbol] = DataLoadingState.loaded;
      completer.complete(result);
      return result;
    } catch (e) {
      final result = DataLoadResult(
        data: _dataCache[symbol] ?? [],
        startIndex: currentStartIndex,
        endIndex: currentStartIndex,
        hasMorePast: currentStartIndex > 0,
        hasMoreFuture: true,
        error: e.toString(),
      );

      _loadingStates[symbol] = DataLoadingState.error;
      completer.complete(result);
      return result;
    }
  }

  /// Fast load for future data (optimized for scrolling)
  Future<DataLoadResult> fastLoadFutureData(
      String symbol, int currentEndIndex, int loadSize) async {
    if (_loadingStates[symbol] == DataLoadingState.loading) {
      return await _loadingCompleters[symbol]!.future;
    }

    _loadingStates[symbol] = DataLoadingState.loading;
    final completer = Completer<DataLoadResult>();
    _loadingCompleters[symbol] = completer;

    try {
      final totalCount = _totalDataCounts[symbol] ?? 0;
      if (currentEndIndex >= totalCount) {
        final result = DataLoadResult(
          data: _dataCache[symbol] ?? [],
          startIndex: 0,
          endIndex: currentEndIndex,
          hasMorePast: true,
          hasMoreFuture: false,
        );
        _loadingStates[symbol] = DataLoadingState.loaded;
        completer.complete(result);
        return result;
      }

      // Use smaller chunk size for faster loading
      final chunkSize = loadSize.clamp(50, _fastLoadThreshold);
      final newStartIndex = currentEndIndex;
      final newEndIndex = (currentEndIndex + chunkSize).clamp(0, totalCount);

      if (newEndIndex <= newStartIndex) {
        final result = DataLoadResult(
          data: _dataCache[symbol] ?? [],
          startIndex: 0,
          endIndex: currentEndIndex,
          hasMorePast: true,
          hasMoreFuture: false,
        );
        _loadingStates[symbol] = DataLoadingState.loaded;
        completer.complete(result);
        return result;
      }

      // Load future data
      final futureData = await _loadDataRange(newStartIndex, newEndIndex);

      // Merge with existing data
      final existingData = _dataCache[symbol] ?? [];
      final mergedData = [...existingData, ...futureData];

      // Trim cache if too large
      if (mergedData.length > _maxCacheSize) {
        final trimAmount = mergedData.length - _maxCacheSize;
        _dataCache[symbol] = mergedData.sublist(trimAmount);
      } else {
        _dataCache[symbol] = mergedData;
      }

      final result = DataLoadResult(
        data: _dataCache[symbol]!,
        startIndex: 0,
        endIndex: newEndIndex,
        hasMorePast: true,
        hasMoreFuture: newEndIndex < totalCount,
      );

      _loadingStates[symbol] = DataLoadingState.loaded;
      completer.complete(result);
      return result;
    } catch (e) {
      final result = DataLoadResult(
        data: _dataCache[symbol] ?? [],
        startIndex: 0,
        endIndex: currentEndIndex,
        hasMorePast: true,
        hasMoreFuture: currentEndIndex < (_totalDataCounts[symbol] ?? 0),
        error: e.toString(),
      );

      _loadingStates[symbol] = DataLoadingState.error;
      completer.complete(result);
      return result;
    }
  }

  /// Get cached data for a symbol
  List<CandleStick>? getCachedData(String symbol) {
    return _dataCache[symbol];
  }

  /// Clear cache for a symbol
  void clearCache(String symbol) {
    _dataCache.remove(symbol);
    _metadataCache.remove(symbol);
    _totalDataCounts.remove(symbol);
    _loadingStates.remove(symbol);
    _loadingCompleters.remove(symbol);
  }

  /// Clear all caches
  void clearAllCaches() {
    _dataCache.clear();
    _metadataCache.clear();
    _totalDataCounts.clear();
    _loadingStates.clear();
    _loadingCompleters.clear();
    _rawJsonCache = null;
  }

  /// Load raw JSON data once and cache it
  Future<void> _loadRawJsonData() async {
    if (_rawJsonCache != null) return;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/XAUUSD_M1.json');
      _rawJsonCache = json.decode(jsonString);
    } catch (e) {
      throw Exception('Failed to load raw JSON data: $e');
    }
  }

  /// Get total data count from cached JSON
  int _getTotalDataCount() {
    if (_rawJsonCache == null) return 0;
    final timeArray = _rawJsonCache!['time'] as List<dynamic>? ?? [];
    return timeArray.length;
  }

  /// Load a specific range of data from cached JSON
  Future<List<CandleStick>> _loadDataRange(int startIndex, int endIndex) async {
    if (_rawJsonCache == null) {
      await _loadRawJsonData();
    }

    final timeArray = _rawJsonCache!['time'] as List<dynamic>;
    final openArray = _rawJsonCache!['open'] as List<dynamic>;
    final highArray = _rawJsonCache!['high'] as List<dynamic>;
    final lowArray = _rawJsonCache!['low'] as List<dynamic>;
    final closeArray = _rawJsonCache!['close'] as List<dynamic>;
    final volumeArray = _rawJsonCache!['volume'] as List<dynamic>;

    final dataLength = timeArray.length;
    final actualStartIndex = startIndex.clamp(0, dataLength);
    final actualEndIndex = endIndex.clamp(0, dataLength);

    final List<CandleStick> candleSticks = [];

    for (int i = actualStartIndex; i < actualEndIndex; i++) {
      final candleStick = CandleStick(
        time: _convertTime(timeArray[i]),
        open: _convertPrice(openArray[i]),
        high: _convertPrice(highArray[i]),
        low: _convertPrice(lowArray[i]),
        close: _convertPrice(closeArray[i]),
        volume: _convertVolume(volumeArray[i]),
      );

      candleSticks.add(candleStick);
    }

    return candleSticks;
  }

  /// Convert time value to DateTime
  DateTime _convertTime(dynamic timeValue) {
    if (timeValue is int) {
      final baseDate = DateTime(1970, 1, 1);
      final minutesSinceBase = timeValue - 13352528;
      return baseDate.add(Duration(minutes: minutesSinceBase));
    } else if (timeValue is String) {
      return DateTime.parse(timeValue);
    }
    throw Exception('Invalid time format: $timeValue');
  }

  /// Convert price value to double
  double _convertPrice(dynamic priceValue) {
    if (priceValue is num) {
      return priceValue.toDouble();
    } else if (priceValue is String) {
      return double.parse(priceValue);
    }
    throw Exception('Invalid price format: $priceValue');
  }

  /// Convert volume value to double
  double _convertVolume(dynamic volumeValue) {
    if (volumeValue is num) {
      return volumeValue.toDouble();
    } else if (volumeValue is String) {
      return double.parse(volumeValue);
    }
    throw Exception('Invalid volume format: $volumeValue');
  }
}
