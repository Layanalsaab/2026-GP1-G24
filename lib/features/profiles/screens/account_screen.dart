import '../../../helpers/open_link.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../helpers/app_session.dart';
import '../../../models/app_user.dart';
import '../../../models/home_item.dart';
import '../../../models/list_entries.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../startups/widgets/role_tag.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/cards/home_card.dart';
import '../../../shared_ui/widgets/cards/profile_blocks.dart';
import '../../../shared_ui/widgets/headers/profile_banner.dart';
import '../../startup_profile/screens/startup_profile_screen.dart';
import '../../startups/screens/manage_startup_screen.dart';
import '../../startups/screens/startup_steps_screen.dart';
import '../view_models/account_view_model.dart';
import '../widgets/investor_profile_body.dart';
import '../widgets/profile_widgets.dart';
import 'edit_account_screen.dart';

/// The signed-in user's own profile (docs/05 C4, screenshots 40 and 40b):
/// banner with back and "Edit profile", the head block, About, (investor)
/// what I can bring / hope to gain, (founder) My startups, (investor)
/// associations and Contact.
class OwnProfileScreen extends StatefulWidget {
  const OwnProfileScreen({super.key, required this.user});

  final AppUser user;

  /// Opens the profile of the signed-in user (menu "View profile").
  static void open(BuildContext context) {
    final user = AppSession.instance.user;
    if (user == null) return;
    AppNav.push(context, OwnProfileScreen(user: user), greenHeader: true);
  }

  @override
  State<OwnProfileScreen> createState() => _OwnProfileScreenState();
}

class _OwnProfileScreenState extends State<OwnProfileScreen> {
  late final AccountViewModel _vm = AccountViewModel(user: widget.user);

  @override
  void initState() {
    super.initState();
    _vm.reload();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final updated = await AppNav.push<AppUser>(
      context,
      EditProfileScreen(user: _vm.user),
    );
    // The session holds the saved profile even if no result came back.
    final latest = updated ?? AppSession.instance.user;
    if (latest != null) _vm.updateUser(latest);
    // A new name also changes my team cards, so read the startups again.
    await _vm.refreshStartups();
  }

  /// My startups, as the same cards as the Hub (and as on a founder's
  /// profile), each with my role there as a capsule at the top right.
  Widget _myStartups(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    ProfileStrings.myStartups,
                    style: AppText.sectionTitle,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: ProfileStrings.addStartup,
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => StartupStepsScreen.openAdd(context),
                  child: Text(
                    ProfileStrings.addStartup,
                    style: AppText.sans(
                      size: 14.5,
                      weight: FontWeight.w600,
                      color: AppColors.moss600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_vm.startupEntries.isEmpty)
          const ProfileText(ProfileStrings.noStartups, muted: true)
        else
          for (var i = 0; i < _vm.startupEntries.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
              child: Builder(
                builder: (context) {
                  final entry = _vm.startupEntries[i];
                  final item = HomeItem.fromStartup(entry.startup);
                  return HomeCard(
                    name: item.name,
                    tag: item.tag,
                    city: item.city,
                    body: item.line,
                    bodyMaxLines: 2,
                    animate: false,
                    badge: RoleTag(entry.role),
                    imageUrl: item.imageUrl,
                    imageData: item.imageData,
                    onTap: () => _openStartup(entry),
                  );
                },
              ),
            ),
      ],
    );
  }

  Future<void> _openStartup(MyStartupEntry entry) async {
    await ManageStartupScreen.push(
      context,
      entry.startup,
      role: entry.role,
      onLeave: () => unawaited(_vm.leave(entry.startup.id)),
    );
    if (mounted) await _vm.refreshStartups();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final u = _vm.user;
        var n = 0;
        Duration stagger() => Duration(milliseconds: 60 * n++);
        final about = u.bio.trim();
        return Scaffold(
          backgroundColor: AppColors.profileBg,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileBanner.edit(
                  onBack: () => AppNav.back(context),
                  onEdit: _edit,
                ),
                ProfileHead(
                  initials: u.initials,
                  name: u.fullName,
                  role: _vm.roleLabel,
                  city: u.city,
                  metaTail: _vm.joinedLabel,
                  tagsLabel: u.isInvestor
                      ? ProfileStrings.investsIn
                      : ProfileStrings.interestedIn,
                  tags: _vm.sectors,
                  photoUrl: u.photoUrl,
                  photoData: u.photoData,
                  linkedin: _vm.linkedin,
                  onLinkedin: () => openExternalLink(_vm.linkedin),
                ),
                if (u.isInvestor)
                  InvestorProfileBody(
                    data: InvestorProfileData.fromUser(u),
                    associations: _vm.associations,
                    contact: InvestorContactData(
                      email: u.email,
                      emailPublic: u.emailPublic,
                      phone: _vm.phoneLabel,
                      phonePublic: u.phonePublic,
                      linkedin: u.linkedin ?? '',
                    ),
                  )
                else
                  ProfileSections(
                    children: [
                      if (about.isNotEmpty)
                        ProfileSection(
                          title: ProfileStrings.about,
                          delay: stagger(),
                          child: ProfileText(about),
                        ),
                      if (_vm.isFounder) _myStartups(context),
                      if (_vm.associations.isNotEmpty)
                        ProfileSection(
                          title: ProfileStrings.associations,
                          delay: stagger(),
                          child: Column(
                            children: [
                              for (var i = 0; i < _vm.associations.length; i++)
                                ListRow(
                                  showDivider: i > 0,
                                  leading: HueAvatar(
                                    name: _vm.associations[i].name,
                                    size: 44,
                                    imageUrl: _vm.associations[i].logoUrl,
                                    imageData: _vm.associations[i].logoData,
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
                      // On my own profile both are listed, each with a pill that
                      // says who sees it (Public or Only you).
                      if (_vm.contactRows().isNotEmpty)
                        ProfileSection(
                          title: ProfileStrings.contact,
                          delay: stagger(),
                          child: Column(
                            children: [
                              for (final (i, row) in _vm.contactRows().indexed)
                                InfoRow(
                                  icon: row.kind == ContactKind.email
                                      ? AppIcons.mail
                                      : AppIcons.phone,
                                  label: row.kind == ContactKind.email
                                      ? ProfileStrings.email
                                      : ProfileStrings.phone,
                                  value: row.value,
                                  showDivider: i > 0,
                                  trailing: _ContactPill(
                                    isPublic: row.isPublic,
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
        );
      },
    );
  }
}

/// The small "Public" / "Only you" pill at the end of a Contact row:
/// height 22, 12 px semibold; Public in moss, Only you in grey.
class _ContactPill extends StatelessWidget {
  const _ContactPill({required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final color = isPublic ? AppColors.moss600 : AppColors.grey;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Public: moss fill. Only you: a muted grey fill.
        color: isPublic ? const Color(0xFFEEF4EF) : const Color(0xFFF0EDE6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isPublic ? const Color(0xFFCFE0D3) : const Color(0xFFF0EDE6),
        ),
      ),
      child: Text(
        isPublic ? ProfileStrings.contactPublic : ProfileStrings.contactOnlyYou,
        style: AppText.sans(size: 12, weight: FontWeight.w600, color: color),
      ),
    );
  }
}
