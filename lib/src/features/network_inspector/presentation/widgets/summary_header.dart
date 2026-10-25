import 'package:flutter/material.dart';

import '../../domain/entities/network_transaction.dart';
import 'method_chip.dart';
import 'status_badge.dart';
import '../../../../config/theme/inspector_colors.dart';

/// Summary header showing aggregate stats about all captured requests.
class SummaryHeader extends StatelessWidget {
  const SummaryHeader({super.key, required this.transactions});
  final List<NetworkTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final total = transactions.length;
    final successes = transactions.where((t) => t.succeeded).length;
    final errors = total - successes;
    final avgMs = total == 0
        ? 0
        : transactions
                  .map((t) => t.duration.inMilliseconds)
                  .reduce((a, b) => a + b) ~/
              total;
    final totalBytes = transactions
        .map((t) => t.responseBodySize)
        .fold<int>(0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(context, '$total', 'Total', Icons.list_alt_outlined),
          _divider(context),
          _stat(
            context,
            '$successes',
            'Success',
            Icons.check_circle_outline,
            color: InspectorColors.status2xx,
          ),
          _divider(context),
          _stat(
            context,
            '$errors',
            'Errors',
            Icons.error_outline,
            color: InspectorColors.status5xx,
          ),
          _divider(context),
          _stat(context, '${avgMs}ms', 'Avg', Icons.timer_outlined),
          _divider(context),
          _stat(context, _size(totalBytes), 'Data', Icons.data_usage_outlined),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String value,
    String label,
    IconData icon, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) => Container(
    height: 30,
    width: 1,
    color: Theme.of(context).colorScheme.outlineVariant,
  );

  static String _size(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(1)} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// The method + status breakdown bar shown below the summary.
class MethodBreakdownRow extends StatelessWidget {
  const MethodBreakdownRow({super.key, required this.transactions});
  final List<NetworkTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final methods = <String, int>{};
    for (final t in transactions) {
      methods[t.method] = (methods[t.method] ?? 0) + 1;
    }
    if (methods.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: methods.entries
            .map(
              (e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MethodChip(e.key, small: true),
                  const SizedBox(width: 4),
                  Text(
                    '${e.value}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
