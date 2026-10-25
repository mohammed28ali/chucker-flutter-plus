import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';

/// A single key-value info row used in Overview tab and header lists.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.monospace = false,
    this.redacted = false,
    this.onReveal,
    this.muted = false,
    this.copyable = true,
  });

  final String label;
  final String value;
  final bool monospace;
  final bool redacted;
  final bool muted;
  final bool copyable;
  final VoidCallback? onReveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: monospace ? 'monospace' : null,
      color: muted
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.gap6,
        horizontal: AppSizes.paddingLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.labelColumnWidth,
            child: Text(label.toUpperCase(), style: labelStyle),
          ),
          const SizedBox(width: AppSizes.gap8),
          Expanded(
            child: redacted
                ? Row(
                    children: [
                      const Text(
                        AppStrings.redactedMask,
                        style: TextStyle(letterSpacing: 2),
                      ),
                      if (onReveal != null) ...[
                        const SizedBox(width: AppSizes.gap8),
                        GestureDetector(
                          onTap: onReveal,
                          child: Text(
                            AppStrings.reveal,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: AppSizes.textMd,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : GestureDetector(
                    onLongPress: copyable
                        ? () {
                            Clipboard.setData(ClipboardData(text: value));
                            _showCopied(context);
                          }
                        : null,
                    child: SelectableText(value, style: valueStyle),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCopied(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text(AppStrings.copiedToClipboard),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }
}

/// Thin divider between KeyValueRow items inside a card
class KeyValueDivider extends StatelessWidget {
  const KeyValueDivider({super.key});
  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: AppSizes.paddingLg,
    endIndent: AppSizes.paddingLg,
  );
}
