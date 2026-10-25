import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/network_transaction_model.dart';

class NetworkTransactionLocalDataSource {
  static const _storageKey = 'chucker_flutter_plus.transactions.v1';

  Future<List<NetworkTransactionModel>> readAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null) return const [];

    final decoded = jsonDecode(raw) as List<Object?>;
    return decoded
        .cast<Map<Object?, Object?>>()
        .map(
          (item) =>
              NetworkTransactionModel.fromJson(item.cast<String, Object?>()),
        )
        .toList(growable: false);
  }

  Future<void> writeAll(List<NetworkTransactionModel> transactions) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(
        transactions.map((transaction) => transaction.toJson()).toList(),
      ),
    );
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
