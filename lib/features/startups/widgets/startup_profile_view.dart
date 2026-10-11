import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../models/startup.dart';
import '../../../models/startup_association.dart';
import '../../../models/startup_enums.dart';
import '../../../data_access/mock_data/mock_investors.dart';
import '../../../navigation/placeholder_features.dart';
import '../../../shared_ui/common_widgets/plain_top_bar.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import 'startup_logo.dart';
import 'startup_tag.dart';

/// Who is looking at a startup profile (Figma "V2 · 45 / 45b / 45c").
enum StartupProfileMode {
  /// The founder previewing their own startup: banner on top, no action.
  preview,

  /// A signed-in investor: "Send request".
  investor,

  /// A startup seeker without an account: "Express interest".
  guest,
}

/// One investment association; the profile lists only the approved, public
/// ones (the rest are filtered out here, so no caller can leak them).
typedef ProfileAssociation = StartupAssociation;

/// The page body shared by the three startup profile views. The founder
/// preview, investor view and guest view differ only in the banner, the top
/// bar buttons and the action button.
///
/// Sending a request, expressing interest, bookmarking and sharing are not
/// built yet; they are visual placeholders only (not tappable, no feedback).
/// An investment association opens that investor's profile.
class StartupProfileView extends StatelessWidget {
  const StartupProfileView({
    super.key,
    required this.startup,
    required this.mode,
    this.founderName,
    this.associations = const [],
    this.notices = const [],
  });

  final Startup startup;
  final StartupProfileMode mode;

  /// Shown as "Founded by ...". The row is hidden when this is unknown.
  final String? founderName;
  final List<ProfileAssociation> associations;

  /// Extra lines under the preview banner (private startup, unsaved changes).
  final List<String> notices;

