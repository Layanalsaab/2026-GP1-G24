import 'package:flutter/material.dart';

import '../../../shared_ui/navigation/app_route.dart';
import '../screens/welcome_screen.dart';

/// The on-screen back arrow of every auth screen (docs/04 stack model): pop
/// when there is a screen below, otherwise go to Welcome.
void authBack(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    AppNav.back(context);
  } else {
    WelcomeScreen.open(context);
  }
}

/// Like [authBack], but a plain pop that the screen's own back guard
/// (`PopScope`) cannot intercept. Use it after the user has already decided
/// to leave (e.g. "Discard"), otherwise the guard would ask again.
void authLeave(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    WelcomeScreen.open(context);
  }
}
