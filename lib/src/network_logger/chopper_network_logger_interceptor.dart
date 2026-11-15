import 'package:chopper/chopper.dart';

import 'network_log_models.dart';
import 'network_logger.dart';

/// Chopper 8 interceptor bridge for the shared logger.
class ChopperNetworkLoggerInterceptor implements Interceptor {
  /// Use as `Request.tag` to skip logging for a single Chopper request.
  static const Object disableRequestTag = 'network_logger.disabled';

  ChopperNetworkLoggerInterceptor({required this.logger});
  final NetworkLogger logger;

  @override
  Future<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) async {
    final request = chain.request;
    final started = DateTime.now();
    final logRequest = NetworkRequestLog(
      method: request.method,
      url: request.url,
      headers: request.headers,
      body: request.body,
      enabled: request.tag != disableRequestTag,
    );
    logger.logRequest(logRequest);
    try {
      final response = await chain.proceed(request);
      logger.logResponse(
        logRequest,
        NetworkResponseLog(
          statusCode: response.statusCode,
          headers: response.headers,
          body: response.body,
        ),
        DateTime.now().difference(started),
      );
      return response;
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
  }
}
