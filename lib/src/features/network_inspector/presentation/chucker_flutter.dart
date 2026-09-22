import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../config/dependency_injection/chucker_dependencies.dart';
import '../domain/entities/network_transaction.dart';
import 'pages/network_inspector_page.dart';

/// Configures and opens the in-app network inspector.
class ChuckerFlutterPlus {
  ChuckerFlutterPlus._();

  /// Attach this key to the host application's root [MaterialApp].
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Enables recording outside debug builds. Keep this disabled in production
  /// unless the captured traffic has been reviewed for sensitive data.
  static bool showOnRelease = false;

  /// Controls whether an in-app status message is shown after a transaction.
  static bool showNotification = true;

  static ChuckerDependencies _dependencies = ChuckerDependencies.create();

  static bool get isEnabled => kDebugMode || showOnRelease;

  /// Replaces the default local store configuration.
  ///
  /// Call before creating interceptors or making requests.
  static void configure({int maximumEntries = 100, bool? enableOnRelease}) {
    if (maximumEntries < 0) {
      throw ArgumentError.value(
        maximumEntries,
        'maximumEntries',
        'Must not be negative.',
      );
    }
    showOnRelease = enableOnRelease ?? showOnRelease;
    _dependencies = ChuckerDependencies.create(maximumEntries: maximumEntries);
  }

  /// Opens the inspector route using [navigatorKey].
  static Future<void> showChuckerScreen() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw StateError(
        'Attach ChuckerFlutterPlus.navigatorKey to the root MaterialApp before opening the inspector.',
      );
    }
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NetworkInspectorPage(dependencies: _dependencies),
      ),
    );
  }

  /// A small button suitable for placing in a debug-only app bar or drawer.
  static Widget button({Key? key}) => IconButton(
    key: key,
    tooltip: 'Network inspector',
    icon: const Icon(Icons.network_check),
    onPressed: isEnabled ? showChuckerScreen : null,
  );

  static Future<void> record(NetworkTransaction transaction) async {
    if (!isEnabled) return;
    await _dependencies.recordTransaction(transaction);
    if (showNotification) _showStatus(transaction);
  }

  static void _showStatus(NetworkTransaction transaction) {
    final messenger = navigatorKey.currentState?.context.mounted == true
        ? ScaffoldMessenger.maybeOf(navigatorKey.currentState!.context)
        : null;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          '${transaction.method} ${transaction.uri.path} · ${transaction.statusCode ?? 'error'}',
        ),
        action: SnackBarAction(label: 'Details', onPressed: showChuckerScreen),
      ),
    );
  }
}
