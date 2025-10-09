import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class DatasetCacheService {
  DatasetCacheService(this._box);

  static const String _downloadedKeyPrefix =
      'downloaded:'; // downloaded:<symbol>
  static const String _datasetKeyPrefix = 'dataset:'; // dataset:<symbol>

  final Box _box;

  Future<bool> isDownloaded(String symbol) async {
    return _box.get('$_downloadedKeyPrefix$symbol', defaultValue: false)
        as bool;
  }

  Future<void> markDownloaded(String symbol) async {
    await _box.put('$_downloadedKeyPrefix$symbol', true);
  }

  Future<void> cacheDatasetJson(
      String symbol, Map<String, dynamic> jsonMap) async {
    final String jsonString = json.encode(jsonMap);
    await _box.put('$_datasetKeyPrefix$symbol', jsonString);
  }

  Map<String, dynamic>? getCachedDatasetJson(String symbol) {
    final String? jsonString = _box.get('$_datasetKeyPrefix$symbol') as String?;
    if (jsonString == null) return null;
    return json.decode(jsonString) as Map<String, dynamic>;
  }
}
