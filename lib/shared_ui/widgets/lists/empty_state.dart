import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import '../buttons/app_button.dart';

/// Plain empty state (prototype `.hempty`): a 64 circle `#EEF4EF` with an
/// icon, a 16/700 title, a 14 `#6B726C` message and an optional small
/// outline button. Padding 36 16, gap 6.
///
/// [EmptyState.noMatches] is the Hub/Explore "No matches" variant:
/// "No matches" / "Try removing a filter or searching for something else." and
/// a "Clear all" button.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.search,
    this.actionLabel,
    this.onAction,
  });

  /// The search "No matches" state with a "Clear all" button.
  const EmptyState.noMatches({super.key, required VoidCallback this.onAction})
    : title = 'No matches',
      message = 'Try removing a filter or searching for something else.',
      icon = AppIcons.search,
      actionLabel = 'Clear all';

  final String title;
  final String message;

  /// Filled icon path (28 px, moss600).
  final String icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              color: AppColors.mossChip,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppIcon.filled(icon, size: 28, color: AppColors.moss600),
          ),
          const SizedBox(height: 6),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.sans(size: 16, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.sans(
              size: 14,
              color: AppColors.metaText,
              height: 20,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
              expanded: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Illustrated empty card (prototype `.mempty`, e.g. My Startups empty):
/// white card radius 20 (list-card shadow), padding 24 20, centered
/// [illustration] (wrapped in [Float] unless [float] is false), title 20/700
/// (ls -0.3), message 14/20 grey and an optional full-width primary button
/// with a plus icon. The illustration itself is screen-specific.
class IllustratedEmptyCard extends StatelessWidget {
  const IllustratedEmptyCard({
    super.key,
    required this.illustration,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = AppIcons.plus,
    this.float = true,
  });

  final Widget illustration;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? actionIcon;

  /// Wrap [illustration] in the looping [Float] effect.
  final bool float;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        boxShadow: AppShadow.listCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          float ? Float(child: illustration) : illustration,
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.sans(
                size: 20,
                weight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              icon: actionIcon,
            ),
          ],
        ],
      ),
    );
  }
}

/// The guest "Join Start.sa" card (prototype `.gcta`): green, radius 18,
/// padding 18 16, "Join Start.sa" 16/700, 13.5/20 `#CFE0D3` copy and a white
/// "Sign up" button (46 high, radius 13, 15/700 green).
class GuestJoinCard extends StatelessWidget {
  const GuestJoinCard({super.key, required this.onSignUp});

  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Join Start.sa',
              style: AppText.sans(
                size: 16,
                color: AppColors.white,
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a free account to bookmark startups and investors, send requests and get matched.',
            style: AppText.sans(
              size: 13.5,
              color: AppColors.onGreenMuted,
              height: 20,
            ),
          ),
          const SizedBox(height: 14),
          Pressable(
            onTap: onSignUp,
            child: Semantics(
              button: true,
              label: 'Sign up',
              excludeSemantics: true,
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  'Sign up',
                  style: AppText.sans(
                    size: 15,
                    color: AppColors.green,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
