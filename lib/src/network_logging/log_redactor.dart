/// Redacts common secrets from headers and nested JSON-like values.
class LogRedactor {
  const LogRedactor({
    this.sensitiveHeaders = const {
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'api-key',
    },
    this.sensitiveJsonKeys = const {
      'password',
      'token',
      'access_token',
      'refresh_token',
      'secret',
      'authorization',
      'api_key',
    },
    this.replacement = '[REDACTED]',
  });
  final Set<String> sensitiveHeaders;
  final Set<String> sensitiveJsonKeys;
  final String replacement;

  Map<String, Object?> redactHeaders(Map<String, Object?> headers) => {
    for (final entry in headers.entries)
      entry.key: _contains(sensitiveHeaders, entry.key)
          ? replacement
          : redactValue(entry.value),
  };

  Object? redactValue(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key
              .toString(): _contains(sensitiveJsonKeys, entry.key.toString())
              ? replacement
              : redactValue(entry.value),
      };
    }
    if (value is Iterable) {
      return value.map(redactValue).toList(growable: false);
    }
    return value;
  }

  bool _contains(Set<String> values, String candidate) =>
      values.any((value) => _normalize(value) == _normalize(candidate));

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
}
