import 'package:flutter/material.dart';

import '../utils/app_sizes.dart';

/// A custom text widget that wraps [Text] with preset styles drawn from
/// the current theme. Instead of repeating [TextStyle] inline everywhere,
/// use one of the named constructors:
///
/// ```dart
/// AppText.label('METHOD')          // xs, w700, uppercase style
/// AppText.body('Some value')       // bodyMedium
/// AppText.caption('11 ms')         // xs, muted
/// AppText.title('Overview')        // titleSmall, bold
/// AppText.monospace('{"key":1}')   // md, monospace font
/// ```
///
/// All constructors forward [style] overrides, [maxLines], [overflow],
/// [textAlign] and [softWrap] to the underlying [Text] widget.
class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
    required this._variant,
  });

  // ── Named constructors ───────────────────────────────────────────────────

  /// Small uppercase label – used for key-value row labels and filter chips.
  const AppText.label(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  }) : _variant = _Variant.label;

  /// Standard body text using [TextTheme.bodyMedium].
  const AppText.body(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  }) : _variant = _Variant.body;

  /// Small muted caption text (e.g. durations, sizes, timestamps).
  const AppText.caption(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  }) : _variant = _Variant.caption;

  /// Section/card title using [TextTheme.titleSmall] bold.
  const AppText.title(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  }) : _variant = _Variant.title;

  /// Monospace text for bodies, URLs, JSON, and code snippets.
  const AppText.monospace(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  }) : _variant = _Variant.monospace;

  /// Bold stat value used in summary header tiles.
  const AppText.stat(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  }) : _variant = _Variant.stat;

  // ── Fields ───────────────────────────────────────────────────────────────

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;
  final _Variant _variant;

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextStyle base;

    switch (_variant) {
      case _Variant.label:
        base = (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: theme.colorScheme.onSurfaceVariant,
        );
      case _Variant.body:
        base = theme.textTheme.bodyMedium ?? const TextStyle();
      case _Variant.caption:
        base = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
          fontSize: AppSizes.textSm,
          color: theme.colorScheme.onSurfaceVariant,
        );
      case _Variant.title:
        base = (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        );
      case _Variant.monospace:
        base = const TextStyle(
          fontFamily: 'monospace',
          fontSize: AppSizes.textMd,
        );
      case _Variant.stat:
        base = TextStyle(
          fontSize: AppSizes.textBase,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        );
    }

    final merged = style != null ? base.merge(style) : base;

    return Text(
      text,
      style: merged,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softWrap,
    );
  }
}

enum _Variant { label, body, caption, title, monospace, stat }
