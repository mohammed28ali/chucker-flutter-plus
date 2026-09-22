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

Attach the navigator key, then add a supported adapter to your client:

```dart
import 'package:chucker_flutter_plus/chucker_flutter_plus.dart';
import 'package:dio/dio.dart';

final dio = Dio()..interceptors.add(ChuckerDioInterceptor());

MaterialApp(
  navigatorKey: ChuckerFlutterPlus.navigatorKey,
  home: const MyAppHome(),
);
```

For `package:http`, wrap the client instead:

```dart
final client = ChuckerHttpClient(http.Client());
```

Open the inspector from any debug UI location:

```dart
ChuckerFlutterPlus.button()
// or
await ChuckerFlutterPlus.showChuckerScreen();
```

Capture is enabled only in debug builds by default. Calling
`ChuckerFlutterPlus.configure(enableOnRelease: true)` enables it in release builds;
review and redact sensitive traffic before doing so.

## Public API

- `ChuckerDioInterceptor` — records Dio responses and failures.
- `ChuckerHttpClient` — records `package:http` requests and failures.
- `ChuckerFlutterPlus` — navigator integration, UI launch, and configuration.
- `NetworkTransaction` — immutable representation of a captured transaction.

## Architecture

```text
lib/
├── chucker_flutter_plus.dart
└── src/
    ├── config/dependency_injection/ # Composition root
    └── features/network_inspector/
        ├── domain/                  # Rules and repository contract
        ├── data/                    # SharedPreferences implementation
        ├── infrastructure/          # Dio and http adapters
        └── presentation/            # Inspector UI and host integration
```

```text
Presentation → Domain ← Data
      ↑                    ↑
   Flutter UI       SharedPreferences
      ↑
Dio / http adapters
```

The domain layer is independent of Flutter, Dio, HTTP, and persistence.

## Development

```bash
dart format .
flutter analyze
flutter test
```
