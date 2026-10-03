import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared_ui/theme/app_theme.dart';
import '../../../shared_ui/common_widgets/design_canvas.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import 'intro_one_screen.dart';

/// Figma: "V2 · 01 · Splash"
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  Timer? _timer;

  static const _sparkles = [
    Offset(48, 90),
    Offset(310, 130),
    Offset(70, 560),
    Offset(300, 600),
    Offset(40, 260),
    Offset(320, 310),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _timer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const IntroOneScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _goldLine(double left) => Positioned(
        left: left,
        top: 540,
        width: 48,
        height: 1.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      background: AppColors.cream,
      children: [
        // Decorative house-shaped rings.
        positionedSvg('splash_ring0.svg', left: 50, top: 79, width: 260, height: 325),
        positionedSvg('splash_ring1.svg', left: -5, top: 48.5, width: 370, height: 462.5),
        positionedSvg('splash_ring2.svg', left: -60, top: 18, width: 480, height: 600),
        positionedSvg('splash_ring3.svg', left: -115, top: -12.5, width: 590, height: 737.5),
        for (final p in _sparkles)
          positionedSvg('sparkle.svg', left: p.dx, top: p.dy, width: 6, height: 6),
        Positioned.fill(
          child: FadeTransition(
            opacity: _fade,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 87,
                  top: 222,
                  width: 186,
                  height: 177,
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 432,
                  child: Text(
                    'Start.sa',
                    textAlign: TextAlign.center,
                    style: AppText.serif(size: 44, color: AppColors.green),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 492,
                  child: Text(
                    'Connect. Invest. Grow.',
                    textAlign: TextAlign.center,
                    style: AppText.sans(size: 15, color: AppColors.grey),
                  ),
                ),
                // Gold divider: line, diamond, line.
                _goldLine(114.5),
                Positioned(
                  left: 178,
                  top: 533,
                  child: Transform.rotate(
                    angle: -0.7853981633974483,
                    child: Container(width: 7, height: 7, color: AppColors.gold),
                  ),
                ),
                _goldLine(197.5),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
