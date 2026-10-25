import '../entities/network_transaction.dart';

abstract interface class NetworkTransactionRepository {
  Future<List<NetworkTransaction>> getAll();

  Future<void> save(NetworkTransaction transaction);

  Future<void> clear();
}
