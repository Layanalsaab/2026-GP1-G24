import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

/// Tells the main screen (top bar and side menu) that the signed-in user's
/// profile changed, e.g. a new name or photo saved on Edit profile.
class CurrentUser {
  CurrentUser._();

  static final ValueNotifier<AppUser?> changes = ValueNotifier<AppUser?>(null);

  static void publish(AppUser user) => changes.value = user;
}
