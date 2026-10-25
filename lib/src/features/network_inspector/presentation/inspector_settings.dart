import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../data/datasources/local/chucker_hive.dart';

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
  static const _boxName = 'chucker_flutter_plus_settings';
  Box<Map>? _box;
  Future<Box<Map>> get _open async {
    await ChuckerHive.initialize();
    return _box ??= await Hive.openBox<Map>(_boxName);
  }

  Future<void> load() async {
    final p = (await _open).get('settings') ?? const <String, dynamic>{};
    value = InspectorSettings(
      inAppBanner: p['banner'] as bool? ?? true,
      systemNotifications: p['system'] as bool? ?? true,
      statusBarWhileForeground: p['statusForeground'] as bool? ?? false,
      onlyErrors: p['errors'] as bool? ?? false,
      bannerDuration: Duration(milliseconds: p['duration'] as int? ?? 3000),
      bannerPosition: (p['position'] as String? ?? 'top') == 'bottom'
          ? BannerPosition.bottom
          : BannerPosition.top,
      maximumEntries: p['max'] as int? ?? 100,
    );
  }

  Future<void> save(InspectorSettings next) async {
    value = next;
    await (await _open).put('settings', <String, dynamic>{
      'schemaVersion': 1,
      'banner': next.inAppBanner,
      'system': next.systemNotifications,
      'statusForeground': next.statusBarWhileForeground,
      'errors': next.onlyErrors,
      'duration': next.bannerDuration.inMilliseconds,
      'position': next.bannerPosition.name,
      'max': next.maximumEntries,
    });
  }
}
