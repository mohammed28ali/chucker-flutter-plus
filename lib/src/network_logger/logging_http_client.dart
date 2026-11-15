import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'network_log_models.dart';
import 'network_logger.dart';

/// `package:http` wrapper. Streaming response bytes are forwarded as they
/// arrive; logging happens after the consumer finishes the stream.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient({
    required this.inner,
    required this.logger,
    this.shouldLog,
  });
  final http.Client inner;
  final NetworkLogger logger;
  final bool Function(http.BaseRequest request)? shouldLog;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final started = DateTime.now();
    final parts = <NetworkMultipartPart>[];
    Object? body;
    if (request is http.Request) {
      body = request.body;
    } else if (request is http.MultipartRequest) {
      parts.addAll(
        request.fields.entries.map(
          (e) => NetworkMultipartPart(name: e.key, value: e.value),
        ),
      );
      parts.addAll(
        request.files.map(
          (e) => NetworkMultipartPart(
            name: e.field,
            filename: e.filename,
            length: e.length,
          ),
        ),
      );
    }
    final logRequest = NetworkRequestLog(
      method: request.method,
      url: request.url,
      headers: request.headers,
      body: body,
      multipartParts: parts,
      enabled: shouldLog?.call(request) ?? true,
    );
    logger.logRequest(logRequest);
    late http.StreamedResponse response;
    try {
      response = await inner.send(request);
    } catch (error) {
      logger.logError(
        logRequest,
        NetworkErrorLog(
          message: error.toString(),
          type: error.runtimeType.toString(),
        ),
        DateTime.now().difference(started),
      );
      rethrow;
    }

    final bytes = BytesBuilder(copy: false);
    final forwarded = response.stream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          bytes.add(chunk);
          sink.add(chunk);
        },
        handleError: (Object error, StackTrace stack, sink) {
          logger.logError(
            logRequest,
            NetworkErrorLog(
              message: error.toString(),
              type: error.runtimeType.toString(),
            ),
            DateTime.now().difference(started),
          );
          sink.addError(error, stack);
        },
        handleDone: (sink) {
          logger.logResponse(
            logRequest,
            NetworkResponseLog(
              statusCode: response.statusCode,
              headers: response.headers,
              body: _decode(bytes.toBytes(), response.headers['content-type']),
            ),
            DateTime.now().difference(started),
          );
          sink.close();
        },
      ),
    );
    return http.StreamedResponse(
      forwarded,
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => inner.close();

  Object _decode(Uint8List bytes, String? contentType) {
    if (contentType?.toLowerCase().contains('text') == true ||
        contentType?.toLowerCase().contains('json') == true) {
      try {
        return utf8.decode(bytes);
      } catch (_) {}
    }
    return '<${bytes.length} binary bytes>';
  }
}
