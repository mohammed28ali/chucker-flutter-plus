import 'inspector_settings.dart';

/// Notification and capture options for [Inspector.init].
class InspectorConfig {
  const InspectorConfig({
    this.showInAppNotification = true,
    this.showStatusBarNotification = true,
    this.statusBarWhileForeground = false,
    this.inAppNotificationDuration = const Duration(seconds: 3),
    this.inAppNotificationPosition = BannerPosition.top,
    this.notifyOnlyOnError = false,
    this.statusBarIcon = '@drawable/chucker_icon',
    this.maximumEntries = 100,
  });
  final bool showInAppNotification;
  final bool showStatusBarNotification;
  final bool statusBarWhileForeground;
  final Duration inAppNotificationDuration;
  final BannerPosition inAppNotificationPosition;
  final bool notifyOnlyOnError;
  final String statusBarIcon;
  final int maximumEntries;

  InspectorConfig copyWith({
    bool? showInAppNotification,
    bool? showStatusBarNotification,
    bool? statusBarWhileForeground,
    Duration? inAppNotificationDuration,
    BannerPosition? inAppNotificationPosition,
    bool? notifyOnlyOnError,
    String? statusBarIcon,
    int? maximumEntries,
  }) => InspectorConfig(
    showInAppNotification: showInAppNotification ?? this.showInAppNotification,
    showStatusBarNotification:
        showStatusBarNotification ?? this.showStatusBarNotification,
    statusBarWhileForeground:
        statusBarWhileForeground ?? this.statusBarWhileForeground,
    inAppNotificationDuration:
        inAppNotificationDuration ?? this.inAppNotificationDuration,
    inAppNotificationPosition:
        inAppNotificationPosition ?? this.inAppNotificationPosition,
    notifyOnlyOnError: notifyOnlyOnError ?? this.notifyOnlyOnError,
    statusBarIcon: statusBarIcon ?? this.statusBarIcon,
    maximumEntries: maximumEntries ?? this.maximumEntries,
  );
}

enum NotificationDelivery { none, inApp, statusBar }
