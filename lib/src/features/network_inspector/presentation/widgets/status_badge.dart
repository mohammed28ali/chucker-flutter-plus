import 'package:flutter/material.dart';

import '../../../../config/theme/inspector_colors.dart';

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
    if (error != null && code == null) return 'ERR';
    if (code == null) return '???';
    return '$code';
  }

  static String _meaning(int? code, String? error) {
    if (error != null && code == null) return 'Network Error';
    if (code == null) return 'Unknown';
    return switch (code) {
      200 => '200 OK',
      201 => '201 Created',
      204 => '204 No Content',
      301 => '301 Moved Permanently',
      302 => '302 Found',
      304 => '304 Not Modified',
      400 => '400 Bad Request',
      401 => '401 Unauthorized',
      403 => '403 Forbidden',
      404 => '404 Not Found',
      405 => '405 Method Not Allowed',
      408 => '408 Request Timeout',
      409 => '409 Conflict',
      422 => '422 Unprocessable Entity',
      429 => '429 Too Many Requests',
      500 => '500 Internal Server Error',
      502 => '502 Bad Gateway',
      503 => '503 Service Unavailable',
      504 => '504 Gateway Timeout',
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
          horizontal: small ? 6 : 8,
          vertical: small ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasError) ...[
              Icon(Icons.error_outline, size: small ? 10 : 12, color: fg),
              SizedBox(width: small ? 3 : 4),
            ],
            Text(
              _label(statusCode, error),
              style: TextStyle(
                color: fg,
                fontSize: small ? 10 : 11,
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
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: InspectorColors.statusPendingBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: small ? 8 : 10,
            height: small ? 8 : 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: InspectorColors.statusPending,
            ),
          ),
          SizedBox(width: small ? 4 : 5),
          Text(
            'pending',
            style: TextStyle(
              color: InspectorColors.statusPending,
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
