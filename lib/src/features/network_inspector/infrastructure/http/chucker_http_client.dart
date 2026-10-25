import 'package:http/http.dart' as http;

import '../../domain/entities/network_transaction.dart';
import '../body_capture.dart';
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
      await ChuckerFlutterPlus.record(
        NetworkTransaction(
          id: '${request.hashCode}-${startedAt.microsecondsSinceEpoch}',
          startedAt: startedAt,
          completedAt: DateTime.now(),
          method: request.method,
          uri: request.url,
          statusCode: response.statusCode,
          requestHeaders: ChuckerFlutterPlus.redactHeaders(request.headers),
          responseHeaders: ChuckerFlutterPlus.redactHeaders(response.headers),
          rawRequestBody: _requestBody(request),
          rawResponseBody: BodyCapture.raw(bytes),
          requestBodySize: _requestBodySize(request),
          responseBodySize: response.contentLength ?? bytes.length,
          contentType: response.headers['content-type'],
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
    } catch (error, stackTrace) {
      await ChuckerFlutterPlus.record(
        NetworkTransaction(
          id: '${request.hashCode}-${startedAt.microsecondsSinceEpoch}',
          startedAt: startedAt,
          completedAt: DateTime.now(),
          method: request.method,
          uri: request.url,
          statusCode: null,
          requestHeaders: ChuckerFlutterPlus.redactHeaders(request.headers),
          responseHeaders: const {},
          rawRequestBody: _requestBody(request),
          requestBodySize: _requestBodySize(request),
          error: error.toString(),
          stackTrace: stackTrace.toString(),
        ),
      );
      rethrow;
    }
  }

  @override
  void close() => _client.close();

  static String? _requestBody(http.BaseRequest request) {
    if (request case http.Request(:final body)) {
      return body;
    }
    if (request case http.MultipartRequest(:final fields))
      return fields.toString();
    return null;
  }

  static int _requestBodySize(http.BaseRequest request) =>
      request.contentLength ?? BodyCapture.size(null, _requestBody(request));
}
