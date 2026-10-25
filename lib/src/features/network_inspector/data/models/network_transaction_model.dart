import '../../domain/entities/network_transaction.dart';

/// JSON-safe representation used by the local data source.
class NetworkTransactionModel extends NetworkTransaction {
  NetworkTransactionModel({
    required super.id,
    required super.startedAt,
    required super.completedAt,
    required super.method,
    required super.uri,
    required super.statusCode,
    required super.requestHeaders,
    required super.responseHeaders,
    super.rawRequestBody,
    super.rawResponseBody,
    super.requestBodySize,
    super.responseBodySize,
    super.contentType,
    super.imageWidth,
    super.imageHeight,
    super.error,
    super.stackTrace,
  });

  factory NetworkTransactionModel.fromEntity(NetworkTransaction transaction) =>
      NetworkTransactionModel(
        id: transaction.id,
        startedAt: transaction.startedAt,
        completedAt: transaction.completedAt,
        method: transaction.method,
        uri: transaction.uri,
        statusCode: transaction.statusCode,
        requestHeaders: transaction.requestHeaders,
        responseHeaders: transaction.responseHeaders,
        rawRequestBody: transaction.rawRequestBody,
        rawResponseBody: transaction.rawResponseBody,
        requestBodySize: transaction.requestBodySize,
        responseBodySize: transaction.responseBodySize,
        contentType: transaction.contentType,
        imageWidth: transaction.imageWidth,
        imageHeight: transaction.imageHeight,
        error: transaction.error,
        stackTrace: transaction.stackTrace,
      );

  factory NetworkTransactionModel.fromJson(Map<String, Object?> json) =>
      NetworkTransactionModel(
        id: json['id']! as String,
        startedAt: DateTime.parse(json['startedAt']! as String),
        completedAt: DateTime.parse(json['completedAt']! as String),
        method: json['method']! as String,
        uri: Uri.parse(json['uri']! as String),
        statusCode: json['statusCode'] as int?,
        requestHeaders: _stringMap(json['requestHeaders']),
        responseHeaders: _stringMap(json['responseHeaders']),
        rawRequestBody: json['rawRequestBody'] as String?,
        rawResponseBody: json['rawResponseBody'] as String?,
        requestBodySize: json['requestBodySize'] as int? ?? 0,
        responseBodySize: json['responseBodySize'] as int? ?? 0,
        contentType: json['contentType'] as String?,
        imageWidth: json['imageWidth'] as int?,
        imageHeight: json['imageHeight'] as int?,
        error: json['error'] as String?,
        stackTrace: json['stackTrace'] as String?,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'method': method,
    'uri': uri.toString(),
    'statusCode': statusCode,
    'requestHeaders': requestHeaders,
    'responseHeaders': responseHeaders,
    'rawRequestBody': rawRequestBody,
    'rawResponseBody': rawResponseBody,
    'requestBodySize': requestBodySize,
    'responseBodySize': responseBodySize,
    'contentType': contentType,
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
    'error': error,
    'stackTrace': stackTrace,
  };

  static Map<String, String> _stringMap(Object? value) =>
      (value as Map<Object?, Object?>? ?? const {}).map(
        (key, entry) => MapEntry('$key', '$entry'),
      );
}
