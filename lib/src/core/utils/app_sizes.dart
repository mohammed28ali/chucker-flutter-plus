/// Central registry of spacing, padding, border-radius, icon-size and
/// font-size constants used across the network inspector.
///
/// Usage:
/// ```dart
/// import 'package:chucker_flutter_plus/src/core/utils/app_sizes.dart';
///
/// SizedBox(height: AppSizes.gap8)
/// BorderRadius.circular(AppSizes.radiusMd)
/// ```
abstract final class AppSizes {
  // ── Gaps / spacing ──────────────────────────────────────────────────────
  static const double gap2 = 2;
  static const double gap4 = 4;
  static const double gap6 = 6;
  static const double gap8 = 8;
  static const double gap12 = 12;
  static const double gap16 = 16;
  static const double gap24 = 24;
  static const double gap32 = 32;
  static const double gap40 = 40;

  // ── Border radii ────────────────────────────────────────────────────────
  /// Small chip / badge: 6
  static const double radiusSm = 6;

  /// Standard card / container: 12
  static const double radiusMd = 12;

  /// Large sheet / dialog: 16
  static const double radiusLg = 16;

  /// Banner / overlay: 14
  static const double radiusBanner = 14;

  // ── Icon sizes ──────────────────────────────────────────────────────────
  static const double iconXs = 10;
  static const double iconSm = 12;
  static const double iconMd = 16;
  static const double iconLg = 20;
  static const double iconXl = 24;
  static const double iconXxl = 40;

  // ── Font sizes ──────────────────────────────────────────────────────────
  static const double textXs = 10;
  static const double textSm = 11;
  static const double textSmPlus = 11.5;
  static const double textMd = 12;
  static const double textBase = 13;
  static const double textLg = 14;

  // ── Misc widget dimensions ───────────────────────────────────────────────
  /// Label column width in KeyValueRow
  static const double labelColumnWidth = 120;

  /// Color strip width in request banner
  static const double bannerStripWidth = 5;

  /// Color strip height in request banner
  static const double bannerStripHeight = 64;

  /// Empty-state icon container size
  static const double emptyStateIconBox = 80;

  /// Empty-state icon size
  static const double emptyStateIcon = 40;

  // ── Standard paddings ───────────────────────────────────────────────────
  static const double paddingXs = 4;
  static const double paddingSm = 8;
  static const double paddingMd = 12;
  static const double paddingLg = 16;
  static const double paddingXl = 24;
  static const double paddingAll40 = 40;
}
