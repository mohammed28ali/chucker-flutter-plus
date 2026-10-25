import 'package:flutter/material.dart';
import '../theme/inspector_colors.dart';

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
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
