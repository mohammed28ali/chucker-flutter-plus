import 'package:chucker_flutter_plus/chucker_flutter_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redacts sensitive headers and nested JSON keys', () {
    final redactor = LogRedactor();
    expect(
      redactor.headers({'Authorization': 'secret'})['Authorization'],
      '[REDACTED]',
    );
    expect(redactor.body('{"user":{"password":"secret"},"ok":true}'), {
      'user': {'password': '[REDACTED]'},
      'ok': true,
    });
  });

  test('logs request, cURL, response status color, and slow threshold', () {
    final output = <String>[];
    final logger = NetworkLogger(
      config: const NetworkLogConfig(
        slowRequestThreshold: Duration(milliseconds: 1),
      ),
      printer: output.add,
    );
    final request = NetworkRequestLog(
      method: 'POST',
      url: Uri.parse('https://example.test/items'),
      headers: const {'Authorization': 'secret'},
      body: const {'password': 'secret'},
    );
    logger.logRequest(request);
    logger.logResponse(
      request,
      const NetworkResponseLog(statusCode: 503, body: 'oops'),
      const Duration(seconds: 2),
    );
    expect(output.first, contains('curl -X'));
    expect(output.first, isNot(contains('secret')));
    expect(output.last, contains('SLOW REQUEST'));
    expect(output.last, contains('\x1B[31m'));
  });

  test('truncates bodies and suppresses disabled requests', () {
    final output = <String>[];
    final logger = NetworkLogger(
      config: const NetworkLogConfig(maxBodyLength: 5, logCurlCommand: false),
      printer: output.add,
    );
    logger.logRequest(
      NetworkRequestLog(
        method: 'POST',
        url: Uri.parse('https://example.test'),
        body: 'abcdefgh',
      ),
    );
    logger.logRequest(
      NetworkRequestLog(
        method: 'GET',
        url: Uri.parse('https://example.test'),
        enabled: false,
      ),
    );
    expect(output, hasLength(1));
    expect(output.single, contains('[truncated'));
  });

  test('printer exceptions never escape', () {
    final logger = NetworkLogger(
      printer: (_) => throw StateError('printer failure'),
    );
    expect(
      () => logger.logRequest(
        NetworkRequestLog(
          method: 'GET',
          url: Uri.parse('https://example.test'),
        ),
      ),
      returnsNormally,
    );
  });
}
