import '../../domain/entities/network_transaction.dart';
import '../../domain/repositories/network_transaction_repository.dart';
import '../datasources/local/network_transaction_local_data_source.dart';
import '../models/network_transaction_model.dart';

/// Local-persistence implementation of [NetworkTransactionRepository].
class NetworkTransactionRepositoryImpl implements NetworkTransactionRepository {
  NetworkTransactionRepositoryImpl(
    this._localDataSource, {
    this.maximumEntries = 100,
    this.retention,
  });

  final NetworkTransactionLocalDataSource _localDataSource;
  final int maximumEntries;
  final Duration? retention;

  @override
  Future<List<NetworkTransaction>> getAll() async {
    final transactions = (await _localDataSource.readAll()).toList();
    transactions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return _prune(transactions);
  }

  @override
  Future<void> save(NetworkTransaction transaction) async {
    if (maximumEntries <= 0) return;
    final transactions = (await _localDataSource.readAll()).toList();
    transactions.add(NetworkTransactionModel.fromEntity(transaction));
    transactions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    await _localDataSource.writeAll(
      _prune(transactions).take(maximumEntries).toList(),
    );
  }

  @override
  Future<void> clear() => _localDataSource.clear();

  List<NetworkTransactionModel> _prune(List<NetworkTransactionModel> values) {
    final limit = retention;
    if (limit == null) return values;
    final cutoff = DateTime.now().subtract(limit);
    return values.where((value) => !value.startedAt.isBefore(cutoff)).toList();
  }
}
