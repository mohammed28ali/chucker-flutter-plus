import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../config/dependency_injection/chucker_dependencies.dart';
import '../domain/entities/network_transaction.dart';
import '../infrastructure/body_capture.dart';
import '../infrastructure/notifications/chucker_notification_service.dart';
import 'pages/network_inspector_page.dart';

/// Configuration and host-safe presentation entry point for the inspector.
class ChuckerFlutterPlus {
  ChuckerFlutterPlus._();
  static bool showOnRelease = false;
  static bool showNotification = false;
  static String notificationChannelName = 'Network inspector';
  static Set<String> sensitiveHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
  };
  static ChuckerDependencies _dependencies = ChuckerDependencies.create();
  static OverlayEntry? _entry;
  static ChuckerNotificationService? _notifications;
  static bool get isEnabled => kDebugMode || showOnRelease;

  /// [navigatorKey] is only consulted to locate the host overlay. It is never
  /// registered with, or used to navigate, the host app.
  static Future<void> initialize({
    int maximumEntries = 100,
    Duration? retention,
    bool? enableOnRelease,
    bool enableNotifications = false,
    String notificationChannelName = 'Network inspector',
    String notificationIcon = '@drawable/ic_launcher',
    Set<String> redactHeaders = const {'authorization', 'cookie', 'set-cookie'},
    GlobalKey<NavigatorState>? navigatorKey,
    void Function(String? payload)? onUnrecognizedNotificationPayload,
  }) async {
    configure(
      maximumEntries: maximumEntries,
      retention: retention,
      enableOnRelease: enableOnRelease,
      redactHeaders: redactHeaders,
    );
    showNotification = enableNotifications;
    ChuckerFlutterPlus.notificationChannelName = notificationChannelName;
    if (enableNotifications) {
      _notifications = ChuckerNotificationService(
        onRequestSelected: (id) {
          final context = navigatorKey?.currentContext;
          if (context != null) showInspector(context, requestId: id);
        },
        onUnrecognizedPayload: onUnrecognizedNotificationPayload,
      );
      await _notifications!.initialize(
        channelName: notificationChannelName,
        icon: notificationIcon,
      );
    }
  }

  static void configure({
    int maximumEntries = 100,
    Duration? retention,
    bool? enableOnRelease,
    Set<String>? redactHeaders,
  }) {
    if (maximumEntries < 0)
      throw ArgumentError.value(
        maximumEntries,
        'maximumEntries',
        'Must not be negative.',
      );
    showOnRelease = enableOnRelease ?? showOnRelease;
    sensitiveHeaders = (redactHeaders ?? sensitiveHeaders)
        .map((e) => e.toLowerCase())
        .toSet();
    _dependencies = ChuckerDependencies.create(
      maximumEntries: maximumEntries,
      retention: retention,
    );
  }

  static Map<String, String> redactHeaders(Map<String, String> headers) =>
      BodyCapture.redact(headers, sensitiveHeaders);

  /// Opens an isolated Navigator in an OverlayEntry and leaves host routes alone.
  static void showInspector(BuildContext context, {String? requestId}) {
    if (!isEnabled || _entry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null)
      throw StateError('showInspector requires a context below an Overlay.');
    _entry = OverlayEntry(
      builder: (_) => Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => NetworkInspectorPage(
                dependencies: _dependencies,
                initiallySelectedId: requestId,
                onClose: hideInspector,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  static void hideInspector() {
    _entry?.remove();
    _entry = null;
  }

  static Widget button({Key? key}) => Builder(
    builder: (context) => IconButton(
      key: key,
      tooltip: 'Network inspector',
      icon: const Icon(Icons.network_check),
      onPressed: isEnabled ? () => showInspector(context) : null,
    ),
  );

  static Future<void> record(NetworkTransaction transaction) async {
    if (!isEnabled) return;
    await _dependencies.recordTransaction(transaction);
    if (showNotification)
      await _notifications?.show(
        transaction,
        channelName: notificationChannelName,
      );
  }
}
