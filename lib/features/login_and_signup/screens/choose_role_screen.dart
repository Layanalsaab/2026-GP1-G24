import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/form_page.dart';
import '../../../shared_ui/widgets/headers/auth_headers.dart';
import '../../../shared_ui/widgets/headers/overlap_layout.dart';
import '../widgets/auth_navigation.dart';
import '../widgets/role_card.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Choose role (docs/05 A6): Founder (pre-selected) or Investor, then
/// Continue to the sign-up form for that role.
class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  /// Pushes Choose role (Welcome's "Create account", the Log in footer and
  /// the guest "Sign up" pill).
  static void open(BuildContext context) =>
      AppNav.push(context, const ChooseRoleScreen(), greenHeader: true);

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  AccountRole _role = AccountRole.founder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoleHeader(
              title: AuthStrings.chooseRoleTitle,
              onBack: () => authBack(context),
            ),
            OverlapList(
              gap: 14,
              children: [
                RoleCard(
                  icon: AppIcons.sprout,
                  title: AuthStrings.founder,
                  description: AuthStrings.founderDescription,
                  selected: _role == AccountRole.founder,
                  onTap: () => setState(() => _role = AccountRole.founder),
                ),
                RoleCard(
                  icon: AppIcons.trend,
                  title: AuthStrings.investor,
                  description: AuthStrings.investorDescription,
                  selected: _role == AccountRole.investor,
                  onTap: () => setState(() => _role = AccountRole.investor),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: AppButton(
                    label: AuthStrings.continueLabel,
                    onPressed: () => SignupScreen.open(context, _role),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FooterLink.moss(
                    prefix: AuthStrings.haveAccount,
                    linkLabel: AuthStrings.logIn,
                    onTap: () => LoginScreen.open(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
