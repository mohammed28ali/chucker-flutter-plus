import 'dart:convert';

import 'log_redactor.dart';
import 'network_log_models.dart';

typedef NetworkLogPrinter = void Function(String message);

/// Client-independent console logger. All failures from formatting or the
/// configured printer are swallowed so diagnostics never affect a request.
class NetworkLogger {
  NetworkLogger({
    this.config = const NetworkLogConfig(),
    this.printer = print,
    LogRedactor? redactor,
  }) : redactor =
           redactor ??
           LogRedactor(
             sensitiveHeaders: config.sensitiveHeaders,
             sensitiveJsonKeys: config.sensitiveJsonKeys,
           );

  final NetworkLogConfig config;
  final NetworkLogPrinter printer;
  final LogRedactor redactor;

  bool get _active =>
      config.forceLogging ||
      (config.enabled &&
          const bool.fromEnvironment('dart.vm.product') == false);

  void logRequest(NetworkRequestLog request) => _safe(() {
    if (!_active || !request.enabled) return;
    final lines = <String>[
      '${config.requestColor}--> ${request.method} ${request.url}${config.resetColor}',
    ];
    if (config.logRequestHeaders) {
      lines.add('Headers: ${_json(redactor.headers(request.headers))}');
    }
    if (config.logRequestBody && request.body != null) {
      lines.add('Body: ${_formatBody(request.body)}');
    }
    for (final part in request.multipartParts) {
      lines.add('Multipart ${part.name}: ${_formatPart(part)}');
    }
    if (config.logCurlCommand) {
      lines.add('cURL: ${curlCommand(request)}');
    }
    printer(lines.join('\n'));
  });

  void logResponse(
    NetworkRequestLog request,
    NetworkResponseLog response,
    Duration duration,
  ) => _safe(() {
    if (!_active || !request.enabled) return;
    final color = _statusColor(response.statusCode);
    final lines = <String>[
      '$color<-- ${response.statusCode} ${request.url} (${duration.inMilliseconds}ms)${config.resetColor}',
    ];
    if (duration >= config.slowRequestThreshold) {
      lines.add(
        'SLOW REQUEST: threshold ${config.slowRequestThreshold.inMilliseconds}ms',
      );
    }
    if (config.logResponseHeaders) {
      lines.add('Headers: ${_json(redactor.headers(response.headers))}');
    }
    if (config.logResponseBody && response.body != null) {
      lines.add('Body: ${_formatBody(response.body)}');
    }
    printer(lines.join('\n'));
  });

  void logError(
    NetworkRequestLog request,
    NetworkErrorLog error,
    Duration duration,
  ) => _safe(() {
    if (!_active || !request.enabled) return;
    final lines = <String>[
      '${config.errorColor}<-- ERROR ${request.url} (${duration.inMilliseconds}ms): ${error.type == null ? '' : '${error.type}: '}${error.message}${config.resetColor}',
    ];
    if (duration >= config.slowRequestThreshold) {
      lines.add(
        'SLOW REQUEST: threshold ${config.slowRequestThreshold.inMilliseconds}ms',
      );
    }
    if (config.logErrorBody && error.body != null) {
      lines.add('Error body: ${_formatBody(error.body)}');
    }
    printer(lines.join('\n'));
  });

  String curlCommand(NetworkRequestLog request) {
    final b = StringBuffer("curl -X '${request.method}' '${request.url}'");
    for (final entry in redactor.headers(request.headers).entries) {
      b.write(" -H '${_shell(entry.key)}: ${_shell(entry.value)}'");
    }
    if (request.body != null) {
      b.write(" --data '${_shell(_stringify(redactor.body(request.body)))}'");
    }
    for (final part in request.multipartParts) {
      final value = redactor.sensitiveJsonKeys.contains(part.name.toLowerCase())
          ? '[REDACTED]'
          : part.filename == null
          ? _stringify(redactor.body(part.value))
          : '@${part.filename}';
      b.write(" -F '${_shell(part.name)}=${_shell(value)}'");
    }
    return b.toString();
  }

  String _formatPart(NetworkMultipartPart part) {
    if (redactor.sensitiveJsonKeys.contains(part.name.toLowerCase())) {
      return '[REDACTED]';
    }
    if (part.filename != null) {
      return 'file=${part.filename}, length=${part.length ?? 'unknown'}';
    }
    return _formatBody(part.value);
  }

  String _formatBody(Object? body) {
    final value = _stringify(redactor.body(body));
    if (value.length <= config.maxBodyLength) return value;
    return '${value.substring(0, config.maxBodyLength)}… [truncated, ${value.length} chars]';
  }

  String _statusColor(int code) => code >= 500
      ? config.errorColor
      : code >= 400
      ? '\x1B[33m'
      : code >= 300
      ? '\x1B[36m'
      : config.responseColor;
  String _json(Object? value) =>
      const JsonEncoder.withIndent('  ').convert(value);
  String _stringify(Object? value) {
    if (value is String) return value;
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  String _shell(Object? value) => value.toString().replaceAll("'", "'\\''");
  void _safe(void Function() action) {
    try {
      action();
    } catch (_) {}
  }
}
