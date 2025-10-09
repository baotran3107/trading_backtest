// A small, SOLID-friendly abstraction for HTTP operations.
// Consumers depend on this interface instead of concrete clients.

import 'api_response.dart';

abstract class ApiClient {
  /// Base URL for all requests (should not end with a trailing slash)
  String get baseUrl;

  /// Perform a GET request to the given [path].
  ///
  /// - [queryParameters] are appended to the URL.
  /// - [headers] are merged with default headers.
  /// - [decoder] transforms the raw JSON body into the desired type [T].
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic json)? decoder,
  });
}
