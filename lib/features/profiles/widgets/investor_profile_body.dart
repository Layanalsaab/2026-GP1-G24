import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../models/app_user.dart';
import '../../../models/investor_profile.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/cards/profile_blocks.dart';
import '../../startup_profile/screens/startup_profile_screen.dart';
import 'profile_widgets.dart';

/// Email / phone of the signed-in investor with their Private / Public tags.
class InvestorContactData {
  const InvestorContactData({
    this.email = '',
    this.emailPublic = false,
    this.phone = '',
    this.phonePublic = false,
    this.linkedin = '',
    this.ownerView = true,
  });

  final String email;
  final bool emailPublic;
  final String phone;
  final bool phonePublic;
  final String linkedin;

  /// True on the investor's own profile: email and phone are both listed,
  /// each with its pill. Anybody else sees only what was made Public, and no
  /// Contact section when both are private.
  final bool ownerView;
}

/// Everything the investor profile body shows, as plain strings and lists.
/// Every field may be empty; empty parts are hidden.
class InvestorProfileData {
  const InvestorProfileData({
    this.sizeAmount = '',
    this.about = '',
    this.offer = '',
    this.lookingFor = '',
    this.yearsInvesting = '',
    this.startupsInvested = '',
    this.roundSize = '',
    this.ledRound,
    this.sectors = const [],
    this.stages = const [],
    this.commerceModels = const [],
  });

  /// "SAR 500K – 1M" per funding round; empty (no startups invested in yet)
  /// hides the hero card.
  final String sizeAmount;
  final String about;
  final String offer;
  final String lookingFor;
  final String yearsInvesting;

  /// "0", "1–3", ... "10+".
  final String startupsInvested;
  final String roundSize;
  final bool? ledRound;
  final List<String> sectors;
  final List<String> stages;

  /// Short names ("B2B"); "Other" already replaced by typed text.
  final List<String> commerceModels;

  static List<String> _withOther(List<String> values, String? typed) {
    final other = (typed ?? '').trim();
    return [
      for (final v in values)
        if (v == 'Other')
          if (other.isNotEmpty) other else v
        else
          v,
    ];
  }

  /// The signed-in investor's own answers.
  factory InvestorProfileData.fromUser(AppUser u) {
    final c = u.investorCriteria;
    final deals = (c?.dealsCount ?? '').trim();
    final round = deals == '0'
        ? ''
        : InvestorProfile.amountLabel(c?.roundMin, c?.roundMax);
    final short = c?.commerceModelsShort ?? '';
    return InvestorProfileData(
      sizeAmount: round,
      about: u.bio.trim(),
      offer: u.valueOffered.trim(),
      lookingFor: u.gain.trim(),
      yearsInvesting: (c?.yearsInvesting ?? '').trim(),
      startupsInvested: deals,
      roundSize: round,
      ledRound: c?.hasLedRound,
      sectors: _withOther(c?.sectors ?? const [], c?.sectorsOther),
      stages: _withOther(c?.stages ?? const [], c?.stagesOther),
      commerceModels: short.isEmpty
          ? const []
          : short.split(', ').where((s) => s.isNotEmpty).toList(),
    );
  }

  /// A sample / listed investor as a founder sees them.
  factory InvestorProfileData.fromInvestor(InvestorProfile i) {
    return InvestorProfileData(
      sizeAmount: (i.startupsInvested ?? '').trim() == '0'
          ? ''
          : i.ticketRange.trim(),
      about: i.profileBio.trim(),
      offer: (i.valueOffered ?? '').trim(),
      lookingFor: (i.hopeToGain ?? '').trim(),
      yearsInvesting: (i.yearsInvesting ?? '').trim(),
      startupsInvested: (i.startupsInvested ?? '').trim(),
      roundSize: (i.roundSize ?? '').trim(),
      ledRound: i.ledRound,
      sectors: i.sectors,
      stages: i.stages,
      commerceModels: i.commerceModels,
    );
  }
}

/// The body of an investor profile, shared by the investor's own profile and
/// the founder's view of an investor: ticket hero card, About, offer, what
/// they look for, background, interests, associations and (own profile only)
/// contact.
class InvestorProfileBody extends StatelessWidget {
  const InvestorProfileBody({
    super.key,
    required this.data,
    this.associations = const [],
    this.contact,
  });

  final InvestorProfileData data;
  final List<Startup> associations;

  /// Shown only on the investor's own profile.
  final InvestorContactData? contact;

