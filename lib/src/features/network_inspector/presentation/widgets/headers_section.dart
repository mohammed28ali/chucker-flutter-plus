import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import 'key_value_row.dart';
import 'section_card.dart';

/// Collapsible, searchable headers section used in Request and Response tabs.
class HeadersSection extends StatefulWidget {
  const HeadersSection({
    super.key,
    required this.headers,
    required this.title,
    this.sensitiveKeys = const {'authorization', 'cookie', 'set-cookie'},
  });
  final Map<String, String> headers;
  final String title;
  final Set<String> sensitiveKeys;

  @override
  State<HeadersSection> createState() => _HeadersSectionState();
}

class _HeadersSectionState extends State<HeadersSection> {
  bool _expanded = true;
  String _query = '';
  final Map<String, bool> _revealed = {};

  @override
  Widget build(BuildContext context) {
    if (widget.headers.isEmpty) {
      return SectionCard(
        title: widget.title,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLg,
            vertical: AppSizes.paddingSm,
          ),
          child: Text(
            AppStrings.noHeaders,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final filtered =
        widget.headers.entries
            .where(
              (e) =>
                  _query.isEmpty ||
                  e.key.toLowerCase().contains(_query.toLowerCase()) ||
                  e.value.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    return SectionCard(
      title: widget.title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.headers.length}',
            style: TextStyle(
              fontSize: AppSizes.textMd,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            icon: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              size: AppSizes.iconLg,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            tooltip: _expanded ? AppStrings.collapse : AppStrings.expand,
          ),
        ],
      ),
      padding: EdgeInsets.zero,
      child: AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: Column(
          children: [
            if (widget.headers.length > 4)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg,
                  AppSizes.paddingSm,
                  AppSizes.paddingLg,
                  AppSizes.paddingSm,
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: AppSizes.icon18),
                    hintText: AppStrings.searchHeaders,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ...filtered.map((e) {
              final isSensitive = widget.sensitiveKeys.contains(
                e.key.toLowerCase(),
              );
              final revealed = _revealed[e.key] ?? false;
              return Column(
                children: [
                  KeyValueRow(
                    label: e.key,
                    value: e.value,
                    monospace: true,
                    redacted: isSensitive && !revealed,
                    onReveal: isSensitive && !revealed
                        ? () => setState(() => _revealed[e.key] = true)
                        : null,
                  ),
                  if (e != filtered.last) const KeyValueDivider(),
                ],
              );
            }),
            const SizedBox(height: AppSizes.gap8),
          ],
        ),
        crossFadeState: _expanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }
}
