import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BannerPosition { top, bottom }

class InspectorSettings {
  const InspectorSettings({
    this.inAppBanner = true,
    this.systemNotifications = true,
    this.statusBarWhileForeground = false,
    this.bannerDuration = const Duration(seconds: 3),
    this.bannerPosition = BannerPosition.top,
    this.onlyErrors = false,
    this.maximumEntries = 100,
  });
  final bool inAppBanner,
      systemNotifications,
      statusBarWhileForeground,
      onlyErrors;
  final Duration bannerDuration;
  final BannerPosition bannerPosition;
  final int maximumEntries;
  InspectorSettings copyWith({
    bool? inAppBanner,
    bool? systemNotifications,
    bool? statusBarWhileForeground,
    Duration? bannerDuration,
    BannerPosition? bannerPosition,
    bool? onlyErrors,
    int? maximumEntries,
  }) => InspectorSettings(
    inAppBanner: inAppBanner ?? this.inAppBanner,
    systemNotifications: systemNotifications ?? this.systemNotifications,
    statusBarWhileForeground:
        statusBarWhileForeground ?? this.statusBarWhileForeground,
    bannerDuration: bannerDuration ?? this.bannerDuration,
    bannerPosition: bannerPosition ?? this.bannerPosition,
    onlyErrors: onlyErrors ?? this.onlyErrors,
    maximumEntries: maximumEntries ?? this.maximumEntries,
  );
}

class InspectorSettingsStore extends ValueNotifier<InspectorSettings> {
  InspectorSettingsStore() : super(const InspectorSettings());
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    value = InspectorSettings(
      inAppBanner: p.getBool('banner') ?? true,
      systemNotifications: p.getBool('system') ?? true,
      statusBarWhileForeground: p.getBool('statusForeground') ?? false,
      onlyErrors: p.getBool('errors') ?? false,
      bannerDuration: Duration(milliseconds: p.getInt('duration') ?? 3000),
      bannerPosition: (p.getString('position') ?? 'top') == 'bottom'
          ? BannerPosition.bottom
          : BannerPosition.top,
      maximumEntries: p.getInt('max') ?? 100,
    );
  }

  Future<void> save(InspectorSettings next) async {
    value = next;
    final p = await SharedPreferences.getInstance();
    await p.setBool('banner', next.inAppBanner);
    await p.setBool('system', next.systemNotifications);
    await p.setBool('statusForeground', next.statusBarWhileForeground);
    await p.setBool('errors', next.onlyErrors);
    await p.setInt('duration', next.bannerDuration.inMilliseconds);
    await p.setString('position', next.bannerPosition.name);
    await p.setInt('max', next.maximumEntries);
  }
}
