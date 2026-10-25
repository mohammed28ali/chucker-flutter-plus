import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Friendly empty state shown when no requests have been captured.
class EmptyState extends StatefulWidget {
  const EmptyState({super.key, this.filtered = false});
  final bool filtered;
  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingAll40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSizes.emptyStateIconBox,
                  height: AppSizes.emptyStateIconBox,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.filtered
                        ? Icons.search_off_rounded
                        : Icons.network_check_rounded,
                    size: AppSizes.emptyStateIcon,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.gap24),
                AppText.title(
                  widget.filtered
                      ? AppStrings.emptyNoMatches
                      : AppStrings.emptyNoRequests,
                ),
                const SizedBox(height: AppSizes.gap8),
                AppText.body(
                  widget.filtered
                      ? AppStrings.emptyNoMatchesSubtitle
                      : AppStrings.emptyNoRequestsSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
