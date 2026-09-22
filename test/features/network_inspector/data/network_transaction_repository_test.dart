import 'package:chucker_flutter_plus/src/features/network_inspector/data/datasources/local/network_transaction_local_data_source.dart';
import 'package:chucker_flutter_plus/src/features/network_inspector/data/repositories/network_transaction_repository_impl.dart';
import 'package:chucker_flutter_plus/src/features/network_inspector/domain/entities/network_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  NetworkTransaction transaction(String id, DateTime startedAt) =>
      NetworkTransaction(
        id: id,
        startedAt: startedAt,
        completedAt: startedAt.add(const Duration(milliseconds: 10)),
        method: 'GET',
        uri: Uri.parse('https://example.com/$id'),
        statusCode: 200,
        requestHeaders: const {'accept': 'application/json'},
        responseHeaders: const {'content-type': 'application/json'},
        responseBody: const {'ok': true},
      );

  test('keeps the newest records within its configured capacity', () async {
    final repository = NetworkTransactionRepositoryImpl(
      NetworkTransactionLocalDataSource(),
      maximumEntries: 2,
    );
    final first = DateTime.utc(2025);

    await repository.save(transaction('one', first));
    await repository.save(
      transaction('two', first.add(const Duration(seconds: 1))),
    );
    await repository.save(
      transaction('three', first.add(const Duration(seconds: 2))),
    );

    final records = await repository.getAll();

    expect(records.map((record) => record.id), ['three', 'two']);
  });

  test('clears persisted records', () async {
    final repository = NetworkTransactionRepositoryImpl(
      NetworkTransactionLocalDataSource(),
    );
    await repository.save(transaction('one', DateTime.utc(2025)));

    await repository.clear();

    expect(await repository.getAll(), isEmpty);
  });
}
