# chucker_flutter_plus

<<<<<<< Updated upstream
`chucker_flutter_plus` captures HTTP traffic from Dio and `package:http`, keeps
a bounded local history, and opens an in-app screen where you can inspect
requests and responses. It also includes an optional console `NetworkLogger`
that can be shared by Dio, Chopper, and `package:http`.
=======
An in-app HTTP inspector and client-independent network logger for Flutter. It
captures requests from Dio, Chopper, or `package:http`, prints sanitized logs,
and can retain transactions for inspection in the app.
>>>>>>> Stashed changes

## Install

Add the package to your app:

```sh
flutter pub add chucker_flutter_plus
```

Or add it to `pubspec.yaml`:

```yaml
dependencies:
  chucker_flutter_plus: ^0.1.0
```

<<<<<<< Updated upstream
## Capture traffic and open the inspector

Initialize Chucker once before `runApp`, then add the adapter for each client
whose traffic you want to capture. Chucker uses your app's existing navigator;
it does not replace your router or navigator key.
=======
Then run `flutter pub get`.

## Shared network logger

Create one logger and pass it to every client adapter. `NetworkLogger` and its
models are client-independent and are available from
`package:chucker_flutter_plus/network_logger.dart`.
>>>>>>> Stashed changes

```dart
import 'package:chucker_flutter_plus/network_logger.dart';

final networkLogger = NetworkLogger(
  config: const NetworkLogConfig(
    logRequestHeaders: true,
    logRequestBody: true,
    logResponseHeaders: true,
    logResponseBody: true,
    logErrorBody: true,
    logCurlCommand: true,
    maxBodyLength: 4000,
    slowRequestThreshold: Duration(seconds: 10),
  ),
  printer: (line) => debugPrint(line),
);
```

Logging is enabled in debug builds by default. Set `enabled: true` to opt in
elsewhere, or set `forceLogging: true` to force logs even when `enabled` is
false. Review captured traffic carefully before enabling logs in production.

### Dio

```dart
import 'package:chucker_flutter_plus/dio_network_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ChuckerFlutterPlus.initialize(
    maximumEntries: 200,
    retention: const Duration(days: 7),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorObservers: [ChuckerFlutterPlus.navigatorObserver],
    home: const HomePage(),
  );
}

final dio = Dio()
  ..interceptors.add(DioNetworkLoggerInterceptor(logger: networkLogger));
```

### Chopper

```dart
import 'package:chucker_flutter_plus/chopper_network_logger.dart';
import 'package:chopper/chopper.dart';

final chopper = ChopperClient(
  interceptors: [ChopperNetworkLoggerInterceptor(logger: networkLogger)],
);
```

### `package:http`

```dart
import 'package:chucker_flutter_plus/http_network_logger.dart';
import 'package:http/http.dart' as http;

final httpClient = LoggingHttpClient(
  inner: http.Client(),
  logger: networkLogger,
);
```

The HTTP adapter tees response bytes as the application reads them, preserving
the response stream. It retains at most four times `maxBodyLength` bytes for
diagnostic output. It logs a request body when the request is an `http.Request`;
it does not consume a `StreamedRequest` body to inspect it.

## Configuration, redaction, and request control

`NetworkLogConfig` controls request, response, and error logging, request and
response headers and bodies, cURL generation, truncation, slow-call threshold,
ANSI colors, and sensitive header/body keys. Authorization, cookie, API key,
password, and token fields are redacted by default. Provide a `LogRedactor` to
customize sensitive keys:

```dart
final logger = NetworkLogger(
  config: const NetworkLogConfig(enabled: true),
  redactor: const LogRedactor(
    sensitiveHeaders: {'authorization', 'x-session-id'},
    sensitiveJsonKeys: {'password', 'access_token', 'private_note'},
  ),
  printer: (message) => myLogger.info(message),
);
```

Use the following markers to omit an individual request from logs:

