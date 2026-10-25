import 'dart:convert';

import 'package:chucker_flutter_plus/src/config/theme/inspector_colors.dart';
import 'package:chucker_flutter_plus/src/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _ViewMode { tree, pretty, raw }

class BodyViewer extends StatefulWidget {
  const BodyViewer({
    super.key,
    required this.body,
    required this.contentType,
    this.truncated = false,
    this.label = AppStrings.bodyLabel,
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
  final String _search = '';
  bool _showLineNumbers = false;

  bool get _isJson {
    final ct = widget.contentType?.toLowerCase() ?? '';
    if (ct.contains('json')) return true;
    final b = widget.body?.trim() ?? '';
    return b.startsWith('{') || b.startsWith('[');
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
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Text(
          AppStrings.noBody,
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
            context.successSnackBar(AppStrings.bodyCopied);
          },
          body: body,
        ),
        if (widget.truncated)
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLg,
              vertical: AppSizes.paddingXs,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingSm + 2,
              vertical: AppSizes.paddingSm - 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppSizes.radius8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppSizes.icon14,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: AppSizes.gap6),
                Expanded(
                  child: Text(
                    AppStrings.bodyTruncatedWarning,
                    style: TextStyle(
                      fontSize: AppSizes.textMd,
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
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLg,
        0,
        AppSizes.paddingSm,
        AppSizes.paddingSm,
      ),
      child: Row(
        children: [
          if (isJson) ...[
            _ModeButton(
              AppStrings.bodyViewTree,
              _ViewMode.tree,
              mode,
              onModeChange,
            ),
            const SizedBox(width: AppSizes.gap4),
            _ModeButton(
              AppStrings.bodyViewPretty,
              _ViewMode.pretty,
              mode,
              onModeChange,
            ),
            const SizedBox(width: AppSizes.gap4),
            _ModeButton(
              AppStrings.bodyViewRaw,
              _ViewMode.raw,
              mode,
              onModeChange,
            ),
            const SizedBox(width: AppSizes.gap8),
          ],
          const Spacer(),
          Tooltip(
            message: AppStrings.wordWrap,
            child: IconButton(
              icon: Icon(
                Icons.wrap_text,
                size: AppSizes.icon18,
                color: wordWrap ? theme.colorScheme.primary : null,
              ),
              onPressed: () => onWordWrapChange(!wordWrap),
            ),
          ),
          Tooltip(
            message: AppStrings.lineNumbers,
            child: IconButton(
              icon: Icon(
                Icons.format_list_numbered,
                size: AppSizes.icon18,
                color: showLineNumbers ? theme.colorScheme.primary : null,
              ),
              onPressed: () => onLineNumbersChange(!showLineNumbers),
            ),
          ),
          Tooltip(
            message: AppStrings.copy,
            child: IconButton(
              icon: const Icon(Icons.copy_outlined, size: AppSizes.icon18),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingSm + 2,
          vertical: AppSizes.paddingXs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.textSm,
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
      fontSize: AppSizes.textSmPlus,
      height: 1.6,
      color: theme.colorScheme.onSurface,
    );
    final lineNumStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: AppSizes.textSmPlus,
      height: 1.6,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
    );

    return SingleChildScrollView(
      scrollDirection: wordWrap ? Axis.vertical : Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLg,
        0,
        AppSizes.paddingLg,
        AppSizes.paddingLg,
      ),
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
                const SizedBox(width: AppSizes.gap12),
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
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLg,
        0,
        AppSizes.paddingLg,
        AppSizes.paddingLg,
      ),
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
      final count = isMap ? v.length : (v as List).length;
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
                  size: AppSizes.icon18,
                  color: isDark
                      ? InspectorColors.jsonKeyDark
                      : InspectorColors.jsonKey,
                ),
                if (key != null)
                  Text(
                    '"$key": ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: AppSizes.textMd,
                      color: isDark
                          ? InspectorColors.jsonKeyDark
                          : InspectorColors.jsonKey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  _expanded
                      ? bracket.$1
                      : '${bracket.$1}…${bracket.$2} $count ${AppStrings.items}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: AppSizes.textMd,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: AppSizes.paddingLg),
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
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: AppSizes.textMd,
              ),
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
                  fontSize: AppSizes.textMd,
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
                fontSize: AppSizes.textMd,
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
    if (v == null) {
      return dark ? InspectorColors.jsonNullDark : InspectorColors.jsonNull;
    }
    if (v is String) {
      return dark ? InspectorColors.jsonStringDark : InspectorColors.jsonString;
    }
    if (v is num) {
      return dark ? InspectorColors.jsonNumberDark : InspectorColors.jsonNumber;
    }
    if (v is bool) {
      return dark ? InspectorColors.jsonBoolDark : InspectorColors.jsonBool;
    }
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
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Text(
          AppStrings.emptyFormData,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLg,
        0,
        AppSizes.paddingLg,
        AppSizes.paddingLg,
      ),
      child: Table(
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        border: TableBorder.all(
          color: theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            children: [
              _cell(AppStrings.key, bold: true, theme: theme),
              _cell(AppStrings.value, bold: true, theme: theme),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingSm,
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      );
}
