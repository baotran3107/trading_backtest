import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../model/candle_model.dart';
import '../services/api/api_client.dart';
import '../utils/config.dart' show AppConfig, AppConfigKey;
import 'xauusd_repository.dart';

@LazySingleton(as: XauusdRepository)
class XauusdRepositoryImpl implements XauusdRepository {
  XauusdRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<CandleStick>> fetchAllM1() async {
    // Build path relative to base URL
    // Full: https://<base>/storage/v1/object/sign/history-pricing/xauusd/XAUUSD_M1.json?token=<token>
    final path =
        'storage/v1/object/sign/history-pricing/xauusd/${AppConfigKey.xauusdM1.fileName}';

    final response = await _apiClient.get<List<CandleStick>>(
      path,
      queryParameters: {
        'token': AppConfig.supabaseSignedToken,
      },
      decoder: (dynamic jsonBody) {
        // dio already decodes JSON by default; ensure we can handle both String and List
        final dynamic data =
            jsonBody is String ? json.decode(jsonBody) : jsonBody;
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map<CandleStick>(CandleStick.fromJson)
              .toList();
        }
        return <CandleStick>[];
      },
    );

    if (!response.isSuccessful || response.data == null) {
      throw StateError(
          'Failed to load XAUUSD_M1.json (status: ${response.statusCode})');
    }

    return response.data!;
  }
}
