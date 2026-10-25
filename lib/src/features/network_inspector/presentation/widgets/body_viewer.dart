import 'dart:convert';

import 'package:chucker_flutter_plus/src/config/theme/inspector_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _ViewMode { tree, pretty, raw }

/// Smart body viewer that handles JSON, XML/HTML, form-data, plain text, and binary.
class BodyViewer extends StatefulWidget {
  const BodyViewer({
    super.key,
    required this.body,
    required this.contentType,
    this.truncated = false,
    this.label = 'Body',
  });
  final String? body;
  final String? contentType;
  final bool truncated;
  final String label;

  @override
  State<BodyViewer> createState() => _BodyViewerState();
}

class _BodyViewerState extends State<BodyViewer> {
  _ViewMode _mode = _ViewMode.pretty;
  bool _wordWrap = true;
  String _search = '';
  int _searchPage = 0;
  bool _showLineNumbers = false;

  bool get _isJson {
    final ct = widget.contentType?.toLowerCase() ?? '';
    if (ct.contains('json')) return true;
    final b = widget.body?.trim() ?? '';
    return (b.startsWith('{') || b.startsWith('['));
  }

  bool get _isXml {
    final ct = widget.contentType?.toLowerCase() ?? '';
    return ct.contains('xml') || ct.contains('html');
  }

  bool get _isFormData {
    final ct = widget.contentType?.toLowerCase() ?? '';
    return ct.contains('x-www-form-urlencoded');
  }

  Object? _parsedJson;
  bool _parseAttempted = false;

  Object? get parsedJson {
    if (!_parseAttempted) {
      _parseAttempted = true;
      try {
        _parsedJson = jsonDecode(widget.body ?? '');
      } catch (_) {
        _parsedJson = null;
      }
    }
    return _parsedJson;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = widget.body;

    if (body == null || body.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No body',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        _Toolbar(
          isJson: _isJson,
          mode: _mode,
          wordWrap: _wordWrap,
          showLineNumbers: _showLineNumbers,
          onModeChange: (m) => setState(() => _mode = m),
          onWordWrapChange: (v) => setState(() => _wordWrap = v),
          onLineNumbersChange: (v) => setState(() => _showLineNumbers = v),
          onCopy: () {
            Clipboard.setData(ClipboardData(text: body));
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('Body copied to clipboard'),
                duration: Duration(milliseconds: 1500),
              ),
            );
          },
          body: body,
        ),
        if (widget.truncated)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Body truncated — full body was too large to capture.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Content
        if (_isJson && _mode == _ViewMode.tree && parsedJson != null)
          _JsonTree(json: parsedJson!)
        else if (_isFormData)
          _FormDataTable(body: body)
        else
          _TextBody(
            body: _isJson && _mode == _ViewMode.pretty
                ? _prettyJson(body)
                : body,
            wordWrap: _wordWrap,
            showLineNumbers: _showLineNumbers,
            search: _search,
          ),
      ],
    );
  }

  String _prettyJson(String raw) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } catch (_) {
      return raw;
    }
  }
}

// ── Toolbar ────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.isJson,
    required this.mode,
    required this.wordWrap,
    required this.showLineNumbers,
    required this.onModeChange,
    required this.onWordWrapChange,
    required this.onLineNumbersChange,
    required this.onCopy,
    required this.body,
  });
  final bool isJson;
  final _ViewMode mode;
  final bool wordWrap, showLineNumbers;
  final ValueChanged<_ViewMode> onModeChange;
  final ValueChanged<bool> onWordWrapChange;
  final ValueChanged<bool> onLineNumbersChange;
  final VoidCallback onCopy;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          if (isJson) ...[
            _ModeButton('Tree', _ViewMode.tree, mode, onModeChange),
            const SizedBox(width: 4),
            _ModeButton('Pretty', _ViewMode.pretty, mode, onModeChange),
            const SizedBox(width: 4),
            _ModeButton('Raw', _ViewMode.raw, mode, onModeChange),
            const SizedBox(width: 8),
          ],
          const Spacer(),
          Tooltip(
            message: 'Word wrap',
            child: IconButton(
              icon: Icon(
                Icons.wrap_text,
                size: 18,
                color: wordWrap ? theme.colorScheme.primary : null,
              ),
              onPressed: () => onWordWrapChange(!wordWrap),
            ),
          ),
          Tooltip(
            message: 'Line numbers',
            child: IconButton(
              icon: Icon(
                Icons.format_list_numbered,
                size: 18,
                color: showLineNumbers ? theme.colorScheme.primary : null,
              ),
              onPressed: () => onLineNumbersChange(!showLineNumbers),
            ),
          ),
          Tooltip(
            message: 'Copy',
            child: IconButton(
              icon: const Icon(Icons.copy_outlined, size: 18),
              onPressed: onCopy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton(this.label, this.value, this.current, this.onTap);
  final String label;
  final _ViewMode value, current;
  final ValueChanged<_ViewMode> onTap;
  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Text body ──────────────────────────────────────────────────────────────

class _TextBody extends StatelessWidget {
  const _TextBody({
    required this.body,
    required this.wordWrap,
    required this.showLineNumbers,
    required this.search,
  });
  final String body;
  final bool wordWrap, showLineNumbers;
  final String search;

  @override
  Widget build(BuildContext context) {
    final lines = body.split('\n');
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      height: 1.6,
      color: theme.colorScheme.onSurface,
    );
    final lineNumStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      height: 1.6,
      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
    );

    return SingleChildScrollView(
      scrollDirection: wordWrap ? Axis.vertical : Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: showLineNumbers
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < lines.length; i++)
                      Text('${i + 1}', style: lineNumStyle),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final l in lines) Text(l, style: textStyle)],
                ),
              ],
            )
          : SelectableText(body, style: textStyle),
    );
  }
}

