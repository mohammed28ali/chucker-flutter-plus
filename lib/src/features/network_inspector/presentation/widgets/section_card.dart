import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// A rounded card used as a section container throughout the inspector.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: AppSizes.gap8),
  });

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingLg,
                AppSizes.paddingMd,
                AppSizes.paddingLg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppText.title(title!),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          if (title != null)
            Divider(
              height: AppSizes.gap12,
              indent: AppSizes.paddingLg,
              endIndent: AppSizes.paddingLg,
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
