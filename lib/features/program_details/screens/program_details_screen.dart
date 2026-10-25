import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../helpers/open_link.dart';
import '../../../data_access/repositories/bookmark_repository.dart';
import '../../../models/program.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_metrics.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/cards/pills.dart';
import '../../../shared_ui/widgets/headers/header_buttons.dart';
import '../../profiles/widgets/profile_widgets.dart';
import '../view_models/program_details_view_model.dart';

/// Program details (docs/05 C3, screenshots 32 and 27f): a light radial hero
/// with three gold circles that draw themselves, the gold tile, name, pills,
/// website link and "Visit website", then About, Focus sectors and Details
/// separated by hairlines.
class ProgramDetailsScreen extends StatefulWidget {
  const ProgramDetailsScreen({super.key, required this.program});

  final Program program;

  /// Opens the page with the forward transition.
  static void open(BuildContext context, Program program) {
    AppNav.push(context, ProgramDetailsScreen(program: program));
  }

  @override
  State<ProgramDetailsScreen> createState() => _ProgramDetailsScreenState();
}

class _ProgramDetailsScreenState extends State<ProgramDetailsScreen> {
  late final ProgramDetailsViewModel _vm = ProgramDetailsViewModel(
    program: widget.program,
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _openWebsite() => openExternalLink(_vm.website);

  /// A circle as an SVG path (the prototype's `<circle>`).
  static String _circle(double cx, double cy, double r) =>
      'M${cx + r} $cy a$r $r 0 1 0 ${-2 * r} 0 a$r $r 0 1 0 ${2 * r} 0';

  @override
  Widget build(BuildContext context) {
    final p = widget.program;
    final inset = MediaQuery.paddingOf(context).top;
    final bookmarks = BookmarkRepository.instance.keys;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRect(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [
                      AppColors.moss100,
                      AppColors.moss50,
                      AppColors.cream,
                    ],
                    stops: [0, 0.55, 1],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(16, inset, 16, 20),
                child: Stack(
                  children: [
                    Positioned(
                      left: -16,
                      right: -16,
                      top: -40,
                      height: 317,
                      child: ExcludeSemantics(
                        child: Stack(
                          children: [
                            for (final (i, r, a) in const [
                              (0, 70.0, 0.35),
                              (1, 110.0, 0.22),
                              (2, 150.0, 0.14),
                            ])
                              DrawPath(
                                pathData: _circle(195, 140, r),
                                color: AppColors.gold.withValues(alpha: a),
                                viewBox: const Size(390, 300),
                                delay: Duration(milliseconds: 120 * i),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Transform.translate(
                                offset: const Offset(-6, 0),
                                child: AppIconButton(
                                  icon: AppIcons.arrowBack,
                                  semanticLabel: 'Back',
                                  onTap: () => AppNav.back(context),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(6, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_vm.showBookmark)
                                      ValueListenableBuilder<Set<String>>(
                                        valueListenable: bookmarks,
                                        builder: (context, keys, _) =>
                                            HeaderBookmarkButton(
                                              glass: false,
                                              color: AppColors.ink,
                                              bookmarked: keys.contains(
                                                _vm.key,
                                              ),
                                              onTap: () =>
                                                  ProfileActions.toggleBookmark(
                                                    context,
                                                    _vm.key,
                                                  ),
                                            ),
                                      ),
                                    AppIconButton(
                                      icon: AppIcons.share,
                                      iconSize: 22,
                                      semanticLabel: 'Share',
                                      onTap: () => ProfileActions.share(
                                        context,
                                        _vm.key,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Rise(
                          child: Column(
                            children: [
                              TileAvatar(
                                initials: p.initial,
                                tone: TileTone.gold,
                                size: 88,
                                radius: 26,
                                fontSize: 30,
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x668A6A1F),
                                    blurRadius: 28,
                                    spreadRadius: -12,
                                    offset: Offset(0, 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Semantics(
                                header: true,
                                child: Text(
                                  p.name,
                                  textAlign: TextAlign.center,
                                  style: AppText.sans(
                                    size: 26,
                                    height: 32,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  AppPill(label: p.type.label),
                                  AppPill(label: p.duration),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const AppIcon.filled(
                                        AppIcons.pin,
                                        size: 15,
                                        color: AppColors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        p.city,
                                        style: AppText.sans(
                                          size: 14,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (_vm.hasWebsite)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Semantics(
                                    button: true,
                                    label: _vm.website,
                                    excludeSemantics: true,
                                    child: Pressable(
                                      onTap: _openWebsite,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const AppIcon.filled(
                                            AppIcons.link,
                                            size: 18,
                                            color: AppColors.moss600,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _vm.website,
                                              style: AppText.sans(
                                                size: 15,
                                                weight: FontWeight.w600,
                                                color: AppColors.moss600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_vm.hasWebsite)
                          Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: AppButton(
                              label: ProfileStrings.visitWebsite,
                              icon: AppIcons.globe,
                              size: AppButtonSize.cta,
                              onPressed: _openWebsite,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_vm.about.isNotEmpty)
                    _Section(
                      title: ProfileStrings.about,
                      child: Text(
                        _vm.about,
                        style: AppText.sans(size: 15, height: 23),
                      ),
                    ),
                  if (p.focusSectors.isNotEmpty)
                    _Section(
                      title: ProfileStrings.focusSectors,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in p.focusSectors)
                            AppPill(label: s, tone: AppPillTone.gold),
                        ],
                      ),
                    ),
                  _Section(
                    title: ProfileStrings.details,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DetailCard(
                            label: ProfileStrings.duration,
                            value: p.duration,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DetailCard(
                            label: ProfileStrings.runningSince,
                            value: '${p.sinceYear}',
                          ),
                        ),
                      ],
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

/// A section with the gold 3 x 18 bar before its title and a hairline below.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.dividerSoft)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppText.sans(size: 18, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.cardBorder),
      boxShadow: AppShadow.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.sans(size: 12, color: AppColors.grey)),
        const SizedBox(height: 2),
        Text(value, style: AppText.sans(size: 16, weight: FontWeight.w700)),
      ],
    ),
  );
}
