import '../../../helpers/open_link.dart';

import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../helpers/app_session.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/cards/profile_blocks.dart';
import '../../../shared_ui/widgets/headers/profile_banner.dart';
import '../../startup_profile/screens/startup_profile_screen.dart';
import '../../startups/screens/manage_startup_screen.dart';
import '../../startups/screens/startup_steps_screen.dart';
import '../view_models/account_view_model.dart';
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
    if (updated != null) _vm.updateUser(updated);
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
                  linkedin: _vm.linkedin,
                  onLinkedin: () => openExternalLink(_vm.linkedin),
                ),
                ProfileSections(
                  children: [
                    if (about.isNotEmpty)
                      ProfileSection(
                        title: ProfileStrings.about,
                        delay: stagger(),
                        child: ProfileText(about),
                      ),
                    if (u.isInvestor && u.valueOffered.trim().isNotEmpty)
                      ProfileSection(
                        title: ProfileStrings.canBring,
                        delay: stagger(),
                        child: ProfileText(u.valueOffered.trim()),
                      ),
                    if (u.isInvestor && u.gain.trim().isNotEmpty)
                      ProfileSection(
                        title: ProfileStrings.hopeToGain,
                        delay: stagger(),
                        child: ProfileText(u.gain.trim()),
                      ),
                    if (_vm.isFounder)
                      ProfileSection(
                        title: ProfileStrings.myStartups,
                        actionLabel: ProfileStrings.addStartup,
                        onAction: () => StartupStepsScreen.openAdd(context),
                        delay: stagger(),
                        child: _vm.startups.isEmpty
                            ? const ProfileText(
                                ProfileStrings.noStartups,
                                muted: true,
                              )
                            : Column(
                                children: [
                                  for (var i = 0; i < _vm.startups.length; i++)
                                    ListRow(
                                      showDivider: i > 0,
                                      leading: HueAvatar(
                                        name: _vm.startups[i].name,
                                        size: 44,
                                      ),
                                      title: _vm.startups[i].name,
                                      subtitle: _vm.startups[i].summary,
                                      onTap: () => ManageStartupScreen.open(
                                        context,
                                        _vm.startups[i],
                                      ),
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
                            for (var i = 0; i < _vm.associations.length; i++)
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
                    // The email and phone show only when the user made them
                    // public (the Private / Public pill at sign-up).
                    if (u.emailPublic ||
                        (u.phonePublic && _vm.phoneLabel.isNotEmpty))
                      ProfileSection(
                        title: ProfileStrings.contact,
                        delay: stagger(),
                        child: Column(
                          children: [
                            if (u.emailPublic)
                              InfoRow(
                                icon: AppIcons.mail,
                                label: ProfileStrings.email,
                                value: u.email,
                              ),
                            if (u.phonePublic && _vm.phoneLabel.isNotEmpty)
                              InfoRow(
                                icon: AppIcons.phone,
                                label: ProfileStrings.phone,
                                value: _vm.phoneLabel,
                                showDivider: u.emailPublic,
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
