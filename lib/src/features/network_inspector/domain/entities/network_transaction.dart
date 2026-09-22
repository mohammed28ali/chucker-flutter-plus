/// An immutable record of a completed HTTP transaction.
class NetworkTransaction {
  const NetworkTransaction({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.method,
    required this.uri,
    required this.statusCode,
    required this.requestHeaders,
    required this.responseHeaders,
    this.requestBody,
    this.responseBody,
    this.error,
  });

  final String id;
  final DateTime startedAt;
  final DateTime completedAt;
  final String method;
  final Uri uri;
  final int? statusCode;
  final Map<String, String> requestHeaders;
  final Map<String, String> responseHeaders;
  final Object? requestBody;
  final Object? responseBody;
  final String? error;

  Duration get duration => completedAt.difference(startedAt);

  bool get succeeded =>
      statusCode != null && statusCode! < 400 && error == null;
}
