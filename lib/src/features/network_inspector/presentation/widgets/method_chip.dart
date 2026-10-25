import 'package:flutter/material.dart';

import '../../../../config/theme/inspector_colors.dart';
import '../../../../core/core.dart';

/// Color-coded chip showing the HTTP method.
class MethodChip extends StatelessWidget {
  const MethodChip(this.method, {super.key, this.small = false});
  final String method;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = InspectorColors.methodColor(method);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppSizes.gap6 : AppSizes.gap8,
        vertical: small ? AppSizes.gap2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: small ? AppSizes.textXs : AppSizes.textSm,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
