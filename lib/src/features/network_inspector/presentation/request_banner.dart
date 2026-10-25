import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/entities/network_transaction.dart';
import 'inspector_settings.dart';

class RequestBannerController {
  OverlayState? _overlay;
  BuildContext? _context;
  OverlayEntry? _entry;
  Timer? _timer;
  int _pending = 0;
  BuildContext? get context => _context;
  void bind(BuildContext context) {
    _context = context;
    _overlay = Overlay.maybeOf(context, rootOverlay: true);
  }

  void show(
    NetworkTransaction transaction,
    InspectorSettings settings,
    VoidCallback details,
  ) {
    if (_overlay == null || _entry != null) {
      _pending++;
      return;
    }
    _entry = OverlayEntry(
      builder: (_) => _Banner(
        transaction: transaction,
        extra: _pending,
        top: settings.bannerPosition == BannerPosition.top,
        onDetails: details,
        onDismiss: dismiss,
      ),
    );
    _overlay!.insert(_entry!);
    _timer = Timer(settings.bannerDuration, dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;
    _pending = 0;
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.transaction,
    required this.extra,
    required this.top,
    required this.onDetails,
    required this.onDismiss,
  });
  final NetworkTransaction transaction;
  final int extra;
  final bool top;
  final VoidCallback onDetails, onDismiss;
  @override
  Widget build(BuildContext context) {
    final code = transaction.statusCode ?? 0;
    final color = code >= 500 || transaction.error != null
        ? Colors.red
        : code >= 400
        ? Colors.orange
        : code >= 300
        ? Colors.blue
        : Colors.green;
    return Positioned(
      left: 12,
      right: 12,
      top: top ? 12 : null,
      bottom: top ? null : 12,
      child: Dismissible(
        key: ValueKey(transaction.id),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => onDismiss(),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: color.shade700,
          child: InkWell(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${transaction.method} ${transaction.statusCode ?? 'ERROR'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          transaction.uri.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (extra > 0)
                          Text(
                            '+$extra more requests',
                            style: const TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onDetails,
                    child: const Text(
                      'Details',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
