import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../models/list_entries.dart';
import '../../../models/team_member.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/widgets/cards/profile_blocks.dart';
import '../../../shared_ui/widgets/headers/profile_banner.dart';
import '../../profiles/widgets/profile_widgets.dart';
import '../../startups/widgets/role_tag.dart';

/// A team member's profile, opened by tapping their row in the startup page's
/// Team tab.
///
/// It shows what the startup itself knows about the person: name, role, the
/// tag (Founder / Co-founder / Member) and what they contribute. Their own
/// account details (city, sectors, bio and the Public contact lines) come
/// from their account once the app can read other people's profiles.
class TeamMemberProfileScreen extends StatelessWidget {
  const TeamMemberProfileScreen({
    super.key,
    required this.member,
    this.startupName = '',
  });

  final TeamMember member;
  final String startupName;

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
  Widget build(BuildContext context) {
    final role = member.role.trim();
    final about = member.contribution.trim();
    return Scaffold(
      backgroundColor: AppColors.profileBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileBanner(onBack: () => AppNav.back(context)),
            ProfileHead(
              initials: member.initials,
              name: member.name,
              role: role.isEmpty ? RoleTag.labelOf(_roleOf()) : role,
              metaTail: startupName,
              tagsLabel: '',
              tags: const [],
            ),
            ProfileSections(
              children: [
                if (about.isNotEmpty)
                  ProfileSection(
                    title: ProfileStrings.about,
                    child: ProfileText(about),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  StartupRole _roleOf() => member.isFounder
      ? StartupRole.founder
      : member.coFounder
      ? StartupRole.coFounder
      : StartupRole.member;
}
