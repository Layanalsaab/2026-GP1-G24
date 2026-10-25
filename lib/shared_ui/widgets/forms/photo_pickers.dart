import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// Sign-up profile photo picker: 92 px moss100 circle with a person icon (40)
/// or, when [hasPhoto], a moss gradient circle with white initials (30/600,
/// pops in), a 30 px moss600 camera badge with a 3 px cream ring at the
/// bottom-right, and the label "Add profile photo" (14/600 moss600).
class PhotoPickerPlaceholder extends StatelessWidget {
  const PhotoPickerPlaceholder({
    super.key,
    required this.onTap,
    this.hasPhoto = false,
    this.initials = '',
    this.label = 'Add profile photo',
    this.image,
  });

  final VoidCallback? onTap;
  final bool hasPhoto;
  final String initials;
  final String label;

  /// Optional picked image shown instead of the initials.
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Center(
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Pressable(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.moss100,
                        ),
                        child: hasPhoto
                            ? Pop(
                                child: Container(
                                  width: 92,
                                  height: 92,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment(-0.57, -0.82),
                                      end: Alignment(0.57, 0.82),
                                      colors: [
                                        AppColors.moss400,
                                        AppColors.moss600,
                                      ],
                                    ),
                                    image: image == null
                                        ? null
                                        : DecorationImage(
                                            image: image!,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  child: image != null
                                      ? null
                                      : Text(
                                          initials,
                                          style: AppText.sans(
                                            size: 30,
                                            weight: FontWeight.w600,
                                            color: AppColors.onDark,
                                          ),
                                        ),
                                ),
                              )
                            : AppIcon.filled(
                                AppIcons.person,
                                size: 40,
                                color: AppColors.moss600,
                              ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: 2,
                        child: Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.moss600,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cream,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: AppIcon.filled(
                            AppIcons.camera,
                            size: 16,
                            color: AppColors.onDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppText.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.moss600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Add-startup step 1 logo row (padding 20 16 0, gap 14): a 76 px tile (dashed
/// 1.5 `#8C918D` placeholder with an image icon, radius 20; after upload a
/// gold gradient tile with initials 26/700, pops in) next to "Startup logo"
/// (15/500) and the link "Upload logo" / "Change logo" (14/600 moss600).
class LogoPickerRow extends StatelessWidget {
  const LogoPickerRow({
    super.key,
    required this.onTap,
    this.hasLogo = false,
    this.image,
  });

  final VoidCallback? onTap;
  final bool hasLogo;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    // The same square as the profile photo in Create your account: empty
    // (dashed border, camera) until a logo is picked, then the picture.
    final tile = image != null
        ? Pop(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(image: image!, fit: BoxFit.cover),
              ),
            ),
          )
        : CustomPaint(
            painter: _DashedRRectPainter(),
            child: SizedBox(
              width: 76,
              height: 76,
              child: Center(
                child: AppIcon.filled(
                  AppIcons.camera,
                  size: 26,
                  color: AppColors.grey,
                ),
              ),
            ),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Upload logo',
            excludeSemantics: true,
            child: Pressable(onTap: onTap, child: tile),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Startup Logo',
                style: AppText.sans(size: 15, weight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Semantics(
                button: true,
                excludeSemantics: true,
                label: hasLogo ? 'Change logo' : 'Upload logo',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Text(
                    hasLogo ? 'Change logo' : 'Upload logo',
                    style: AppText.sans(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.moss600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Founder sign-up profile photo row, the same design as the Add startup
/// logo row (padding 20 16 0, gap 14): a 76 px square with radius 20 and a
/// 1.5 dashed `#8C918D` border, white fill and a 26 px `#5B625D` camera, next
/// to "Profile photo" (15/500) and the link "Upload photo" (14/600
/// `#2F5D3A`). After a photo is picked the square shows it without a border
/// and the link reads "Change photo". No toast.
class ProfilePhotoRow extends StatelessWidget {
  const ProfilePhotoRow({super.key, required this.onTap, this.image});

  final VoidCallback? onTap;

  /// The picked photo, or null while there is none.
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = image != null;
    final tile = hasPhoto
        ? Pop(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(image: image!, fit: BoxFit.cover),
              ),
            ),
          )
        : CustomPaint(
            painter: _DashedRRectPainter(),
            child: SizedBox(
              width: 76,
              height: 76,
              child: Center(
                child: AppIcon.filled(
                  AppIcons.camera,
                  size: 26,
                  color: AppColors.grey,
                ),
              ),
            ),
          );
    final action = hasPhoto ? 'Change photo' : 'Upload photo';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: action,
            excludeSemantics: true,
            child: Pressable(onTap: onTap, child: tile),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Photo',
                style: AppText.sans(size: 15, weight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Semantics(
                button: true,
                excludeSemantics: true,
                label: action,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Text(
                    action,
                    style: AppText.sans(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.moss600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dashed rounded-rectangle outline (also used by the "Add team member"
/// button).
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    this.radius = 12,
    this.strokeWidth = 1.5,
    this.dash = 6,
    this.gap = 4,
    this.fill,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    if (fill != null) canvas.drawPath(path, Paint()..color = fill!);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color || old.radius != radius || old.fill != fill;
}

class _DashedRRectPainter extends DashedBorderPainter {
  _DashedRRectPainter()
    : super(color: AppColors.borderStrong, radius: 20, fill: AppColors.surface);
}
