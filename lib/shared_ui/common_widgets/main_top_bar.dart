import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_constants/navigation_strings.dart';
import '../../navigation/placeholder_features.dart';
import '../theme/app_theme.dart';
import 'svg_asset.dart';
import 'user_avatar.dart';

/// The cream top bar of the three main tabs (Figma "Top bar"): the user's
/// avatar on the left (opens the side menu), the logo in the middle and the
/// notifications bell on the right.
///
/// A guest (startup seeker) has no initials, so the avatar shows a person
/// icon, and there is no bell.
class MainTopBar extends StatelessWidget {
  const MainTopBar({
    super.key,
    required this.onMenu,
    this.name,
    this.photoUrl,
  });

  final VoidCallback onMenu;

  /// The user's name (for the initials); null for a guest.
  final String? name;

  /// The user's profile photo, if they have one.
  final String? photoUrl;

  bool get _isGuest => name == null;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        color: AppColors.cream,
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: SizedBox(
          height: 56,
          child: Stack(
            children: [
              Positioned(left: 8, top: 6, child: _avatar()),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 30,
                  height: 29,
                  fit: BoxFit.cover,
                ),
              ),
              if (!_isGuest) Positioned(right: 12, top: 8, child: _bell()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    return Semantics(
      button: true,
      label: NavigationStrings.openMenu,
      excludeSemantics: true,
      onTap: onMenu,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onMenu,
        // The circle is 34 px, inside a 44 px touch target.
        child: SizedBox(
          width: 52,
          height: 44,
          child: Align(
            alignment: Alignment.center,
            child: _isGuest
                ? Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.moss100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: AppColors.moss600,
                    ),
                  )
                : UserAvatar(name: name!, photoUrl: photoUrl, size: 34),
          ),
        ),
      ),
    );
  }

  /// Bell with the small gold "new" dot. Inert: notifications are not built yet.
  Widget _bell() {
    return PlaceholderIcon(
      feature: PlaceholderFeature.notifications,
      size: 40,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            svgIcon('bell.svg', size: 40, color: AppColors.ink),
            Positioned(
              right: 10,
              top: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cream, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
