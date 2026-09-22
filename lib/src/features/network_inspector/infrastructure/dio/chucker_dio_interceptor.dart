import 'package:dio/dio.dart';

import '../../domain/entities/network_transaction.dart';
import '../../presentation/chucker_flutter.dart';

/// A Dio interceptor that records responses and failures for inspection.
class ChuckerDioInterceptor extends Interceptor {
  static const _startedAtKey = 'chucker_flutter_plus.started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _recordResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _recordError(err);
    handler.next(err);
  }

  void _recordResponse(Response<dynamic> response) {
    final request = response.requestOptions;
    _record(
      NetworkTransaction(
        id: _id(request),
        startedAt: _startedAt(request),
        completedAt: DateTime.now(),
        method: request.method,
        uri: request.uri,
        statusCode: response.statusCode,
        requestHeaders: _requestHeaders(request.headers),
        responseHeaders: _headers(response.headers),
        requestBody: request.data,
        responseBody: response.data,
      ),
    );
  }

  void _recordError(DioException error) {
    final request = error.requestOptions;
    final response = error.response;
    _record(
      NetworkTransaction(
        id: _id(request),
        startedAt: _startedAt(request),
        completedAt: DateTime.now(),
        method: request.method,
        uri: request.uri,
        statusCode: response?.statusCode,
        requestHeaders: _requestHeaders(request.headers),
        responseHeaders: response == null
            ? const {}
            : _headers(response.headers),
        requestBody: request.data,
        responseBody: response?.data,
        error: error.message ?? error.type.name,
      ),
    );
  }

  void _record(NetworkTransaction transaction) {
    // Dio's interceptor API is synchronous; persistence must not delay a call.
    ChuckerFlutterPlus.record(transaction).ignore();
  }

  DateTime _startedAt(RequestOptions request) =>
      request.extra[_startedAtKey] as DateTime? ?? DateTime.now();

  String _id(RequestOptions request) =>
      '${request.hashCode}-${DateTime.now().microsecondsSinceEpoch}';

  Map<String, String> _headers(Headers headers) =>
      headers.map.map((key, values) => MapEntry(key, values.join(', ')));

  Map<String, String> _requestHeaders(Map<String, dynamic> headers) =>
      headers.map((key, value) => MapEntry(key, value.toString()));
}
