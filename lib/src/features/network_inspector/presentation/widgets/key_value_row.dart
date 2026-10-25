import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      color: muted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label.toUpperCase(), style: labelStyle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: redacted
                ? Row(
                    children: [
                      const Text(
                        '••••••••••••',
                        style: TextStyle(letterSpacing: 2),
                      ),
                      if (onReveal != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onReveal,
                          child: Text(
                            'reveal',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
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
        content: Text('Copied to clipboard'),
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
    indent: 16,
    endIndent: 16,
  );
}
