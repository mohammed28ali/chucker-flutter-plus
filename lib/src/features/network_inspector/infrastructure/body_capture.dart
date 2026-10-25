import 'dart:convert';
import 'dart:typed_data';

class BodyCapture {
  static String? raw(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List<int>) return base64Encode(value);
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  static int size(Object? value, String? rawValue) {
    if (value is Uint8List || value is List<int>) {
      return (value as List<int>).length;
    }
    return rawValue == null ? 0 : utf8.encode(rawValue).length;
  }

  static Map<String, String> redact(
    Map<String, String> headers,
    Set<String> sensitive,
  ) => Map.unmodifiable(
    headers.map(
      (key, value) => MapEntry(
        key,
        sensitive.contains(key.toLowerCase()) ? '██REDACTED██' : value,
      ),
    ),
  );
}
