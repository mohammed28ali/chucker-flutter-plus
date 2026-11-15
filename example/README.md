# Chucker Flutter Plus example

A small API playground demonstrating local request capture with Dio and
`ChuckerFlutterPlus`. It includes successful GET and POST calls, a 404 response,
and a live response list with a detail request.

## Run

From this directory:

```sh
flutter pub get
flutter run
```

Tap a request card to generate traffic, then open the inspector from the app
bar, hero card, or floating action button. Captured data stays in the app's
local inspector history. This demo uses the public JSONPlaceholder API, so an
internet connection is required.

The package is consumed through a relative path dependency, which makes the
example useful while developing the package locally.

## Structure

- `presentation/` contains the dashboard, its view model, and immutable UI state.
- `domain/` contains the `Post` entity, repository contract, and request use cases.
- `data/` contains the Dio data source, JSON model, and repository implementation.
- `core/config/` contains the demo API and sample request configuration.
- `core/di/` composes the repository and configures Dio with Chucker.

The app composes those pieces in `lib/main.dart`. The Chucker Dio interceptor
is registered at the network client boundary, while widgets depend on view
model actions rather than Dio or JSON maps.
