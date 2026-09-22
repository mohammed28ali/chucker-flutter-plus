import '../entities/network_transaction.dart';

/// Persists and retrieves inspected network traffic.
abstract interface class NetworkTransactionRepository {
  Future<List<NetworkTransaction>> getAll();

  Future<void> save(NetworkTransaction transaction);

  Future<void> clear();
}
