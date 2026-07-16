/// LillithApp - helpers for opening external links.
///
/// The app never bundles a paid places API or asks for the device's GPS. When
/// the user wants to buy a relief item, we hand off to tools they already have:
///  * [openMapsNearMe] opens their maps app with an "item near me" search, so
///    proximity is resolved by the maps app itself (no location permission
///    requested by LillithApp);
///  * [openRetailerSearch] opens a web search for the item at online retailers.
///
/// This keeps LillithApp honest about what it does — it points the user at a
/// search rather than pretending to rank distributors by delivery speed, which
/// would need a paid API and their precise location.

library;

import 'package:url_launcher/url_launcher.dart';

/// Open an arbitrary [url] in the platform's default handler.
Future<bool> openUrl(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Open the maps app searching for [item] near the user. The maps app supplies
/// the location, so LillithApp itself needs no location permission.
Future<bool> openMapsNearMe(String item) {
  final query = Uri.encodeComponent('$item near me');
  return openUrl('https://www.google.com/maps/search/$query');
}

/// Open a general web search for buying [item] online.
Future<bool> openRetailerSearch(String item) {
  final query = Uri.encodeComponent('buy $item');
  return openUrl('https://www.google.com/search?q=$query&tbm=shop');
}
