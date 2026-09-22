import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../config/dependency_injection/chucker_dependencies.dart';
import '../../domain/entities/network_transaction.dart';

/// Displays locally captured HTTP transactions.
class NetworkInspectorPage extends StatefulWidget {
  const NetworkInspectorPage({required this.dependencies, super.key});

  final ChuckerDependencies dependencies;

  @override
  State<NetworkInspectorPage> createState() => _NetworkInspectorPageState();
}

class _NetworkInspectorPageState extends State<NetworkInspectorPage> {
  late Future<List<NetworkTransaction>> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = widget.dependencies.transactions.getAll();
  }

  void _reload() =>
      setState(() => _transactions = widget.dependencies.transactions.getAll());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Network inspector'),
      actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        IconButton(
          tooltip: 'Clear requests',
          onPressed: () async {
            await widget.dependencies.transactions.clear();
            _reload();
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: FutureBuilder<List<NetworkTransaction>>(
      future: _transactions,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load requests: ${snapshot.error}'),
          );
        }
        final transactions = snapshot.data ?? const [];
        if (transactions.isEmpty) {
          return const Center(child: Text('No requests captured yet.'));
        }
        return ListView.separated(
          itemCount: transactions.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, index) =>
              _TransactionTile(transaction: transactions[index]),
        );
      },
    ),
  );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final NetworkTransaction transaction;

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
      '${transaction.uri.host} · ${transaction.duration.inMilliseconds} ms',
    ),
    onTap: () => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TransactionDetails(transaction: transaction),
    ),
  );
}

class _TransactionDetails extends StatelessWidget {
  const _TransactionDetails({required this.transaction});

  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    builder: (_, controller) => ListView(
      controller: controller,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${transaction.method} ${transaction.uri}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Status',
          value: '${transaction.statusCode ?? 'Request failed'}',
        ),
        _Section(
          title: 'Request headers',
          value: _format(transaction.requestHeaders),
        ),
        _Section(
          title: 'Request body',
          value: _format(transaction.requestBody),
        ),
        _Section(
          title: 'Response headers',
          value: _format(transaction.responseHeaders),
        ),
        _Section(
          title: 'Response body',
          value: _format(transaction.responseBody),
        ),
        if (transaction.error != null)
          _Section(title: 'Error', value: transaction.error!),
      ],
    ),
  );

  static String _format(Object? value) {
    if (value == null) return '—';
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } on JsonUnsupportedObjectError {
      return value.toString();
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    ),
  );
}
