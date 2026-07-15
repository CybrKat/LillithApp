# LillithApp

LillithApp — a private menstrual-cycle tracker that predicts your next period
from the skin temperature recorded by a smart ring or watch.

Built on the [`solidui`](https://pub.dev/packages/solidui) /
[`solidpod`](https://pub.dev/packages/solidpod) scaffold, so all of your health
data stays **encrypted on your own Solid Pod** — never on someone else's server.
It comes with:

- a [`SolidLogin`] screen that connects to the user's data vault on their
  chosen Solid server;
- a [`SolidScaffold`] with a navigation rail (collapsing to a drawer on narrow
  screens) and a status bar showing the server, login and security-key state;
- a **Dashboard** with the predicted next period, current cycle day and latest
  temperature;
- a **Log** page for daily skin temperature and period starts (import from a
  ring/watch is stubbed and ready to wire up);
- a **History** page with a temperature-trend chart and every logged reading;
- theme switching, an About dialog and an Invite Others action.

> LillithApp gives wellness estimates only. It is **not** a medical device and
> must not be used for contraception or diagnosis.

## How prediction works

After ovulation, progesterone raises resting skin temperature by ~0.2–0.5 °C,
producing a *biphasic* curve. LillithApp uses two estimates and prefers the
better-supported one (see `lib/services/cycle_predictor.dart`):

1. **Temperature shift** — detect the sustained post-ovulation rise in the
   current cycle, infer the ovulation day, then add the luteal-phase length
   (measured from your history, or 14 days by default).
2. **Cycle-length average** — average the gaps between logged period starts and
   add that to your most recent period.

## Getting started

```bash
flutter pub get
flutter run          # or: flutter run -d windows
flutter test         # exercises the cycle-prediction logic
```

## Next steps

A few values were filled in with placeholders when this project was generated.
Update them for your own deployment:

- **Solid app registration** in `lib/constants/app.dart` — `appClientId`,
  `appRedirectUris`, `appPostLogoutRedirectUris` and `appLink`, passed to
  `SolidLogin` from `lib/app.dart`. These identify your app to the Solid server
  during login. **The `appClientId` URL must actually resolve to a Client
  Identifier Document (a `client-profile.jsonld`) that lists these exact
  redirect URIs.** Until you publish that document (and list your
  `com.example.spireapp://redirect` scheme in it), the identity provider has
  no client to validate and the login page will not appear — this is the most
  common reason a freshly generated app cannot reach the login screen. See the
  [Solid-OIDC client identifiers](https://solidproject.org/TR/oidc#clientids)
  documentation.
- **App constants** in `lib/constants/app.dart` — the title, POD data directory
  (`lillith_app`), hosting URL and the Invite Others message.
- **Icons** in `assets/images/` — replace `app_icon.png` and `app_image.jpg`,
  then run `dart run flutter_launcher_icons` to regenerate platform icons.

## Login (OIDC) setup

> **Required before login works:** publish this app's Client Identifier
> Document. The identity provider fetches your `clientId` URL to learn which
> `redirect_uris` are allowed; if it is missing the login is cancelled after the
> consent screen (`ASWebAuthenticationSession Code=1`). Two files exist for
> this: `client-profile.jsonld` and `redirect.html`, both in the project
> **root** (and `redirect.html` is also in `web/` for the web build).

### Where to publish the two files

- **`client-profile.jsonld` → GitHub Pages (the `clientId`).** It lives in the
  repository root so that, once you enable GitHub Pages for the repo (Settings →
  Pages → Deploy from a branch → `main` / `/root`), it is served at
  `https://cybrkat.github.io/SpireApp/client-profile.jsonld` and is re-published
  automatically on every push. `appClientId` in `lib/constants/app.dart` and the
  document's own `client_id` field must both equal that exact URL, and the
  `.jsonld` must be publicly readable (HTTP 200, no auth).
- **`redirect.html` → the same Pages site (root).** A copy sits in the repo root
  so a root-served Pages site publishes it at
  `https://cybrkat.github.io/SpireApp/redirect.html`. The web build also ships
  `web/redirect.html` and reads its redirect from `Uri.base.origin` at runtime,
  so the redirect is always same-origin with wherever the app is served — the
  deployed host in production and `http://localhost:4400` under
  `flutter run -d chrome --web-port=4400`. Both origins must be listed in the
  published `client-profile.jsonld`.

Verify the document is reachable:

```bash
curl -I https://cybrkat.github.io/SpireApp/client-profile.jsonld   # expect 200
```

The OIDC redirect is pre-wired so that login works on every platform:

- **macOS** — `macos/Runner/*.entitlements` grant `network.client`, keychain
  access (for token storage) and user-selected file access.
- **Android** — `android/app/build.gradle.kts` sets the `appAuthRedirectScheme`
  manifest placeholder.
- **iOS** — `ios/Runner/Info.plist` registers the custom URL scheme.

## Project layout

```
client-profile.jsonld  Solid-OIDC client document; publish via GitHub Pages
                       from the repo root (this is your clientId).
redirect.html          Root copy of the OIDC redirect helper for the Pages site.
lib/
  main.dart            Application entry point and desktop window setup.
  app.dart             Root widget; wraps the app in SolidLogin.
  app_scaffold.dart    SolidScaffold with the nav bar, status bar and menu.
  home.dart            Dashboard: next-period prediction, cycle day, latest temp.
  constants/app.dart   App-wide constants (title, POD dir, data file, invite).
  models/
    temperature_reading.dart  One day's skin-temperature reading (+ source).
    period_event.dart         A logged period start.
  services/
    cycle_predictor.dart      Temperature-shift + cycle-average prediction.
    health_repository.dart     Loads/saves encrypted cycle data on the POD.
  screens/
    log_entry.dart     Log temperature / period starts; device-import hook.
    history.dart       Temperature-trend chart and reading list.
    browse_files.dart  Whole-POD file browser (SolidFile at the root).
test/
  cycle_predictor_test.dart   Deterministic tests for the prediction logic.
web/
  redirect.html        Web/post-logout redirect helper for the web build.
```
