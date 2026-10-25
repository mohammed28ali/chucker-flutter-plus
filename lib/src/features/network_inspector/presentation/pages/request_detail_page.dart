import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/core.dart';
import '../../domain/entities/network_transaction.dart';
import '../chucker_flutter.dart';
import '../widgets/body_viewer.dart';
import '../widgets/headers_section.dart';
import '../widgets/key_value_row.dart';
import '../widgets/method_chip.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class RequestDetailPage extends StatefulWidget {
  const RequestDetailPage({super.key, required this.transaction});
  final NetworkTransaction transaction;

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late final List<_TabDef> _tabs;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _tabs = [
      const _TabDef(AppStrings.tabOverview, Icons.info_outline),
      const _TabDef(AppStrings.tabRequest, Icons.upload_outlined),
      const _TabDef(AppStrings.tabResponse, Icons.download_outlined),
      const _TabDef(AppStrings.tabRaw, Icons.code),
      if (t.error != null)
        const _TabDef(AppStrings.tabError, Icons.error_outline),
      if (_isMedia(t)) const _TabDef(AppStrings.tabMedia, Icons.image_outlined),
    ];
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool _isMedia(NetworkTransaction t) {
    final ct = t.contentType?.toLowerCase() ?? '';
    return ct.startsWith('image/') || ct.startsWith('video/');
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            floating: false,
            snap: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: AppStrings.shareAsCurl,
                onPressed: () => _shareCurl(t),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'copy_curl',
                    child: Text(AppStrings.copyCurl),
                  ),
                  const PopupMenuItem(
                    value: 'copy_url',
                    child: Text(AppStrings.copyUrl),
                  ),
                  const PopupMenuItem(
                    value: 'share_json',
                    child: Text(AppStrings.shareAsJson),
                  ),
                ],
                onSelected: (v) => _onAction(v, t),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                color: theme.scaffoldBackgroundColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLg,
                      56,
                      AppSizes.paddingLg,
                      0,
                    ),
                    child: _Header(transaction: t),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: _tabs
                  .map(
                    (tab) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab.icon, size: AppSizes.iconMd),
                          const SizedBox(width: AppSizes.gap6),
                          Text(tab.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: _tabs.map((tab) => _buildTab(tab.label, t)).toList(),
        ),
      ),
    );
  }

  Widget _buildTab(String label, NetworkTransaction t) {
    return switch (label) {
      AppStrings.tabOverview => _OverviewTab(transaction: t),
      AppStrings.tabRequest => _RequestTab(transaction: t),
      AppStrings.tabResponse => _ResponseTab(transaction: t),
      AppStrings.tabRaw => _RawTab(transaction: t),
      AppStrings.tabError => _ErrorTab(transaction: t),
      AppStrings.tabMedia => _MediaTab(transaction: t),
      _ => const SizedBox.shrink(),
    };
  }

  void _shareCurl(NetworkTransaction t) async {
    await SharePlus.instance.share(ShareParams(text: _buildCurl(t)));
  }

  void _onAction(String action, NetworkTransaction t) async {
    switch (action) {
      case 'copy_curl':
        await Clipboard.setData(ClipboardData(text: _buildCurl(t)));
        if (mounted) {
          context.successSnackBar(AppStrings.curlCopied);
        }
      case 'copy_url':
        await Clipboard.setData(ClipboardData(text: t.uri.toString()));
        if (mounted) {
          context.successSnackBar(AppStrings.urlCopied);
        }
      case 'share_json':
        final json = jsonEncode({
          'url': t.uri.toString(),
          'method': t.method,
          'statusCode': t.statusCode,
          'durationMs': t.duration.inMilliseconds,
          'requestHeaders': t.requestHeaders,
          'responseHeaders': t.responseHeaders,
          'requestBody': t.rawRequestBody,
          'responseBody': t.rawResponseBody,
        });
        await SharePlus.instance.share(ShareParams(text: json));
    }
  }

  String _buildCurl(NetworkTransaction t) {
    final headers = t.requestHeaders.entries
        .map((e) => "-H '${e.key}: ${e.value}'")
        .join(' ');
    final data = t.rawRequestBody != null ? "--data '${t.rawRequestBody}'" : '';
    return "curl -X ${t.method} $headers $data '${t.uri}'";
  }
}

// ── Tab definitions ──────────────────────────────────────────────────────────

class _TabDef {
  const _TabDef(this.label, this.icon);
  final String label;
  final IconData icon;
}

// ── Collapsing header ────────────────────────────────────────────────────────

