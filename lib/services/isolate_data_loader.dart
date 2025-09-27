import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart';
import '../model/candle_model.dart';

/// Message types for isolate communication
class IsolateMessage {
  final String type;
  final dynamic data;

  const IsolateMessage(this.type, this.data);
}

/// Response from isolate
class IsolateResponse {
  final String type;
  final dynamic data;
  final String? error;

  const IsolateResponse(this.type, this.data, this.error);
}

/// Isolate-based data loader that processes JSON data in background
class IsolateDataLoader {
  static Isolate? _isolate;
  static final Completer<SendPort> _isolateReady = Completer<SendPort>();
  static String? _cachedJsonString;

  /// Initialize the isolate for data processing
  static Future<void> initialize() async {
    if (_isolate != null) return;

    // Load JSON string in main thread first
    _cachedJsonString ??=
        await rootBundle.loadString('assets/data/XAUUSD_M1.json');

    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntryPoint, receivePort.sendPort);

    receivePort.listen((message) {
      if (message is SendPort) {
        _isolateReady.complete(message);
      }
    });
  }

  /// Load all XAUUSD data using isolate
  static Future<List<CandleStick>> loadAllXAUUSDData() async {
    await initialize();
    final sendPort = await _isolateReady.future;

    final completer = Completer<List<CandleStick>>();
    final receivePort = ReceivePort();

    sendPort.send(IsolateMessage('loadAllData', {
      'jsonString': _cachedJsonString,
      'responsePort': receivePort.sendPort,
    }));

    receivePort.listen((message) {
      if (message is IsolateResponse) {
        if (message.error != null) {
          completer.completeError(Exception(message.error));
        } else {
          completer.complete(List<CandleStick>.from(message.data));
        }
        receivePort.close();
      }
    });

    return completer.future;
  }

  /// Load data range using isolate
  static Future<List<CandleStick>> loadDataRange({
    required int startIndex,
    required int count,
  }) async {
    await initialize();
    final sendPort = await _isolateReady.future;

    final completer = Completer<List<CandleStick>>();
    final receivePort = ReceivePort();

    sendPort.send(IsolateMessage('loadDataRange', {
      'jsonString': _cachedJsonString,
      'startIndex': startIndex,
      'count': count,
      'responsePort': receivePort.sendPort,
    }));

    receivePort.listen((message) {
      if (message is IsolateResponse) {
        if (message.error != null) {
          completer.completeError(Exception(message.error));
        } else {
          completer.complete(List<CandleStick>.from(message.data));
        }
        receivePort.close();
      }
    });

    return completer.future;
  }

  /// Load metadata using isolate
  static Future<Map<String, dynamic>> loadMetadata() async {
    await initialize();
    final sendPort = await _isolateReady.future;

    final completer = Completer<Map<String, dynamic>>();
    final receivePort = ReceivePort();

    sendPort.send(IsolateMessage('loadMetadata', {
      'jsonString': _cachedJsonString,
      'responsePort': receivePort.sendPort,
    }));

    receivePort.listen((message) {
      if (message is IsolateResponse) {
        if (message.error != null) {
          completer.completeError(Exception(message.error));
        } else {
          completer.complete(Map<String, dynamic>.from(message.data));
        }
        receivePort.close();
      }
    });

    return completer.future;
  }

  /// Get data count without loading all data
  static Future<int> getDataCount() async {
    await initialize();
    final sendPort = await _isolateReady.future;

    final completer = Completer<int>();
    final receivePort = ReceivePort();

    sendPort.send(IsolateMessage('getDataCount', {
      'jsonString': _cachedJsonString,
      'responsePort': receivePort.sendPort,
    }));

    receivePort.listen((message) {
      if (message is IsolateResponse) {
        if (message.error != null) {
          completer.completeError(Exception(message.error));
        } else {
          completer.complete(message.data as int);
        }
        receivePort.close();
      }
    });

    return completer.future;
  }

  /// Dispose the isolate
  static void dispose() {
    _isolate?.kill();
    _isolate = null;
    if (!_isolateReady.isCompleted) {
      _isolateReady.completeError(Exception('Isolate disposed'));
    }
  }
}

/// Entry point for the isolate
void _isolateEntryPoint(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is IsolateMessage) {
      _handleMessage(message);
    }
  });
}

/// Handle messages in the isolate
Future<void> _handleMessage(IsolateMessage message) async {
  try {
    switch (message.type) {
      case 'loadAllData':
        final jsonString = message.data['jsonString'] as String;
        final data = await _loadAllData(jsonString);
        final responsePort = message.data['responsePort'] as SendPort;
        responsePort.send(IsolateResponse('loadAllData', data, null));
        break;

      case 'loadDataRange':
        final jsonString = message.data['jsonString'] as String;
        final startIndex = message.data['startIndex'] as int;
        final count = message.data['count'] as int;
        final responsePort = message.data['responsePort'] as SendPort;
        final data = await _loadDataRange(jsonString, startIndex, count);
        responsePort.send(IsolateResponse('loadDataRange', data, null));
        break;

      case 'loadMetadata':
        final jsonString = message.data['jsonString'] as String;
        final responsePort = message.data['responsePort'] as SendPort;
        final metadata = await _loadMetadata(jsonString);
        responsePort.send(IsolateResponse('loadMetadata', metadata, null));
        break;

      case 'getDataCount':
        final jsonString = message.data['jsonString'] as String;
        final responsePort = message.data['responsePort'] as SendPort;
        final count = await _getDataCount(jsonString);
        responsePort.send(IsolateResponse('getDataCount', count, null));
        break;
    }
  } catch (e) {
    final responsePort = message.data['responsePort'] as SendPort;
    responsePort.send(IsolateResponse(message.type, null, e.toString()));
  }
}

/// Load all data in isolate
Future<List<CandleStick>> _loadAllData(String jsonString) async {
  final jsonData = json.decode(jsonString);

  final timeArray = jsonData['time'] as List<dynamic>;
  final openArray = jsonData['open'] as List<dynamic>;
  final highArray = jsonData['high'] as List<dynamic>;
  final lowArray = jsonData['low'] as List<dynamic>;
  final closeArray = jsonData['close'] as List<dynamic>;
  final volumeArray = jsonData['volume'] as List<dynamic>;

  final List<CandleStick> candleSticks = [];

  for (int i = 0; i < timeArray.length; i++) {
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

/// Load data range in isolate
Future<List<CandleStick>> _loadDataRange(
    String jsonString, int startIndex, int count) async {
  final jsonData = json.decode(jsonString);

  final timeArray = jsonData['time'] as List<dynamic>;
  final openArray = jsonData['open'] as List<dynamic>;
  final highArray = jsonData['high'] as List<dynamic>;
  final lowArray = jsonData['low'] as List<dynamic>;
  final closeArray = jsonData['close'] as List<dynamic>;
  final volumeArray = jsonData['volume'] as List<dynamic>;

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
}

/// Load metadata in isolate
Future<Map<String, dynamic>> _loadMetadata(String jsonString) async {
  final jsonData = json.decode(jsonString);

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
}

/// Get data count in isolate
Future<int> _getDataCount(String jsonString) async {
  final jsonData = json.decode(jsonString);
  final timeArray = jsonData['time'] as List<dynamic>;
  return timeArray.length;
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
