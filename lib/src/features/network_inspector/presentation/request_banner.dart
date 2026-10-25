import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/inspector_colors.dart';
import '../../../core/core.dart';
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
    if (_overlay == null) return;
    if (_entry != null) {
      _pending++;
      return;
    }
    _entry = OverlayEntry(
      builder: (_) => _AnimatedBanner(
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

class _AnimatedBanner extends StatefulWidget {
  const _AnimatedBanner({
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
  State<_AnimatedBanner> createState() => _AnimatedBannerState();
}

class _AnimatedBannerState extends State<_AnimatedBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final begin = widget.top ? const Offset(0, -1.5) : const Offset(0, 1.5);
    _slide = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final code = t.statusCode ?? 0;
    final hasError = t.error != null && code == 0;

    final stripColor = hasError
        ? InspectorColors.statusError
        : code >= 500
        ? InspectorColors.status5xx
        : code >= 400
        ? InspectorColors.status4xx
        : code >= 300
        ? InspectorColors.status3xx
        : InspectorColors.status2xx;

    return Positioned(
      left: AppSizes.paddingMd,
      right: AppSizes.paddingMd,
      top: widget.top ? 44 : null,
      bottom: widget.top ? null : 24,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Dismissible(
            key: ValueKey(t.id),
            direction: DismissDirection.horizontal,
            onDismissed: (_) => widget.onDismiss(),
            child: Material(
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSizes.radiusBanner),
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radiusBanner),
                onTap: _dismiss,
                child: Row(
                  children: [
                    // Color strip
                    Container(
                      width: AppSizes.bannerStripWidth,
                      height: AppSizes.bannerStripHeight,
                      decoration: BoxDecoration(
                        color: stripColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppSizes.radiusBanner),
                          bottomLeft: Radius.circular(AppSizes.radiusBanner),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.gap12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.paddingMd,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                _MethodBadge(t.method),
                                const SizedBox(width: AppSizes.gap6),
                                _StatusLabel(t.statusCode, t.error, stripColor),
                                const Spacer(),
                                Text(
                                  _fmtDuration(t.duration),
                                  style: const TextStyle(
                                    fontSize: AppSizes.textSm,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.gap8),
                              ],
                            ),
                            const SizedBox(height: AppSizes.gap4),
                            Text(
                              t.uri.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: AppSizes.textSmPlus,
                                color: Colors.black87,
                              ),
                            ),
                            if (widget.extra > 0) ...[
                              const SizedBox(height: AppSizes.gap2),
                              Text(
                                '+${widget.extra} more request${widget.extra == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: AppSizes.textSm,
                                  color: Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Details button
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onDetails();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: stripColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMd,
                          vertical: AppSizes.paddingSm,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        AppStrings.details,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppSizes.textBase,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.gap4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDuration(Duration d) {
    if (d.inSeconds >= 1) {
      return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
    return '${d.inMilliseconds}ms';
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge(this.method);
  final String method;
  @override
  Widget build(BuildContext context) {
    final color = InspectorColors.methodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSm - 2,
        vertical: AppSizes.paddingXs / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel(this.code, this.error, this.color);
  final int? code;
  final String? error;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final label = error != null && code == null
        ? AppStrings.statusErrorUpper
        : '${code ?? AppStrings.statusUnknown}';
    return Text(
      label,
      style: TextStyle(
        fontSize: AppSizes.textMd,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
