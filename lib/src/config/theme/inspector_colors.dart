import 'package:flutter/material.dart';

abstract final class InspectorColors {
  static const Color seed = Color(0xFF0891F2);
  static const Color seedAccent = Color(0xFF22D3EE);

  static const Color brandNavy = Color(0xFF0B1428);
  static const Color brandBlue = Color(0xFF008DFF);
  static const Color brandCyan = Color(0xFF22D3EE);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22D3EE), Color(0xFF0891F2), Color(0xFF0066FF)],
  );

  // ── Method chips ────────────────────────────────────────────────
  static const Color get_ = Color(0xFF0284C7); // blue
  static const Color post = Color(0xFF059669); // emerald
  static const Color put = Color(0xFFD97706); // amber
  static const Color patch = Color(0xFF9333EA); // violet
  static const Color delete = Color(0xFFDC2626); // red
  static const Color head = Color(0xFF0891B2); // cyan
  static const Color options = Color(0xFF4F46E5); // indigo
  static const Color other = Color(0xFF64748B); // slate

  // ── Status code groups (light) ──────────────────────────────────
  static const Color status2xx = Color(0xFF059669);
  static const Color status2xxBg = Color(0xFFD1FAE5);

  static const Color status3xx = Color(0xFF2563EB);
  static const Color status3xxBg = Color(0xFFDBEAFE);

  static const Color status4xx = Color(0xFFD97706);
  static const Color status4xxBg = Color(0xFFFEF3C7);

  static const Color status5xx = Color(0xFFDC2626);
  static const Color status5xxBg = Color(0xFFFEE2E2);

  static const Color statusError = Color(0xFFBE123C);
  static const Color statusErrorBg = Color(0xFFFFE4E6);

  static const Color statusPending = Color(0xFF64748B);
  static const Color statusPendingBg = Color(0xFFF1F5F9);

  // ── Status code groups (dark) ──────────────────────────────────
  static const Color status2xxDark = Color(0xFF34D399);
  static const Color status2xxBgDark = Color(0xFF064E3B);

  static const Color status3xxDark = Color(0xFF60A5FA);
  static const Color status3xxBgDark = Color(0xFF172554);

  static const Color status4xxDark = Color(0xFFFBBF24);
  static const Color status4xxBgDark = Color(0xFF78350F);

  static const Color status5xxDark = Color(0xFFFB7185);
  static const Color status5xxBgDark = Color(0xFF881337);

  static const Color statusErrorDark = Color(0xFFFDA4AF);
  static const Color statusErrorBgDark = Color(0xFF4C0519);

  // ── JSON syntax (light) ─────────────────────────────────────────
  static const Color jsonString = Color(0xFF059669);
  static const Color jsonNumber = Color(0xFF0284C7);
  static const Color jsonBool = Color(0xFFD97706);
  static const Color jsonNull = Color(0xFF64748B);
  static const Color jsonKey = Color(0xFF7C3AED);

  // ── JSON syntax (dark) ──────────────────────────────────────────
  static const Color jsonStringDark = Color(0xFF6EE7B7);
  static const Color jsonNumberDark = Color(0xFF38BDF8);
  static const Color jsonBoolDark = Color(0xFFFCD34D);
  static const Color jsonNullDark = Color(0xFF94A3B8);
  static const Color jsonKeyDark = Color(0xFFC4B5FD);

  // ── Surface / overlay tones (light) ─────────────────────────────
  static const Color surface = Color(0xFFF4F8FF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFDFE7F2);

  // ── Surface / overlay tones (dark) ──────────────────────────────
  static const Color surfaceDark = Color(0xFF0B1428);
  static const Color cardDark = Color(0xFF111D35);
  static const Color dividerDark = Color(0xFF263650);

  // ── Brand-specific surfaces ─────────────────────────────────────
  static const Color primaryLight = Color(0xFF007BFF);
  static const Color primaryDark = Color(0xFF38BDF8);

  static const Color accentLight = Color(0xFF0891B2);
  static const Color accentDark = Color(0xFF22D3EE);

  static const Color brandTintLight = Color(0xFFE0F2FE);
  static const Color brandTintDark = Color(0xFF102D4D);

  // ── Helpers ─────────────────────────────────────────────────────
  static Color methodColor(String method) => switch (method.toUpperCase()) {
    'GET' => get_,
    'POST' => post,
    'PUT' => put,
    'PATCH' => patch,
    'DELETE' => delete,
    'HEAD' => head,
    'OPTIONS' => options,
    _ => other,
  };

  static (Color fg, Color bg) statusColors(int? code, {required bool dark}) {
    if (code == null) {
      return dark
          ? (statusErrorDark, statusErrorBgDark)
          : (statusError, statusErrorBg);
    }

    if (code < 300) {
      return dark ? (status2xxDark, status2xxBgDark) : (status2xx, status2xxBg);
    }

    if (code < 400) {
      return dark ? (status3xxDark, status3xxBgDark) : (status3xx, status3xxBg);
    }

    if (code < 500) {
      return dark ? (status4xxDark, status4xxBgDark) : (status4xx, status4xxBg);
    }

    return dark ? (status5xxDark, status5xxBgDark) : (status5xx, status5xxBg);
  }
}
