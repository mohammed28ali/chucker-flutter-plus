import 'package:chucker_flutter_plus/src/config/theme/inspector_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:convert';

import '../../../config/dependency_injection/chucker_dependencies.dart';
import '../../../core/routes/routes.dart';
import '../domain/entities/network_transaction.dart';
import '../infrastructure/body_capture.dart';
import '../infrastructure/notifications/chucker_notification_service.dart';
import 'inspector_settings.dart';
import 'inspector_config.dart';
import 'request_banner.dart';

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
  static ChuckerDependencies get dependencies => _dependencies;
  static OverlayEntry? _entry;
  static ChuckerNotificationService? _notifications;
  static final settings = InspectorSettingsStore();
  static final _banner = RequestBannerController();
  static bool get isEnabled => kDebugMode || showOnRelease;

  static NotificationDelivery notificationDelivery({
    required bool isForeground,
    required InspectorSettings settings,
  }) {
    if (isForeground && settings.inAppBanner) return NotificationDelivery.inApp;
    if (settings.systemNotifications &&
        (!isForeground ||
            !settings.inAppBanner ||
            settings.statusBarWhileForeground)) {
      return NotificationDelivery.statusBar;
    }
    return NotificationDelivery.none;
  }

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
    await settings.load();
    configure(
      maximumEntries: settings.value.maximumEntries,
      retention: retention,
      enableOnRelease: enableOnRelease,
      redactHeaders: redactHeaders,
    );
    if (navigatorKey?.currentContext case final context? when context.mounted) {
      _banner.bind(context);
    }
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
    if (maximumEntries < 0) {
      throw ArgumentError.value(
        maximumEntries,
        'maximumEntries',
        'Must not be negative.',
      );
    }
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

  static void showInspector(BuildContext context, {String? requestId}) {
    if (!isEnabled || _entry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      throw StateError('showInspector requires a context below an Overlay.');
    }
    _banner.bind(context);
    // Capture system brightness at show-time; the inspector has its own theme.
    final brightness =
        MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light;
    _entry = OverlayEntry(
      builder: (_) => _IsolatedInspector(
        brightness: brightness,
        dependencies: _dependencies,
        requestId: requestId,
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
    final foreground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    final canShow = !settings.value.onlyErrors || !transaction.succeeded;
    final delivery = notificationDelivery(
      isForeground: foreground,
      settings: settings.value,
    );
    if (delivery == NotificationDelivery.inApp && canShow) {
      _banner.show(transaction, settings.value, () {
        _banner.dismiss();
        final context = _banner.context;
        if (context != null) showInspector(context, requestId: transaction.id);
      });
    }
    if (delivery == NotificationDelivery.statusBar &&
        showNotification &&
        canShow) {
      await _notifications?.show(
        transaction,
        channelName: notificationChannelName,
      );
    }
  }

  static Future<void> clearLogs() => _dependencies.transactions.clear();
  static Future<String> exportLogs() async => jsonEncode(
    (await _dependencies.transactions.getAll())
        .map(
          (t) => {
            'id': t.id,
            'method': t.method,
            'url': t.uri.toString(),
            'statusCode': t.statusCode,
            'timestamp': t.startedAt.toIso8601String(),
            'durationMs': t.duration.inMilliseconds,
            'requestHeaders': t.requestHeaders,
            'responseHeaders': t.responseHeaders,
            'requestBody': t.rawRequestBody,
            'responseBody': t.rawResponseBody,
            'error': t.error,
          },
        )
        .toList(),
  );
  static Future<void> dispose() async {
    hideInspector();
    await _dependencies.transactions.dispose();
  }
}

/// Concise public facade for configuration-object based setup.
class Inspector {
  Inspector._();
  static Future<void> init({
    required InspectorConfig config,
    GlobalKey<NavigatorState>? navigatorKey,
    void Function(String? payload)? onUnrecognizedNotificationPayload,
  }) async {
    await ChuckerFlutterPlus.initialize(
      maximumEntries: config.maximumEntries,
      enableNotifications: config.showStatusBarNotification,
      notificationIcon: config.statusBarIcon,
      navigatorKey: navigatorKey,
      onUnrecognizedNotificationPayload: onUnrecognizedNotificationPayload,
    );
    await updateConfig(config);
  }

  static Future<void> updateConfig(InspectorConfig config) async {
    if (config.showStatusBarNotification &&
        ChuckerFlutterPlus._notifications == null) {
      await ChuckerFlutterPlus.initialize(
        maximumEntries: config.maximumEntries,
        enableNotifications: true,
        notificationIcon: config.statusBarIcon,
      );
    }
    await ChuckerFlutterPlus.settings.save(
      InspectorSettings(
        inAppBanner: config.showInAppNotification,
        systemNotifications: config.showStatusBarNotification,
        statusBarWhileForeground: config.statusBarWhileForeground,
        bannerDuration: config.inAppNotificationDuration,
        bannerPosition: config.inAppNotificationPosition,
        onlyErrors: config.notifyOnlyOnError,
        maximumEntries: config.maximumEntries,
      ),
    );
    ChuckerFlutterPlus.showNotification = config.showStatusBarNotification;
    ChuckerFlutterPlus.configure(maximumEntries: config.maximumEntries);
  }

  static Future<void> clearLogs() => ChuckerFlutterPlus.clearLogs();
  static Future<String> exportLogs() => ChuckerFlutterPlus.exportLogs();
  static Future<void> dispose() => ChuckerFlutterPlus.dispose();
}

/// A self-contained overlay widget that provides an isolated Material 3 theme
/// so the inspector never inherits or modifies the host app's theme.
class _IsolatedInspector extends StatefulWidget {
  const _IsolatedInspector({
    required this.brightness,
    required this.dependencies,
    this.requestId,
  });
  final Brightness brightness;
  final ChuckerDependencies dependencies;
  final String? requestId;

  @override
  State<_IsolatedInspector> createState() => _IsolatedInspectorState();
}

class _IsolatedInspectorState extends State<_IsolatedInspector> {
  late Brightness _brightness;

  @override
  void initState() {
    super.initState();
    _brightness = widget.brightness;
  }

  @override
  Widget build(BuildContext context) {
    // Re-read system brightness so a toggle in Settings works immediately
    final theme = _brightness == Brightness.dark
        ? InspectorTheme.dark()
        : InspectorTheme.light();
    return Theme(
      data: theme,
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Navigator(
            onGenerateRoute: (routeSettings) => AppRoutes.onGenerateRoute(
              routeSettings,
              dependencies: widget.dependencies,
              initialRequestId: widget.requestId,
              onClose: ChuckerFlutterPlus.hideInspector,
            ),
          ),
        ),
      ),
    );
  }
}
