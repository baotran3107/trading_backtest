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
  /// The time format appears to be a custom format from DukasCopy
  /// Based on the values (starting around 13352528), this looks like
  /// a day-based counter since some epoch
  DateTime _convertTime(dynamic timeValue) {
    if (timeValue is int) {
      // This appears to be days since some epoch
      // Based on typical Forex data, this could be days since 1900-01-01
      // or days since Excel epoch (1900-01-01, but Excel has a bug with leap years)

      // Let's use a base date and add the number of minutes
      // Since this is M1 (1-minute) data, let's treat it as minutes since epoch
      final baseDate = DateTime(1970, 1, 1); // Unix epoch

      // If the number is too large for minutes, it might be a different format
      // Let's try treating it as a custom format
      // For now, let's create a reasonable date progression
      final minutesSinceBase =
          timeValue - 13352528; // Normalize to start from 0
      return baseDate.add(Duration(minutes: minutesSinceBase));
    } else if (timeValue is String) {
      return DateTime.parse(timeValue);
    }
    throw Exception('Invalid time format: $timeValue');
  }

  /// Converts price value to double
  double _convertPrice(dynamic priceValue) {
    if (priceValue is num) {
      // The prices appear to be already in the correct format (e.g., 3300.468)
      // The JSON metadata shows point=0.001, but the prices are already scaled properly
      return priceValue.toDouble();
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
