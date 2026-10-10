import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../navigation/seeker_main_screen.dart';
import '../../../shared_ui/common_widgets/design_canvas.dart';
import '../../../shared_ui/common_widgets/gold_divider.dart';
import '../../../shared_ui/common_widgets/house_rings.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import 'choose_role_screen.dart';
import 'login_screen.dart';

/// Figma: "V2 · 02 · Welcome"
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// Opens the welcome screen and clears the splash/intro history, so Back
  /// from here leaves the app instead of replaying the intros.
  static void open(BuildContext context) =>
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );

  static const _sparkles = [
    Offset(44, 80),
    Offset(312, 120),
    Offset(52, 420),
    Offset(308, 450),
  ];

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      background: AppColors.cream,
      children: [
        ...houseRings(dy: -40, sparkles: _sparkles),
        _logoWithShadow(),
        Positioned(
          left: 0,
          right: 0,
          top: 320,
          child: Text(
            'Start.sa',
            textAlign: TextAlign.center,
            style: AppText.serif(size: 38, color: AppColors.green),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 378,
          child: Text(
            'The Saudi startup and investment hub.\n'
            'Where founders, investors, and talent meet.',
            textAlign: TextAlign.center,
            style: AppText.sans(size: 14, color: AppColors.grey, height: 22),
          ),
        ),
        ...goldDivider(lineTop: 442),
        Positioned(
          left: 24,
          top: 606,
          width: 312,
          child: PrimaryButton(
            label: 'Create account',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
            ),
          ),
        ),
        Positioned(
          left: 24,
          top: 666,
          width: 312,
          child: SecondaryButton(
            label: 'Log in',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ),
        Positioned(
          left: 24,
          top: 722,
          width: 312,
          height: 44,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A guest browses the seeker Hub / Explore / Programs, no account.
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SeekerMainScreen()),
            ),
            child: Center(
              child: Text(
                'Continue as guest',
                style: AppText.sans(
                  size: 14,
                  color: AppColors.grey,
                  weight: FontWeight.w500,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Logo with a soft green drop shadow that follows its shape.
  Widget _logoWithShadow() {
    final logo = Image.asset('assets/images/logo.png', fit: BoxFit.cover);
    return Positioned(
      left: 105,
      top: 150,
      width: 150,
      height: 142,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: const Offset(0, 10),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0x2E1F4026),
                  BlendMode.srcIn,
                ),
                child: SizedBox(width: 150, height: 142, child: logo),
              ),
            ),
          ),
          SizedBox(width: 150, height: 142, child: logo),
        ],
      ),
    );
  }
}
