import 'package:flutter/material.dart';

import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/theme/app_text.dart';

/// The notice at the top of every Manage tab for a team member: light blue
/// box (`#EEF2F8`, 1 px `#D7E1F0`, radius 16, padding 12 / 14), a white 36 px
/// tile with a navy lock, "View only" (15.5 bold navy) and the reason.
class ViewOnlyBanner extends StatelessWidget {
  const ViewOnlyBanner({super.key});

  static const title = 'View only';
  static const message =
      'You’re a team member. Only the founder and co-founders can make changes.';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $message',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7E1F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: AppIcon.filled(
                  AppIcons.lock,
                  size: 18,
                  color: Color(0xFF1F3A5F),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.sans(
                      size: 15.5,
                      weight: FontWeight.w700,
                      color: const Color(0xFF1F3A5F),
                    ),
                  ),
                  Text(
                    message,
                    style: AppText.sans(
                      size: 13.5,
                      height: 19,
                      color: const Color(0xFF3C5A86),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
