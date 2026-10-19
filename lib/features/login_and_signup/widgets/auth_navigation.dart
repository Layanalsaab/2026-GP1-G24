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