```dart
// Dio
dio.get('/private', options: Options(extra: {
  DioNetworkLoggerInterceptor.disableLoggingExtraKey: true,
}));

// Chopper
final privateRequest = chopper.Request(
  'GET', Uri.parse('/private'), Uri.parse('https://api.example.com'),
  tag: const NetworkLoggerDisabled(),
);

// HTTP: this control header is stripped before the request is sent.
final request = http.Request('GET', uri)
  ..headers[LoggingHttpClient.disableLoggingHeader] = 'true';
```

Logging and printer exceptions are contained by the logger so they do not
change the network client's result.

## In-app inspector and notifications

Attach the navigator key to the host app and install an inspector adapter:

```dart
final dio = Dio()..interceptors.add(ChuckerDioInterceptor());
```

<<<<<<< Updated upstream
If your app already uses a navigator key, pass it to `initialize` and keep
using it in your app:

```dart
final appNavigatorKey = GlobalKey<NavigatorState>();

await ChuckerFlutterPlus.initialize(navigatorKey: appNavigatorKey);

MaterialApp(navigatorKey: appNavigatorKey, home: const HomePage());
```

For `package:http`, wrap the client:

```dart
import 'package:http/http.dart' as http;

final httpClient = ChuckerHttpClient(http.Client());
final response = await httpClient.get(Uri.parse('https://example.com/items'));
```

Open the inspector from a widget, for example with a button:

```dart
ChuckerFlutterPlus.button()
```

Or open it from a widget context and optionally select a captured request:

```dart
ChuckerFlutterPlus.showInspector(context);
ChuckerFlutterPlus.showInspector(context, requestId);
```

`ChuckerFlutterPlus.hideInspector()` closes it. You can also clear the saved
history or export it as JSON:

```dart
await ChuckerFlutterPlus.clearLogs();
final json = await ChuckerFlutterPlus.exportLogs();
```

## In-app and system notifications

In-app banners are configured separately from operating system notifications.
Use `InspectorConfig` when you want to set their behavior:

```dart
await Inspector.init(
  config: const InspectorConfig(
    showInAppNotification: true,
    showStatusBarNotification: false,
    inAppNotificationDuration: Duration(seconds: 3),
    inAppNotificationPosition: BannerPosition.top,
    notifyOnlyOnError: false,
    maximumEntries: 200,
  ),
);
```

System notifications require platform permission. On Android, add this to the
host app's `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Provide a white-on-transparent `chucker_icon` drawable in
`android/app/src/main/res/drawable`, or set `statusBarIcon` in
`InspectorConfig`. iOS permission is requested during initialization. Tapping
a Chucker notification opens the inspector at the matching request; other
notification payloads are forwarded to the callback passed to
`initialize`/`Inspector.init`.

## Shared console `NetworkLogger`

The console logger is independent of transaction storage and the inspector UI.
Create one instance and pass it to as many client adapters as you use:

```dart
import 'package:chopper/chopper.dart';
import 'package:chucker_flutter_plus/network_logger.dart';
import 'package:chucker_flutter_plus/network_logger_dio.dart';
import 'package:chucker_flutter_plus/network_logger_chopper.dart';
import 'package:chucker_flutter_plus/network_logger_http.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

final dio = Dio();
final logger = NetworkLogger(
  config: const NetworkLogConfig(
    logRequestHeaders: true,
    logRequestBody: true,
    logResponseHeaders: true,
    logResponseBody: true,
    logErrorBody: true,
    logCurlCommand: true,
    maxBodyLength: 4000,
    slowRequestThreshold: Duration(seconds: 10),
  ),
);

dio.interceptors.add(DioNetworkLoggerInterceptor(logger: logger));

final chopperClient = ChopperClient(
  baseUrl: Uri.parse('https://example.com'),
  interceptors: [ChopperNetworkLoggerInterceptor(logger: logger)],
);

final loggedHttpClient = LoggingHttpClient(
  inner: http.Client(),
  logger: logger,
);
```

