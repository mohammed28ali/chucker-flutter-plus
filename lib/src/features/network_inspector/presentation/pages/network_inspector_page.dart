import 'package:chucker_flutter_plus/src/config/theme/inspector_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/dependency_injection/chucker_dependencies.dart';
import '../../domain/entities/network_transaction.dart';
import '../chucker_flutter.dart';
import '../inspector_settings.dart';
import '../widgets/method_chip.dart';
import '../widgets/status_badge.dart';
import '../widgets/summary_header.dart';
import '../widgets/empty_state.dart';
import 'request_detail_page.dart';
import 'settings_page.dart';

// ── Sort options ────────────────────────────────────────────────────────────

enum _SortMode { newest, slowest, largest }

// ── Main list page ──────────────────────────────────────────────────────────

class NetworkInspectorPage extends StatefulWidget {
  const NetworkInspectorPage({
    required this.dependencies,
    this.initiallySelectedId,
    this.onClose,
    super.key,
  });
  final ChuckerDependencies dependencies;
  final String? initiallySelectedId;
  final VoidCallback? onClose;

  @override
  State<NetworkInspectorPage> createState() => _NetworkInspectorPageState();
}

class _NetworkInspectorPageState extends State<NetworkInspectorPage> {
  late Future<List<NetworkTransaction>> _future;
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _methodFilter = 'All';
  String _statusFilter = 'All'; // 'All', '2', '3', '4', '5', 'Error'
  bool _errorsOnly = false;
  _SortMode _sort = _SortMode.newest;
  bool _openedInitial = false;
  final Set<String> _selected = {};
  bool _selectMode = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() =>
      setState(() => _future = widget.dependencies.transactions.getAll());

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all logs?'),
        content: const Text(
          'This will permanently remove all captured requests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.dependencies.transactions.clear();
      _reload();
    }
  }

  List<NetworkTransaction> _filter(List<NetworkTransaction> all) {
    var list = all.where((t) {
      final q = _query.toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          t.uri.toString().toLowerCase().contains(q) ||
          t.method.toLowerCase().contains(q) ||
          '${t.statusCode}'.contains(q) ||
          (t.rawResponseBody?.toLowerCase().contains(q) ?? false);
      final matchesMethod = _methodFilter == 'All' || t.method == _methodFilter;
      final matchesStatus =
          _statusFilter == 'All' ||
          (_statusFilter == 'Error' && t.error != null) ||
          '${t.statusCode ?? 0}'.startsWith(_statusFilter);
      final matchesErrors = !_errorsOnly || !t.succeeded;
      return matchesQuery && matchesMethod && matchesStatus && matchesErrors;
    }).toList();

    return switch (_sort) {
      _SortMode.newest =>
        list..sort((a, b) => b.startedAt.compareTo(a.startedAt)),
      _SortMode.slowest =>
        list..sort((a, b) => b.duration.compareTo(a.duration)),
      _SortMode.largest =>
        list..sort((a, b) => b.responseBodySize.compareTo(a.responseBodySize)),
    };
  }

  void _openDetail(BuildContext context, NetworkTransaction t) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => RequestDetailPage(transaction: t),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic),
              ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: _selectMode ? _selectAppBar(theme) : _normalAppBar(theme),
      body: FutureBuilder<List<NetworkTransaction>>(
        future: _future,
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <NetworkTransaction>[];

          // Auto-open initial
          if (!_openedInitial && widget.initiallySelectedId != null) {
            final match = all
                .where((t) => t.id == widget.initiallySelectedId)
                .cast<NetworkTransaction?>()
                .firstOrNull;
            if (match != null) {
              _openedInitial = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _openDetail(context, match);
              });
            }
          }

          final filtered = _filter(all);
          final loading = snapshot.connectionState != ConnectionState.done;

          return Column(
            children: [
              // Summary header
              if (all.isNotEmpty) SummaryHeader(transactions: all),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search URL, method, status, body…',
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              // Filter + sort chips
              _FiltersRow(
                all: all,
                methodFilter: _methodFilter,
                statusFilter: _statusFilter,
                errorsOnly: _errorsOnly,
                sort: _sort,
                onMethodChanged: (v) => setState(() => _methodFilter = v),
                onStatusChanged: (v) => setState(() => _statusFilter = v),
                onErrorsOnlyChanged: (v) => setState(() => _errorsOnly = v),
                onSortChanged: (v) => setState(() => _sort = v),
              ),
              const SizedBox(height: 4),
              // List
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? EmptyState(filtered: all.isNotEmpty)
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final t = filtered[i];
                          return _TransactionTile(
                            transaction: t,
                            selected: _selected.contains(t.id),
                            selectMode: _selectMode,
                            onTap: () {
                              if (_selectMode) {
                                setState(() {
                                  if (_selected.contains(t.id)) {
                                    _selected.remove(t.id);
                                  } else {
                                    _selected.add(t.id);
                                  }
                                  if (_selected.isEmpty) _selectMode = false;
                                });
                              } else {
                                _openDetail(context, t);
                              }
                            },
                            onLongPress: () => setState(() {
                              _selectMode = true;
                              _selected.add(t.id);
                            }),
                            onDelete: () async {
                              // TODO: implement per-item delete when repo supports it
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  AppBar _normalAppBar(ThemeData theme) => AppBar(
    leading: widget.onClose != null
        ? IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close inspector',
            onPressed: widget.onClose,
          )
        : null,
    title: const Text('Network Inspector'),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh_rounded),
        tooltip: 'Refresh',
        onPressed: _reload,
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: 'More options',
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'settings', child: Text('Settings')),
          const PopupMenuItem(value: 'export', child: Text('Export logs')),
          const PopupMenuItem(
            value: 'clear',
            child: Text('Clear all', style: TextStyle(color: Colors.red)),
          ),
        ],
        onSelected: (v) async {
          if (v == 'settings') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InspectorSettingsPage()),
            );
          } else if (v == 'export') {
            final json = await ChuckerFlutterPlus.exportLogs();
            await SharePlus.instance.share(ShareParams(text: json));
          } else if (v == 'clear') {
            await _clearAll();
          }
        },
      ),
    ],
  );

  AppBar _selectAppBar(ThemeData theme) => AppBar(
    leading: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => setState(() {
        _selectMode = false;
        _selected.clear();
      }),
    ),
    title: Text('${_selected.length} selected'),
    actions: [
      IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete selected',
        onPressed: () async {
          // TODO: implement batch delete when repo supports per-item delete
          setState(() {
            _selectMode = false;
            _selected.clear();
          });
        },
      ),
    ],
  );
}

