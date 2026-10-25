import 'package:flutter/material.dart';

abstract final class InspectorColors {
  // ── Brand seed ──────────────────────────────────────────────────
  static const Color seed = Color(0xFF4F6AF5);

  // ── Method chips ────────────────────────────────────────────────
  static const Color get_ = Color(0xFF1E88E5);
  static const Color post = Color(0xFF43A047);
  static const Color put = Color(0xFFFB8C00);
  static const Color patch = Color(0xFF8E24AA);
  static const Color delete = Color(0xFFE53935);
  static const Color head = Color(0xFF00ACC1);
  static const Color options = Color(0xFF6D4C41);
  static const Color other = Color(0xFF546E7A);

  // ── Status code groups ──────────────────────────────────────────
  static const Color status2xx = Color(0xFF2E7D32);
  static const Color status2xxBg = Color(0xFFE8F5E9);
  static const Color status3xx = Color(0xFF1565C0);
  static const Color status3xxBg = Color(0xFFE3F2FD);
  static const Color status4xx = Color(0xFFE65100);
  static const Color status4xxBg = Color(0xFFFFF3E0);
  static const Color status5xx = Color(0xFFC62828);
  static const Color status5xxBg = Color(0xFFFFEBEE);
  static const Color statusError = Color(0xFFB71C1C);
  static const Color statusErrorBg = Color(0xFFFFEBEE);
  static const Color statusPending = Color(0xFF546E7A);
  static const Color statusPendingBg = Color(0xFFECEFF1);

  // ── Dark variants (lighter for dark bg) ─────────────────────────
  static const Color status2xxDark = Color(0xFF66BB6A);
  static const Color status2xxBgDark = Color(0xFF1B5E20);
  static const Color status3xxDark = Color(0xFF42A5F5);
  static const Color status3xxBgDark = Color(0xFF0D47A1);
  static const Color status4xxDark = Color(0xFFFF9800);
  static const Color status4xxBgDark = Color(0xFFE65100);
  static const Color status5xxDark = Color(0xFFEF5350);
  static const Color status5xxBgDark = Color(0xFFB71C1C);

  // ── JSON syntax ─────────────────────────────────────────────────
  static const Color jsonString = Color(0xFF388E3C);
  static const Color jsonNumber = Color(0xFF1976D2);
  static const Color jsonBool = Color(0xFF7B1FA2);
  static const Color jsonNull = Color(0xFF9E9E9E);
  static const Color jsonKey = Color(0xFFBF360C);
  static const Color jsonStringDark = Color(0xFF81C784);
  static const Color jsonNumberDark = Color(0xFF64B5F6);
  static const Color jsonBoolDark = Color(0xFFCE93D8);
  static const Color jsonNullDark = Color(0xFF757575);
  static const Color jsonKeyDark = Color(0xFFFFAB91);

  // ── Surface / overlay tones ──────────────────────────────────────
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceDark = Color(0xFF111318);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E2128);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF2A2D35);

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
      return dark ? (statusError, statusErrorBg) : (statusError, statusErrorBg);
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
