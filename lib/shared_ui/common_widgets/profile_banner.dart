import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The green banner at the top of Profile and Edit profile: a dark green
/// gradient with faint gold rings in the right corner.
class ProfileBanner extends StatelessWidget {
  const ProfileBanner({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _BannerPainter()),
    );
  }
}

class _BannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.green, AppColors.moss600],
        ).createShader(rect),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.gold.withValues(alpha: 0.35);
    final center = Offset(size.width * 0.92, size.height * 0.2);
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, 36.0 * i, ring);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
