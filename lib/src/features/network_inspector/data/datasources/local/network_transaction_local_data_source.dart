import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/network_transaction_model.dart';
import 'chucker_hive.dart';

/// Package-owned lazy Hive box. It never closes or clears global Hive state.
class NetworkTransactionLocalDataSource {
  NetworkTransactionLocalDataSource({
    this.typeId = 30001,
    this.maximumBodyBytes = 1024 * 1024,
    this.encryptionKey,
    this.initializeHive,
  });
  static const boxName = 'chucker_flutter_plus_requests';
  final int typeId;
  final int maximumBodyBytes;
  final List<int>? encryptionKey;
  final Future<void> Function()? initializeHive;
  LazyBox<NetworkTransactionModel>? _box;

  Future<LazyBox<NetworkTransactionModel>> get _open async {
    if (!ChuckerHive.initialized) {
      if (initializeHive != null) {
        await initializeHive!();
      } else {
        await ChuckerHive.initialize();
      }
      ChuckerHive.markInitialized();
    }
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter(_RequestLogAdapter(typeId));
    }
    return _box ??= await Hive.openLazyBox<NetworkTransactionModel>(
      boxName,
      encryptionCipher: encryptionKey == null
          ? null
          : HiveAesCipher(Uint8List.fromList(encryptionKey!)),
    );
  }

  Future<List<NetworkTransactionModel>> readAll() async {
    final box = await _open;
    final values = await Future.wait(box.keys.map((key) => box.get(key)));
    return values.whereType<NetworkTransactionModel>().toList();
  }

  Future<void> writeAll(List<NetworkTransactionModel> transactions) async {
    final box = await _open;
    await box.clear();
    for (final transaction in transactions) {
      await box.put(transaction.id, _truncate(transaction));
    }
  }

  Future<void> clear() async => (await _open).clear();
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  NetworkTransactionModel _truncate(NetworkTransactionModel value) {
    if ((value.contentType?.startsWith('image/') ?? false) ||
        (value.contentType?.startsWith('video/') ?? false)) {
      return NetworkTransactionModel.fromJson({
        ...value.toJson(),
        'rawResponseBody': null,
        'responseBodyTruncated': true,
      });
    }
    final request = _cap(value.rawRequestBody);
    final response = _cap(value.rawResponseBody);
    return NetworkTransactionModel.fromJson({
      ...value.toJson(),
      'rawRequestBody': request.$1,
      'rawResponseBody': response.$1,
      'requestBodyTruncated': request.$2,
      'responseBodyTruncated': response.$2,
    });
  }

  (String?, bool) _cap(String? value) {
    if (value == null || utf8.encode(value).length <= maximumBodyBytes) {
      return (value, false);
    }
    return (value.substring(0, value.length.clamp(0, maximumBodyBytes)), true);
  }
}

class _RequestLogAdapter extends TypeAdapter<NetworkTransactionModel> {
  const _RequestLogAdapter(this.typeId);
  @override
  final int typeId;
  @override
  NetworkTransactionModel read(BinaryReader reader) =>
      NetworkTransactionModel.fromJson(
        (reader.read() as Map).cast<String, Object?>(),
      );
  @override
  void write(BinaryWriter writer, NetworkTransactionModel value) =>
      writer.write(value.toJson());
}
