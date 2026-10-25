import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/network_transaction.dart';

class ChuckerNotificationService {
  ChuckerNotificationService({
    this.onRequestSelected,
    this.onUnrecognizedPayload,
  });

  static const _channelId = 'chucker_network';
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final void Function(String requestId)? onRequestSelected;
  final void Function(String? payload)? onUnrecognizedPayload;
  int _count = 0;
  int _ok = 0;
  int _failed = 0;

  Future<void> initialize({
    String channelName = 'Network inspector',
    String icon = '@drawable/chucker_icon',
  }) async {
    await _plugin.initialize(
      settings: InitializationSettings(
        android: AndroidInitializationSettings(icon),
        iOS: const DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) => _route(response.payload),
    );
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _route(details?.notificationResponse?.payload);
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> show(
    NetworkTransaction transaction, {
    String channelName = 'Network inspector',
  }) async {
    _count++;
    transaction.succeeded ? _ok++ : _failed++;
    final text = '$_count requests: $_ok OK, $_failed failed';
    await _plugin.show(
      id: 7101,
      title: 'Network activity',
      body: text,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          channelName,
          channelDescription: 'Captured network requests',
          groupKey: _channelId,
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'chucker:${transaction.id}',
    );
  }

  void _route(String? payload) {
    if (payload?.startsWith('chucker:') ?? false) {
      onRequestSelected?.call(payload!.substring('chucker:'.length));
    } else {
      onUnrecognizedPayload?.call(payload);
    }
  }
}
