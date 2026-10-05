import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/seeker_strings.dart';
import '../../../models/startup_listing.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/listing_card_parts.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import 'express_interest_screen.dart';

/// Figma "V2 · 14c · Startup Profile — Seeker POV": a startup as a startup
/// seeker sees it. Design phase: sharing does nothing, and "Express Interest"
/// only opens the form.
class SeekerStartupProfileScreen extends StatelessWidget {
  const SeekerStartupProfileScreen({super.key, required this.listing});

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
            GreenTopBar(
              title: '',
              leading: const TopBarBackButton(),
              actions: [
                // Design only: sharing isn't connected yet.
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: svgIcon('share.svg', size: 22)),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: 24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _hero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _content(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    final startup = listing.startup;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.gold100,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold, width: 3),
            ),
            child: Text(
              listing.initials,
              style: AppText.serif(size: 26, color: AppColors.gold700),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            listing.name,
            textAlign: TextAlign.center,
            style: AppText.serif(size: 26, color: AppColors.ink),
          ),
          if (startup.tagline != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              startup.tagline!,
              textAlign: TextAlign.center,
              style: AppText.sans(size: 14, color: AppColors.grey),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                listing.sectorLabel,
                background: AppColors.moss600,
                foreground: Colors.white,
              ),
              if (listing.stageLabel.isNotEmpty)
                _chip(
                  listing.stageLabel,
                  background: AppColors.surface,
                  foreground: AppColors.moss600,
                  border: AppColors.moss600,
                ),
              _chip(
                listing.city,
                background: AppColors.surface,
                foreground: AppColors.grey,
                border: AppColors.border,
                pin: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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

  Widget _chip(
    String text, {
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

  Widget _content(BuildContext context) {
    final startup = listing.startup;
    final seeking = startup.fundingRequirement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stats(
          seeking: seeking == null ? '—' : _compactSar(seeking),
          team: listing.teamSize == null ? '—' : '${listing.teamSize}',
          founded: startup.foundedYear == null ? '—' : '${startup.foundedYear}',
        ),
        if (listing.lookingForNote != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _lookingFor(listing.lookingForNote!),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(SeekerStrings.about, style: _heading),
        const SizedBox(height: AppSpacing.lg),
        Text(
          startup.description,
          style: AppText.sans(size: 16, color: AppColors.grey, height: 24),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: SeekerStrings.expressInterest,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExpressInterestScreen(listing: listing),
            ),
          ),
        ),
        if (listing.associations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            SeekerStrings.associations,
            style: AppText.sans(
              size: 14,
              color: AppColors.ink,
              weight: FontWeight.w600,
            ),
          ),
          for (final association in listing.associations) ...[
            const SizedBox(height: AppSpacing.lg),
            _associationRow(association.name, association.subtitle),
          ],
        ],
      ],
    );
  }

  TextStyle get _heading => AppText.sans(
        size: 16,
        color: AppColors.ink,
        weight: FontWeight.w600,
        height: 24,
      );

  /// 500000 -> "SAR 500K", 1200000 -> "SAR 1.2M".
  static String _compactSar(int value) {
    if (value >= 1000000) {
      final millions = value / 1000000;
      final text = millions == millions.roundToDouble()
          ? millions.toStringAsFixed(0)
          : millions.toStringAsFixed(1);
      return 'SAR ${text}M';
    }
    return 'SAR ${(value / 1000).round()}K';
  }

  Widget _stats({
    required String seeking,
    required String team,
    required String founded,
  }) {
    Widget stat(String value, String label) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text(
                  value,
                  style: AppText.sans(
                    size: 16,
                    color: AppColors.ink,
                    weight: FontWeight.w600,
                    height: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(label, style: AppText.caption),
              ],
            ),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          stat(seeking, SeekerStrings.seeking),
          stat(team, SeekerStrings.team),
          stat(founded, SeekerStrings.founded),
        ],
      ),
    );
  }

  Widget _lookingFor(String note) {
    final style = AppText.sans(size: 14, color: AppColors.gold700, height: 20);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.gold100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SeekerStrings.lookingFor,
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(note, style: style),
        ],
      ),
    );
  }

  Widget _associationRow(String name, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          InitialsBadge(
            initials: _initialsOf(name),
            size: 44,
            circle: true,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.itemTitle),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.gold),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                svgIcon('globe.svg', size: 14),
                const SizedBox(width: 4),
                Text(
                  SeekerStrings.publicBadge,
                  style: AppText.sans(
                    size: 10,
                    color: AppColors.gold700,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initialsOf(String name) {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }
}
