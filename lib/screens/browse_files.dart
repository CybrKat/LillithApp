/// LillithApp - display all folders from the root of a user's pod.
///
/// Scaffolded from the `solidui` app template (`dart run solidui:create`).

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:lillith_app/constants/app.dart';

class BrowseFiles extends StatelessWidget {
  const BrowseFiles({super.key});

  @override
  Widget build(BuildContext context) {
    // SolidFile() from `solidui` is a comprehensive file browser for the
    // resources contained in your data vault hosted on any Solid server.

    return const SolidFile(
      currentPath: SolidFile.podRoot,
      friendlyFolderName: 'All Files and Folders',
      uploadConfig: appUploadConfig,
    );
  }
}
