import '../model/candle_model.dart';
import '../services/data_import_service.dart';

/// Repository for managing trading data
class TradingDataRepository {
  final DataImportService _dataImportService = DataImportService();

  List<CandleStick>? _cachedData;
  Map<String, dynamic>? _cachedMetadata;

  /// Gets all XAUUSD candlestick data
  /// Caches the data after first load for better performance
  Future<List<CandleStick>> getAllXAUUSDData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    _cachedData = await _dataImportService.importXAUUSDData();
    return _cachedData!;
  }

  /// Gets a range of XAUUSD data for pagination or performance
  Future<List<CandleStick>> getXAUUSDDataRange({
    required int startIndex,
    required int count,
  }) async {
    return await _dataImportService.importXAUUSDDataRange(
      startIndex: startIndex,
      count: count,
    );
  }

  /// Gets the latest N candlesticks
  Future<List<CandleStick>> getLatestXAUUSDData(int count) async {
    final allData = await getAllXAUUSDData();
    if (allData.length <= count) {
      return allData;
    }

    return allData.sublist(allData.length - count);
  }

  /// Gets data for a specific time range
  Future<List<CandleStick>> getXAUUSDDataByTimeRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final allData = await getAllXAUUSDData();

    return allData.where((candle) {
      return candle.time.isAfter(startTime) && candle.time.isBefore(endTime);
    }).toList();
  }

  /// Gets metadata about the dataset
  Future<Map<String, dynamic>> getDataMetadata() async {
    if (_cachedMetadata != null) {
      return _cachedMetadata!;
    }

    _cachedMetadata = await _dataImportService.getDataMetadata();
    return _cachedMetadata!;
  }

  /// Clears the cached data to force reload
  void clearCache() {
    _cachedData = null;
    _cachedMetadata = null;
  }

  /// Gets data count without loading all data
  Future<int> getDataCount() async {
    final metadata = await getDataMetadata();
    return metadata['bars'] ?? 0;
  }

  /// Gets sample data for testing (first 100 records)
  Future<List<CandleStick>> getSampleData() async {
    return await getXAUUSDDataRange(startIndex: 0, count: 100);
  }

  /// Searches for data around a specific time
  Future<List<CandleStick>> getDataAroundTime({
    required DateTime targetTime,
    int radiusMinutes = 60,
  }) async {
    final allData = await getAllXAUUSDData();

    final startTime = targetTime.subtract(Duration(minutes: radiusMinutes));
    final endTime = targetTime.add(Duration(minutes: radiusMinutes));

    return allData.where((candle) {
      return candle.time.isAfter(startTime) && candle.time.isBefore(endTime);
    }).toList();
  }

  /// Gets aggregated statistics about the data
  Future<Map<String, dynamic>> getDataStatistics() async {
    final allData = await getAllXAUUSDData();

    if (allData.isEmpty) {
      return {
        'count': 0,
        'minPrice': 0.0,
        'maxPrice': 0.0,
        'avgPrice': 0.0,
        'totalVolume': 0.0,
        'timeRange': null,
      };
    }

    double minPrice = allData.first.low;
    double maxPrice = allData.first.high;
    double totalPrice = 0.0;
    double totalVolume = 0.0;

    for (final candle in allData) {
      minPrice = minPrice < candle.low ? minPrice : candle.low;
      maxPrice = maxPrice > candle.high ? maxPrice : candle.high;
      totalPrice += candle.close;
      totalVolume += candle.volume;
    }

    return {
      'count': allData.length,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'avgPrice': totalPrice / allData.length,
      'totalVolume': totalVolume,
      'timeRange': {
        'start': allData.first.time.toIso8601String(),
        'end': allData.last.time.toIso8601String(),
      },
    };
  }
}
