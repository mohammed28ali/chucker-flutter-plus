import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../chucker_flutter.dart';
import '../inspector_settings.dart';

/// Settings page for the network inspector — fully isolated from host app.
class InspectorSettingsPage extends StatelessWidget {
  const InspectorSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.inspectorSettingsTitle)),
      body: ValueListenableBuilder<InspectorSettings>(
        valueListenable: ChuckerFlutterPlus.settings,
        builder: (context, s, _) => ListView(
          children: [
            // ── Notifications ────────────────────────────────────────────────
            const _SectionHeader(AppStrings.sectionNotifications),
            _SwitchTile(
              title: AppStrings.inAppBanner,
              subtitle: AppStrings.inAppBannerSubtitle,
              value: s.inAppBanner,
              onChanged: (v) =>
                  ChuckerFlutterPlus.settings.save(s.copyWith(inAppBanner: v)),
            ),
            _SwitchTile(
              title: AppStrings.systemNotifications,
              subtitle: AppStrings.systemNotificationsSubtitle,
              value: s.systemNotifications,
              onChanged: (v) => ChuckerFlutterPlus.settings.save(
                s.copyWith(systemNotifications: v),
              ),
            ),
            _SwitchTile(
              title: AppStrings.statusBarWhileForeground,
              subtitle: AppStrings.statusBarWhileForegroundSubtitle,
              value: s.statusBarWhileForeground,
              onChanged: (v) => ChuckerFlutterPlus.settings.save(
                s.copyWith(statusBarWhileForeground: v),
              ),
            ),
            _SwitchTile(
              title: AppStrings.notifyOnlyOnError,
              subtitle: AppStrings.notifyOnlyOnErrorSubtitle,
              value: s.onlyErrors,
              onChanged: (v) =>
                  ChuckerFlutterPlus.settings.save(s.copyWith(onlyErrors: v)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLg,
                vertical: AppSizes.paddingXs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.bannerDuration,
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          AppStrings.bannerDurationSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<int>(
                    value: s.bannerDuration.inSeconds.clamp(1, 10),
                    items: const [1, 3, 5, 10]
                        .map(
                          (v) =>
                              DropdownMenuItem(value: v, child: Text('$v s')),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ChuckerFlutterPlus.settings.save(
                          s.copyWith(bannerDuration: Duration(seconds: v)),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLg,
                vertical: AppSizes.paddingXs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.bannerPosition,
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          AppStrings.bannerPositionSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<BannerPosition>(
                    value: s.bannerPosition,
                    items: BannerPosition.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p == BannerPosition.top
                                  ? AppStrings.positionTop
                                  : AppStrings.positionBottom,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (p) {
                      if (p != null) {
                        ChuckerFlutterPlus.settings.save(
                          s.copyWith(bannerPosition: p),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Storage ──────────────────────────────────────────────────────
            const Divider(
              height: AppSizes.gap32,
              indent: AppSizes.paddingLg,
              endIndent: AppSizes.paddingLg,
            ),
            const _SectionHeader(AppStrings.sectionStorage),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLg,
                vertical: AppSizes.paddingXs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.maxLogEntries,
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          AppStrings.maxLogEntriesSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<int>(
                    value: [50, 100, 200, 500].contains(s.maximumEntries)
                        ? s.maximumEntries
                        : 100,
                    items: const [50, 100, 200, 500]
                        .map(
                          (n) => DropdownMenuItem(value: n, child: Text('$n')),
                        )
                        .toList(),
                    onChanged: (n) async {
                      if (n != null) {
                        await ChuckerFlutterPlus.settings.save(
                          s.copyWith(maximumEntries: n),
                        );
                        ChuckerFlutterPlus.configure(maximumEntries: n);
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Danger Zone ──────────────────────────────────────────────────
            const Divider(
              height: AppSizes.gap32,
              indent: AppSizes.paddingLg,
              endIndent: AppSizes.paddingLg,
            ),
            const _SectionHeader(AppStrings.sectionDangerZone),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLg,
                vertical: AppSizes.paddingSm,
              ),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text(AppStrings.clearAllCapturedRequests),
                onPressed: () => _confirmClear(context),
              ),
            ),
            const SizedBox(height: AppSizes.gap24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.clearLogsTitle),
        content: const Text(AppStrings.clearLogsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.clear),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ChuckerFlutterPlus.clearLogs();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.allLogsCleared),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLg,
        AppSizes.paddingLg,
        AppSizes.paddingLg,
        AppSizes.paddingXs,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
