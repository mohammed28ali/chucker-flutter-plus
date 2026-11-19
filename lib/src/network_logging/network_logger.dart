import 'dart:convert';

import 'log_redactor.dart';
import 'network_log_models.dart';

typedef NetworkLogPrinter = void Function(String message);

/// Client-independent formatter and printer for network activity.
class NetworkLogger {
  NetworkLogger({
    NetworkLogConfig config = const NetworkLogConfig(),
    NetworkLogPrinter? printer,
    LogRedactor? redactor,
  }) : config = config,
       printer = printer ?? _defaultPrinter,
       redactor =
           redactor ??
           LogRedactor(
             sensitiveHeaders: config.sensitiveHeaders,
             sensitiveJsonKeys: config.sensitiveJsonKeys,
           );

  final NetworkLogConfig config;
  final NetworkLogPrinter printer;
  final LogRedactor redactor;
  // ignore: avoid_print
  static void _defaultPrinter(String message) => print(message);
  bool get _enabled => config.enabled || config.forceLogging;

  void logRequest(NetworkRequestLog request) => _safe(() {
    if (!_enabled || request.loggingDisabled || !config.logRequests) return;
    final b = StringBuffer(
      '${config.requestColor}┌─ ${request.method} ${request.url}\n',
    );
    if (config.logCurlCommand) b.writeln('│ cURL: ${curlCommand(request)}');
    if (config.logRequestHeaders) {
      b.writeln('│ Headers: ${_json(redactor.redactHeaders(request.headers))}');
    }
    if (config.logRequestBody) {
      b.writeln('│ Body: ${_formatBody(request.body)}');
      if (request.multipartParts.isNotEmpty) {
        b.writeln('│ Multipart: ${_json(_multipart(request.multipartParts))}');
      }
    }
    b.write('└─${config.resetColor}');
    printer(b.toString());
  });

  void logResponse(NetworkResponseLog response) => _safe(() {
    if (!_enabled || response.request.loggingDisabled || !config.logResponses) {
      return;
    }
    final status = response.statusCode;
    final color = status >= 500
        ? config.errorColor
        : status >= 400
        ? '\x1B[33m'
        : status >= 300
        ? '\x1B[36m'
        : config.responseColor;
    final b = StringBuffer(
      '$color┌─ ${response.request.method} ${response.request.url} [$status] ${response.duration.inMilliseconds}ms\n',
    );
    if (response.duration >= config.slowRequestThreshold) {
      b.writeln(
        '│ SLOW REQUEST (>${config.slowRequestThreshold.inMilliseconds}ms)',
      );
    }
    if (config.logResponseHeaders) {
      b.writeln(
        '│ Headers: ${_json(redactor.redactHeaders(response.headers))}',
      );
    }
    if (config.logResponseBody) {
      b.writeln('│ Body: ${_formatBody(response.body)}');
    }
    b.write('└─${config.resetColor}');
    printer(b.toString());
  });

  void logError(NetworkErrorLog error) => _safe(() {
    if (!_enabled || error.request.loggingDisabled || !config.logErrors) return;
    final b = StringBuffer(
      '${config.errorColor}┌─ ${error.request.method} ${error.request.url} ERROR ${error.statusCode ?? ''} ${error.duration.inMilliseconds}ms\n',
    );
    b.writeln('│ ${error.type ?? error.error.runtimeType}: ${error.error}');
    if (config.logResponseHeaders && error.headers.isNotEmpty) {
      b.writeln('│ Headers: ${_json(redactor.redactHeaders(error.headers))}');
    }
    if (config.logErrorBody) b.writeln('│ Body: ${_formatBody(error.body)}');
    if (error.duration >= config.slowRequestThreshold) {
      b.writeln(
        '│ SLOW REQUEST (>${config.slowRequestThreshold.inMilliseconds}ms)',
      );
    }
    b.write('└─${config.resetColor}');
    printer(b.toString());
  });

  String curlCommand(NetworkRequestLog request) {
    final parts = <String>['curl', '-X', _quote(request.method)];
    for (final entry in redactor.redactHeaders(request.headers).entries) {
      parts.addAll(['-H', _quote('${entry.key}: ${entry.value}')]);
    }
    if (request.body != null && request.multipartParts.isEmpty) {
      parts.addAll([
        '--data-raw',
        _quote(_bodyString(_redactBody(request.body))),
      ]);
    }
    for (final part in request.multipartParts) {
      final value =
          redactor.sensitiveJsonKeys.any(
            (key) => key.toLowerCase() == part.name.toLowerCase(),
          )
          ? redactor.replacement
          : redactor.redactValue(part.value);
      parts.addAll([
        '-F',
        _quote(
          part.fileName != null
              ? '${part.name}=@${part.fileName}'
              : '${part.name}=${value ?? ''}',
        ),
      ]);
    }
    parts.add(_quote(request.url.toString()));
    return parts.join(' ');
  }

  String _formatBody(Object? value) {
    if (value == null) return '<empty>';
    final text = _bodyString(_redactBody(value));
    if (text.length <= config.maxBodyLength) return text;
    return '${text.substring(0, config.maxBodyLength)}… [truncated ${text.length - config.maxBodyLength} chars]';
  }

  Object? _redactBody(Object? value) {
    if (value is String) {
      try {
        return redactor.redactValue(jsonDecode(value));
      } on FormatException {
        return value;
      }
    }
    return redactor.redactValue(value);
  }

  String _bodyString(Object? value) => value is String
      ? value
      : const JsonEncoder.withIndent('  ').convert(value);
  String _json(Object? value) =>
      const JsonEncoder.withIndent('  ').convert(value);
  List<Map<String, Object?>> _multipart(List<NetworkMultipartPart> parts) => [
    for (final p in parts)
      {
        'name': p.name,
        if (p.value != null) 'value': redactor.redactValue(p.value),
        if (p.fileName != null) 'fileName': p.fileName,
        if (p.contentType != null) 'contentType': p.contentType,
        if (p.length != null) 'length': p.length,
      },
  ];
  void _safe(void Function() action) {
    try {
      action();
    } catch (_) {
      /* Logging must not affect requests. */
    }
  }

  static String _quote(String value) => "'${value.replaceAll("'", "'\\''")}'";
}
