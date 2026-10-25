import 'dart:convert';

import 'package:chucker_flutter_plus/src/config/theme/inspector_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/network_transaction.dart';
import '../widgets/method_chip.dart';
import '../widgets/status_badge.dart';
import '../widgets/key_value_row.dart';
import '../widgets/section_card.dart';
import '../widgets/headers_section.dart';
import '../widgets/body_viewer.dart';
import '../chucker_flutter.dart';

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
      _TabDef('Overview', Icons.info_outline),
      _TabDef('Request', Icons.upload_outlined),
      _TabDef('Response', Icons.download_outlined),
      _TabDef('Raw', Icons.code),
      if (t.error != null) _TabDef('Error', Icons.error_outline),
      if (_isMedia(t)) _TabDef('Media', Icons.image_outlined),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share as cURL',
                onPressed: () => _shareCurl(t),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'copy_curl',
                    child: Text('Copy cURL'),
                  ),
                  const PopupMenuItem(
                    value: 'copy_url',
                    child: Text('Copy URL'),
                  ),
                  const PopupMenuItem(
                    value: 'share_json',
                    child: Text('Share as JSON'),
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
                    padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
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
                          Icon(tab.icon, size: 16),
                          const SizedBox(width: 6),
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
      'Overview' => _OverviewTab(transaction: t),
      'Request' => _RequestTab(transaction: t),
      'Response' => _ResponseTab(transaction: t),
      'Raw' => _RawTab(transaction: t),
      'Error' => _ErrorTab(transaction: t),
      'Media' => _MediaTab(transaction: t),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('cURL copied'),
              duration: Duration(milliseconds: 1500),
            ),
          );
        }
      case 'copy_url':
        await Clipboard.setData(ClipboardData(text: t.uri.toString()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('URL copied'),
              duration: Duration(milliseconds: 1500),
            ),
          );
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
            const SizedBox(width: 8),
            StatusBadge(t.statusCode, error: t.error),
            const SizedBox(width: 8),
            Text(
              _fmtDuration(t.duration),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              _relTime(t.startedAt),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // URL (expandable)
        GestureDetector(
          onTap: () => setState(() => _urlExpanded = !_urlExpanded),
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: t.uri.toString()));
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('URL copied'),
                duration: Duration(milliseconds: 1200),
              ),
            );
          },
          child: AnimatedCrossFade(
            firstChild: Text(
              t.uri.toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                color: theme.colorScheme.primary,
                height: 1.4,
              ),
            ),
            secondChild: SelectableText(
              t.uri.toString(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
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
        const SizedBox(height: 8),
        // Size row
        Row(
          children: [
            Icon(
              Icons.upload_outlined,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _sizeStr(t.requestBodySize),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.download_outlined,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _sizeStr(t.responseBodySize),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmtDuration(Duration d) {
    if (d.inSeconds >= 1)
      return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
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
      ('URL', t.uri.toString(), true),
      ('Method', t.method, false),
      ('Status', t.statusCode != null ? '${t.statusCode}' : 'Error', false),
      ('Host', t.host, true),
      ('Path', t.uri.path.isEmpty ? '/' : t.uri.path, true),
      ('Query', t.uri.query.isEmpty ? '—' : t.uri.query, true),
      ('Content-Type', t.contentType ?? '—', false),
      ('Request size', _sizeStr(t.requestBodySize), false),
      ('Response size', _sizeStr(t.responseBodySize), false),
      ('Duration', '${t.duration.inMilliseconds} ms', false),
      ('Started', t.startedAt.toLocal().toString(), false),
      ('Completed', t.completedAt.toLocal().toString(), false),
      if (t.requestBodyTruncated) ('Request body', 'Truncated', false),
      if (t.responseBodyTruncated) ('Response body', 'Truncated', false),
      if (t.imageWidth != null && t.imageHeight != null)
        ('Dimensions', '${t.imageWidth} × ${t.imageHeight}', false),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'General',
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
      padding: const EdgeInsets.all(16),
      children: [
        HeadersSection(
          headers: t.requestHeaders,
          title: 'Request Headers',
          sensitiveKeys: ChuckerFlutterPlus.sensitiveHeaders,
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Request Body',
          padding: EdgeInsets.zero,
          child: BodyViewer(
            body: t.rawRequestBody,
            contentType:
                t.requestHeaders['content-type'] ??
                t.requestHeaders['Content-Type'],
            truncated: t.requestBodyTruncated,
            label: 'Request Body',
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
      padding: const EdgeInsets.all(16),
      children: [
        HeadersSection(
          headers: t.responseHeaders,
          title: 'Response Headers',
          sensitiveKeys: ChuckerFlutterPlus.sensitiveHeaders,
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Response Body',
          padding: EdgeInsets.zero,
          child: BodyViewer(
            body: t.rawResponseBody,
            contentType:
                t.contentType ??
                t.responseHeaders['content-type'] ??
                t.responseHeaders['Content-Type'],
            truncated: t.responseBodyTruncated,
            label: 'Response Body',
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
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Raw Payloads',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Row(
              children: [
                const Text('Formatted', style: TextStyle(fontSize: 13)),
                Switch(
                  value: _formatted,
                  onChanged: (v) => setState(() => _formatted = v),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Request',
          padding: EdgeInsets.zero,
          child: _RawText(text: _formatIfJson(t.rawRequestBody)),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Response',
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
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
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
      return 'Timeout: the server did not respond in time. Check your network connection or increase the timeout setting.';
    }
    if (e.contains('connection refused') || e.contains('connrefused')) {
      return 'Connection refused: the server actively rejected the connection. Check if the server is running and the port is correct.';
    }
    if (e.contains('certificate') || e.contains('ssl') || e.contains('tls')) {
      return 'SSL/TLS error: certificate verification failed. The server may have an invalid or self-signed certificate.';
    }
    if (e.contains('no route') ||
        e.contains('unreachable') ||
        e.contains('network')) {
      return 'Network unreachable: no route to host. Check your network connection.';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final theme = Theme.of(context);
    final hint = _hint(t.error);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hint.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.onTertiaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SectionCard(
          title: 'Error',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueRow(label: 'Type', value: t.error ?? '—'),
              if (t.stackTrace != null) ...[
                const KeyValueDivider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Stack Trace',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SelectableText(
                    t.stackTrace!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
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
    final theme = Theme.of(context);
    final ct = t.contentType?.toLowerCase() ?? '';
    final isImage = ct.startsWith('image/');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Media Info',
          child: Column(
            children: [
              KeyValueRow(label: 'Content-Type', value: t.contentType ?? '—'),
              const KeyValueDivider(),
              KeyValueRow(label: 'Size', value: _sizeStr(t.responseBodySize)),
              if (t.imageWidth != null && t.imageHeight != null) ...[
                const KeyValueDivider(),
                KeyValueRow(
                  label: 'Dimensions',
                  value: '${t.imageWidth} × ${t.imageHeight} px',
                ),
              ],
            ],
          ),
        ),
        if (isImage && t.rawResponseBody != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: 'Preview',
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Builder(
                builder: (context) {
                  try {
                    final bytes = base64Decode(t.rawResponseBody!);
                    return GestureDetector(
                      onTap: () => _showFullImage(context, bytes),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(child: Image.memory(bytes as Uint8List)),
          ),
        ),
      ),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Preview not available',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
