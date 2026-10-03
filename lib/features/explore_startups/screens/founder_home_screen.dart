import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../models/app_user.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/common_widgets/placeholder_home.dart';

/// Placeholder until the Founder home (Figma "09b · Explore — Founder") is built.
class FounderHomeScreen extends StatelessWidget {
  const FounderHomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => PlaceholderHome(
        title: AppStrings.founderHomeTitle,
        userName: user.fullName,
        onLogOut: () => AppRouter.logOut(context),
      );
}
