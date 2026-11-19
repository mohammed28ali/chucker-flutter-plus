import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../network_log_models.dart';
import '../../network_logger.dart';

/// An `http.Client` wrapper that tees response bytes while preserving streaming.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient({required this.inner, required this.logger});
  final http.Client inner;
  final NetworkLogger logger;
  static const disableLoggingHeader = 'x-network-logger-disabled';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final started = DateTime.now();
    final disabled =
        request.headers[disableLoggingHeader]?.toLowerCase() == 'true';
    request.headers.remove(disableLoggingHeader);
    final requestLog = NetworkRequestLog(
      method: request.method,
      url: request.url,
      headers: {
        for (final entry in request.headers.entries) entry.key: entry.value,
      },
      body: request is http.Request ? request.body : null,
      startedAt: started,
      loggingDisabled: disabled,
      multipartParts: request is http.MultipartRequest
          ? [
              ...request.fields.entries.map(
                (e) => NetworkMultipartPart(name: e.key, value: e.value),
              ),
              ...request.files.map(
                (f) => NetworkMultipartPart(
                  name: f.field,
                  fileName: f.filename,
                  contentType: f.contentType.toString(),
                  length: f.length,
                ),
              ),
            ]
          : const [],
    );
    try {
      logger.logRequest(requestLog);
      final response = await inner.send(request);
      final bytes = <int>[];
      final stream = response.stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (chunk, sink) {
            if (logger.config.logResponseBody &&
                !disabled &&
                bytes.length < logger.config.maxBodyLength * 4) {
              final remaining = logger.config.maxBodyLength * 4 - bytes.length;
              bytes.addAll(chunk.take(remaining));
            }
            sink.add(chunk);
          },
          handleError: (error, stack, sink) {
            logger.logError(
              NetworkErrorLog(
                request: requestLog,
                error: error,
                type: error.runtimeType.toString(),
                statusCode: response.statusCode,
              ),
            );
            sink.addError(error, stack);
          },
          handleDone: (sink) {
            logger.logResponse(
              NetworkResponseLog(
                request: requestLog,
                statusCode: response.statusCode,
                headers: {
                  for (final entry in response.headers.entries)
                    entry.key: entry.value,
                },
                body: logger.config.logResponseBody && !disabled
                    ? _decode(bytes)
                    : null,
              ),
            );
            sink.close();
          },
        ),
      );
      return http.StreamedResponse(
        stream,
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (error) {
      logger.logError(
        NetworkErrorLog(
          request: requestLog,
          error: error,
          type: error.runtimeType.toString(),
        ),
      );
      rethrow;
    }
  }

  @override
  void close() => inner.close();

  static Object? _decode(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }
}
