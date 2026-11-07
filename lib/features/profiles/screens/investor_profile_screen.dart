import '../../../data_access/repositories/discovery_repository.dart';
import '../../../shared_ui/widgets/lists/app_refresh.dart';
import '../../../helpers/open_link.dart';

import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/bookmark_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../models/investor_profile.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/widgets/headers/profile_banner.dart';
import '../view_models/investor_profile_view_model.dart';
import '../widgets/investor_profile_body.dart';
import '../widgets/profile_widgets.dart';

/// Investor profile (docs/05 C2, screenshots 31 and 27e): banner with
/// bookmark (not guests) and share, the head block, then the shared
/// [InvestorProfileBody] (ticket, About, offer, background, interests,
/// associations). The
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

  /// Pull down: the directory is read again and this profile follows it.
  Future<void> _refresh() async {
    final discovery = DiscoveryRepository.instance;
    await discovery.refresh();
    final fresh = discovery.investorById(widget.investor.id);
    if (fresh != null && mounted) _vm.replaceInvestor(fresh);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = _vm.investor;
    final bookmarks = BookmarkRepository.instance.keys;
    final requests = RequestRepository.instance.outgoing;
    return ListenableBuilder(
      listenable: Listenable.merge([bookmarks, requests]),
      builder: (context, _) {
        final sent = requests.value.contains(_vm.key);
        return Scaffold(
          backgroundColor: AppColors.profileBg,
          body: Column(
            children: [
              Expanded(
                child: AppRefresh(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: AppRefresh.physics,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProfileBanner.glass(
                          onBack: () => AppNav.back(context),
                          onShare: () => ProfileActions.share(
                            context,
                            _vm.key,
                            title: _vm.investor.name,
                          ),
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
                          // The sectors are listed under Interests below: no
                          // second "Invests in" line under the name.
                          tagsLabel: '',
                          tags: const [],
                          photoUrl: inv.photoUrl,
                          linkedin: _vm.linkedin,
                          onLinkedin: () => openExternalLink(_vm.linkedin),
                        ),
                        InvestorProfileBody(
                          data: InvestorProfileData.fromInvestor(inv),
                          associations: _vm.associations,
                          contact: InvestorContactData(
                            email: inv.email ?? '',
                            emailPublic: inv.emailPublic,
                            phone: (inv.phone ?? '').isEmpty
                                ? ''
                                : AccountStrings.formatPhone(inv.phone!),
                            phonePublic: inv.phonePublic,
                            ownerView: false,
                          ),
                        ),
                      ],
                    ),
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
