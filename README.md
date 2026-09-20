# Jev Choices

A Flutter chat that asks Jev which option to select: **Stripe** (payments),
**PostHog** (analytics), or **Clerk** (authentication).
It returns a selection only. It does not connect to or perform actions in those services.

## Run

```sh
flutter pub get
flutter run -d chrome
```

Chrome debug uses Flutter's built-in development proxy, configured in
`web_dev_config.yaml`is needed. Fully stop and restart `flutter run` after changing this configuration;
hot reload does not reload development server settings.
Native Android/iOS/macOS builds call Jev directly (for example, `flutter run -d macos`).
A published web build still requires a backend at `/api/v1/systemone` because
Flutter's development proxy is only available during development.
Paste your Jev / TypeSafe API key into the app, type a question, and send it.
The key is held in memory only and is not saved. Example prompts fill the composer.

## How it works

`lib/choice_service.dart` uses `jev_dart: ^0.1.0` and calls
`TypeSafeClient.systemOne` with the current question, the last 12 conversation
messages, and a typed `choice` question containing exactly three criteria:
`stripe`, `posthog`, and `clerk`. It reads `result.choice('service').choice`
and validates the label before displaying it. There is no local keyword fallback.
Jev selects the closest match even for ambiguous or unrelated questions.
The category shown under each result is a fixed service description, not a
model-generated explanation.

The UI includes pending state, duplicate submission prevention, retry, new chat,
and readable authentication/network errors. Mobile and macOS network permissions
are configured.

This is a local prototype using a user-supplied API key. Browser access is explicitly
enabled in the SDK; browser users can inspect their own key and requests.
For a distributed app, move Jev calls and credentials to an authenticated backend.

## Verify

```sh
flutter analyze
flutter test
flutter build web
```

Tests use mocked Jev responses to check the request schema, all three returned
choices, authentication failures, and the chat UI. A live end-to-end request
requires your API key.

Package documentation: https://pub.dev/packages/jev_dart
