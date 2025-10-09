class ApiResponse<T> {
  final T? data;
  final int statusCode;
  final Map<String, String> headers;
  final Object? error;

  const ApiResponse({
    required this.statusCode,
    this.data,
    this.headers = const {},
    this.error,
  });

  bool get isSuccessful => statusCode >= 200 && statusCode < 300;
}
