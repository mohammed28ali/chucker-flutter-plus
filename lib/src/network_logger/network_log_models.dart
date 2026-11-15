/// Client-independent description of an outgoing HTTP request.
class NetworkRequestLog {
  const NetworkRequestLog({
    required this.method,
    required this.url,
    this.headers = const {},
    this.body,
    this.multipartParts = const [],
    this.enabled = true,
  });

  final String method;
  final Uri url;
  final Map<String, Object?> headers;
  final Object? body;
  final List<NetworkMultipartPart> multipartParts;

  /// Set false to suppress logging for this request.
  final bool enabled;
}

/// Multipart metadata that can be safely logged without depending on a client.
class NetworkMultipartPart {
  const NetworkMultipartPart({
    required this.name,
    this.value,
    this.filename,
    this.length,
  });
  final String name;
  final Object? value;
  final String? filename;
  final int? length;
}

/// Client-independent description of an HTTP response.
class NetworkResponseLog {
  const NetworkResponseLog({
    required this.statusCode,
    this.headers = const {},
    this.body,
  });
  final int statusCode;
  final Map<String, Object?> headers;
  final Object? body;
}

/// Client-independent description of a request failure.
class NetworkErrorLog {
  const NetworkErrorLog({required this.message, this.type, this.body});
  final String message;
  final String? type;
  final Object? body;
}

/// Shared behavior for [NetworkLogger].
class NetworkLogConfig {
  const NetworkLogConfig({
    this.logRequestHeaders = true,
    this.logRequestBody = true,
    this.logResponseHeaders = true,
    this.logResponseBody = true,
    this.logErrorBody = true,
    this.logCurlCommand = true,
    this.enabled = true,
    this.forceLogging = false,
    this.maxBodyLength = 4000,
    this.slowRequestThreshold = const Duration(seconds: 10),
    this.sensitiveHeaders = const {
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
    },
    this.sensitiveJsonKeys = const {
      'password',
      'token',
      'access_token',
      'refresh_token',
      'secret',
    },
    this.requestColor = '\x1B[36m',
    this.responseColor = '\x1B[32m',
    this.errorColor = '\x1B[31m',
    this.resetColor = '\x1B[0m',
  }) : assert(maxBodyLength >= 0);

  final bool logRequestHeaders,
      logRequestBody,
      logResponseHeaders,
      logResponseBody,
      logErrorBody,
      logCurlCommand,
      enabled,
      forceLogging;
  final int maxBodyLength;
  final Duration slowRequestThreshold;
  final Set<String> sensitiveHeaders, sensitiveJsonKeys;
  final String requestColor, responseColor, errorColor, resetColor;
}
