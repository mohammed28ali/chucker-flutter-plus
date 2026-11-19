import 'package:flutter/foundation.dart';

/// Marker for disabling logging on a single Chopper request via its [tag].
class NetworkLoggerDisabled {
  const NetworkLoggerDisabled();
}

/// Client-independent request details passed to [NetworkLogger].
class NetworkRequestLog {
  NetworkRequestLog({
    required this.method,
    required this.url,
    Map<String, Object?> headers = const {},
    this.body,
    DateTime? startedAt,
    this.id,
    this.loggingDisabled = false,
    this.multipartParts = const [],
  }) : headers = Map.unmodifiable(headers),
       startedAt = startedAt ?? DateTime.now();

  final String? id;
  final String method;
  final Uri url;
  final Map<String, Object?> headers;
  final Object? body;
  final DateTime startedAt;
  final bool loggingDisabled;
  final List<NetworkMultipartPart> multipartParts;
}

/// Response details paired with their normalized request.
class NetworkResponseLog {
  const NetworkResponseLog({
    required this.request,
    required this.statusCode,
    this.headers = const {},
    this.body,
    this.completedAt,
  });
  final NetworkRequestLog request;
  final int statusCode;
  final Map<String, Object?> headers;
  final Object? body;
  final DateTime? completedAt;
  Duration get duration =>
      (completedAt ?? DateTime.now()).difference(request.startedAt);
}

/// Failure details paired with their normalized request.
class NetworkErrorLog {
  const NetworkErrorLog({
    required this.request,
    required this.error,
    this.type,
    this.statusCode,
    this.headers = const {},
    this.body,
    this.completedAt,
  });
  final NetworkRequestLog request;
  final Object error;
  final String? type;
  final int? statusCode;
  final Map<String, Object?> headers;
  final Object? body;
  final DateTime? completedAt;
  Duration get duration =>
      (completedAt ?? DateTime.now()).difference(request.startedAt);
}

/// Metadata for a multipart field or file without exposing client types.
class NetworkMultipartPart {
  const NetworkMultipartPart({
    required this.name,
    this.value,
    this.fileName,
    this.contentType,
    this.length,
  });
  final String name;
  final Object? value;
  final String? fileName;
  final String? contentType;
  final int? length;
}

/// Common configuration for client-independent network logs.
class NetworkLogConfig {
  const NetworkLogConfig({
    this.enabled = kDebugMode,
    this.forceLogging = false,
    this.logRequests = true,
    this.logResponses = true,
    this.logErrors = true,
    this.logRequestHeaders = true,
    this.logRequestBody = true,
    this.logResponseHeaders = true,
    this.logResponseBody = true,
    this.logErrorBody = true,
    this.logCurlCommand = true,
    this.maxBodyLength = 4000,
    this.slowRequestThreshold = const Duration(seconds: 3),
    this.sensitiveHeaders = const {
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'api-key',
    },
    this.sensitiveJsonKeys = const {
      'password',
      'token',
      'access_token',
      'refresh_token',
      'secret',
      'authorization',
      'api_key',
    },
    this.requestColor = '\x1B[36m',
    this.responseColor = '\x1B[32m',
    this.errorColor = '\x1B[31m',
    this.resetColor = '\x1B[0m',
  }) : assert(maxBodyLength >= 0);
  final bool enabled;
  final bool forceLogging;
  final bool logRequests;
  final bool logResponses;
  final bool logErrors;
  final bool logRequestHeaders;
  final bool logRequestBody;
  final bool logResponseHeaders;
  final bool logResponseBody;
  final bool logErrorBody;
  final bool logCurlCommand;
  final int maxBodyLength;
  final Duration slowRequestThreshold;
  final Set<String> sensitiveHeaders;
  final Set<String> sensitiveJsonKeys;
  final String requestColor;
  final String responseColor;
  final String errorColor;
  final String resetColor;
}
