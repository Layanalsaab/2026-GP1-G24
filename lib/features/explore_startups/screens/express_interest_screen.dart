import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/seeker_strings.dart';
import '../../../models/startup_listing.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/listing_card_parts.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';

/// Figma "V2 · 26 · Expression of Interest — Seeker". Design phase: the
/// fields can be typed in, but "Submit interest" doesn't send anything yet.
class ExpressInterestScreen extends StatelessWidget {
  const ExpressInterestScreen({super.key, required this.listing});

  final StartupListing listing;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            const GreenTopBar(
              title: SeekerStrings.formTitle,
              leading: TopBarBackButton(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _startupCard(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    SeekerStrings.formPrompt,
                    style: AppText.sans(
                      size: 16,
                      color: AppColors.grey,
                      height: 24,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppTextField(
                    label: SeekerStrings.nameLabel,
                    hint: SeekerStrings.nameHint,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppTextField(
                    label: SeekerStrings.expertiseLabel,
                    hint: SeekerStrings.expertiseHint,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppTextField(
                    label: SeekerStrings.contributionLabel,
                    hint: SeekerStrings.contributionHint,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppTextField(
                    label: SeekerStrings.emailLabel,
                    hint: SeekerStrings.emailHint,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              // Design only: nothing is sent yet. The empty handler keeps the
              // button looking active.
              child: PrimaryButton(
                label: SeekerStrings.submit,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The startup being applied to, summarised at the top of the form.
  Widget _startupCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          InitialsBadge(
            initials: listing.initials,
            size: 40,
            radius: 10,
            fontSize: 12,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.name, style: AppText.itemTitle),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${listing.sectorStage} · ${listing.city}',
                  style: AppText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
