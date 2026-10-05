import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/explore_strings.dart';
import '../../../app_constants/seeker_strings.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/investor_card.dart';
import '../../../shared_ui/common_widgets/listing_card_parts.dart';
import '../../../shared_ui/common_widgets/search_filter_widgets.dart';
import '../../../shared_ui/common_widgets/startup_card.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import '../../explore_startups/screens/seeker_startup_profile_screen.dart';
import '../../startups/screens/startup_profile_screen.dart';
import '../view_models/hub_view_model.dart';

/// Figma "V2 · 12 / 12b · Hub": search, filters and a list to browse.
///
/// Design phase: the search box and filters are for show, the list is sample
/// data, and only the first card opens a profile.
class HubScreen extends StatefulWidget {
  const HubScreen({super.key, required this.role, this.isSeeker = false});

  final AccountRole role;

  /// A startup seeker's Hub (Figma "V2 · 12c"): the same list of startups,
  /// with "Express Interest" instead of "Send Request", opening the seeker's
  /// startup profile.
  final bool isSeeker;

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  late final HubViewModel _viewModel = HubViewModel(role: widget.role);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => Column(
            children: [
              GreenTopBar(
                title: ExploreStrings.hubTitle,
                titleStyle: AppText.serif(
                  size: 22,
                  color: AppColors.onDark,
                  height: 28,
                ),
                // Design only: notifications aren't built yet.
                actions: [svgIcon('bell.svg', size: 44)],
              ),
              // The search row overlaps the bottom of the green bar, as in Figma.
              Stack(
                children: [
                  Container(height: 8, color: AppColors.green),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: SearchBox(hint: ExploreStrings.searchHint)),
                        SizedBox(width: 8),
                        FilterButton(size: 48, radius: 12, iconSize: 20),
                      ],
                    ),
                  ),
                ],
              ),
              FilterChipsRow(
                labels: ExploreStrings.filters,
                selected: _viewModel.filterIndex,
                onSelect: _viewModel.selectFilter,
              ),
              Expanded(child: _list()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list() {
    final investors = _viewModel.investors;
    final startups = _viewModel.startups;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        for (var i = 0; i < investors.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          InvestorCard(
            investor: investors[i],
            style: ListingStyle.hub,
            onViewProfile: i == 0
                ? () => _open(InvestorProfileScreen(investor: investors[i]))
                : null,
          ),
        ],
        for (var i = 0; i < startups.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          StartupCard(
            listing: startups[i],
            style: ListingStyle.hub,
            actionLabel: widget.isSeeker
                ? SeekerStrings.expressInterest
                : ExploreStrings.sendRequest,
            onViewProfile: i == 0
                ? () => _open(
                      widget.isSeeker
                          ? SeekerStartupProfileScreen(listing: startups[i])
                          : StartupProfileScreen(startup: startups[i].startup),
                    )
                : null,
          ),
        ],
      ],
    );
  }
}
