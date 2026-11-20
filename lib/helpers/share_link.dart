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

class ShareLink {
  ShareLink._();

  static const String base = AppConfig.shareLinkBase;

  static String startup(String id) => '$base/startup/$id';
  static String investor(String id) => '$base/investor/$id';
  static String program(String id) => '$base/program/$id';

  static String forKey(String key) {
    final id = key.length > 2 ? key.substring(2) : '';
    return switch (key.isEmpty ? '' : key[0]) {
      's' => startup(id),
      'i' => investor(id),
      'p' => program(id),
      _ => '$base/$key',
    };
  }

  /// Opens an app or a web address.
  static ShareLauncher launcher = (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  };

  /// Opens the phone's own share sheet.
  static SystemShare systemShare = (text, subject) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  };

  /// Opens the share sheet for url.
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

  /// Copies url and says "Link copied" (the sheet's "Copy link").
  static void copy(BuildContext context, String url) {
    unawaited(Clipboard.setData(ClipboardData(text: url)));
    AppToast.confirm(context, ProfileStrings.linkCopied);
  }
}
