import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../config/dependency_injection/chucker_dependencies.dart';
import '../../domain/entities/network_transaction.dart';

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
  String _query = '';
  String _method = 'All';
  String _status = 'All';
  @override
  void initState() {
    super.initState();
    _future = widget.dependencies.transactions.getAll();
  }

  void _reload() =>
      setState(() => _future = widget.dependencies.transactions.getAll());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Network inspector'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: widget.onClose,
      ),
      actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await widget.dependencies.transactions.clear();
            _reload();
          },
        ),
      ],
    ),
    body: FutureBuilder<List<NetworkTransaction>>(
      future: _future,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <NetworkTransaction>[];
        final values = all
            .where(
              (t) =>
                  (_query.isEmpty ||
                      '${t.uri} ${t.method} ${t.host}'.toLowerCase().contains(
                        _query.toLowerCase(),
                      )) &&
                  (_method == 'All' || t.method == _method) &&
                  (_status == 'All' ||
                      '${t.statusCode ?? 0}'.startsWith(_status)),
            )
            .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search URL or host',
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                _filter('All', _method, (v) => setState(() => _method = v), [
                  'All',
                  ...{for (final t in all) t.method},
                ]),
                _filter('All', _status, (v) => setState(() => _status = v), [
                  'All',
                  '2',
                  '3',
                  '4',
                  '5',
                ]),
              ],
            ),
            Expanded(
              child: snapshot.connectionState != ConnectionState.done
                  ? const Center(child: CircularProgressIndicator())
                  : values.isEmpty
                  ? const Center(child: Text('No requests captured yet.'))
                  : ListView.separated(
                      itemCount: values.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _Tile(
                        transaction: values[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _Details(transaction: values[i]),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
  Widget _filter(
    String label,
    String selected,
    ValueChanged<String> onChanged,
    List<String> values,
  ) => DropdownButton<String>(
    value: selected,
    items: values
        .map(
          (v) =>
              DropdownMenuItem(value: v, child: Text(v == 'All' ? label : v)),
        )
        .toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.transaction, required this.onTap});
  final NetworkTransaction transaction;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      backgroundColor: transaction.succeeded ? Colors.green : Colors.red,
      child: Text(
        '${transaction.statusCode ?? '!'}',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    ),
    title: Text('${transaction.method} ${transaction.uri.path}'),
    subtitle: Text(
      '${transaction.host} · ${transaction.duration.inMilliseconds} ms · ${_size(transaction.responseBodySize)}',
    ),
    trailing: Text(transaction.contentType ?? ''),
    onTap: onTap,
  );
}

class _Details extends StatefulWidget {
  const _Details({required this.transaction});
  final NetworkTransaction transaction;
  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool raw = true;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    return Scaffold(
      appBar: AppBar(
        title: Text('${t.method} ${t.statusCode ?? 'Error'}'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Request'),
            Tab(text: 'Raw data'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _text('URL', t.uri.toString()),
          _text(
            'Headers',
            '${t.requestHeaders}\n\nBody (${_size(t.requestBodySize)})\n${_body(t.rawRequestBody)}',
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: Text(raw ? 'Raw' : 'Formatted'),
                value: raw,
                onChanged: (v) => setState(() => raw = v),
              ),
              _actions(t),
              _text(
                'Request (${_size(t.requestBodySize)})',
                _body(t.rawRequestBody),
              ),
              _text(
                'Response (${_size(t.responseBodySize)})',
                _body(t.rawResponseBody),
              ),
              _text('Response headers', t.responseHeaders.toString()),
              if (t.error != null)
                _text('Error', '${t.error}\n${t.stackTrace ?? ''}'),
            ],
          ),
        ],
      ),
    );
  }

  String _body(String? value) {
    if (value == null) return '—';
    if (raw) return value;
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(value));
    } catch (_) {
      return value;
    }
  }

  Widget _actions(NetworkTransaction t) => Wrap(
    spacing: 8,
    children: [
      TextButton.icon(
        onPressed: () =>
            Clipboard.setData(ClipboardData(text: t.rawResponseBody ?? '')),
        icon: const Icon(Icons.copy),
        label: const Text('Copy raw'),
      ),
      TextButton.icon(
        onPressed: () => Clipboard.setData(ClipboardData(text: _curl(t))),
        icon: const Icon(Icons.terminal),
        label: const Text('Copy cURL'),
      ),
      TextButton.icon(
        onPressed: () => SharePlus.instance.share(ShareParams(text: _curl(t))),
        icon: const Icon(Icons.share),
        label: const Text('Share'),
      ),
    ],
  );
  String _curl(NetworkTransaction t) {
    final headers = t.requestHeaders.entries
        .map((e) => '-H ${e.key}:${e.value}')
        .join(' ');
    final data = t.rawRequestBody == null ? '' : '--data ${t.rawRequestBody}';
    return 'curl -X ${t.method} $headers $data ${t.uri}';
  }

  Widget _text(String title, String value) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SelectableText(value),
      ],
    ),
  );
}

String _size(int bytes) => bytes < 1024
    ? '$bytes B'
    : bytes < 1024 * 1024
    ? '${(bytes / 1024).toStringAsFixed(1)} KB'
    : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
