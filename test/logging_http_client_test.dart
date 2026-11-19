import 'dart:convert';

import 'package:chucker_flutter_plus/http_network_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'tees streamed responses and logs after their bytes are consumed',
    () async {
      final messages = <String>[];
      final client = LoggingHttpClient(
        inner: _FakeClient(),
        logger: NetworkLogger(
          config: const NetworkLogConfig(enabled: true),
          printer: messages.add,
        ),
      );
      final response = await client.send(
        http.Request('GET', Uri.parse('https://example.test')),
      );
      expect(messages, hasLength(1)); // request line
      final responseBytes = await response.stream.toBytes();

      expect(utf8.decode(responseBytes), '{"ok":true}');
      expect(messages, hasLength(2));
      expect(messages.last, contains('200'));
      expect(messages.last, contains('"ok": true'));
      client.close();
    },
  );

  test(
    'per request marker is removed before forwarding and disables logs',
    () async {
      final fake = _FakeClient();
      final messages = <String>[];
      final client = LoggingHttpClient(
        inner: fake,
        logger: NetworkLogger(
          config: const NetworkLogConfig(enabled: true),
          printer: messages.add,
        ),
      );
      final request = http.Request('GET', Uri.parse('https://example.test'))
        ..headers[LoggingHttpClient.disableLoggingHeader] = 'true';
      final response = await client.send(request);
      await response.stream.drain<void>();

      expect(
        fake.lastHeaders,
        isNot(contains(LoggingHttpClient.disableLoggingHeader)),
      );
      expect(messages, isEmpty);
      client.close();
    },
  );
}

class _FakeClient extends http.BaseClient {
  Map<String, String>? lastHeaders;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastHeaders = Map.of(request.headers);
    final chunks = Stream<List<int>>.fromIterable([
      utf8.encode('{"ok":'),
      utf8.encode('true}'),
    ]);
    return http.StreamedResponse(
      chunks,
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}
