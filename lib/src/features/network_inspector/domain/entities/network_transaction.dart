import 'dart:convert';

/// An immutable, persistable record of a completed HTTP transaction.
///
/// Raw bodies deliberately retain their original string/byte representation;
/// presentation may choose to format them but must not overwrite them.
class NetworkTransaction {
  NetworkTransaction({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.method,
    required this.uri,
    required this.statusCode,
    required this.requestHeaders,
    required this.responseHeaders,
    String? rawRequestBody,
    String? rawResponseBody,
    Object? requestBody,
    Object? responseBody,
    this.requestBodySize = 0,
    this.responseBodySize = 0,
    this.contentType,
    this.imageWidth,
    this.imageHeight,
    this.error,
    this.stackTrace,
  }) : rawRequestBody = rawRequestBody ?? _legacyRaw(requestBody),
       rawResponseBody = rawResponseBody ?? _legacyRaw(responseBody);

  final String id;
  final DateTime startedAt;
  final DateTime completedAt;
  final String method;
  final Uri uri;
  final int? statusCode;
  final Map<String, String> requestHeaders;
  final Map<String, String> responseHeaders;
  final String? rawRequestBody;
  final String? rawResponseBody;
  final int requestBodySize;
  final int responseBodySize;
  final String? contentType;
  final int? imageWidth;
  final int? imageHeight;
  final String? error;
  final String? stackTrace;

  Duration get duration => completedAt.difference(startedAt);

  bool get succeeded =>
      statusCode != null && statusCode! < 400 && error == null;

  String get host => uri.host;

  static String? _legacyRaw(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }
}