The core logger is also available on its own through
`package:chucker_flutter_plus/network_logger.dart`. Adapter entry points are
`network_logger_dio.dart`, `network_logger_chopper.dart`, and
`network_logger_http.dart`.

The logger prints in debug builds by default. Set `forceLogging: true` to log
in release builds. A custom printer can route messages to your logging system:

```dart
final logger = NetworkLogger(
  config: const NetworkLogConfig(forceLogging: true),
  printer: (message) => myAppLogger.debug(message),
);
```

Common credential headers (`Authorization`, `Cookie`, `Set-Cookie`, and
`X-Api-Key`) and sensitive JSON keys (`password`, `token`, `access_token`,
`refresh_token`, and `secret`) are redacted by default. Configure the key sets
through `NetworkLogConfig.sensitiveHeaders` and `sensitiveJsonKeys`, or provide
a custom `LogRedactor` to `NetworkLogger`.

Disable console logging for one request with Dio's `extra` map:

```dart
await dio.get(
  '/private',
  options: Options(extra: {'network_logger.disabled': true}),
);
```

For Chopper, set `Request.tag` to
`ChopperNetworkLoggerInterceptor.disableRequestTag`. For `package:http`, pass
a `shouldLog` predicate to `LoggingHttpClient`. The HTTP logger does not consume
request streams to inspect them; it forwards response chunks as they arrive
and logs the response once its stream has been read.

## Configuration and privacy

Capture is enabled in debug builds by default. To enable inspector capture in
release builds, call:

```dart
ChuckerFlutterPlus.configure(enableOnRelease: true);
```

Set `maximumEntries` to bound local history and `retention` to remove older
transactions. Request headers are redacted before they are stored; by default
`Authorization`, `Cookie`, and `Set-Cookie` are sensitive. Customize them with
`redactHeaders` during initialization:

```dart
await ChuckerFlutterPlus.initialize(
  redactHeaders: {'authorization', 'cookie', 'x-api-key'},
);
```

Request and response bodies are retained for inspection. Review the data your
app sends before enabling capture in release builds. Binary bodies are shown
as Base64; JSON can be pretty-printed in the inspector.

## API overview

- `ChuckerDioInterceptor` and `ChuckerHttpClient` record transactions for the
  inspector.
- `DioNetworkLoggerInterceptor`, `ChopperNetworkLoggerInterceptor`, and
  `LoggingHttpClient` send normalized events to the shared console logger.
- `ChuckerFlutterPlus` initializes capture and opens the inspector.
- `Inspector` and `InspectorConfig` provide an object-based notification and
  retention setup.
- `NetworkTransaction` is the immutable model for a captured request.

## Development

```sh
dart format .
flutter analyze
flutter test
```
=======
Captured requests show an in-app notification with method, status or error, and
URL. **Details** opens the transaction inspector. Set
`ChuckerFlutterPlus.showNotification = false` to suppress the banner. Open the
inspector manually with `ChuckerFlutterPlus.button()` or
`ChuckerFlutterPlus.showChuckerScreen()`.

The capture adapters (`ChuckerDioInterceptor` and `ChuckerHttpClient`) persist
transactions for the inspector. The `DioNetworkLoggerInterceptor`,
`ChopperNetworkLoggerInterceptor`, and `LoggingHttpClient` adapters print
sanitized diagnostics. You can use both features together.

Capture is enabled only in debug builds by default. Call
`ChuckerFlutterPlus.configure(enableOnRelease: true)` to capture in release
builds; sanitize or redact sensitive traffic before enabling it.

## Public entry points

- `network_logger.dart`: shared logger, configuration, models, and redactor.
- `dio_network_logger.dart`: shared logger and Dio logging adapter.
- `chopper_network_logger.dart`: shared logger and Chopper logging adapter.
- `http_network_logger.dart`: shared logger and HTTP logging adapter.
- `chucker_flutter_plus.dart`: inspector, capture adapters, and all logger APIs.
>>>>>>> Stashed changes
