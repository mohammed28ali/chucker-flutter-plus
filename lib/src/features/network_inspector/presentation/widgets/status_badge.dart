import 'package:flutter/material.dart';

import '../../../../config/theme/inspector_colors.dart';
import '../../../../core/core.dart';

/// Badge showing an HTTP status code, color-coded by group.
/// Tapping shows a tooltip with the status meaning.
class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.statusCode, {
    super.key,
    this.error,
    this.small = false,
  });
  final int? statusCode;
  final String? error;
  final bool small;

  static String _label(int? code, String? error) {
    if (error != null && code == null) return AppStrings.statusErr;
    if (code == null) return AppStrings.statusUnknown;
    return '$code';
  }

  static String _meaning(int? code, String? error) {
    if (error != null && code == null) return AppStrings.statusNetworkError;
    if (code == null) return AppStrings.statusUnknown;
    return switch (code) {
      200 => AppStrings.status200,
      201 => AppStrings.status201,
      204 => AppStrings.status204,
      301 => AppStrings.status301,
      302 => AppStrings.status302,
      304 => AppStrings.status304,
      400 => AppStrings.status400,
      401 => AppStrings.status401,
      403 => AppStrings.status403,
      404 => AppStrings.status404,
      405 => AppStrings.status405,
      408 => AppStrings.status408,
      409 => AppStrings.status409,
      422 => AppStrings.status422,
      429 => AppStrings.status429,
      500 => AppStrings.status500,
      502 => AppStrings.status502,
      503 => AppStrings.status503,
      504 => AppStrings.status504,
      _ when code < 300 => '$code Success',
      _ when code < 400 => '$code Redirect',
      _ when code < 500 => '$code Client Error',
      _ => '$code Server Error',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = error != null && statusCode == null;
    final (fg, bg) = hasError
        ? (InspectorColors.statusError, InspectorColors.statusErrorBg)
        : InspectorColors.statusColors(statusCode, dark: isDark);

    return Tooltip(
      message: _meaning(statusCode, error),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? AppSizes.gap6 : AppSizes.gap8,
          vertical: small ? AppSizes.gap2 : 3,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasError) ...[
              Icon(
                Icons.error_outline,
                size: small ? AppSizes.iconXs : AppSizes.iconSm,
                color: fg,
              ),
              SizedBox(width: small ? 3 : AppSizes.gap4),
            ],
            Text(
              _label(statusCode, error),
              style: TextStyle(
                color: fg,
                fontSize: small ? AppSizes.textXs : AppSizes.textSm,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pending badge shown while the request is in-flight
class PendingBadge extends StatelessWidget {
  const PendingBadge({super.key, this.small = false});
  final bool small;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppSizes.gap6 : AppSizes.gap8,
        vertical: small ? AppSizes.gap2 : 3,
      ),
      decoration: BoxDecoration(
        color: InspectorColors.statusPendingBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: small ? AppSizes.gap8 : AppSizes.textSm,
            height: small ? AppSizes.gap8 : AppSizes.textSm,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: InspectorColors.statusPending,
            ),
          ),
          SizedBox(width: small ? AppSizes.gap4 : 5),
          Text(
            AppStrings.statusPending,
            style: TextStyle(
              color: InspectorColors.statusPending,
              fontSize: small ? AppSizes.textXs : AppSizes.textSm,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