// ── Filters row ─────────────────────────────────────────────────────────────

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.all,
    required this.methodFilter,
    required this.statusFilter,
    required this.errorsOnly,
    required this.sort,
    required this.onMethodChanged,
    required this.onStatusChanged,
    required this.onErrorsOnlyChanged,
    required this.onSortChanged,
  });
  final List<NetworkTransaction> all;
  final String methodFilter, statusFilter;
  final bool errorsOnly;
  final _SortMode sort;
  final ValueChanged<String> onMethodChanged, onStatusChanged;
  final ValueChanged<bool> onErrorsOnlyChanged;
  final ValueChanged<_SortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final methods = {'All', ...all.map((t) => t.method)};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Method chips
          ...methods.map(
            (m) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: m,
                selected: methodFilter == m,
                color: m == 'All' ? null : InspectorColors.methodColor(m),
                onSelected: () => onMethodChanged(m),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Status group chips
          ...[
            ('All', null),
            ('2xx', InspectorColors.status2xx),
            ('3xx', InspectorColors.status3xx),
            ('4xx', InspectorColors.status4xx),
            ('5xx', InspectorColors.status5xx),
          ].map((entry) {
            final label = entry.$1;
            final color = entry.$2;
            final key = label == 'All' ? 'All' : label[0];
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: label,
                selected: statusFilter == key,
                color: color,
                onSelected: () => onStatusChanged(key),
              ),
            );
          }),
          const SizedBox(width: 4),
          // Errors only toggle
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _FilterChip(
              label: 'Errors only',
              selected: errorsOnly,
              color: InspectorColors.statusError,
              icon: Icons.error_outline,
              onSelected: () => onErrorsOnlyChanged(!errorsOnly),
            ),
          ),
          const SizedBox(width: 4),
          // Sort
          _SortChip(current: sort, onChanged: onSortChanged),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
    this.icon,
  });
  final String label;
  final bool selected;
  final Color? color;
  final IconData? icon;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? c.withOpacity(0.15)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? c : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? c : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.current, required this.onChanged});
  final _SortMode current;
  final ValueChanged<_SortMode> onChanged;

  String get _label => switch (current) {
    _SortMode.newest => 'Newest',
    _SortMode.slowest => 'Slowest',
    _SortMode.largest => 'Largest',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<_SortMode>(
      initialValue: current,
      onSelected: onChanged,
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _SortMode.newest,
          child: Text('Newest first'),
        ),
        const PopupMenuItem(
          value: _SortMode.slowest,
          child: Text('Slowest first'),
        ),
        const PopupMenuItem(
          value: _SortMode.largest,
          child: Text('Largest first'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 13),
            const SizedBox(width: 4),
            Text(
              _label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Transaction tile ─────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    this.selected = false,
    this.selectMode = false,
  });
  final NetworkTransaction transaction;
  final VoidCallback onTap, onLongPress, onDelete;
  final bool selected, selectMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = transaction;

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: selected
              ? theme.colorScheme.primaryContainer.withOpacity(0.5)
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (selectMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                // Method chip
                MethodChip(t.method),
                const SizedBox(width: 8),
                // Status badge
                StatusBadge(t.statusCode, error: t.error),
                const SizedBox(width: 10),
                // URL info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.uri.path.isEmpty ? '/' : t.uri.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right meta column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDuration(t.duration),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _durationColor(t.duration, theme),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(t.startedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (t.responseBodySize > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        _sizeStr(t.responseBodySize),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _durationColor(Duration d, ThemeData theme) {
    if (d.inMilliseconds < 300) return InspectorColors.status2xx;
    if (d.inMilliseconds < 1000) return InspectorColors.status4xx;
    return InspectorColors.status5xx;
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds >= 1)
      return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
    return '${d.inMilliseconds}ms';
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String _sizeStr(int bytes) => bytes < 1024
      ? '$bytes B'
      : bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(1)} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
