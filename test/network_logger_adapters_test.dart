import 'dart:async';
import 'dart:typed_data';

import 'package:chopper/chopper.dart' as chopper;
import 'package:chucker_flutter_plus/chopper_network_logger.dart';
import 'package:chucker_flutter_plus/dio_network_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'Dio interceptor normalizes a response through a fake adapter',
    () async {
      final lines = <String>[];
      final dio = Dio()
        ..httpClientAdapter = _FakeDioAdapter()
        ..interceptors.add(
          DioNetworkLoggerInterceptor(
            logger: NetworkLogger(
              config: const NetworkLogConfig(enabled: true),
              printer: lines.add,
            ),
          ),
        );
      await dio.get<Map<String, dynamic>>('https://example.test/value');
      expect(lines, hasLength(2));
      expect(lines.first, contains('GET'));
      expect(lines.last, contains('200'));
      dio.close();
    },
  );

  test('Chopper interceptor normalizes response data', () async {
    final lines = <String>[];
    final logger = NetworkLogger(
      config: const NetworkLogConfig(enabled: true),
      printer: lines.add,
    );
    final interceptor = ChopperNetworkLoggerInterceptor(logger: logger);
    final request = chopper.Request(
      'GET',
      Uri.parse('/value'),
      Uri.parse('https://example.test'),
    );
    final response = chopper.Response<Map<String, Object?>>(
      http.Response('ignored', 200),
      const {'ok': true},
    );
    final result = await interceptor.intercept<Map<String, Object?>>(
      _FakeChain(request, response),
    );
    expect(result.statusCode, 200);
    expect(lines, hasLength(2));
    expect(lines.first, contains('GET'));
    expect(lines.last, contains('200'));
  });
}

class _FakeDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"ok":true}',
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

class _FakeChain<T> implements chopper.Chain<T> {
  _FakeChain(this.request, this.response);
  @override
  final chopper.Request request;
  final chopper.Response<T> response;

  @override
  FutureOr<chopper.Response<T>> proceed(chopper.Request request) async =>
      response;
}
