import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/explore_strings.dart';
import '../../../models/investor_profile.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';

/// Figma "V2 · 15 · Investor Profile — Founder POV": what a founder sees when
/// opening an investor. Design phase: the two request buttons are for show.
class InvestorProfileScreen extends StatelessWidget {
  const InvestorProfileScreen({super.key, required this.investor});

  final InvestorProfile investor;

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
              title: ExploreStrings.investorProfileTitle,
              leading: TopBarBackButton(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _intro(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    ExploreStrings.investmentPreferences,
                    style: AppText.sans(
                      size: 16,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                      height: 24,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _preferences(),
                  const SizedBox(height: AppSpacing.lg),
                  // Design only: the requests aren't connected yet. The empty
                  // handlers keep the buttons looking active.
                  PrimaryButton(
                    label: ExploreStrings.sendInvestmentRequest,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: ExploreStrings.sendAssociationRequest,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intro() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.gold100,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 3),
            ),
            child: Text(
              investor.initials,
              style: AppText.serif(size: 28.8, color: AppColors.gold700),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            investor.name,
            textAlign: TextAlign.center,
            style: AppText.serif(size: 26, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                text: investor.title,
                background: AppColors.moss600,
                foreground: Colors.white,
              ),
              _chip(
                text: investor.city,
                background: AppColors.surface,
                foreground: AppColors.grey,
                border: AppColors.border,
                pin: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String text,
    required Color background,
    required Color foreground,
    Color? border,
    bool pin = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pin) ...[
            svgIcon('pin.svg', size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: AppText.sans(
              size: 12,
              color: foreground,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _preferences() {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.sans(
                  size: 14,
                  color: AppColors.grey,
                  weight: FontWeight.w500,
                  height: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: AppText.sans(size: 14, color: AppColors.ink, height: 20),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          row(ExploreStrings.sectors, investor.sectors.join(', ')),
          row(ExploreStrings.stages, investor.stages.join(', ')),
          row(ExploreStrings.ticketSize, investor.ticketRange),
          row(ExploreStrings.location, investor.locations.join(', ')),
        ],
      ),
    );
  }
}
