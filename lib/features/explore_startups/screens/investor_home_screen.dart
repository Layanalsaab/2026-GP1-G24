import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../models/app_user.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/common_widgets/placeholder_home.dart';

/// Placeholder until the Investor home (Figma "10 · Explore — Investor") is built.
class InvestorHomeScreen extends StatelessWidget {
  const InvestorHomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => PlaceholderHome(
        title: AppStrings.investorHomeTitle,
        userName: user.fullName,
        onLogOut: () => AppRouter.logOut(context),
      );
}
