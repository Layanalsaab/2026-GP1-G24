import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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
        Positioned(left: 24, top: 486, width: 312, height: 64, child: _stats()),
        Positioned(
          left: 24,
          top: 636,
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
          top: 696,
          width: 312,
          child: SecondaryButton(
            label: 'Log in',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  Widget _stats() {
    Widget stat(String value, String label) => Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: AppText.serif(size: 18, color: AppColors.gold)),
              const SizedBox(height: 2),
              Text(label, style: AppText.sans(size: 11, color: AppColors.grey)),
            ],
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141F4026),
            offset: Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        children: [
          stat('120+', 'Startups'),
          stat('45+', 'Investors'),
          stat('30+', 'Programs'),
        ],
      ),
    );
  }
}
