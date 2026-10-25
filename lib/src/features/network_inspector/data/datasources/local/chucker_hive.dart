import 'package:hive_ce_flutter/hive_flutter.dart';

class ChuckerHive {
  static bool _initialized = false;
  static bool get initialized => _initialized;
  static void markInitialized() => _initialized = true;
  static Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter('chucker_flutter_plus_hive');
    _initialized = true;
  }
}