  bool get _isPreview => mode == StartupProfileMode.preview;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final shownAssociations = StartupAssociation.publicOnly(associations);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (_isPreview ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            if (_isPreview) _PreviewBanner(notices: notices),
            PlainTopBar(
              color: AppColors.moss100,
              safeTop: !_isPreview,
              leading: _isPreview
                  ? PlainTopBarIcon(
                      asset: 'st_close.svg',
                      tooltip: StartupStrings.close,
                      iconSize: 22,
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : PlainTopBarIcon.back(context, iconSize: 22),
              trailing: [
                // Guests (startup seekers) have no bookmarks, and the founder's
                // own preview has nothing to save.
                if (mode == StartupProfileMode.investor)
                  const _InertTopIcon(
                    asset: 'st_bookmark.svg',
                    feature: PlaceholderFeature.bookmarks,
                  ),
                const _InertTopIcon(
                  asset: 'st_share.svg',
                  feature: PlaceholderFeature.shareStartup,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 24 + bottom),
                children: [
                  _Hero(startup: startup, founderName: founderName),
                  if (!_isPreview) _ActionButton(mode: mode),
                  const _Rule(),
                  _Section(
                    title: StartupStrings.aboutTitle,
                    child: Text(
                      startup.description,
                      style: AppText.sans(
                        size: 15,
                        color: AppColors.ink,
                        height: 22,
                      ),
                    ),
                  ),
                  const _Rule(),
                  _LookingForSection(startup: startup),
                  const _Rule(),
                  _Section(
                    title: StartupStrings.detailsTitle,
                    child: _Details(startup: startup),
                  ),
                  if (shownAssociations.isNotEmpty) ...[
                    const _Rule(),
                    _Section(
                      title: StartupStrings.associationsTitle,
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < shownAssociations.length;
                            i++
                          ) ...[
                            if (i > 0) const SizedBox(height: AppSpacing.sm),
                            _AssociationRow(item: shownAssociations[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A top bar icon of a feature that isn't built yet: same look as a button,
/// but inert.
class _InertTopIcon extends StatelessWidget {
  const _InertTopIcon({required this.asset, required this.feature});

  final String asset;
  final PlaceholderFeature feature;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: feature.label,
      excludeSemantics: true,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(child: svgIcon(asset, size: 22)),
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.notices});

  final List<String> notices;

  @override
  Widget build(BuildContext context) {
    final text = AppText.sans(
      size: 13,
      color: AppColors.onDark,
      weight: FontWeight.w500,
    );
    return Container(
      width: double.infinity,
      color: AppColors.green,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 10,
        16,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              svgIcon('st_eye_gold.svg', size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(StartupStrings.previewBanner, style: text)),
            ],
          ),
          for (final notice in notices) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                notice,
                style: text.copyWith(
                  color: AppColors.onDarkMuted,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.startup, required this.founderName});

  final Startup startup;
  final String? founderName;

  Future<void> _openWebsite(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text(StartupStrings.websiteOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final website = startup.websiteUrl;
    final founder = founderName?.trim();
    // Figma "Hero": moss-100 fading to cream, with three faint gold rings.
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.moss100, AppColors.cream],
        ),
      ),
      child: ClipRect(
        child: CustomPaint(
          painter: const _RingsPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            child: Column(
              children: [
                StartupLogo(
                  initials: startup.initials,
                  url: startup.logoUrl,
                  size: 88,
                  cornerFactor: 0.27,
                  background: AppColors.tagGoldFill,
                  foreground: AppColors.tagGoldText,
                  fontSize: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  startup.name,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 24,
                    color: AppColors.ink,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StartupTag(startup.sectorLabel, pill: true),
                    StartupTag(startup.stageLabel, pill: true),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        svgIcon('st_pin.svg', size: 15),
                        const SizedBox(width: 3),
                        Text(
                          startup.location.label,
                          style: AppText.sans(size: 14, color: AppColors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                if (website != null) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _openWebsite(context, website),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        svgIcon('st_link.svg', size: 15),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            Formatters.shortUrl(website),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(
                              size: 14,
                              color: AppColors.moss600,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (founder != null && founder.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.moss100,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            Startup.initialsOf(founder),
                            style: AppText.sans(
                              size: 8,
                              color: AppColors.moss600,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${StartupStrings.foundedBy} ',
                                  style: AppText.sans(
                                    size: 13,
                                    color: AppColors.grey,
                                  ),
                                ),
                                TextSpan(
                                  text: founder,
                                  style: AppText.sans(
                                    size: 13,
                                    color: AppColors.ink,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three concentric rings behind the logo (Figma "Ring", 290 / 220 / 150 px,
/// centred 48 px below the top of the hero).
class _RingsPainter extends CustomPainter {
  const _RingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, 48);
    for (final radius in const [145.0, 110.0, 75.0]) {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => false;
}

/// "Send request" (investor) or "Express interest" (guest).
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.mode});

  final StartupProfileMode mode;

  @override
  Widget build(BuildContext context) {
    final investor = mode == StartupProfileMode.investor;
    final shape = BorderRadius.circular(AppRadius.md);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      // Placeholder: requests and expressions of interest aren't built, so
      // the button is inert (no tap, ripple or feedback).
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.moss600,
          borderRadius: shape,
        ),
        child: Semantics(
          child: SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                svgIcon('st_send.svg', size: 18),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    investor
                        ? StartupStrings.sendRequest
                        : StartupStrings.expressInterest,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.button,
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

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.border);
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Figma: a small gold accent bar before each section title.
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  title,
                  style: AppText.sans(
                    size: 16,
                    color: AppColors.ink,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LookingForSection extends StatelessWidget {
  const _LookingForSection({required this.startup});

  final Startup startup;

  @override
  Widget build(BuildContext context) {
    final funding = startup.fundingRequirement;
    return _Section(
      title: StartupStrings.lookingForTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in LookingFor.values)
                if (startup.lookingFor.contains(item))
                  StartupTag(
                    startup.lookingForLabelOf(item),
                    gold: true,
                    pill: true,
                  ),
            ],
          ),
          if (startup.seeksFunding && funding != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 6,
              children: [
                Text(
                  Formatters.sar(funding),
                  style: AppText.sans(
                    size: 20,
                    color: AppColors.ink,
                    weight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    StartupStrings.raisingThisRound,
                    style: AppText.sans(size: 13, color: AppColors.grey),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.startup});

  final Startup startup;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Fact(
              label: StartupStrings.businessModelLabel,
              value: startup.businessModelLabel,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Fact(
              label: StartupStrings.foundedYearLabel,
              value:
                  startup.foundedYear?.toString() ?? StartupStrings.notProvided,
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(size: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(
              size: 15,
              color: AppColors.ink,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssociationRow extends StatelessWidget {
  const _AssociationRow({required this.item});

  final StartupAssociation item;

  @override
  Widget build(BuildContext context) {
    // Opens the investor's profile. An investor missing from the sample data
    // has no profile to open, so that row is plain (no chevron, no ripple).
    final investor = MockInvestors.byName(item.name);
    final shape = BorderRadius.circular(AppRadius.md);
    return Semantics(
      button: investor != null,
      child: InkWell(
        borderRadius: shape,
        onTap: investor == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvestorProfileScreen(investor: investor),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.moss100,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  Startup.initialsOf(item.name),
                  style: AppText.sans(
                    size: 14,
                    color: AppColors.moss600,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 15,
                        color: AppColors.ink,
                        weight: FontWeight.w600,
                      ),
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          svgIcon('st_pin.svg', size: 13),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sans(
                                size: 13,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (investor != null) ...[
                const SizedBox(width: AppSpacing.sm),
                svgIcon('st_chev18.svg', size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
