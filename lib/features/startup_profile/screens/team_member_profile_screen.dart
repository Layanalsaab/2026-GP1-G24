import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/public_profile_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/open_link.dart';
import '../../../models/list_entries.dart';
import '../../../models/public_profile.dart';
import '../../../models/home_item.dart';
import '../../../models/startup.dart';
import '../../../models/team_member.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/cards/home_card.dart';
import '../../../shared_ui/widgets/cards/profile_blocks.dart';
import '../../../shared_ui/widgets/headers/profile_banner.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../../profiles/widgets/profile_widgets.dart';
import '../../startups/widgets/role_tag.dart';
import 'startup_profile_screen.dart';

/// A person's full profile, opened by tapping them on a startup's Team tab.
///
/// The profile is always public (name, city, bio, sectors, LinkedIn, the
/// startups they belong to). Their e-mail and phone show only when they made
/// that one Public (each on its own); when both are private the Contact
/// section is not shown.
///
/// Read from `publicProfiles/{uid}`. A person with no profile (no account
/// link) falls back to what the startup itself knows: name, role and what they
/// contribute.
class TeamMemberProfileScreen extends StatefulWidget {
  const TeamMemberProfileScreen({
    super.key,
    required this.member,
    this.startupName = '',
    this.repository,
  });

  final TeamMember member;
  final String startupName;

  /// Tests pass a fake.
  final PublicProfileRepository? repository;

  static void open(
    BuildContext context,
    TeamMember member, {
    String startupName = '',
  }) => AppNav.push(
    context,
    TeamMemberProfileScreen(member: member, startupName: startupName),
    greenHeader: true,
  );

  @override
  State<TeamMemberProfileScreen> createState() =>
      _TeamMemberProfileScreenState();
}

class _TeamMemberProfileScreenState extends State<TeamMemberProfileScreen> {
  PublicProfile? _profile;
  List<ProfileStartupRef> _startups = const [];
  final Map<String, Startup> _full = {};
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
      if (profile != null) startups = await _repo.startupsOf(profile);
    }
    // The full startups, so each row can show its description, sector and city.
    final full = <String, Startup>{};
    await Future.wait([
      for (final r in startups)
        () async {
          try {
            final st = await StartupRepository.instance.fetchById(r.id);
            if (st != null) full[r.id] = st;
          } catch (_) {
            // The row falls back to the name and the role.
          }
        }(),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _startups = startups;
      _full
        ..clear()
        ..addAll(full);
      _loading = false;
    });
  }

  Future<void> _openStartup(ProfileStartupRef ref) async {
    try {
      final startup = await StartupRepository.instance.fetchById(ref.id);
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
    final role = widget.member.role.trim();
    if (role.isNotEmpty) return role;
    return RoleTag.labelOf(
      widget.member.isFounder
          ? StartupRole.founder
          : widget.member.coFounder
          ? StartupRole.coFounder
          : StartupRole.member,
    );
  }

  /// The person's startups as the same cards as the Hub, each with the
  /// person's role there as a capsule at the top right.
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
    final role = switch (ref.role) {
      'founder' => StartupRole.founder,
      'coFounder' => StartupRole.coFounder,
      _ => StartupRole.member,
    };
    final st = _full[ref.id];
    final item = st == null ? null : HomeItem.fromStartup(st);
    return HomeCard(
      name: ref.name,
      tag: item?.tag ?? '',
      city: item?.city ?? '',
      body: item?.line ?? '',
      bodyMaxLines: 2,
      animate: false,
      badge: RoleTag(role),
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
              tags: p?.sectors ?? const [],
              photoUrl: p?.photoUrl,
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
                      title: ProfileStrings.about,
                      child: ProfileText(about),
                    ),
                  if (_startups.isNotEmpty) _startupCards(),
                  // Only what the person made Public (each on its own).
                  if (p != null && (p.email != null || p.phone != null))
                    ProfileSection(
                      title: ProfileStrings.contact,
                      child: Column(
                        children: [
                          if (p.email != null)
                            InfoRow(
                              icon: AppIcons.mail,
                              label: ProfileStrings.email,
                              value: p.email!,
                            ),
                          if (p.phone != null)
                            InfoRow(
                              icon: AppIcons.phone,
                              label: ProfileStrings.phone,
                              value: '+966 ${p.phone}',
                              showDivider: p.email != null,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
