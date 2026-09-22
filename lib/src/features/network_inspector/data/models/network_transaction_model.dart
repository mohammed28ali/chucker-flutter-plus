import 'dart:convert';

import '../../domain/entities/network_transaction.dart';

/// JSON-safe representation used by the local data source.
class NetworkTransactionModel extends NetworkTransaction {
  const NetworkTransactionModel({
    required super.id,
    required super.startedAt,
    required super.completedAt,
    required super.method,
    required super.uri,
    required super.statusCode,
    required super.requestHeaders,
    required super.responseHeaders,
    super.requestBody,
    super.responseBody,
    super.error,
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
        requestBody: transaction.requestBody,
        responseBody: transaction.responseBody,
        error: transaction.error,
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
        requestBody: json['requestBody'],
        responseBody: json['responseBody'],
        error: json['error'] as String?,
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
    'requestBody': _jsonValue(requestBody),
    'responseBody': _jsonValue(responseBody),
    'error': error,
  };

  static Map<String, String> _stringMap(Object? value) =>
      (value as Map<Object?, Object?>? ?? const {}).map(
        (key, entry) => MapEntry('$key', '$entry'),
      );

  static Object? _jsonValue(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    try {
      jsonEncode(value);
      return value;
    } on JsonUnsupportedObjectError {
      return value.toString();
    }
  }
}
