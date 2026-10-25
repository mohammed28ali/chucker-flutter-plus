/// All user-visible strings used by the network inspector.
///
/// Centralising strings makes it easy to localise the package later
/// and prevents scattered hard-coded literals throughout the UI code.
///
/// Usage:
/// ```dart
/// import 'package:chucker_flutter_plus/src/core/utils/app_strings.dart';
///
/// Text(AppStrings.networkInspectorTitle)
/// ```
abstract final class AppStrings {
  // ── App bar / titles ─────────────────────────────────────────────────────
  static const String networkInspectorTitle = 'Network Inspector';
  static const String settingsTitle = 'Settings';
  static const String requestDetailTitle = 'Request Detail';

  // ── Action labels ─────────────────────────────────────────────────────────
  static const String close = 'Close inspector';
  static const String refresh = 'Refresh';
  static const String moreOptions = 'More options';
  static const String settings = 'Settings';
  static const String exportLogs = 'Export logs';
  static const String clearAll = 'Clear all';
  static const String cancel = 'Cancel';
  static const String details = 'Details';
  static const String reveal = 'reveal';

  // ── Popup / menu ─────────────────────────────────────────────────────────
  static const String copyCurl = 'Copy cURL';
  static const String copyUrl = 'Copy URL';
  static const String shareAsJson = 'Share as JSON';
  static const String newestFirst = 'Newest first';
  static const String slowestFirst = 'Slowest first';
  static const String largestFirst = 'Largest first';

  // ── Sort labels ───────────────────────────────────────────────────────────
  static const String sortNewest = 'Newest';
  static const String sortSlowest = 'Slowest';
  static const String sortLargest = 'Largest';

  // ── Filter labels ─────────────────────────────────────────────────────────
  static const String filterAll = 'All';
  static const String filterError = 'Error';
  static const String filterErrorsOnly = 'Errors only';

  // ── Snackbar messages ─────────────────────────────────────────────────────
  static const String curlCopied = 'cURL copied';
  static const String urlCopied = 'URL copied';
  static const String copiedToClipboard = 'Copied to clipboard';

  // ── Clear dialog ──────────────────────────────────────────────────────────
  static const String clearLogsTitle = 'Clear all logs?';
  static const String clearLogsMessage =
      'This will permanently remove all captured requests.';

  // ── Empty state ───────────────────────────────────────────────────────────
  static const String emptyNoRequests = 'No requests yet';
  static const String emptyNoMatches = 'No matching requests';
  static const String emptyNoRequestsSubtitle =
      'Make an HTTP request through a\nconfigured Dio or http client to\nsee it appear here.';
  static const String emptyNoMatchesSubtitle =
      'Try adjusting your search or filters.';

  // ── Status badge labels ───────────────────────────────────────────────────
  static const String statusErr = 'ERR';
  static const String statusUnknown = '???';
  static const String statusPending = 'pending';
  static const String statusNetworkError = 'Network Error';

  // ── HTTP status meanings ──────────────────────────────────────────────────
  static const String status200 = '200 OK';
  static const String status201 = '201 Created';
  static const String status204 = '204 No Content';
  static const String status301 = '301 Moved Permanently';
  static const String status302 = '302 Found';
  static const String status304 = '304 Not Modified';
  static const String status400 = '400 Bad Request';
  static const String status401 = '401 Unauthorized';
  static const String status403 = '403 Forbidden';
  static const String status404 = '404 Not Found';
  static const String status405 = '405 Method Not Allowed';
  static const String status408 = '408 Request Timeout';
  static const String status409 = '409 Conflict';
  static const String status422 = '422 Unprocessable Entity';
  static const String status429 = '429 Too Many Requests';
  static const String status500 = '500 Internal Server Error';
  static const String status502 = '502 Bad Gateway';
  static const String status503 = '503 Service Unavailable';
  static const String status504 = '504 Gateway Timeout';

  // ── Body viewer labels ────────────────────────────────────────────────────
  static const String bodyViewTree = 'Tree';
  static const String bodyViewPretty = 'Pretty';
  static const String bodyViewRaw = 'Raw';
  static const String bodyLabel = 'Body';
  static const String requestBodyLabel = 'Request Body';
  static const String responseBodyLabel = 'Response Body';
  static const String rawPayloads = 'Raw Payloads';

  // ── Key-value / overview labels ───────────────────────────────────────────
  static const String labelUrl = 'URL';
  static const String labelMethod = 'Method';
  static const String labelStatus = 'Status';
  static const String labelDuration = 'Duration';
  static const String labelSize = 'Size';
  static const String labelDimensions = 'Dimensions';
  static const String labelRequestHeaders = 'Request Headers';
  static const String labelResponseHeaders = 'Response Headers';

  // ── Summary header labels ─────────────────────────────────────────────────
  static const String statTotal = 'Total';
  static const String statSuccess = 'Success';
  static const String statErrors = 'Errors';
  static const String statAvg = 'Avg';
  static const String statData = 'Data';

  // ── Selection mode ────────────────────────────────────────────────────────
  static const String deleteSelected = 'Delete selected';

  // ── Placeholder / redacted ────────────────────────────────────────────────
  static const String redactedMask = '••••••••••••';

  // ── Media / image tab ────────────────────────────────────────────────────
  static const String previewNotAvailable = 'Preview not available';

  // ── Error banner messages ─────────────────────────────────────────────────
  static const String errorTimeout =
      'Request timed out. The server took too long to respond.';
  static const String errorSslPrefix = 'SSL/TLS error: ';
  static const String errorNetworkUnreachable =
      'Network unreachable: no route to host. Check your network connection.';
}
