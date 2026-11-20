import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'arch_background.dart';
import 'header_buttons.dart';

class ProfileBanner extends StatelessWidget {
  const ProfileBanner({
    super.key,
    required this.onBack,
    this.trailing,
    this.overlap = 48,
  });

  /// Own profile: back + "Edit profile" outline pill.
  ProfileBanner.edit({
    Key? key,
    required VoidCallback? onBack,
    required VoidCallback? onEdit,
    double overlap = 48,
  }) : this(
         key: key,
         onBack: onBack,
         overlap: overlap,
         trailing: ProfileEditPill(onTap: onEdit),
       );

  /// Investor profile: back + glass bookmark (when showBookmark) + share.
  ProfileBanner.glass({
    Key? key,
    required VoidCallback? onBack,
    required VoidCallback? onShare,
    VoidCallback? onBookmark,
    bool bookmarked = false,
    bool showBookmark = true,
    double overlap = 48,
  }) : this(
         key: key,
         onBack: onBack,
         overlap: overlap,
         trailing: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             if (showBookmark) ...[
               HeaderBookmarkButton(bookmarked: bookmarked, onTap: onBookmark),
               const SizedBox(width: 8),
             ],
             GlassIconButton.share(onTap: onShare),
           ],
         ),
       );

  final VoidCallback? onBack;
  final Widget? trailing;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    return HeaderOverlap(
      overlap: overlap,
      child: SizedBox(
        height: 124 + inset,
        width: double.infinity,
        child: ColoredBox(
          color: AppColors.green,
          child: ClipRect(
            child: Stack(
              children: [
                const ArchBackground.banner(),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, inset, 12, 0),
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HeaderBackButton.profile(onTap: onBack),
                        ?trailing,
                      ],
                    ),
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
