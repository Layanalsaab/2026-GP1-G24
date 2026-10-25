import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_constants/profile_strings.dart';
import '../shared_ui/widgets/overlays/app_toast.dart';

/// The one place every share icon goes through: it copies the item's link to
/// the clipboard and shows the "Link copied" pop-up.
///
/// The link is `https://start.sa/<startup|investor|program>/<id>`. (A link that
/// opens the app on that page can come later; the text copied stays the same.)
class ShareLink {
  ShareLink._();

  static const String base = 'https://start.sa';

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

  /// Copies [url] and says "Link copied".
  static void copy(BuildContext context, String url) {
    unawaited(Clipboard.setData(ClipboardData(text: url)));
    AppToast.confirm(context, ProfileStrings.linkCopied);
  }

  /// Copies the link of the item behind a bookmark key.
  static void copyKey(BuildContext context, String key) =>
      copy(context, forKey(key));
}
