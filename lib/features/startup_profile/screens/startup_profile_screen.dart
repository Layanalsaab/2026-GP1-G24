import '../../../shared_ui/widgets/cards/pin_city.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../shared_ui/widgets/lists/app_refresh.dart';

import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/bookmark_repository.dart';
import '../../../helpers/formatters.dart';
import '../../../models/startup.dart';
import '../../../models/match_summary.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/cards/match_justification.dart';
import '../../../shared_ui/widgets/headers/header_buttons.dart';
import '../../../shared_ui/widgets/headers/tabbed_header.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import '../../../helpers/share_link.dart';
import '../../profiles/widgets/profile_widgets.dart';
import '../../startups/widgets/view_only_banner.dart';
import '../view_models/startup_profile_view_model.dart';
import '../widgets/startup_profile_tabs.dart';

class StartupProfileScreen extends StatefulWidget {
  const StartupProfileScreen({
    super.key,
    required this.startup,
    this.preview = false,
    this.match,
  });

  final Startup startup;

  final MatchSummary? match;

  final bool preview;

  /// Opens the profile with the forward transition.
  static void open(
    BuildContext context, {
    required Startup startup,
    bool preview = false,
    MatchSummary? match,
  }) {
    AppNav.push(
      context,
      StartupProfileScreen(startup: startup, preview: preview, match: match),
      greenHeader: true,
    );
  }

  @override
  State<StartupProfileScreen> createState() => _StartupProfileScreenState();
}

class _StartupProfileScreenState extends State<StartupProfileScreen> {
  late final StartupProfileViewModel _vm = StartupProfileViewModel(
    startup: widget.startup,
    preview: widget.preview,
  );

  /// Pull down: the startup and its funding rounds are read again.
  Future<void> _refresh() async {
    try {
      final fresh = await StartupRepository.instance.fetchById(
        widget.startup.id,
      );
      if (fresh != null && mounted) _vm.replaceStartup(fresh);
    } catch (_) {
      // A startup that can't be read keeps what is shown.
    }
    if (!mounted) return;
    await _vm.loadRounds();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = BookmarkRepository.instance.keys;
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, bookmarks]),
      builder: (context, _) {
        final bookmarked = bookmarks.value.contains(_vm.key);
        final preview = _vm.isPreview;
        final s = _vm.startup;
        final header = TabbedHeader(
          title: s.name,
          avatar: HeaderAvatarTile(initials: s.initials, imageData: s.logoData),
          subline: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${s.sectorLabel} · ${s.stageLabel} · '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: PinCity.gap),
                    child: AppIcon.filled(
                      AppIcons.pin,
                      size: PinCity.pinSize,
                      color: AppText.onGreenMeta.color,
                    ),
                  ),
                ),
                TextSpan(text: s.location.label),
              ],
            ),
            semanticsLabel: _vm.infoLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.onGreenMeta,
          ),
          tabs: [
            for (final t in StartupProfileViewModel.tabLabels) HeaderTab(t),
          ],
          scrollableTabs: true,
          selectedIndex: _vm.tab,
          onTabChanged: _vm.selectTab,
          onBack: () => AppNav.back(context),
          closeIcon: preview,
          actions: [
            if (_vm.showBookmark)
              HeaderBookmarkButton(
                bookmarked: bookmarked,
                onTap: () => ProfileActions.toggleBookmark(context, _vm.key),
              ),
            if (_vm.showShare)
              GlassIconButton.share(
                onTap: () => ShareLink.shareStartup(
                  context,
                  id: _vm.startup.id,
                  name: _vm.startup.name,
                  sector: _vm.startup.sectorLabel,
                  city: _vm.startup.location.label,
                ),
              ),
          ],
        );
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              if (preview) _PreviewBar(_vm.previewText),
              Expanded(
                child: AppRefresh(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: AppRefresh.physics,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The preview bar already covers the status bar.
                        if (preview)
                          MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: header,
                          )
                        else
                          header,
                        // A closed startup says so above its tabs.
                        if (_vm.startup.isClosed)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: ViewOnlyBanner.notice(
                              title: FounderToolsStrings.closedBannerTitle,
                              // The day it was closed.
                              message: FounderToolsStrings.closedBannerPublic(
                                _vm.startup.closedAt == null
                                    ? null
                                    : Formatters.dayMonthYear(
                                        _vm.startup.closedAt!,
                                      ),
                              ),
                              icon: AppIcons.lock,
                            ),
                          ),
                        if (widget.match != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: MatchJustification(summary: widget.match!),
                          ),
                        TabPaneSlide(
                          index: _vm.tab,
                          child: StartupProfilePane(
                            viewModel: _vm,
                            onOpenInvestor: (i) =>
                                InvestorProfileScreen.open(context, i),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_vm.showCta)
                ProfileCtaBar(
                  label: _vm.ctaLabel,
                  icon: _vm.isGuest ? AppIcons.chat : AppIcons.send,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewBar extends StatelessWidget {
  const _PreviewBar(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.previewBar,
      padding: EdgeInsets.fromLTRB(
        16,
        10 + MediaQuery.paddingOf(context).top,
        12,
        10,
      ),
      child: Row(
        children: [
          AppIcon.filled(
            AppIcons.eye,
            size: 18,
            color: AppColors.previewBarText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppText.sans(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.previewBarText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
