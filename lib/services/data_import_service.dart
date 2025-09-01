import 'dart:convert';
import 'package:flutter/services.dart';
import '../model/candle_model.dart';

/// Service for importing trading data from JSON files
class DataImportService {
  /// Imports XAUUSD candlestick data from the assets JSON file
  Future<List<CandleStick>> importXAUUSDData() async {
    try {
      // Load the JSON file from assets
      final String jsonString =
          await rootBundle.loadString('assets/data/XAUUSD_M1.json');

      // Parse the JSON
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Extract the arrays
      final List<dynamic> timeArray = jsonData['time'] ?? [];
      final List<dynamic> openArray = jsonData['open'] ?? [];
      final List<dynamic> highArray = jsonData['high'] ?? [];
      final List<dynamic> lowArray = jsonData['low'] ?? [];
      final List<dynamic> closeArray = jsonData['close'] ?? [];
      final List<dynamic> volumeArray = jsonData['volume'] ?? [];

      // Validate that all arrays have the same length
      final int dataLength = timeArray.length;
      if (openArray.length != dataLength ||
          highArray.length != dataLength ||
          lowArray.length != dataLength ||
          closeArray.length != dataLength ||
          volumeArray.length != dataLength) {
        throw Exception('Data arrays have inconsistent lengths');
      }

      // Convert to CandleStick objects
      final List<CandleStick> candleSticks = [];

      for (int i = 0; i < dataLength; i++) {
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
    } catch (e) {
      throw Exception('Failed to import XAUUSD data: $e');
    }
  }

  /// Converts time value to DateTime
  /// The time appears to be in a specific format that needs to be converted
  DateTime _convertTime(dynamic timeValue) {
    if (timeValue is int) {
      // Assuming this is a timestamp or special time format
      // You may need to adjust this based on the actual time format
      // For now, treating it as seconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(timeValue * 1000);
    } else if (timeValue is String) {
      return DateTime.parse(timeValue);
    }
    throw Exception('Invalid time format: $timeValue');
  }

  /// Converts price value to double
  double _convertPrice(dynamic priceValue) {
    if (priceValue is num) {
      // The JSON metadata shows point=0.001, so we might need to scale
      return priceValue.toDouble() / 1000.0; // Adjust based on point value
    } else if (priceValue is String) {
      return double.parse(priceValue);
    }
    throw Exception('Invalid price format: $priceValue');
  }

  /// Converts volume value to double
  double _convertVolume(dynamic volumeValue) {
    if (volumeValue is num) {
      return volumeValue.toDouble();
    } else if (volumeValue is String) {
      return double.parse(volumeValue);
    }
    throw Exception('Invalid volume format: $volumeValue');
  }

  /// Gets metadata information from the JSON file
  Future<Map<String, dynamic>> getDataMetadata() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/XAUUSD_M1.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      return {
        'version': jsonData['ver'],
        'symbol': jsonData['symbol'],
        'description': jsonData['description'],
        'period': jsonData['period'],
        'baseCurrency': jsonData['baseCurrency'],
        'priceIn': jsonData['priceIn'],
        'digits': jsonData['digits'],
        'point': jsonData['point'],
        'pip': jsonData['pip'],
        'bars': jsonData['bars'],
        'company': jsonData['company'],
        'server': jsonData['server'],
      };
    } catch (e) {
      throw Exception('Failed to get metadata: $e');
    }
  }

  /// Imports a subset of data for testing or pagination
  Future<List<CandleStick>> importXAUUSDDataRange({
    required int startIndex,
    required int count,
  }) async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/XAUUSD_M1.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      final List<dynamic> timeArray = jsonData['time'] ?? [];
      final List<dynamic> openArray = jsonData['open'] ?? [];
      final List<dynamic> highArray = jsonData['high'] ?? [];
      final List<dynamic> lowArray = jsonData['low'] ?? [];
      final List<dynamic> closeArray = jsonData['close'] ?? [];
      final List<dynamic> volumeArray = jsonData['volume'] ?? [];

      final int dataLength = timeArray.length;
      final int endIndex = (startIndex + count).clamp(0, dataLength);
      final int actualStartIndex = startIndex.clamp(0, dataLength);

      final List<CandleStick> candleSticks = [];

      for (int i = actualStartIndex; i < endIndex; i++) {
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
    } catch (e) {
      throw Exception('Failed to import XAUUSD data range: $e');
    }
  }
}
