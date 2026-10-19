import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../widgets/auth_decor.dart';
import 'choose_role_screen.dart';
import 'login_screen.dart';

/// Welcome (docs/05 A5): logo, "Start.sa", two lines of description, and the
/// Create account / Log in / Continue as guest stack.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// Replaces the whole stack with Welcome (the back transition: used after
  /// Log out).
  static void open(BuildContext context) =>
      AppNav.reset(context, const WelcomeScreen(), kind: RouteKind.back);

  @override
  Widget build(BuildContext context) {
    final body = AppText.sans(size: 15, color: AppColors.grey, height: 22);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const WelcomeBackdrop(),
          SafeArea(
            top: false,
            child: FlexPage(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 150),
                      const LogoIn(child: BrandLogo(width: 120, height: 114)),
                      const SizedBox(height: 26),
                      Rise(
                        delay: const Duration(milliseconds: 80),
                        child: Semantics(
                          header: true,
                          child: Text(
                            AuthStrings.appName,
                            style: AppText.wordmarkWelcome,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Rise(
                        delay: const Duration(milliseconds: 140),
                        child: Text(
                          '${AuthStrings.welcomeLine1}\n${AuthStrings.welcomeLine2}',
                          textAlign: TextAlign.center,
                          style: body,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const GoldDivider(lineWidth: 40, diamond: 7),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Rise(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppButton(
                          label: AuthStrings.createAccount,
                          onPressed: () => ChooseRoleScreen.open(context),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: AuthStrings.logIn,
                          variant: AppButtonVariant.outline,
                          onPressed: () => LoginScreen.open(context),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: AuthStrings.continueAsGuest,
                          variant: AppButtonVariant.ghost,
                          onPressed: () => AppRouter.openGuest(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
