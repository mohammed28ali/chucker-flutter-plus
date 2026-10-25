import '../entities/network_transaction.dart';
import '../repositories/network_transaction_repository.dart';

class RecordNetworkTransaction {
  const RecordNetworkTransaction(this._repository);

  final NetworkTransactionRepository _repository;

  Future<void> call(NetworkTransaction transaction) =>
      _repository.save(transaction);
}
