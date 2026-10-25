import 'package:flutter/material.dart';

import '../../../data_access/repositories/bookmark_repository.dart';
import '../../../data_access/repositories/interest_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/headers/header_buttons.dart';
import '../../../shared_ui/widgets/headers/tabbed_header.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import '../../profiles/widgets/profile_widgets.dart';
import '../view_models/startup_profile_view_model.dart';
import '../widgets/startup_profile_tabs.dart';

/// The startup page (docs/05 C1): the Manage-style green header (back, bookmark
/// and share, logo tile, name, one sub-line) with four equal tabs (Overview,
/// Business, Team, Funding), the pinned request / interest bar for investors
/// and guests, and the preview mode ("Preview · ..." bar, close icon).
class StartupProfileScreen extends StatefulWidget {
  const StartupProfileScreen({
    super.key,
    required this.startup,
    this.preview = false,
  });

  final Startup startup;

  /// The founder's own view ("Preview · This is how others see your
  /// startup"). Also turned on automatically for a founder's own startup.
  final bool preview;

  /// Opens the profile with the forward transition.
  static void open(
    BuildContext context, {
    required Startup startup,
    bool preview = false,
  }) {
    AppNav.push(
      context,
      StartupProfileScreen(startup: startup, preview: preview),
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

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = BookmarkRepository.instance.keys;
    final requests = RequestRepository.instance.outgoing;
    final interests = InterestRepository.instance.sent;
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, bookmarks, requests, interests]),
      builder: (context, _) {
        final bookmarked = bookmarks.value.contains(_vm.key);
        _vm.ctaDone = _vm.isGuest
            ? interests.value.contains(_vm.key)
            : requests.value.contains(_vm.key);
        final preview = _vm.isPreview;
        final s = widget.startup;
        // Same header style as Manage: back (or close in preview), the logo
        // tile, the name, ONE sub-line, and four equal tabs. No description
        // and no stat strip here: they live in the Overview tab.
        final header = TabbedHeader(
          title: s.name,
          avatar: HeaderAvatarTile(initials: s.initials),
          subline: Text(
            _vm.infoLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.onGreenMeta,
          ),
          tabs: [
            for (final t in StartupProfileViewModel.tabLabels) HeaderTab(t),
          ],
          equalTabs: true,
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
                onTap: () => ProfileActions.share(context, _vm.key),
              ),
          ],
        );
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              if (preview) _PreviewBar(_vm.previewText),
              Expanded(
                child: SingleChildScrollView(
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
              if (_vm.showCta)
                ProfileCtaBar(
                  label: _vm.ctaLabel,
                  icon: _vm.isGuest ? AppIcons.chat : AppIcons.send,
                  done: _vm.ctaDone,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The gold "Preview" bar above the header (prototype `.pvbar`): eye icon and
/// the preview sentence, 13/600 green on `#F7EDD5`.
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
          const AppIcon.filled(AppIcons.eye, size: 18, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppText.sans(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
