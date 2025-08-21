import 'package:flutter/material.dart';

class CandleStick {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final DateTime time;

  const CandleStick({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
    required this.time,
  });

  bool get isBullish => close > open;
  bool get isBearish => close < open;
  bool get isDoji => open == close;
  double get range => high - low;
  double get bodySize => (close - open).abs();
  double get upperWickSize => isBullish ? high - close : high - open;
  double get lowerWickSize => isBullish ? open - low : close - low;

  Color getColor(
      {Color bullishColor = Colors.green,
      Color bearishColor = Colors.red,
      Color dojiColor = Colors.grey}) {
    if (isDoji) return dojiColor;
    return isBullish ? bullishColor : bearishColor;
  }

  factory CandleStick.fromJson(Map<String, dynamic> json) {
    return CandleStick(
      open: json['open']?.toDouble() ?? 0,
      high: json['high']?.toDouble() ?? 0,
      low: json['low']?.toDouble() ?? 0,
      close: json['close']?.toDouble() ?? 0,
      volume: json['volume']?.toDouble() ?? 0,
      time: json['time'] is DateTime
          ? json['time']
          : DateTime.parse(json['time'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
      'time': time.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'CandleStick(time: $time, O: $open, H: $high, L: $low, C: $close, V: $volume)';
}
