import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../widgets/startup_logo.dart';

/// The public view of a startup: what investors and startup seekers see.
///
/// Founders reach it from Edit ("Preview as public"); [isPreview] then adds
/// a banner explaining it's a preview (and whether the startup is private or
/// has unsaved changes). Later, the Startup Hub can open it with
/// `isPreview: false`.
class StartupProfileScreen extends StatelessWidget {
  const StartupProfileScreen({
    super.key,
    required this.startup,
    this.isPreview = false,
    this.hasUnsavedChanges = false,
  });

  final Startup startup;
  final bool isPreview;
  final bool hasUnsavedChanges;

  static Future<void> openPreview(
    BuildContext context,
    Startup startup, {
    bool hasUnsavedChanges = false,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StartupProfileScreen(
        startup: startup,
        isPreview: true,
        hasUnsavedChanges: hasUnsavedChanges,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final website = startup.websiteUrl;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: ListView(
          padding: EdgeInsets.only(
            bottom: AppSpacing.xxxl + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _Hero(startup: startup, isPreview: isPreview),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isPreview) ..._banners(),
                  if (startup.seeksFunding &&
                      startup.fundingRequirement != null) ...[
                    _FundingCard(amount: startup.fundingRequirement!),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _InfoCard(
                    title: StartupStrings.aboutTitle,
                    icon: Icons.notes_rounded,
                    child: Text(startup.description, style: AppText.body),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _InfoCard(
                    title: StartupStrings.detailsTitle,
                    icon: Icons.info_outline_rounded,
                    child: _DetailsGrid(startup: startup),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _InfoCard(
                    title: StartupStrings.lookingForTitle,
                    icon: Icons.track_changes_rounded,
                    child: _LookingForChips(items: startup.lookingFor),
                  ),
                  if (website != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _WebsiteButton(url: website),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _banners() => [
    const _Banner(
      icon: Icons.visibility_outlined,
      text: StartupStrings.previewBanner,
    ),
    if (!startup.isPublic)
      const _Banner(
        icon: Icons.lock_outline_rounded,
        text: StartupStrings.previewPrivateBanner,
      ),
    if (hasUnsavedChanges)
      const _Banner(
        icon: Icons.edit_note_rounded,
        text: StartupStrings.previewUnsavedBanner,
      ),
    const SizedBox(height: AppSpacing.xs),
  ];
}

/// Green header with decorative gold rings, the logo, name, tagline and the
/// key facts as pills.
class _Hero extends StatelessWidget {
  const _Hero({required this.startup, required this.isPreview});

  final Startup startup;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final tagline = startup.tagline;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl + AppSpacing.sm),
        ),
      ),
      child: Stack(
        children: [
          const Positioned(right: -60, top: -40, child: _Ring(size: 220)),
          const Positioned(left: -50, bottom: -70, child: _Ring(size: 160)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreenTopBar(
                title: isPreview ? StartupStrings.previewAsPublic : '',
                leading: const TopBarBackButton(),
                color: Colors.transparent,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StartupLogo(
                      initial: startup.initial,
                      url: startup.logoUrl,
                      size: AppSizes.profileLogo,
                      ring: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(startup.name, style: AppText.display),
                    if (tagline != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        tagline,
                        style: AppText.body.copyWith(
                          color: AppColors.onDarkMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _HeroPill(
                          icon: Icons.category_outlined,
                          label: startup.sector.label,
                        ),
                        _HeroPill(
                          icon: Icons.trending_up_rounded,
                          label: startup.stage.label,
                        ),
                        _HeroPill(
                          icon: Icons.place_outlined,
                          label: startup.location.label,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.onDark.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.gold),
          const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
          Text(label, style: AppText.badge.copyWith(color: AppColors.onDark)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold100,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.icon - 2, color: AppColors.gold700),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xxs),
          Expanded(
            child: Text(
              text,
              style: AppText.bodyMuted.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _FundingCard extends StatelessWidget {
  const _FundingCard({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold100, AppColors.surface],
        ),
        border: Border.all(color: AppColors.gold),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.touchTarget,
            height: AppSizes.touchTarget,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.onDark,
              size: AppSizes.icon,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StartupStrings.fundingTitle,
                  style: AppText.caption.copyWith(color: AppColors.gold700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(Formatters.sar(amount), style: AppText.figure),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.icon - 2, color: AppColors.gold700),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppText.sectionTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Two-column grid of facts.
class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.startup});

  final Startup startup;

  @override
  Widget build(BuildContext context) {
    final facts = [
      (
        Icons.category_outlined,
        StartupStrings.sectorLabel,
        startup.sector.label,
      ),
      (
        Icons.trending_up_rounded,
        StartupStrings.stageLabel,
        startup.stage.label,
      ),
      (
        Icons.hub_outlined,
        StartupStrings.businessModelLabel,
        startup.businessModel.label,
      ),
      (
        Icons.place_outlined,
        StartupStrings.locationLabel,
        startup.location.label,
      ),
      (
        Icons.event_outlined,
        StartupStrings.foundedYearLabel,
        startup.foundedYear?.toString() ?? StartupStrings.notProvided,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final (icon, label, value) in facts)
              SizedBox(
                width: tileWidth,
                child: _Fact(icon: icon, label: label, value: value),
              ),
          ],
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.moss50,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSm + 2, color: AppColors.moss600),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppText.caption),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppText.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LookingForChips extends StatelessWidget {
  const _LookingForChips({required this.items});

  final Set<LookingFor> items;

  static IconData _iconFor(LookingFor item) => switch (item) {
    LookingFor.funding => Icons.payments_outlined,
    LookingFor.partnerships => Icons.handshake_outlined,
    LookingFor.teamMembers => Icons.group_add_outlined,
    LookingFor.mentorship => Icons.lightbulb_outline_rounded,
    LookingFor.services => Icons.design_services_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in LookingFor.values)
          if (items.contains(item))
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.moss100,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconFor(item),
                    size: AppSizes.iconSm + 2,
                    color: AppColors.moss600,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    item.label,
                    style: AppText.label.copyWith(color: AppColors.green),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _WebsiteButton extends StatelessWidget {
  const _WebsiteButton({required this.url});

  final String url;

  Future<void> _open(BuildContext context) async {
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
    final shape = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: AppColors.surface,
      borderRadius: shape,
      child: InkWell(
        borderRadius: shape,
        onTap: () => _open(context),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.language_rounded, color: AppColors.moss600),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(StartupStrings.visitWebsite, style: AppText.label),
                    Text(
                      Formatters.shortUrl(url),
                      style: AppText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.moss600,
                size: AppSizes.icon - 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
