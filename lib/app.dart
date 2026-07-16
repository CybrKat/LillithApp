/// LillithApp - orchestrate the primary login widget.
///
/// Scaffolded from the `solidui` app template (`dart run solidui:create`) and
/// customised for LillithApp.

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:lillith_app/app_scaffold.dart';
import 'package:lillith_app/constants/app.dart';
import 'package:lillith_app/theme.dart';

// This widget is the root of the application. On startup it calls upon
// [SolidLogin] to connect to the user's Pod stored within their data vault on
// their chosen Solid server.

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidThemeApp(
      // We can manually turn off the debug banner. It is turned off
      // automatically for a `flutter --release`.

      debugShowCheckedModeBanner: false,

      title: appTitle,

      // A soft lilac/amethyst palette with gentle rounded shapes carries the
      // feminine, calming feel of LillithApp across both light and dark modes.
      // See lib/theme.dart for the full palette and component styling.

      theme: lillithLightTheme,
      darkTheme: lillithDarkTheme,

      home: SolidLogin(
        title: appTitle.replaceAll(' - ', '\n'),
        image: const AssetImage('assets/images/app_image.jpg'),
        logo: const AssetImage('assets/images/app_icon.png'),

        // The Solid server to authenticate against (pre-fills the login form).

        webID: appServerUrl,

        // The application folder created on the user's POD.

        appDirectory: appPodDirectory,

        // Solid app registration details. Update these in lib/constants/app.dart
        // to point at your own deployment; the clientId there must resolve to a
        // client profile document listing exactly these redirect URIs (the
        // generated `client-profile.jsonld` in the project root). See
        // https://solidproject.org for more information.

        link: appLink,
        clientId: appClientId,
        redirectUris: appRedirectUris,
        postLogoutRedirectUris: appPostLogoutRedirectUris,
        child: appScaffold,
      ),
    );
  }
}