// ── JSON tree ──────────────────────────────────────────────────────────────

class _JsonTree extends StatelessWidget {
  const _JsonTree({required this.json});
  final Object json;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _JsonNode(value: json, depth: 0, expanded: true),
    );
  }
}

class _JsonNode extends StatefulWidget {
  const _JsonNode({
    super.key,
    required this.value,
    required this.depth,
    this.keyName,
    this.expanded = false,
  });
  final Object? value;
  final int depth;
  final String? keyName;
  final bool expanded;
  @override
  State<_JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<_JsonNode> {
  late bool _expanded;
  @override
  void initState() {
    super.initState();
    _expanded = widget.expanded || widget.depth < 2;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final v = widget.value;
    final key = widget.keyName;

    if (v is Map<String, dynamic> || v is List) {
      final isMap = v is Map;
      final count = isMap ? (v as Map).length : (v as List).length;
      final bracket = isMap ? ('{', '}') : ('[', ']');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded ? Icons.arrow_drop_down : Icons.arrow_right,
                  size: 18,
                  color: isDark
                      ? InspectorColors.jsonKeyDark
                      : InspectorColors.jsonKey,
                ),
                if (key != null)
                  Text(
                    '"$key": ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isDark
                          ? InspectorColors.jsonKeyDark
                          : InspectorColors.jsonKey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  _expanded
                      ? bracket.$1
                      : '${bracket.$1}…${bracket.$2} $count items',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: isMap
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (v as Map<String, dynamic>).entries
                          .map(
                            (e) => _JsonNode(
                              key: ValueKey(e.key),
                              keyName: e.key,
                              value: e.value,
                              depth: widget.depth + 1,
                            ),
                          )
                          .toList(),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (v as List)
                          .asMap()
                          .entries
                          .map(
                            (e) => _JsonNode(
                              key: ValueKey(e.key),
                              keyName: '${e.key}',
                              value: e.value,
                              depth: widget.depth + 1,
                            ),
                          )
                          .toList(),
                    ),
            ),
          if (_expanded)
            Text(
              bracket.$2,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
        ],
      );
    }

    // Leaf node
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          children: [
            if (key != null)
              TextSpan(
                text: '"$key": ',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: isDark
                      ? InspectorColors.jsonKeyDark
                      : InspectorColors.jsonKey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            TextSpan(
              text: _format(v),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: _color(v, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(Object? v) {
    if (v == null) return 'null';
    if (v is String) return '"$v"';
    return '$v';
  }

  Color _color(Object? v, bool dark) {
    if (v == null)
      return dark ? InspectorColors.jsonNullDark : InspectorColors.jsonNull;
    if (v is String)
      return dark ? InspectorColors.jsonStringDark : InspectorColors.jsonString;
    if (v is num)
      return dark ? InspectorColors.jsonNumberDark : InspectorColors.jsonNumber;
    if (v is bool)
      return dark ? InspectorColors.jsonBoolDark : InspectorColors.jsonBool;
    return dark ? Colors.white70 : Colors.black87;
  }
}

// ── Form-data table ────────────────────────────────────────────────────────

class _FormDataTable extends StatelessWidget {
  const _FormDataTable({required this.body});
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pairs = Uri.splitQueryString(body).entries.toList();
    if (pairs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('(empty form data)', style: theme.textTheme.bodyMedium),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Table(
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        border: TableBorder.all(
          color: theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            children: [
              _cell('Key', bold: true, theme: theme),
              _cell('Value', bold: true, theme: theme),
            ],
          ),
          ...pairs.map(
            (e) => TableRow(
              children: [
                _cell(e.key, theme: theme),
                _cell(e.value, theme: theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool bold = false, required ThemeData theme}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      );
}
