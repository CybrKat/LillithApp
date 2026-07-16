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
import 'package:lillith_app/screens/learn.dart';
import 'package:lillith_app/screens/log_entry.dart';
import 'package:lillith_app/screens/privacy.dart';
import 'package:lillith_app/screens/profile.dart';
import 'package:lillith_app/screens/relief.dart';
import 'package:lillith_app/screens/shopping.dart';

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
          icon: Icons.spa_rounded,
          title: 'Dashboard',
          tooltip: '''

            **Dashboard**

            Your cycle at a glance: the predicted next period, current cycle
            day and latest temperature.

            ''',
          child: Home(title: appTitle),
        ),
        SolidMenuItem(
          icon: Icons.edit_note_rounded,
          title: 'Log',
          tooltip: '''

            **Log**

            Record a daily skin temperature or mark the day your period
            started. Import from a smart ring or watch here too.

            ''',
          child: LogEntry(),
        ),
        SolidMenuItem(
          icon: Icons.insights_rounded,
          title: 'History',
          tooltip: '''

            **History**

            Review your temperature trend and every logged reading.

            ''',
          child: History(),
        ),
        SolidMenuItem(
          icon: Icons.healing_rounded,
          title: 'Relief',
          tooltip: '''

            **Relief**

            Gentle, science-backed ideas for your symptoms, sourced from
            trusted health bodies and real people — and re-ranked to whatever
            has worked best for you.

            ''',
          child: Relief(),
        ),
        SolidMenuItem(
          icon: Icons.shopping_basket_rounded,
          title: 'Shopping',
          tooltip: '''

            **Shopping list**

            Relief items you want to buy, saved privately on your POD. Find
            them nearby or online.

            ''',
          child: Shopping(),
        ),
        SolidMenuItem(
          icon: Icons.menu_book_rounded,
          title: 'Learn',
          tooltip: '''

            **Learn**

            A kind, curious place to understand your cycle: a daily health
            fact and an "ask me anything" answered from trusted sources.

            ''',
          child: Learn(),
        ),
        SolidMenuItem(
          icon: Icons.spa_rounded,
          title: 'My Profile',
          tooltip: '''

            **My Profile**

            Optional, private notes on conditions (endometriosis, PCOS…) and
            fertility. Also loads a month of sample data to explore the app.

            ''',
          child: Profile(),
        ),
        SolidMenuItem(
          icon: Icons.lock_rounded,
          title: 'Privacy',
          tooltip: '''

            **Privacy & Sharing**

            See how your encrypted data stays yours, and share read-only
            access with someone you trust (with one-tap revoke).

            ''',
          child: Privacy(),
        ),
        SolidMenuItem(
          icon: Icons.folder_rounded,
          title: 'App Files',
          tooltip: '''

            **Files**

            Browse the raw LillithApp data files stored on your POD.

            ''',
          child: SolidFile(uploadConfig: appUploadConfig),
        ),
        SolidMenuItem(
          icon: Icons.cloud_rounded,
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
          changelogUrl: 'https://github.com/CybrKat/LillithApp/blob/dev/'
              'CHANGELOG.md',
          showUpdateButton: true,
          downloadUrl: 'https://solidcommunity.au/installers/',
        ),
        actions: [
          SolidAppBarAction(
            icon: Icons.edit_note_rounded,
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
