import 'package:chucker_flutter_plus/src/features/network_inspector/presentation/chucker_flutter.dart';
import 'package:chucker_flutter_plus/src/features/network_inspector/presentation/inspector_config.dart';
import 'package:chucker_flutter_plus/src/features/network_inspector/presentation/inspector_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NotificationDelivery delivery(
    bool foreground, {
    required bool banner,
    required bool status,
  }) => ChuckerFlutterPlus.notificationDelivery(
    isForeground: foreground,
    settings: InspectorSettings(
      inAppBanner: banner,
      systemNotifications: status,
    ),
  );
  test('both enabled uses in-app foreground and status bar background', () {
    expect(
      delivery(true, banner: true, status: true),
      NotificationDelivery.inApp,
    );
    expect(
      delivery(false, banner: true, status: true),
      NotificationDelivery.statusBar,
    );
  });
  test('in-app only is silent in background', () {
    expect(
      delivery(true, banner: true, status: false),
      NotificationDelivery.inApp,
    );
    expect(
      delivery(false, banner: true, status: false),
      NotificationDelivery.none,
    );
  });
  test('status bar only works in every state', () {
    const settings = InspectorSettings(
      inAppBanner: false,
      systemNotifications: true,
    );
    expect(
      ChuckerFlutterPlus.notificationDelivery(
        isForeground: true,
        settings: settings,
      ),
      NotificationDelivery.statusBar,
    );
    expect(
      ChuckerFlutterPlus.notificationDelivery(
        isForeground: false,
        settings: settings,
      ),
      NotificationDelivery.statusBar,
    );
  });
  test('both disabled is silent', () {
    expect(
      delivery(true, banner: false, status: false),
      NotificationDelivery.none,
    );
    expect(
      delivery(false, banner: false, status: false),
      NotificationDelivery.none,
    );
  });
}
