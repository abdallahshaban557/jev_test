# Jev + GenUI order support

A Flutter order-support agent with Jev selecting the interface and GenUI rendering
interactive cards for order details, tracking, and returns.

## Run

```sh
flutter pub get
flutter run -d chrome
```

Open the key icon, enter your Jev / TypeSafe API key, and try:

- `Show my orders`
- `Return my backpack`
- `Where are my headphones?`
- `What is the return policy?`

The key stays in memory. Chrome debug uses Flutter's built-in proxy in
`web_dev_config.yaml`; no Python server is needed. Restart `flutter run` after
changing that configuration. Native platforms call Jev directly.

### Keep your development key across restarts

Set `JEV_API_KEY` in the local `jev.local.json` file (excluded from Git), then run:

```sh
flutter run -d chrome --dart-define-from-file=jev.local.json
```

In VS Code, select **Jev Chrome (local key)** and start debugging. The order-support chat
automatically prefills the key. After changing the file, stop and relaunch the app.
Keys typed into the app remain session-only and do not update this file.
For a fresh clone, create `jev.local.json` with `{"JEV_API_KEY": "your-key"}`.

This file stores the key as plain text locally, and Flutter compiles its value
into the app. Use it for local development only; do not publish a build containing
the key. Production credentials belong on your backend.

## Provider architecture

`SupportViewModel` owns a GenUI `Conversation`, `SurfaceController`, and custom
`JevGenUiProvider`. The provider supplies `A2uiTransportAdapter.onSend`.

1. The provider sends the current request, recent conversation, selected order,
   and sample order facts through `jev_dart`.
2. Jev answers two typed choice questions: `ui` (six allowed screens) and `order`
   (known sample order IDs or `none`). Invalid labels are rejected.
3. The provider maps those choices to A2UI `CreateSurfaceMessage` and
   `UpdateComponentsMessage` objects. This uses approved templates, not
   arbitrary model-generated widgets or a second LLM.
4. GenUI renders a `Surface` using the custom support catalog: order list,
   order details, tracking, return form, return policy, and help.
5. Buttons dispatch GenUI `UserActionEvent`s. Navigation goes back through Jev.
   Explicit return submission validates eligibility and the reason locally,
   then emits a confirmation surface. Model text cannot execute a return.

The repository contains three clearly labeled sample orders: a backpack,
headphones, and a tote. All are delivered and within the 30-day return window. Return submissions are in-memory, idempotent demo records.
They do not create real refunds, labels, or commerce-system actions. Starting a
new conversation resets the sample session.

For deployment, provide an authenticated backend at `/api/v1/systemone`, keep
production Jev credentials there, and replace `OrderRepository` with real order
access and server-side return validation. Flutter's development proxy is not
included in a release web build.

## Verify

```sh
flutter analyze
flutter test
flutter build web
```

Tests exercise Jev's request schema, GenUI rendering of every screen, unknown
orders, return eligibility, and form-to-confirmation events using mock model
responses. Live Jev selection quality requires a valid API key.

Package docs: https://pub.dev/packages/genui and https://pub.dev/packages/jev_dart
