import 'package:chucker_flutter_plus/network_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NetworkRequestLog request({
    bool disabled = false,
    DateTime? startedAt,
    Object? body,
  }) => NetworkRequestLog(
    method: 'POST',
    url: Uri.parse('https://example.test/items'),
    headers: const {
      'Authorization': 'Bearer private',
      'content-type': 'application/json',
    },
    body:
        body ??
        const {
          'profile': {'password': 'secret'},
          'safe': true,
        },
    startedAt: startedAt ?? DateTime.now().subtract(const Duration(seconds: 6)),
    loggingDisabled: disabled,
    multipartParts: const [
      NetworkMultipartPart(
        name: 'upload',
        fileName: 'image.png',
        contentType: 'image/png',
        length: 4,
      ),
    ],
  );

  test(
    'redacts headers and nested JSON; formats curl and multipart metadata',
    () {
      final lines = <String>[];
      final logger = NetworkLogger(
        config: const NetworkLogConfig(enabled: true),
        printer: lines.add,
      );
      final req = request();
      logger.logRequest(req);
      final output = lines.single;

      expect(output, contains('[REDACTED]'));
      expect(output, isNot(contains('Bearer private')));
      expect(output, isNot(contains('secret')));
      expect(output, contains('Multipart'));
      expect(logger.curlCommand(req), contains("'upload=@image.png'"));
      expect(logger.curlCommand(req), isNot(contains('Bearer private')));
    },
  );

  test('logs dynamic response colors, duration, slow calls and truncation', () {
    final lines = <String>[];
    final logger = NetworkLogger(
      config: const NetworkLogConfig(enabled: true, maxBodyLength: 12),
      printer: lines.add,
    );
    final req = request(body: 'request');
    logger.logResponse(
      NetworkResponseLog(
        request: req,
        statusCode: 503,
        body: 'a very long response body',
      ),
    );

    expect(lines.single, contains('\x1B[31m'));
    expect(lines.single, contains('SLOW REQUEST'));
    expect(lines.single, contains('[truncated'));
    expect(lines.single, contains('6000ms'));
  });

  test('disabled logging and a throwing printer never escape', () {
    final lines = <String>[];
    final disabled = NetworkLogger(
      config: const NetworkLogConfig(enabled: false),
      printer: lines.add,
    );
    disabled.logRequest(request());
    expect(lines, isEmpty);

    final enabled = NetworkLogger(
      config: const NetworkLogConfig(enabled: true),
      printer: (_) => throw StateError('printer failed'),
    );
    expect(() => enabled.logRequest(request(disabled: true)), returnsNormally);
    expect(
      () => enabled.logResponse(
        NetworkResponseLog(request: request(), statusCode: 200),
      ),
      returnsNormally,
    );
    expect(
      () => enabled.logError(
        NetworkErrorLog(request: request(), error: Exception('failed')),
      ),
      returnsNormally,
    );
  });

  test('body logging can be disabled independently', () {
    final lines = <String>[];
    final logger = NetworkLogger(
      config: const NetworkLogConfig(
        enabled: true,
        logRequestBody: false,
        logCurlCommand: false,
      ),
      printer: lines.add,
    );
    logger.logRequest(request());
    expect(lines.single, isNot(contains('secret')));
    expect(lines.single, isNot(contains('Body:')));
  });
}
