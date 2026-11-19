import 'package:dio/dio.dart';

import '../../network_log_models.dart';
import '../../network_logger.dart';

/// Adapts Dio lifecycle events to the shared [NetworkLogger].
class DioNetworkLoggerInterceptor extends Interceptor {
  DioNetworkLoggerInterceptor({required this.logger});
  final NetworkLogger logger;
  static const disableLoggingExtraKey = 'networkLoggerDisabled';
  static const _startedAtKey = 'networkLoggerStartedAt';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final started = DateTime.now();
    options.extra[_startedAtKey] = started;
    try {
      final req = _request(options, started);
      logger.logRequest(req);
    } catch (_) {}
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    try {
      final request = _request(
        response.requestOptions,
        _started(response.requestOptions),
      );
      logger.logResponse(
        NetworkResponseLog(
          request: request,
          statusCode: response.statusCode ?? 0,
          headers: _headers(response.headers.map),
          body: response.data,
        ),
      );
    } catch (_) {}
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      final options = err.requestOptions;
      final response = err.response;
      logger.logError(
        NetworkErrorLog(
          request: _request(options, _started(options)),
          error: err,
          type: err.type.name,
          statusCode: response?.statusCode,
          headers: response == null ? const {} : _headers(response.headers.map),
          body: response?.data,
        ),
      );
    } catch (_) {}
    handler.next(err);
  }

  NetworkRequestLog _request(RequestOptions options, DateTime started) {
    final data = options.data;
    final parts = <NetworkMultipartPart>[];
    Object? body = data;
    if (data is FormData) {
      body = null;
      for (final field in data.fields) {
        parts.add(NetworkMultipartPart(name: field.key, value: field.value));
      }
      for (final file in data.files) {
        parts.add(
          NetworkMultipartPart(
            name: file.key,
            fileName: file.value.filename,
            contentType: file.value.contentType?.toString(),
            length: file.value.length,
          ),
        );
      }
    }
    return NetworkRequestLog(
      id: options.extra['requestId']?.toString(),
      method: options.method,
      url: options.uri,
      headers: _headers(options.headers),
      body: body,
      startedAt: started,
      loggingDisabled: options.extra[disableLoggingExtraKey] == true,
      multipartParts: parts,
    );
  }

  DateTime _started(RequestOptions options) =>
      options.extra[_startedAtKey] as DateTime? ?? DateTime.now();
  Map<String, Object?> _headers(Map<String, dynamic> headers) => {
    for (final entry in headers.entries) entry.key: entry.value,
  };
}
