import '../../features/network_inspector/data/datasources/local/network_transaction_local_data_source.dart';
import '../../features/network_inspector/data/repositories/network_transaction_repository_impl.dart';
import '../../features/network_inspector/domain/repositories/network_transaction_repository.dart';
import '../../features/network_inspector/domain/usecases/record_network_transaction.dart';

/// Composition root for the network-inspector feature.
class ChuckerDependencies {
  ChuckerDependencies({
    required this.transactions,
    required this.recordTransaction,
  });

  factory ChuckerDependencies.create({int maximumEntries = 100}) {
    final repository = NetworkTransactionRepositoryImpl(
      NetworkTransactionLocalDataSource(),
      maximumEntries: maximumEntries,
    );
    return ChuckerDependencies(
      transactions: repository,
      recordTransaction: RecordNetworkTransaction(repository),
    );
  }

  final NetworkTransactionRepository transactions;
  final RecordNetworkTransaction recordTransaction;
}
