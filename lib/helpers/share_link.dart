import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_constants/app_config.dart';
import '../app_constants/profile_strings.dart';
import '../models/home_item.dart';
import '../shared_ui/widgets/overlays/app_toast.dart';
import '../shared_ui/widgets/overlays/share_sheet.dart';

/// The one place every share icon goes through: it opens the share sheet
/// (WhatsApp, X, Telegram, LinkedIn, Facebook, Email, "Copy link" and "More",
/// which opens the phone's own share sheet).
///
/// The link is `<AppConfig.shareLinkBase>/<startup|investor|program>/<id>`.
/// A startup or investor link opens that page in the app (see ShareLinks) or,
/// without the app, the web page on Firebase Hosting.
class ShareLink {
  ShareLink._();

  static const String base = AppConfig.shareLinkBase;

  static String startup(String id) => '$base/startup/$id';
  static String investor(String id) => '$base/investor/$id';
  static String program(String id) => '$base/program/$id';

  /// The link of a bookmark key: `s-<id>` startup, `i-<id>` investor,
  /// `p-<id>` program (the keys used all over the app).
  static String forKey(String key) {
    final id = key.length > 2 ? key.substring(2) : '';
    return switch (key.isEmpty ? '' : key[0]) {
      's' => startup(id),
      'i' => investor(id),
      'p' => program(id),
      _ => '$base/$key',
    };
  }

  /// Opens an app or a web address. Tests replace it.
  static ShareLauncher launcher = (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  };

  /// Opens the phone's own share sheet. Tests replace it.
  static SystemShare systemShare = (text, subject) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  };

  /// Opens the share sheet for [url]. [title] is the item's name, used in the
  /// message ("Look, I found Rafeeq Health on Start.sa ...").
  static Future<void> share(
    BuildContext context,
    String url, {
    String? title,
    String? text,
  }) => showShareSheet(
    context,
    url: url,
    title: title,
    text: text,
    copy: () => copy(context, url),
    launch: launcher,
    systemShare: systemShare,
  );

  /// Shares a startup with its ready message ("Check out Rafeeq Health on
  /// Start.sa, a HealthTech startup from Riyadh! <link>"); the wording lives
  /// in [ProfileStrings.startupShareTemplate].
  static Future<void> shareStartup(
    BuildContext context, {
    required String id,
    required String name,
    required String sector,
    required String city,
  }) {
    final link = startup(id);
    return share(
      context,
      link,
      title: name,
      text: ProfileStrings.startupShare(
        name: name,
        sector: sector,
        city: city,
        link: link,
      ),
    );
  }

  /// Shares an investor profile with its ready message ("Check out Ahmad
  /// Alharbi on Start.sa, an investor from Riyadh! <link>"); the wording
  /// lives in [ProfileStrings.investorShareTemplate].
  static Future<void> shareInvestor(
    BuildContext context, {
    required String id,
    required String name,
    required String city,
  }) {
    final link = investor(id);
    return share(
      context,
      link,
      title: name,
      text: ProfileStrings.investorShare(name: name, city: city, link: link),
    );
  }

  /// Shares a card item: a startup or an investor with its ready message,
  /// a program with the plain one.
  static Future<void> shareItem(BuildContext context, HomeItem item) =>
      switch (item.kind) {
        HomeItemKind.startup => shareStartup(
          context,
          id: item.id,
          name: item.name,
          sector: item.tag,
          city: item.city,
        ),
        HomeItemKind.investor => shareInvestor(
          context,
          id: item.id,
          name: item.name,
          city: item.city,
        ),
        _ => shareKey(context, item.bookmarkKey, title: item.name),
      };

  /// Opens the share sheet for the item behind a bookmark key.
  static Future<void> shareKey(
    BuildContext context,
    String key, {
    String? title,
  }) => share(context, forKey(key), title: title);

  /// Copies [url] and says "Link copied" (the sheet's "Copy link").
  static void copy(BuildContext context, String url) {
    unawaited(Clipboard.setData(ClipboardData(text: url)));
    AppToast.confirm(context, ProfileStrings.linkCopied);
  }

  /// Copies the link of the item behind a bookmark key.
  static void copyKey(BuildContext context, String key) =>
      copy(context, forKey(key));
}