class _Header extends StatefulWidget {
  const _Header({required this.transaction});
  final NetworkTransaction transaction;
  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _urlExpanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Method + status + duration
        Row(
          children: [
            MethodChip(t.method),
            const SizedBox(width: AppSizes.gap8),
            StatusBadge(t.statusCode, error: t.error),
            const SizedBox(width: AppSizes.gap8),
            Text(
              _fmtDuration(t.duration),
              style: TextStyle(
                fontSize: AppSizes.textMd,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              _relTime(t.startedAt),
              style: TextStyle(
                fontSize: AppSizes.textMd,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gap8),
        // URL (expandable)
        GestureDetector(
          onTap: () => setState(() => _urlExpanded = !_urlExpanded),
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: t.uri.toString()));
            context.successSnackBar(AppStrings.urlCopied);
          },
          child: AnimatedCrossFade(
            firstChild: Text(
              t.uri.toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: AppSizes.textSmPlus,
                color: theme.colorScheme.primary,
                height: 1.4,
              ),
            ),
            secondChild: SelectableText(
              t.uri.toString(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: AppSizes.textSmPlus,
                color: theme.colorScheme.primary,
                height: 1.4,
              ),
            ),
            crossFadeState: _urlExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ),
        const SizedBox(height: AppSizes.gap8),
        // Size row
        Row(
          children: [
            Icon(
              Icons.upload_outlined,
              size: AppSizes.icon14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSizes.gap4),
            Text(
              _sizeStr(t.requestBodySize),
              style: TextStyle(
                fontSize: AppSizes.textSm,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSizes.gap12),
            Icon(
              Icons.download_outlined,
              size: AppSizes.icon14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSizes.gap4),
            Text(
              _sizeStr(t.responseBodySize),
              style: TextStyle(
                fontSize: AppSizes.textSm,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmtDuration(Duration d) {
    if (d.inSeconds >= 1) {
      return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
    return '${d.inMilliseconds}ms';
  }

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  static String _sizeStr(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(1)} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// ── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.transaction});
  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final rows = <(String, String, bool)>[
      (AppStrings.labelUrl, t.uri.toString(), true),
      (AppStrings.labelMethod, t.method, false),
      (
        AppStrings.labelStatus,
        t.statusCode != null ? '${t.statusCode}' : AppStrings.filterError,
        false,
      ),
      (AppStrings.labelHost, t.host, true),
      (AppStrings.labelPath, t.uri.path.isEmpty ? '/' : t.uri.path, true),
      (AppStrings.labelQuery, t.uri.query.isEmpty ? '—' : t.uri.query, true),
      (AppStrings.labelContentType, t.contentType ?? '—', false),
      (AppStrings.labelRequestSize, _sizeStr(t.requestBodySize), false),
      (AppStrings.labelResponseSize, _sizeStr(t.responseBodySize), false),
      (AppStrings.labelDuration, '${t.duration.inMilliseconds} ms', false),
      (AppStrings.labelStarted, t.startedAt.toLocal().toString(), false),
      (AppStrings.labelCompleted, t.completedAt.toLocal().toString(), false),
      if (t.requestBodyTruncated)
        (AppStrings.labelRequestBody, AppStrings.labelTruncated, false),
      if (t.responseBodyTruncated)
        (AppStrings.labelResponseBody, AppStrings.labelTruncated, false),
      if (t.imageWidth != null && t.imageHeight != null)
        (
          AppStrings.labelDimensions,
          '${t.imageWidth} × ${t.imageHeight}',
          false,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      children: [
        SectionCard(
          title: AppStrings.labelGeneral,
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                KeyValueRow(
                  label: rows[i].$1,
                  value: rows[i].$2,
                  monospace: rows[i].$3,
                ),
                if (i < rows.length - 1) const KeyValueDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _sizeStr(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(1)} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// ── Request tab ───────────────────────────────────────────────────────────────

class _RequestTab extends StatelessWidget {
  const _RequestTab({required this.transaction});
  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      children: [
        HeadersSection(
          headers: t.requestHeaders,
          title: AppStrings.labelRequestHeaders,
          sensitiveKeys: ChuckerFlutterPlus.sensitiveHeaders,
        ),
        const SizedBox(height: AppSizes.gap12),
        SectionCard(
          title: AppStrings.requestBodyLabel,
          padding: EdgeInsets.zero,
          child: BodyViewer(
            body: t.rawRequestBody,
            contentType:
                t.requestHeaders['content-type'] ??
                t.requestHeaders['Content-Type'],
            truncated: t.requestBodyTruncated,
            label: AppStrings.requestBodyLabel,
          ),
        ),
      ],
    );
  }
}

// ── Response tab ──────────────────────────────────────────────────────────────

class _ResponseTab extends StatelessWidget {
  const _ResponseTab({required this.transaction});
  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      children: [
        HeadersSection(
          headers: t.responseHeaders,
          title: AppStrings.labelResponseHeaders,
          sensitiveKeys: ChuckerFlutterPlus.sensitiveHeaders,
        ),
        const SizedBox(height: AppSizes.gap12),
        SectionCard(
          title: AppStrings.responseBodyLabel,
          padding: EdgeInsets.zero,
          child: BodyViewer(
            body: t.rawResponseBody,
            contentType:
                t.contentType ??
                t.responseHeaders['content-type'] ??
                t.responseHeaders['Content-Type'],
            truncated: t.responseBodyTruncated,
            label: AppStrings.responseBodyLabel,
          ),
        ),
      ],
    );
  }
}

// ── Raw tab ────────────────────────────────────────────────────────────────────

class _RawTab extends StatefulWidget {
  const _RawTab({required this.transaction});
  final NetworkTransaction transaction;
  @override
  State<_RawTab> createState() => _RawTabState();
}

class _RawTabState extends State<_RawTab> {
  bool _formatted = false;

  String _formatIfJson(String? raw) {
    if (raw == null) return '—';
    if (!_formatted) return raw;
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.rawPayloads,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Row(
              children: [
                const Text(
                  AppStrings.labelFormatted,
                  style: TextStyle(fontSize: AppSizes.textBase),
                ),
                Switch(
                  value: _formatted,
                  onChanged: (v) => setState(() => _formatted = v),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSizes.gap12),
        SectionCard(
          title: AppStrings.tabRequest,
          padding: EdgeInsets.zero,
          child: _RawText(text: _formatIfJson(t.rawRequestBody)),
        ),
        const SizedBox(height: AppSizes.gap12),
        SectionCard(
          title: AppStrings.tabResponse,
          padding: EdgeInsets.zero,
          child: _RawText(text: _formatIfJson(t.rawResponseBody)),
        ),
      ],
    );
  }
}

class _RawText extends StatelessWidget {
  const _RawText({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: AppSizes.textMd,
          height: 1.6,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ── Error tab ─────────────────────────────────────────────────────────────────

class _ErrorTab extends StatelessWidget {
  const _ErrorTab({required this.transaction});
  final NetworkTransaction transaction;

  String _hint(String? error) {
    if (error == null) return '';
    final e = error.toLowerCase();
    if (e.contains('timeout') || e.contains('timedout')) {
      return AppStrings.errorTimeout;
    }
    if (e.contains('connection refused') || e.contains('connrefused')) {
      return AppStrings.errorConnRefused;
    }
    if (e.contains('certificate') || e.contains('ssl') || e.contains('tls')) {
      return AppStrings.errorSsl;
    }
    if (e.contains('no route') ||
        e.contains('unreachable') ||
        e.contains('network')) {
      return AppStrings.errorNetworkUnreachable;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final theme = Theme.of(context);
    final hint = _hint(t.error);

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      children: [
        if (hint.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: AppSizes.gap16),
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.onTertiaryContainer,
                  size: AppSizes.iconLg,
                ),
                const SizedBox(width: AppSizes.gap12),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontSize: AppSizes.textBase,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SectionCard(
          title: AppStrings.tabError,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueRow(
                label: AppStrings.labelType,
                value: t.error ?? '—',
              ),
              if (t.stackTrace != null) ...[
                const KeyValueDivider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLg,
                    AppSizes.paddingSm,
                    AppSizes.paddingLg,
                    AppSizes.paddingSm,
                  ),
                  child: Text(
                    AppStrings.labelStackTrace,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLg,
                    0,
                    AppSizes.paddingLg,
                    AppSizes.paddingSm,
                  ),
                  child: SelectableText(
                    t.stackTrace!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: AppSizes.textSmPlus,
                      height: 1.6,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Media tab ─────────────────────────────────────────────────────────────────

class _MediaTab extends StatelessWidget {
  const _MediaTab({required this.transaction});
  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final ct = t.contentType?.toLowerCase() ?? '';
    final isImage = ct.startsWith('image/');

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      children: [
        SectionCard(
          title: AppStrings.labelMediaInfo,
          child: Column(
            children: [
              KeyValueRow(
                label: AppStrings.labelContentType,
                value: t.contentType ?? '—',
              ),
              const KeyValueDivider(),
              KeyValueRow(
                label: AppStrings.labelSize,
                value: _sizeStr(t.responseBodySize),
              ),
              if (t.imageWidth != null && t.imageHeight != null) ...[
                const KeyValueDivider(),
                KeyValueRow(
                  label: AppStrings.labelDimensions,
                  value: '${t.imageWidth} × ${t.imageHeight} px',
                ),
              ],
            ],
          ),
        ),
        if (isImage && t.rawResponseBody != null) ...[
          const SizedBox(height: AppSizes.gap12),
          SectionCard(
            title: AppStrings.labelPreview,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: Builder(
                builder: (context) {
                  try {
                    final bytes = base64Decode(t.rawResponseBody!);
                    return GestureDetector(
                      onTap: () => _showFullImage(context, bytes),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radius8),
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const _MediaPlaceholder(),
                        ),
                      ),
                    );
                  } catch (_) {
                    return const _MediaPlaceholder();
                  }
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showFullImage(BuildContext context, List<int> bytes) {
    context.pushNamed(
      Routes.mediaPreview,
      arguments: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
    );
  }

  static String _sizeStr(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(1)} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: AppSizes.iconXxl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSizes.gap8),
            Text(
              AppStrings.previewNotAvailable,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
