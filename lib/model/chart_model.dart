import 'package:trading_game/model/candle_model.dart';

class ChartModel {
  final String symbol;
  final List<CandleStick> candlesticks;

  ChartModel({
    required this.symbol,
    required this.candlesticks,
  });

  ChartModel copyWith({
    String? symbol,
    List<CandleStick>? candlesticks,
  }) {
    return ChartModel(
      symbol: symbol ?? this.symbol,
      candlesticks: candlesticks ?? this.candlesticks,
    );
  }

  @override
  String toString() =>
      'ChartModel(symbol: $symbol, candlesticks: ${candlesticks.length})';
}
