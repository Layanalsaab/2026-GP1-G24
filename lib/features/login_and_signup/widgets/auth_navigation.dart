import 'package:flutter/material.dart';

import '../../../shared_ui/navigation/app_route.dart';
import '../screens/welcome_screen.dart';

void authBack(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    AppNav.back(context);
  } else {
    WelcomeScreen.open(context);
  }
}

/// Like authBack, but a plain pop that the screen's own back guard (PopScope) cannot intercept.
void authLeave(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    WelcomeScreen.open(context);
  }
}
