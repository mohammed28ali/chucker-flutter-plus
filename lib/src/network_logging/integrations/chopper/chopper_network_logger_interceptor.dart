import 'package:chopper/chopper.dart' as chopper;

import '../../network_log_models.dart';
import '../../network_logger.dart';

/// Adapts Chopper's request/response interceptor lifecycle to [NetworkLogger].
class ChopperNetworkLoggerInterceptor implements chopper.Interceptor {
  ChopperNetworkLoggerInterceptor({required this.logger});
  final NetworkLogger logger;

  @override
  Future<chopper.Response<BodyType>> intercept<BodyType>(
    chopper.Chain<BodyType> chain,
  ) async {
    final started = DateTime.now();
    final source = chain.request;
    NetworkRequestLog? request;
    try {
      request = NetworkRequestLog(
        method: source.method,
        url: source.url,
        headers: {
          for (final entry in source.headers.entries) entry.key: entry.value,
        },
        body: source.multipart ? null : source.body,
        startedAt: started,
        loggingDisabled: source.tag is NetworkLoggerDisabled,
        multipartParts: source.parts
            .map(
              (part) =>
                  NetworkMultipartPart(name: part.name, value: part.value),
            )
            .toList(),
      );
      logger.logRequest(request);
    } catch (_) {}
    try {
      final response = await chain.proceed(source);
      if (request != null) {
        logger.logResponse(
          NetworkResponseLog(
            request: request,
            statusCode: response.statusCode,
            headers: {
              for (final entry in response.headers.entries)
                entry.key: entry.value,
            },
            body: response.error ?? response.body,
          ),
        );
      }
      return response;
    } catch (error) {
      if (request != null) {
        logger.logError(
          NetworkErrorLog(
            request: request,
            error: error,
            type: error.runtimeType.toString(),
          ),
        );
      }
      rethrow;
    }
  }
}
