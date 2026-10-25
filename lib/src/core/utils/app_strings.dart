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
  static const String inspectorSettingsTitle = 'Inspector Settings';
  static const String requestDetailTitle = 'Request Detail';

  // ── Action labels ─────────────────────────────────────────────────────────
  static const String close = 'Close inspector';
  static const String refresh = 'Refresh';
  static const String moreOptions = 'More options';
  static const String settings = 'Settings';
  static const String exportLogs = 'Export logs';
  static const String clearAll = 'Clear all';
  static const String clear = 'Clear';
  static const String cancel = 'Cancel';
  static const String details = 'Details';
  static const String reveal = 'reveal';
  static const String copy = 'Copy';
  static const String wordWrap = 'Word wrap';
  static const String lineNumbers = 'Line numbers';
  static const String collapse = 'Collapse';
  static const String expand = 'Expand';

  // ── Popup / menu / share ──────────────────────────────────────────────────
  static const String copyCurl = 'Copy cURL';
  static const String copyUrl = 'Copy URL';
  static const String shareAsCurl = 'Share as cURL';
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
  static const String bodyCopied = 'Body copied to clipboard';
  static const String allLogsCleared = 'All logs cleared';

  // ── Clear dialog ──────────────────────────────────────────────────────────
  static const String clearLogsTitle = 'Clear all logs?';
  static const String clearLogsMessage =
      'This will permanently remove all captured requests.';
  static const String clearAllCapturedRequests = 'Clear all captured requests';

  // ── Empty state ───────────────────────────────────────────────────────────
  static const String emptyNoRequests = 'No requests yet';
  static const String emptyNoMatches = 'No matching requests';
  static const String emptyNoRequestsSubtitle =
      'Make an HTTP request through a\nconfigured Dio or http client to\nsee it appear here.';
  static const String emptyNoMatchesSubtitle =
      'Try adjusting your search or filters.';
  static const String noHeaders = 'No headers';
  static const String searchHeaders = 'Search headers';
  static const String noBody = 'No body';
  static const String emptyFormData = '(empty form data)';

  // ── Status badge labels ───────────────────────────────────────────────────
  static const String statusErr = 'ERR';
  static const String statusErrorUpper = 'ERROR';
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

  // ── Tabs ──────────────────────────────────────────────────────────────────
  static const String tabOverview = 'Overview';
  static const String tabRequest = 'Request';
  static const String tabResponse = 'Response';
  static const String tabRaw = 'Raw';
  static const String tabError = 'Error';
  static const String tabMedia = 'Media';

  // ── Body viewer labels ────────────────────────────────────────────────────
  static const String bodyViewTree = 'Tree';
  static const String bodyViewPretty = 'Pretty';
  static const String bodyViewRaw = 'Raw';
  static const String bodyLabel = 'Body';
  static const String requestBodyLabel = 'Request Body';
  static const String responseBodyLabel = 'Response Body';
  static const String rawPayloads = 'Raw Payloads';
  static const String bodyTruncatedWarning =
      'Body truncated — full body was too large to capture.';
  static const String items = 'items';
  static const String key = 'Key';
  static const String value = 'Value';

  // ── Key-value / overview / detail labels ──────────────────────────────────
  static const String labelGeneral = 'General';
  static const String labelUrl = 'URL';
  static const String labelMethod = 'Method';
  static const String labelStatus = 'Status';
  static const String labelHost = 'Host';
  static const String labelPath = 'Path';
  static const String labelQuery = 'Query';
  static const String labelContentType = 'Content-Type';
  static const String labelRequestSize = 'Request size';
  static const String labelResponseSize = 'Response size';
  static const String labelDuration = 'Duration';
  static const String labelStarted = 'Started';
  static const String labelCompleted = 'Completed';
  static const String labelRequestBody = 'Request body';
  static const String labelResponseBody = 'Response body';
  static const String labelTruncated = 'Truncated';
  static const String labelSize = 'Size';
  static const String labelDimensions = 'Dimensions';
  static const String labelRequestHeaders = 'Request Headers';
  static const String labelResponseHeaders = 'Response Headers';
  static const String labelFormatted = 'Formatted';
  static const String labelType = 'Type';
  static const String labelStackTrace = 'Stack Trace';
  static const String labelMediaInfo = 'Media Info';
  static const String labelPreview = 'Preview';

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

  // ── Error messages & hints ────────────────────────────────────────────────
  static const String errorTimeout =
      'Timeout: the server did not respond in time. Check your network connection or increase the timeout setting.';
  static const String errorConnRefused =
      'Connection refused: the server actively rejected the connection. Check if the server is running and the port is correct.';
  static const String errorSsl =
      'SSL/TLS error: certificate verification failed. The server may have an invalid or self-signed certificate.';
  static const String errorNetworkUnreachable =
      'Network unreachable: no route to host. Check your network connection.';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String sectionNotifications = 'Notifications';
  static const String inAppBanner = 'In-app banner';
  static const String inAppBannerSubtitle =
      'Show a floating banner when a request completes.';
  static const String systemNotifications = 'System notifications';
  static const String systemNotificationsSubtitle =
      'Show OS-level notifications for requests.';
  static const String statusBarWhileForeground = 'Status bar while foreground';
  static const String statusBarWhileForegroundSubtitle =
      'Also show system notifications when the app is in the foreground.';
  static const String notifyOnlyOnError = 'Notify only on error';
  static const String notifyOnlyOnErrorSubtitle =
      'Only show notifications for failed requests (4xx/5xx/errors).';
  static const String bannerDuration = 'Banner duration';
  static const String bannerDurationSubtitle =
      'How long to show the in-app banner.';
  static const String bannerPosition = 'Banner position';
  static const String bannerPositionSubtitle =
      'Where the in-app banner appears.';
  static const String positionTop = 'Top';
  static const String positionBottom = 'Bottom';

  static const String sectionStorage = 'Storage';
  static const String maxLogEntries = 'Max log entries';
  static const String maxLogEntriesSubtitle =
      'Older entries are discarded when the limit is reached.';

  static const String sectionDangerZone = 'Danger Zone';
}
