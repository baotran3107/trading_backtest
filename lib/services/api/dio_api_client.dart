import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_response.dart';

class DioApiClient implements ApiClient {
  DioApiClient({
    required String baseUrl,
    Dio? dio,
    Map<String, String>? defaultHeaders,
  })  : _dio = dio ?? Dio(),
        _baseUrl = baseUrl,
        _defaultHeaders = Map.unmodifiable(defaultHeaders ?? const {});

  final Dio _dio;
  final String _baseUrl;
  final Map<String, String> _defaultHeaders;

  @override
  String get baseUrl => _baseUrl;

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic json)? decoder,
  }) async {
    final uri = _composeUrl(path);
    try {
      final response = await _dio.get<dynamic>(
        uri.toString(),
        queryParameters: queryParameters,
        options: Options(
          headers: _mergeHeaders(headers),
          responseType: ResponseType.json,
        ),
      );

      final decoded =
          decoder != null ? decoder(response.data) : response.data as T?;
      return ApiResponse<T>(
        statusCode: response.statusCode ?? 0,
        data: decoded,
        headers: _normalizeHeaders(response.headers.map),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      return ApiResponse<T>(
        statusCode: status,
        data: null,
        headers: _normalizeHeaders(e.response?.headers.map ?? const {}),
        error: e,
      );
    } catch (e) {
      return ApiResponse<T>(
        statusCode: 0,
        data: null,
        headers: const {},
        error: e,
      );
    }
  }

  Uri _composeUrl(String path) {
    final normalizedBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$normalizedBase/$normalizedPath');
  }

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    return {
      ..._defaultHeaders,
      if (headers != null) ...headers,
    };
  }

  Map<String, String> _normalizeHeaders(Map<String, List<String>> raw) {
    final map = <String, String>{};
    for (final entry in raw.entries) {
      if (entry.value.isNotEmpty) {
        map[entry.key] = entry.value.join(', ');
      }
    }
    return map;
  }
}
