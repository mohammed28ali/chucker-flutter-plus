import 'package:dio/dio.dart';

import 'network_log_models.dart';
import 'network_logger.dart';

/// Dio bridge for the client-independent [NetworkLogger].
class DioNetworkLoggerInterceptor extends Interceptor {
  DioNetworkLoggerInterceptor({required this.logger});
  final NetworkLogger logger;
  static const _startKey = 'network_logger.started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    logger.logRequest(_request(options));
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final request = response.requestOptions;
    logger.logResponse(
      _request(request),
      NetworkResponseLog(
        statusCode: response.statusCode ?? 0,
        headers: _headers(response.headers.map),
        body: response.data,
      ),
      DateTime.now().difference(_started(request)),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    logger.logError(
      _request(request),
      NetworkErrorLog(
        message: err.message ?? err.type.name,
        type: err.type.name,
        body: err.response?.data,
      ),
      DateTime.now().difference(_started(request)),
    );
    handler.next(err);
  }

  NetworkRequestLog _request(RequestOptions request) => NetworkRequestLog(
    method: request.method,
    url: request.uri,
    headers: request.headers,
    body: request.data is FormData ? null : request.data,
    multipartParts: request.data is FormData
        ? (request.data as FormData).fields
              .map((e) => NetworkMultipartPart(name: e.key, value: e.value))
              .followedBy(
                (request.data as FormData).files.map(
                  (e) => NetworkMultipartPart(
                    name: e.key,
                    filename: e.value.filename,
                    length: e.value.length,
                  ),
                ),
              )
              .toList()
        : const [],
    enabled: request.extra['network_logger.disabled'] != true,
  );

  DateTime _started(RequestOptions request) =>
      request.extra[_startKey] as DateTime? ?? DateTime.now();
  Map<String, Object?> _headers(Map<String, List<String>> source) =>
      source.map((key, value) => MapEntry(key, value.join(', ')));
}
