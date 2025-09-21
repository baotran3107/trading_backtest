import 'package:trading_game/model/candle_model.dart';

/// Represents a complete chart with symbol and candlestick data
class ChartModel {
  final String symbol;
  final List<CandleStick> candlesticks;
  final DateTime? lastUpdated;

  const ChartModel({
    required this.symbol,
    required this.candlesticks,
    this.lastUpdated,
  });

  /// Create an empty chart model
  factory ChartModel.empty(String symbol) {
    return ChartModel(
      symbol: symbol,
      candlesticks: const [],
      lastUpdated: DateTime.now(),
    );
  }

  /// Check if the chart has data
  bool get isEmpty => candlesticks.isEmpty;

  /// Check if the chart has data
  bool get isNotEmpty => candlesticks.isNotEmpty;

  /// Get the number of candlesticks
  int get length => candlesticks.length;

  /// Get the first candlestick
  CandleStick? get first => candlesticks.isNotEmpty ? candlesticks.first : null;

  /// Get the last candlestick
  CandleStick? get last => candlesticks.isNotEmpty ? candlesticks.last : null;

  /// Get price range for the entire chart
  Map<String, double> getPriceRange() {
    if (candlesticks.isEmpty) {
      return {'min': 0.0, 'max': 0.0, 'range': 0.0};
    }

    double minPrice = candlesticks.first.low;
    double maxPrice = candlesticks.first.high;

    for (final candle in candlesticks) {
      if (candle.low < minPrice) minPrice = candle.low;
      if (candle.high > maxPrice) maxPrice = candle.high;
    }

    return {
      'min': minPrice,
      'max': maxPrice,
      'range': maxPrice - minPrice,
    };
  }

  /// Get candlesticks within a specific time range
  List<CandleStick> getCandlesInRange(DateTime start, DateTime end) {
    return candlesticks.where((candle) {
      return candle.time.isAfter(start) && candle.time.isBefore(end);
    }).toList();
  }

  /// Get candlesticks for a specific date
  List<CandleStick> getCandlesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getCandlesInRange(startOfDay, endOfDay);
  }

  /// Add new candlesticks to the chart
  ChartModel addCandles(List<CandleStick> newCandles) {
    final updatedCandles = [...candlesticks, ...newCandles];
    updatedCandles.sort((a, b) => a.time.compareTo(b.time));
    return copyWith(
      candlesticks: updatedCandles,
      lastUpdated: DateTime.now(),
    );
  }

  /// Update existing candlesticks
  ChartModel updateCandles(List<CandleStick> updatedCandles) {
    return copyWith(
      candlesticks: updatedCandles,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get a subset of candlesticks
  ChartModel getSubset(int start, int end) {
    final subset = candlesticks.sublist(
      start.clamp(0, candlesticks.length),
      end.clamp(0, candlesticks.length),
    );
    return copyWith(candlesticks: subset);
  }

  ChartModel copyWith({
    String? symbol,
    List<CandleStick>? candlesticks,
    DateTime? lastUpdated,
  }) {
    return ChartModel(
      symbol: symbol ?? this.symbol,
      candlesticks: candlesticks ?? this.candlesticks,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartModel &&
        other.symbol == symbol &&
        other.candlesticks.length == candlesticks.length &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode => Object.hash(symbol, candlesticks.length, lastUpdated);

  @override
  String toString() =>
      'ChartModel(symbol: $symbol, candlesticks: ${candlesticks.length}, lastUpdated: $lastUpdated)';
}
