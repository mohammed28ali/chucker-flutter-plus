import 'package:flutter/material.dart';
import '../chucker_flutter.dart';
import '../inspector_settings.dart';

/// Settings page for the network inspector — fully isolated from host app.
class InspectorSettingsPage extends StatelessWidget {
  const InspectorSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Inspector Settings')),
      body: ValueListenableBuilder<InspectorSettings>(
        valueListenable: ChuckerFlutterPlus.settings,
        builder: (context, s, _) => ListView(
          children: [
            // ── Notifications ────────────────────────────────────────────────
            _SectionHeader('Notifications'),
            _SwitchTile(
              title: 'In-app banner',
              subtitle: 'Show a floating banner when a request completes.',
              value: s.inAppBanner,
              onChanged: (v) => ChuckerFlutterPlus.settings.save(s.copyWith(inAppBanner: v)),
            ),
            _SwitchTile(
              title: 'System notifications',
              subtitle: 'Show OS-level notifications for requests.',
              value: s.systemNotifications,
              onChanged: (v) => ChuckerFlutterPlus.settings.save(s.copyWith(systemNotifications: v)),
            ),
            _SwitchTile(
              title: 'Status bar while foreground',
              subtitle: 'Also show system notifications when the app is in the foreground.',
              value: s.statusBarWhileForeground,
              onChanged: (v) => ChuckerFlutterPlus.settings.save(
                s.copyWith(statusBarWhileForeground: v),
              ),
            ),
            _SwitchTile(
              title: 'Notify only on error',
              subtitle: 'Only show notifications for failed requests (4xx/5xx/errors).',
              value: s.onlyErrors,
              onChanged: (v) => ChuckerFlutterPlus.settings.save(s.copyWith(onlyErrors: v)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Banner duration', style: theme.textTheme.bodyLarge),
                        Text(
                          'How long to show the in-app banner.',
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
                        .map((v) => DropdownMenuItem(value: v, child: Text('$v s')))
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Banner position', style: theme.textTheme.bodyLarge),
                        Text(
                          'Where the in-app banner appears.',
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
                            child: Text(p == BannerPosition.top ? 'Top' : 'Bottom'),
                          ),
                        )
                        .toList(),
                    onChanged: (p) {
                      if (p != null) {
                        ChuckerFlutterPlus.settings.save(s.copyWith(bannerPosition: p));
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Storage ──────────────────────────────────────────────────────
            const Divider(height: 32, indent: 16, endIndent: 16),
            _SectionHeader('Storage'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Max log entries', style: theme.textTheme.bodyLarge),
                        Text(
                          'Older entries are discarded when the limit is reached.',
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
                        .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
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
            const Divider(height: 32, indent: 16, endIndent: 16),
            _SectionHeader('Danger Zone'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Clear all captured requests'),
                onPressed: () => _confirmClear(context),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all logs?'),
        content: const Text('This will permanently remove all captured requests.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ChuckerFlutterPlus.clearLogs();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All logs cleared'),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
