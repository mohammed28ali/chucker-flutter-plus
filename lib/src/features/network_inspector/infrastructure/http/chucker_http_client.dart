import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/network_transaction.dart';
import '../../presentation/chucker_flutter.dart';

/// An [http.BaseClient] wrapper that records each completed request.
class ChuckerHttpClient extends http.BaseClient {
  ChuckerHttpClient(this._client);

  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startedAt = DateTime.now();
    try {
      final response = await _client.send(request);
      final bytes = await response.stream.toBytes();
      await ChuckerFlutter.record(
        NetworkTransaction(
          id: '${request.hashCode}-${startedAt.microsecondsSinceEpoch}',
          startedAt: startedAt,
          completedAt: DateTime.now(),
          method: request.method,
          uri: request.url,
          statusCode: response.statusCode,
          requestHeaders: Map.unmodifiable(request.headers),
          responseHeaders: Map.unmodifiable(response.headers),
          requestBody: _requestBody(request),
          responseBody: _decode(bytes),
        ),
      );
      return http.StreamedResponse(
        http.ByteStream.fromBytes(bytes),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (error) {
      await ChuckerFlutter.record(
        NetworkTransaction(
          id: '${request.hashCode}-${startedAt.microsecondsSinceEpoch}',
          startedAt: startedAt,
          completedAt: DateTime.now(),
          method: request.method,
          uri: request.url,
          statusCode: null,
          requestHeaders: Map.unmodifiable(request.headers),
          responseHeaders: const {},
          requestBody: _requestBody(request),
          error: error.toString(),
        ),
      );
      rethrow;
    }
  }

  @override
  void close() => _client.close();

  static Object? _requestBody(http.BaseRequest request) {
    if (request case http.Request(:final body)) {
      return _decode(utf8.encode(body));
    }
    if (request case http.MultipartRequest(:final fields)) return fields;
    return null;
  }

  static Object? _decode(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }
}
