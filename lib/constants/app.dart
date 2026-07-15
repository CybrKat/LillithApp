/// LillithApp - app-wide constants.
///
/// Scaffolded from the `solidui` app template (`dart run solidui:create`) and
/// transformed into LillithApp, a private cycle-tracking app that predicts the
/// next period from skin-temperature data logged by smart rings and watches.

library;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:solidui/solidui.dart'
    show SolidFileUploadConfig, SolidInviteOthersConfig;

/// Application title displayed as the window title.

const String appTitle = 'LillithApp - Cycle Tracking from Skin Temperature';

/// The Solid server LillithApp authenticates against. This pre-fills the WebID /
/// server field on the login page. Users can still type a different server
/// there if their POD is hosted elsewhere.

const String appServerUrl = 'https://pods.solidcommunity.au';

// ── Solid app registration ───────────────────────────────────────────────────

/// Solid OIDC client registration for LillithApp.
///
/// These values identify the app to the Solid server during login. They are
/// gathered here so you can update them in one place when you deploy to your
/// own infrastructure.
///
/// [appClientId] MUST resolve to a publicly hosted client profile document
/// (the `client-profile.jsonld` generated in the project root) whose
/// `redirect_uris` and `post_logout_redirect_uris` list exactly the URIs
/// resolved below. If they do not match, the identity provider will reject the
/// login. The recommended host is GitHub Pages served from the repository root
/// (so a push auto-updates it) — replace `your-org` with your GitHub user or
/// organisation and enable Pages for the repo. See the README and
/// https://solidproject.org for more information.
///
/// Note: the custom redirect scheme drops underscores from the project name
/// ('com.example.lillithapp'), because a URI scheme may not contain
/// underscores. Every other identifier keeps the full project name.

const String appClientId =
    'https://cybrkat.github.io/LillithApp/client-profile.jsonld';

/// One redirect URI per platform; SolidUI's `pickRedirectUri` selects the right
/// one at runtime. Keep this list in step with the `redirect_uris` in the
/// hosted client profile document.
///
/// On web the chosen redirect MUST be same-origin as wherever the app is
/// served, because `redirect.html` hands the auth response back through a
/// same-origin `BroadcastChannel`; any origin mismatch leaves login hanging on
/// the loading spinner. `pickRedirectUri` does NOT match on origin — it just
/// takes the first `https://` entry — so we derive the web entry from
/// `Uri.base.origin` at runtime instead of hard-coding it. That yields the
/// deployed https host in production, and `http://localhost:4400/redirect.html`
/// under `flutter run -d chrome --web-port=4400`. Off the web the list is
/// static: the custom scheme serves Android/iOS/macOS and the loopback entry
/// serves Windows/Linux.

List<String> get appRedirectUris => kIsWeb
    ? ['https://cybrkat.github.io/LillithApp/redirect.html']
    : const [
        'com.example.lillithapp://redirect',
        'http://localhost:4400/redirect.html',
      ];

/// Where the identity provider returns the user after logging out. By default
/// we reuse the login redirect URIs, mirroring the hosted client profile.

List<String> get appPostLogoutRedirectUris => appRedirectUris;

/// The application folder created on the user's POD to store LillithApp data.
///
/// All health data (temperature readings and period events) is written beneath
/// this directory as encrypted files, so it stays private to the POD owner.

const String appPodDirectory = 'lillith_app';

/// Homepage opened from the login page's info button. Point this at your own
/// project page or documentation.

const String appLink = 'https://cybrkat.github.io/LillithApp/';

/// Shared upload configuration for any `SolidFile` view in LillithApp.
///
/// LillithApp stores its cycle data as JSON, so the file picker is restricted
/// to `.json`/`.csv` (the formats a ring/watch export would produce) plus the
/// template's Markdown/text defaults. Extensions are matched case-insensitively
/// by SolidUI.

const SolidFileUploadConfig appUploadConfig = SolidFileUploadConfig(
  allowedExtensions: ['json', 'csv', 'txt'],
);

/// Public URL where LillithApp is hosted. Used by the Invite Others
/// feature to send a working link to the recipient.

const String appUrl = 'https://LillithApp.solidcommunity.au/';

/// Application-wide Invite Others configuration shared by the
/// AppBar share button and the App Info dialog so that users can
/// invite others to set up their POD and try LillithApp.

const SolidInviteOthersConfig inviteOthersConfig = SolidInviteOthersConfig(
  applicationName: 'LillithApp',
  appUrl: appUrl,
  appDescription:
      'privately track skin temperature and predict your cycle with LillithApp',
  messageTemplate: '''
You might like to try the {appName} app, available online here:

{appUrl}

Signing into {appName} will set up your data vault so your skin-temperature
readings and cycle predictions stay private on your own Solid POD.

''',
  subject: 'Try the LillithApp cycle tracker on your Solid POD',
  tooltip: '''

  **Invite Others**

  Tap to invite someone else to try LillithApp. You can copy the
  invitation to the clipboard or share it through any messaging app
  installed on your device.

  ''',
);

// ── LillithApp data storage ──────────────────────────────────────────────────

/// Relative path (within the app's `data` directory on the POD) of the file
/// holding all logged skin-temperature readings and period events, serialised
/// as a single JSON document. Written encrypted so the health data is private.

const String healthDataFile = 'cycle_data.json';
