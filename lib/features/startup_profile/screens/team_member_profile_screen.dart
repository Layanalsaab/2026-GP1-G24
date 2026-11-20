import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/public_profile_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/open_link.dart';
import '../../../models/list_entries.dart';
import '../../../models/public_profile.dart';
import '../../../models/home_item.dart';
import '../../../models/team_member.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/cards/home_card.dart';
import '../../../shared_ui/widgets/cards/profile_blocks.dart';
import '../../../shared_ui/widgets/headers/profile_banner.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../../profiles/widgets/contact_section.dart';
import '../../profiles/widgets/investor_profile_body.dart'
    show ProfileValueRows;
import '../../profiles/widgets/profile_widgets.dart';
import '../../startups/widgets/role_tag.dart';
import 'startup_profile_screen.dart';

/// A person's full profile, opened by tapping them on a startup's Team tab.
class TeamMemberProfileScreen extends StatefulWidget {
  const TeamMemberProfileScreen({
    super.key,
    required this.member,
    this.startupName = '',
    this.startupId,
    this.repository,
  });

  final TeamMember member;
  final String startupName;

  final String? startupId;

  /// Tests pass a fake.
  final PublicProfileRepository? repository;

  static void open(
    BuildContext context,
    TeamMember member, {
    String startupName = '',
    String? startupId,
  }) => AppNav.push(
    context,
    TeamMemberProfileScreen(
      member: member,
      startupName: startupName,
      startupId: startupId,
    ),
    greenHeader: true,
  );

  @override
  State<TeamMemberProfileScreen> createState() =>
      _TeamMemberProfileScreenState();
}

class _TeamMemberProfileScreenState extends State<TeamMemberProfileScreen> {
  PublicProfile? _profile;
  List<ProfileStartupRef> _startups = const [];
  bool _loading = true;

  PublicProfileRepository get _repo =>
      widget.repository ?? PublicProfileRepository.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = widget.member.uid;
    PublicProfile? profile;
    var startups = <ProfileStartupRef>[];
    if (uid != null) {
      profile = await _repo.get(uid);
      if (profile != null) {
        startups = await _repo.startupsOf(profile, alsoCheck: widget.startupId);
      }
    }
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _startups = startups;
      _loading = false;
    });
  }

  Future<void> _openStartup(ProfileStartupRef ref) async {
    try {
      final startup =
          ref.startup ?? await StartupRepository.instance.fetchById(ref.id);
      if (!mounted) return;
      if (startup == null) {
        AppToast.error(context, 'This startup is no longer available.');
        return;
      }
      StartupProfileScreen.open(
        context,
        startup: startup,
        preview: AppSession.instance.ownStartupIds.contains(startup.id),
      );
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'We couldn’t open this startup.');
      }
    }
  }

  String get _roleLine {
    for (final r in _startups) {
      if (r.id == widget.startupId) return RoleTag.labelOf(_roleOf(r.role));
    }
    return RoleTag.labelOf(
      widget.member.isFounder
          ? StartupRole.founder
          : widget.member.coFounder
          ? StartupRole.coFounder
          : StartupRole.member,
    );
  }

  static StartupRole _roleOf(String role) => switch (role) {
    'founder' => StartupRole.founder,
    'coFounder' => StartupRole.coFounder,
    _ => StartupRole.member,
  };

  Widget _startupCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Semantics(
            header: true,
            child: Text('Startups', style: AppText.sectionTitle),
          ),
        ),
        for (var i = 0; i < _startups.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
            child: _startupCard(_startups[i]),
          ),
      ],
    );
  }

  Widget _startupCard(ProfileStartupRef ref) {
    final role = _roleOf(ref.role);
    final st = ref.startup;
    final item = st == null ? null : HomeItem.fromStartup(st);
    return HomeCard(
      name: ref.name,
      tag: item?.tag ?? '',
      city: item?.city ?? '',
      body: item?.line ?? '',
      bodyMaxLines: 2,
      animate: false,
      badges: [
        RoleTag(role),
        if (st != null && st.isClosed)
          const GreyTag(FounderToolsStrings.closedPill),
      ],
      imageData: item?.imageData,
      onTap: () => _openStartup(ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final m = widget.member;
    final about = (p?.bio ?? '').trim().isNotEmpty
        ? p!.bio.trim()
        : m.contribution.trim();
    return Scaffold(
      backgroundColor: AppColors.profileBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileBanner(onBack: () => AppNav.back(context)),
            ProfileHead(
              initials: p?.initials ?? m.initials,
              name: p?.fullName ?? m.name,
              role: _roleLine,
              city: p?.city,
              metaTail: widget.startupName,
              tagsLabel: ProfileStrings.interestedIn,
              // The sectors are listed under Interests below.
              tags: const [],
              photoData: p?.photoData,
              linkedin: p?.linkedin,
              onLinkedin: () => openExternalLink(p?.linkedin ?? ''),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ProfileSections(
                children: [
                  if (about.isNotEmpty)
                    ProfileSection(
                      title: ProfileStrings.bio,
                      child: ProfileText(about),
                    ),
                  ProfileSection(
                    title: ProfileStrings.contact,
                    child: Column(
                      children: [
                        p?.email != null
                            ? PublicContactRow(
                                icon: AppIcons.mail,
                                label: ProfileStrings.email,
                                value: p!.email!,
                              )
                            : const PrivateContactRow(
                                icon: AppIcons.mail,
                                label: ProfileStrings.email,
                              ),
                        p?.phone != null
                            ? PublicContactRow(
                                icon: AppIcons.phone,
                                label: ProfileStrings.phone,
                                value: '+966 ${p!.phone}',
                                showDivider: true,
                              )
                            : const PrivateContactRow(
                                icon: AppIcons.phone,
                                label: ProfileStrings.phone,
                                showDivider: true,
                              ),
                      ],
                    ),
                  ),
                  if ((p?.sectors ?? const []).isNotEmpty)
                    ProfileSection(
                      title: ProfileStrings.founderInterests,
                      child: ProfileValueRows(
                        ProfileStrings.sectors,
                        p!.sectors,
                      ),
                    ),
                  if (_startups.isNotEmpty) _startupCards(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
