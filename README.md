# chucker_flutter_plus

An in-app HTTP inspector for Flutter. It captures requests made through Dio or
the `http` package, persists a bounded history locally, and exposes a Material
inspection screen.

## Installation

```yaml
dependencies:
  chucker_flutter_plus: ^0.0.1
```

Run `flutter pub get` afterward.

## Usage

Initialize once, then add a supported adapter to your client. The package does
not own a navigator key or alter the host router:

```dart
import 'package:chucker_flutter_plus/chucker_flutter_plus.dart';
import 'package:dio/dio.dart';

await ChuckerFlutterPlus.initialize(
  maximumEntries: 200,
  retention: const Duration(days: 7),
  enableNotifications: true,
  // Optional: used only to find an overlay after a notification tap.
  navigatorKey: yourExistingNavigatorKey,
  onUnrecognizedNotificationPayload: hostNotificationHandler,
);
final dio = Dio()..interceptors.add(ChuckerDioInterceptor());
```

For `package:http`, wrap the client instead:

```dart
final client = ChuckerHttpClient(http.Client());
```

## Shared console network logger

`NetworkLogger` is a client-independent console logger that can be shared by
Dio, Chopper, and `package:http`. It is separate from the transaction capture
used by the inspector. The package includes Chopper 8 integration support.
For narrower imports, use `network_logger.dart` for the core, or
`network_logger_dio.dart`, `network_logger_chopper.dart`, and
`network_logger_http.dart` for an individual adapter.

```dart
final logger = NetworkLogger(
  config: const NetworkLogConfig(
    logRequestHeaders: true,
    logRequestBody: true,
    logResponseBody: true,
    logErrorBody: true,
    logCurlCommand: true,
    maxBodyLength: 4000,
    slowRequestThreshold: Duration(seconds: 10),
  ),
);

dio.interceptors.add(DioNetworkLoggerInterceptor(logger: logger));
final chopper = ChopperClient(
  interceptors: [ChopperNetworkLoggerInterceptor(logger: logger)],
);
final httpClient = LoggingHttpClient(inner: http.Client(), logger: logger);
```

The logger masks common credential headers and sensitive JSON keys by default.
Pass custom sets through `NetworkLogConfig.sensitiveHeaders` and
`sensitiveJsonKeys`, or inject a `LogRedactor`. Set `forceLogging: true` to log
in release builds. A custom `NetworkLogPrinter` can route output to a logging
framework. Dio requests can be excluded with
`options.extra['network_logger.disabled'] = true`; for Chopper, use the
`ChopperNetworkLoggerInterceptor.disableRequestTag` request tag. The HTTP wrapper logs only bodies that
are available without consuming a request stream; it tees response streams and
prints the response after the consumer finishes reading them. For per-request
HTTP filtering, provide `shouldLog: (request) => ...` to `LoggingHttpClient`.

Open the inspector from any debug UI location:

```dart
ChuckerFlutterPlus.button()
// or, from any widget context:
ChuckerFlutterPlus.showInspector(context);
```

Capture is enabled only in debug builds by default. Calling
`ChuckerFlutterPlus.configure(enableOnRelease: true)` enables it in release builds;
review and redact sensitive traffic before doing so.

## Public API

- `ChuckerDioInterceptor` — records Dio responses and failures.
- `ChuckerHttpClient` — records `package:http` requests and failures.
- `ChuckerFlutterPlus` — initialization, isolated overlay UI, and configuration.
- `NetworkTransaction` — immutable representation of a captured transaction.

## Architecture

```text
lib/
├── chucker_flutter_plus.dart
└── src/
    ├── config/dependency_injection/ # Composition root
    └── features/network_inspector/
        ├── domain/                  # Rules and repository contract
        ├── data/                    # Package-isolated Hive CE implementation
        ├── infrastructure/          # Dio and http adapters
        └── presentation/            # Inspector UI and host integration
```

```text
Presentation → Domain ← Data
      ↑                    ↑
   Flutter UI          Hive CE
      ↑
Dio / http adapters
```

The domain layer is independent of Flutter, Dio, HTTP, and persistence.

## Notifications

For Android add the notification permission to the host app manifest:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Provide a white-on-transparent drawable named `chucker_icon` (or pass a custom
`notificationIcon`) under `android/app/src/main/res/drawable`. iOS permission
is requested during `initialize`. Notifications use one rolling summary and a
`chucker:<request-id>` payload; non-Chucker payloads are forwarded to the host
callback. Android's channel is created by `flutter_local_notifications`.

## Privacy and release builds

Capture is disabled in release by default. Set `enableOnRelease: true` only
after reviewing your traffic. `Authorization`, `Cookie`, and `Set-Cookie` are
redacted by default; replace the list with `redactHeaders` when initializing.
The inspector displays raw bodies unchanged (byte bodies are Base64) and can
pretty print JSON only on demand.

## Development

```bash
dart format .
flutter analyze
flutter test
```
