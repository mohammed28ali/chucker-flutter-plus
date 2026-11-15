import 'dart:convert';

/// Redaction helpers shared by all network client adapters.
class LogRedactor {
  const LogRedactor({
    this.sensitiveHeaders = const {
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
    },
    this.sensitiveJsonKeys = const {
      'password',
      'token',
      'access_token',
      'refresh_token',
      'secret',
    },
    this.replacement = '[REDACTED]',
  });

  final Set<String> sensitiveHeaders;
  final Set<String> sensitiveJsonKeys;
  final String replacement;

  Map<String, Object?> headers(Map<String, Object?> input) => {
    for (final entry in input.entries)
      entry.key: sensitiveHeaders.contains(entry.key.toLowerCase())
          ? replacement
          : entry.value,
  };

  Object? body(Object? input) {
    if (input is Map) {
      return {
        for (final entry in input.entries)
          entry.key.toString():
              sensitiveJsonKeys.contains(entry.key.toString().toLowerCase())
              ? replacement
              : body(entry.value),
      };
    }
    if (input is List) return input.map(body).toList(growable: false);
    if (input is String) {
      try {
        final decoded = jsonDecode(input);
        if (decoded is Map || decoded is List) return body(decoded);
      } catch (_) {}
    }
    return input;
  }
}
