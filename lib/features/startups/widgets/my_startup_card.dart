import 'package:flutter/material.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import 'startup_logo.dart';
import 'startup_tag.dart';
import 'visibility_badge.dart';

/// A founder's own startup in the My Startups list (Figma "V2 · 44b"):
/// logo, name, one-line summary, sector / stage / "Looking for" tags, the
/// Public/Private badge and a Manage link. Tapping anywhere opens Manage;
/// the "..." button calls [onMore].
class MyStartupCard extends StatelessWidget {
  const MyStartupCard({
    super.key,
    required this.startup,
    required this.onTap,
    this.onMore,
  });

  final Startup startup;

  /// Opens the Manage page.
  final VoidCallback onTap;

  /// The "..." button; hidden when null.
  final VoidCallback? onMore;

  /// "SAR 500K" for funding, otherwise the other things sought.
  String get _lookingFor {
    final funding = startup.fundingRequirement;
    if (startup.seeksFunding && funding != null) {
      return Formatters.compactSar(funding);
    }
    return [
      for (final item in LookingFor.values)
        if (startup.lookingFor.contains(item)) startup.lookingForLabelOf(item),
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(AppRadius.lg);
    final lookingFor = _lookingFor;
    final summary = startup.summary;
    return Material(
      color: AppColors.surface,
      borderRadius: shape,
      child: InkWell(
        borderRadius: shape,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StartupLogo(
                    initials: startup.initials,
                    url: startup.logoUrl,
                    size: 52,
                    cornerFactor: 0.27,
                    fontSize: 17,
                    foreground: AppColors.moss600,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startup.name,
                          style: AppText.sans(
                            size: 16,
                            color: AppColors.ink,
                            weight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (summary.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            summary,
                            style: AppText.sans(
                              size: 13,
                              color: AppColors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onMore != null)
                    Semantics(
                      button: true,
                      label: StartupStrings.moreOptions,
                      excludeSemantics: true,
                      child: InkResponse(
                        onTap: onMore,
                        radius: 22,
                        child: SizedBox(
                          width: 32,
                          height: 40,
                          child: Center(
                            child: svgIcon('st_more.svg', size: 22),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StartupTag(startup.sectorLabel),
                  StartupTag(startup.stageLabel),
                  if (lookingFor.isNotEmpty)
                    StartupTag(
                      StartupStrings.lookingForTag(lookingFor),
                      gold: true,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.dividerSoft,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Flexible(child: VisibilityBadge(isPublic: startup.isPublic)),
                  const SizedBox(width: AppSpacing.sm),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      StartupStrings.manage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 14,
                        color: AppColors.moss600,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  svgIcon('st_chev16.svg', size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