  @override
  Widget build(BuildContext context) {
    var n = 0;
    Duration stagger() => Duration(milliseconds: 60 * n++);
    final d = data;
    final cells = <(String, String)>[
      if (d.yearsInvesting.isNotEmpty)
        (ProfileStrings.yearsOfInvesting, d.yearsInvesting),
      if (d.startupsInvested.isNotEmpty)
        (ProfileStrings.startupsInvested, d.startupsInvested),
      if (d.startupsInvested != '0' && d.roundSize.isNotEmpty)
        (ProfileStrings.roundSize, d.roundSize),
      if (d.ledRound != null)
        (
          ProfileStrings.ledARound,
          d.ledRound! ? ProfileStrings.yes : ProfileStrings.no,
        ),
    ];
    final hasInterests =
        d.sectors.isNotEmpty ||
        d.stages.isNotEmpty ||
        d.commerceModels.isNotEmpty;
    return ProfileSections(
      children: [
        if (d.sizeAmount.isNotEmpty)
          Rise(
            delay: stagger(),
            child: _SizeHero(amount: d.sizeAmount),
          ),
        if (d.about.isNotEmpty)
          ProfileSection(
            title: ProfileStrings.about,
            delay: stagger(),
            child: ProfileText(d.about),
          ),
        if (d.offer.isNotEmpty)
          ProfileSection(
            title: ProfileStrings.offerTitle,
            delay: stagger(),
            child: ProfileText(d.offer),
          ),
        if (d.lookingFor.isNotEmpty)
          ProfileSection(
            title: ProfileStrings.lookingForTitle,
            delay: stagger(),
            child: ProfileText(d.lookingFor),
          ),
        if (cells.isNotEmpty)
          ProfileSection(
            title: ProfileStrings.background,
            delay: stagger(),
            child: _BackgroundGrid(cells: cells),
          ),
        if (hasInterests)
          ProfileSection(
            title: ProfileStrings.interests,
            delay: stagger(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ValueRows(ProfileStrings.sectors, d.sectors),
                _ValueRows(ProfileStrings.stages, d.stages),
                _ValueRows(ProfileStrings.commerceModels, d.commerceModels),
              ],
            ),
          ),
        if (associations.isNotEmpty)
          ProfileSection(
            title: ProfileStrings.associations,
            delay: stagger(),
            child: Column(
              children: [
                for (var i = 0; i < associations.length; i++)
                  ListRow(
                    showDivider: i > 0,
                    leading: HueAvatar(name: associations[i].name, size: 44),
                    title: associations[i].name,
                    subtitle:
                        '${associations[i].sectorLabel} · ${associations[i].location.label}',
                    onTap: () => StartupProfileScreen.open(
                      context,
                      startup: associations[i],
                    ),
                  ),
              ],
            ),
          ),
        if (contact != null &&
            (contact!.ownerView ||
                (contact!.emailPublic && contact!.email.trim().isNotEmpty) ||
                (contact!.phonePublic && contact!.phone.trim().isNotEmpty)))
          ProfileSection(
            title: ProfileStrings.contact,
            delay: stagger(),
            child: Column(
              children: [
                if (contact!.ownerView ||
                    (contact!.emailPublic && contact!.email.trim().isNotEmpty))
                  _ContactRow(
                    icon: AppIcons.mail,
                    label: ProfileStrings.email,
                    value: contact!.email,
                    isPublic: contact!.emailPublic,
                  ),
                if (contact!.ownerView ||
                    (contact!.phonePublic && contact!.phone.trim().isNotEmpty))
                  _ContactRow(
                    icon: AppIcons.phone,
                    label: ProfileStrings.phone,
                    value: contact!.phone,
                    isPublic: contact!.phonePublic,
                    showDivider:
                        contact!.ownerView ||
                        (contact!.emailPublic &&
                            contact!.email.trim().isNotEmpty),
                  ),
                if (contact!.ownerView && contact!.linkedin.trim().isNotEmpty)
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.rowSeparator),
                      ),
                    ),
                    child: InfoRow(
                      icon: AppIcons.linkedIn,
                      label: ProfileStrings.linkedinLabel,
                      value: contact!.linkedin.trim(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SizeHero extends StatelessWidget {
  const _SizeHero({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F5D3A), Color(0xFF1F3F27)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 12, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                ProfileStrings.investmentSize,
                style: AppText.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: const Color(0xCCFFFFFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: AppText.sans(
              size: 28,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ProfileStrings.perFundingRound,
            style: AppText.sans(size: 13, color: const Color(0xCCFFFFFF)),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGrid extends StatelessWidget {
  const _BackgroundGrid({required this.cells});

  final List<(String, String)> cells;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (label, value) in cells)
              Container(
                width: w,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F7F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppText.sans(size: 12, color: AppColors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppText.sans(
                        size: 17,
                        weight: FontWeight.w600,
                        color: AppColors.moss600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One interests group: a small grey label with a gold bar, then the values
/// as plain text, one per line (no chips).
class _ValueRows extends StatelessWidget {
  const _ValueRows(this.label, this.values);

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 12, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.sans(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final v in values)
            Text(
              v,
              style: AppText.sans(
                size: 14,
                height: 22,
                weight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
        ],
      ),
    );
  }
}

/// An [InfoRow] with a Private / Public tag on the right.
class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isPublic,
    this.showDivider = false,
  });

  final String icon;
  final String label;
  final String value;
  final bool isPublic;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(top: BorderSide(color: AppColors.rowSeparator))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: InfoRow(
              icon: icon,
              label: label,
              value: value.trim().isEmpty ? ProfileStrings.notAdded : value,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isPublic ? AppColors.mossChip : const Color(0xFFF1EFEA),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                isPublic
                    ? ProfileStrings.publicTag
                    : ProfileStrings.contactOnlyYou,
                style: AppText.sans(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: isPublic ? AppColors.moss600 : AppColors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
