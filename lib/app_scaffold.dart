/// LillithApp - the primary application scaffold.
///
/// Scaffolded from the `solidui` app template and reworked for LillithApp: the
/// navigation menu exposes the cycle dashboard, the data-entry log, and the
/// temperature history, with the POD file browsers kept for direct access to
/// the stored data file.

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:lillith_app/constants/app.dart';
import 'package:lillith_app/home.dart';
import 'package:lillith_app/screens/browse_files.dart';
import 'package:lillith_app/screens/history.dart';
import 'package:lillith_app/screens/log_entry.dart';

final _scaffoldController = SolidScaffoldController();

const appScaffold = AppScaffold();

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidScaffold(
      controller: _scaffoldController,
      hideNavRail: false,
      enableProfile: true,
      onLogout: (context) => SolidAuthHandler.instance.handleLogout(context),

      // The navigation menu drives the side navigation rail (and the drawer on
      // narrow screens). Each entry exposes a top-level page of the app.

      menu: const [
        SolidMenuItem(
          icon: Icons.favorite,
          title: 'Dashboard',
          tooltip: '''

            **Dashboard**

            Your cycle at a glance: the predicted next period, current cycle
            day and latest temperature.

            ''',
          child: Home(title: appTitle),
        ),
        SolidMenuItem(
          icon: Icons.add_chart,
          title: 'Log',
          tooltip: '''

            **Log**

            Record a daily skin temperature or mark the day your period
            started. Import from a smart ring or watch here too.

            ''',
          child: LogEntry(),
        ),
        SolidMenuItem(
          icon: Icons.show_chart,
          title: 'History',
          tooltip: '''

            **History**

            Review your temperature trend and every logged reading.

            ''',
          child: History(),
        ),
        SolidMenuItem(
          icon: Icons.folder,
          title: 'App Files',
          tooltip: '''

            **Files**

            Browse the raw LillithApp data files stored on your POD.

            ''',
          child: SolidFile(uploadConfig: appUploadConfig),
        ),
        SolidMenuItem(
          icon: Icons.storage,
          title: 'All POD Files',
          tooltip: '''

            **All Files**

            Tap here to browse all folders on your POD from the root.

            ''',
          child: BrowseFiles(),
        ),
      ],
      appBar: SolidAppBarConfig(
        title: appTitle.split(' - ')[0],
        versionConfig: const SolidVersionConfig(
          changelogUrl: 'https://github.com/CybrKat/SpireApp/blob/dev/'
              'CHANGELOG.md',
          showUpdateButton: true,
          downloadUrl: 'https://solidcommunity.au/installers/',
        ),
        actions: [
          SolidAppBarAction(
            icon: Icons.add_chart,
            onPressed: () => _scaffoldController.navigateToSubpage(
              const LogEntry(),
            ),
            tooltip: 'Log a reading',
          ),
        ],
      ),

      // The status bar runs along the bottom of the window, surfacing the
      // current server, login state and security key status.

      statusBar: const SolidStatusBarConfig(
        serverInfo: SolidServerInfo(serverUri: SolidConfig.defaultServerUrl),
        loginStatus: SolidLoginStatus(),
        securityKeyStatus: SolidSecurityKeyStatus(),
      ),
      aboutConfig: SolidAboutConfig(
        applicationName: appTitle.split(' - ')[0],
        applicationIcon: Image.asset(
          'assets/images/app_icon.png',
          width: 64,
          height: 64,
        ),
        applicationLegalese: '''

        © LillithApp

        ''',
        text: '''

        LillithApp helps you understand your menstrual cycle from the skin
        temperature recorded by a smart ring or watch (or entered by hand). It
        detects the post-ovulation temperature shift and estimates the likely
        start of your next period. All data stays private, encrypted on your
        personal online data store (Pod) hosted on a Solid server.

        Key features:

        🌡️ Log daily skin temperature and period starts;

        🔮 Predict the next period from the temperature shift and cycle history;

        📈 Visualise your temperature trend over time;

        ⌚ Ready for smart ring / watch import;

        🔐 Encrypted, POD-hosted storage you control;

        🎨 Theme switching (light/dark/system);

        🧭 Responsive navigation (rail ↔ drawer).

        LillithApp gives wellness estimates only. It is not a medical device and
        must not be used for contraception or diagnosis.

        Built with [solidpod](https://pub.dev/packages/solidpod) and
        [solidui](https://pub.dev/packages/solidui) for the
        [Australian Solid Community](https://solidcommunity.au).

        ''',
      ),
      themeToggle: const SolidThemeToggleConfig(
        enabled: true,
        showInAppBarActions: true,
      ),
      inviteConfig: inviteOthersConfig,
      child: const Home(title: appTitle),
    );
  }
}
