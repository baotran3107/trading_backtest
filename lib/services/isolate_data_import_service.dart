import '../model/candle_model.dart';
import 'isolate_data_loader.dart';

/// Service for importing trading data using isolates to prevent UI blocking
class IsolateDataImportService {
  /// Imports XAUUSD candlestick data using isolate
  Future<List<CandleStick>> importXAUUSDData() async {
    try {
      return await IsolateDataLoader.loadAllXAUUSDData();
    } catch (e) {
      throw Exception('Failed to import XAUUSD data: $e');
    }
  }

  /// Imports a subset of data for testing or pagination using isolate
  Future<List<CandleStick>> importXAUUSDDataRange({
    required int startIndex,
    required int count,
  }) async {
    try {
      return await IsolateDataLoader.loadDataRange(
        startIndex: startIndex,
        count: count,
      );
    } catch (e) {
      throw Exception('Failed to import XAUUSD data range: $e');
    }
  }

  /// Gets metadata information using isolate
  Future<Map<String, dynamic>> getDataMetadata() async {
    try {
      return await IsolateDataLoader.loadMetadata();
    } catch (e) {
      throw Exception('Failed to get metadata: $e');
    }
  }

  /// Gets data count without loading all data using isolate
  Future<int> getDataCount() async {
    try {
      return await IsolateDataLoader.getDataCount();
    } catch (e) {
      throw Exception('Failed to get data count: $e');
    }
  }

  /// Dispose the isolate when done
  void dispose() {
    IsolateDataLoader.dispose();
  }
}
