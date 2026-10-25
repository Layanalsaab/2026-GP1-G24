import '../../../helpers/open_link.dart';

import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/bookmark_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../models/investor_profile.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/cards/profile_blocks.dart';
import '../../../shared_ui/widgets/headers/profile_banner.dart';
import '../../startup_profile/screens/startup_profile_screen.dart';
import '../view_models/investor_profile_view_model.dart';
import '../widgets/profile_widgets.dart';

/// Investor profile (docs/05 C2, screenshots 31 and 27e): banner with
/// bookmark (not guests) and share, the head block, then About, what they can
/// bring, what they hope to gain, investment focus and associations. The
/// "Send investment request" bar is for founders only.
class InvestorProfileScreen extends StatefulWidget {
  const InvestorProfileScreen({super.key, required this.investor});

  final InvestorProfile investor;

  /// Opens the profile with the forward transition.
  static void open(BuildContext context, InvestorProfile investor) {
    AppNav.push(
      context,
      InvestorProfileScreen(investor: investor),
      greenHeader: true,
    );
  }

  @override
  State<InvestorProfileScreen> createState() => _InvestorProfileScreenState();
}

class _InvestorProfileScreenState extends State<InvestorProfileScreen> {
  late final InvestorProfileViewModel _vm = InvestorProfileViewModel(
    investor: widget.investor,
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.investor;
    final bookmarks = BookmarkRepository.instance.keys;
    final requests = RequestRepository.instance.outgoing;
    return ListenableBuilder(
      listenable: Listenable.merge([bookmarks, requests]),
      builder: (context, _) {
        final sent = requests.value.contains(_vm.key);
        var n = 0;
        Duration stagger() => Duration(milliseconds: 60 * n++);
        return Scaffold(
          backgroundColor: AppColors.profileBg,
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileBanner.glass(
                        onBack: () => AppNav.back(context),
                        onShare: () => ProfileActions.share(context, _vm.key),
                        showBookmark: _vm.showBookmark,
                        bookmarked: bookmarks.value.contains(_vm.key),
                        onBookmark: () =>
                            ProfileActions.toggleBookmark(context, _vm.key),
                      ),
                      ProfileHead(
                        initials: inv.initials,
                        name: inv.name,
                        role: inv.title,
                        city: inv.city,
                        metaTail: _vm.associationCount,
                        tagsLabel: ProfileStrings.investsIn,
                        tags: inv.sectors,
                        linkedin: _vm.linkedin,
                        onLinkedin: () => openExternalLink(_vm.linkedin),
                      ),
                      ProfileSections(
                        children: [
                          if (_vm.about.isNotEmpty)
                            ProfileSection(
                              title: ProfileStrings.about,
                              delay: stagger(),
                              child: ProfileText(_vm.about),
                            ),
                          if (_vm.bring.isNotEmpty)
                            ProfileSection(
                              title: ProfileStrings.canBring,
                              delay: stagger(),
                              child: ProfileText(_vm.bring),
                            ),
                          if (_vm.gain.isNotEmpty)
                            ProfileSection(
                              title: ProfileStrings.hopeToGain,
                              delay: stagger(),
                              child: ProfileText(_vm.gain),
                            ),
                          ProfileSection(
                            title: ProfileStrings.investmentFocus,
                            delay: stagger(),
                            child: Column(
                              children: [
                                InfoRow(
                                  label: ProfileStrings.stages,
                                  value: inv.stageRange,
                                ),
                                InfoRow(
                                  label: ProfileStrings.ticketSize,
                                  value: inv.ticketRange,
                                  showDivider: true,
                                ),
                              ],
                            ),
                          ),
                          if (_vm.associations.isNotEmpty)
                            ProfileSection(
                              title: ProfileStrings.associations,
                              delay: stagger(),
                              child: Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < _vm.associations.length;
                                    i++
                                  )
                                    ListRow(
                                      showDivider: i > 0,
                                      leading: HueAvatar(
                                        name: _vm.associations[i].name,
                                        size: 44,
                                      ),
                                      title: _vm.associations[i].name,
                                      subtitle:
                                          '${_vm.associations[i].sectorLabel} · ${_vm.associations[i].location.label}',
                                      onTap: () => StartupProfileScreen.open(
                                        context,
                                        startup: _vm.associations[i],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_vm.showCta)
                ProfileCtaBar(
                  label: sent
                      ? ProfileStrings.requestSent
                      : ProfileStrings.sendRequest,
                  icon: AppIcons.send,
                  done: sent,
                ),
            ],
          ),
        );
      },
    );
  }
}
