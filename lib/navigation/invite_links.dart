import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../app_constants/app_config.dart';
import '../features/startups/screens/invite_screen.dart';
import '../shared_ui/widgets/overlays/app_toast.dart';

/// The "Open Start.sa" link of an invitation e-mail
/// (`https://<site>/invite?i=<invitation id>`). Android opens the app for it
/// when the app is installed; the app shows the invite screen.
///
/// A link that arrives while the app is still starting (the splash) is kept
/// and opened by [appReady], once the first real screen is up.
class InviteLinks {
  InviteLinks._();

  static String? _pending;
  static bool _ready = false;
  static StreamSubscription<Uri>? _subscription;

  /// Starts listening for links (the one that launched the app, and later
  /// ones). Safe to call more than once.
  static Future<void> init() async {
    if (_subscription != null) return;
    try {
      final links = AppLinks();
      final first = await links.getInitialLink();
      if (first != null) handle(first);
      _subscription = links.uriLinkStream.listen(handle);
    } catch (e) {
      debugPrint('Deep links are not available: $e');
    }
  }

  /// The invitation id of an invite link, or null for any other link.
  static String? idFrom(Uri uri) {
    final base = Uri.parse(AppConfig.inviteLinkBase);
    if (uri.host != base.host || uri.path != base.path) return null;
    final id = uri.queryParameters['i'];
    return id == null || id.isEmpty ? null : id;
  }

  static void handle(Uri uri) {
    final id = idFrom(uri);
    if (id == null) return;
    _pending = id;
    if (_ready) _openPending();
  }

  /// The splash is done and a real screen is showing.
  static void appReady() {
    _ready = true;
    _openPending();
  }

  static void _openPending() {
    final id = _pending;
    final context = AppToast.navigatorKey.currentContext;
    if (id == null || context == null) return;
    _pending = null;
    InviteScreen.open(context, id);
  }
}
