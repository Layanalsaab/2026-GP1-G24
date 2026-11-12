import '../../../shared_ui/widgets/lists/app_refresh.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/invitation_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../data_access/repositories/team_lookup.dart';
import '../../../helpers/formatters.dart';
import '../../../helpers/share_link.dart';
import '../../../helpers/validators.dart';
import '../../../models/list_entries.dart';
import '../../../helpers/app_session.dart';
import '../../../models/startup.dart';
import '../../../navigation/app_router.dart';
import '../../../navigation/main_screen.dart';
import '../../connection_requests/screens/interest_tab.dart';
import '../../connection_requests/view_models/interest_view_model.dart';
import '../../connection_requests/view_models/requests_view_model.dart';
import '../../engagement_analytics/view_models/activity_view_model.dart';
import '../../fundraising_calculator/screens/valuation_calculator_screen.dart';
import '../../startup_profile/screens/startup_profile_screen.dart';
import '../view_models/manage_startup_view_model.dart';
import '../view_models/rounds_view_model.dart';
import '../widgets/founder_ui.dart';
import '../widgets/manage_dashboard_tab.dart';
import '../widgets/manage_details_tab.dart';
import '../widgets/manage_rounds_tab.dart';
import '../widgets/role_tag.dart';
import '../widgets/view_only_banner.dart';
import '../widgets/manage_settings_tab.dart';
import '../widgets/owner_handover_dialogs.dart';
import 'my_startups_screen.dart';
import 'startup_steps_screen.dart';

/// Manage startup (docs/05 D3): tabbed green header (Dashboard, Details,
/// Rounds, Requests, Interest, Settings; the tab bar scrolls sideways) and the
/// pane of the selected tab. [role] is the user's role in this startup.
class ManageStartupScreen extends StatefulWidget {
  const ManageStartupScreen({
    super.key,
    required this.startup,
    this.role,
    this.onLeave,
  });

  final Startup startup;

  /// Called after the user leaves this startup (it then disappears from their
  /// My Startups). INTERFACE ONLY: the real leaving is done by the backend.
  final VoidCallback? onLeave;

  /// The user's role in this startup (shown above the name). Null reads it
  /// from the startup itself (founder / `memberRoles`), the founder when
  /// nothing matches.
  final StartupRole? role;

  /// Opens Manage for [startup] (forward transition).
  static void open(
    BuildContext context,
    Startup startup, {
    StartupRole? role,
    VoidCallback? onLeave,
  }) => push(context, startup, role: role, onLeave: onLeave);

  /// Like [open] but completes when the screen is closed.
  static Future<void> push(
    BuildContext context,
    Startup startup, {
    StartupRole? role,
    VoidCallback? onLeave,
  }) => AppNav.push(
    context,
    ManageStartupScreen(startup: startup, role: role, onLeave: onLeave),
    greenHeader: true,
  );

  @override
  State<ManageStartupScreen> createState() => _ManageStartupScreenState();
}

class _ManageStartupScreenState extends State<ManageStartupScreen> {
  late final ManageStartupViewModel _vm = ManageStartupViewModel(
    startup: widget.startup,
  );
  // The investment requests of the open round (shown on the round page).
  late final RequestsViewModel _requests = RequestsViewModel(
    startupId: widget.startup.id,
  );
  late final InterestViewModel _interest = InterestViewModel(
    startupId: widget.startup.id,
  );
  // The startup's funding rounds. Adding / closing one saves the startup
  // too (Funding ticked / unticked), so the header and Details follow.
  late final RoundsViewModel _rounds = RoundsViewModel(
    startup: widget.startup,
    currentStartup: () => _vm.startup,
    canManage: _canEdit,
    onStartupSaved: (saved) => _vm.replace(saved),
  );
  late final ActivityViewModel _activity = ActivityViewModel(
    startupId: widget.startup.id,
  );

  @override
  void initState() {
    super.initState();
    _fixInvitedCards();
    // The owner: is somebody invited to take over still waiting?
    _vm.loadOwnerInvite();
  }

  /// Somebody accepted an invitation while the startup was private, so only
  /// the team can fix their card ("Invited" -> a member). Done when a person
  /// who can manage opens the startup.
  Future<void> _fixInvitedCards() async {
    if (!_canEdit || !widget.startup.team.any((m) => m.invited)) return;
    try {
      final fixed = await InvitationRepository.instance.reconcileTeam(
        widget.startup,
      );
      if (fixed == null || !mounted) return;
      await StartupRepository.instance.setTeam(widget.startup.id, fixed);
      if (mounted) _vm.replace(_vm.startup.copyWith(team: fixed));
    } catch (_) {
      // The cards are fixed next time.
    }
  }

  /// Pull down: the startup (details, team) and its funding rounds are read
  /// again, so a change made by someone else shows.
  Future<void> _refresh() async {
    final fresh = await StartupRepository.instance.fetchById(widget.startup.id);
    if (fresh == null || !mounted) return;
    _vm.replace(fresh);
    await _rounds.load(fresh);
  }

  @override
  void dispose() {
    _vm.dispose();
    _rounds.dispose();
    _requests.dispose();
    _interest.dispose();
    _activity.dispose();
    super.dispose();
  }

  void _toast(String message) => AppToast.show(context, message);

  /// "8 Nov 2026" for the Closed banner (null when it wasn't stored).
  static String? _closedDate(Startup s) =>
      s.closedAt == null ? null : Formatters.dayMonthYear(s.closedAt!);

  /// Share icon: opens the share sheet for the startup.
  void _share() => ShareLink.shareStartup(
    context,
    id: _vm.startup.id,
    name: _vm.startup.name,
    sector: _vm.startup.sectorLabel,
    city: _vm.startup.location.label,
  );

  /// The open section of the Details tab (0-based, like the form's steps).
  int? _openSection;

  /// The user's role here: the one passed in, else read from the startup.
  late final StartupRole _role =
      widget.role ??
      StartupRole.of(widget.startup, AppSession.instance.user?.uid) ??
      StartupRole.founder;

  /// A closed startup is read only for everyone.
  bool get _canEdit => _role.canManage && !widget.startup.isClosed;

  bool get _isOwner => _role == StartupRole.founder;

  String? get _uid => AppSession.instance.user?.uid;

  void _toggleSection(int i) =>
      setState(() => _openSection = _openSection == i ? null : i);

  /// Edit pill: opens ONLY that section of the form, filled in. Saving goes
  /// back here and updates the Details tab.
  Future<void> _editSection(int section) async {
    if (!_canEdit) return;
    final saved = await StartupStepsScreen.pushEditSection(
      context,
      _vm.startup,
      section,
    );
    if (saved != null && mounted) {
      _vm.replace(saved);
      // The Startup Ask may have opened, changed or closed the round.
      _rounds.load(saved);
    }
  }

  /// Valuation tile: the Finance and Growth editor, or (view only) the
  /// Details tab with that section open.
  void _openValuation() {
    const finance = 3;
    if (_canEdit) {
      _editSection(finance);
    } else {
      setState(() => _openSection = finance);
      _vm.selectTab(1);
    }
  }

  void _preview() =>
      StartupProfileScreen.open(context, startup: _vm.startup, preview: true);

  // if there are co-founders or older rounds we can't assume 100% ownership
  void _calculator() {
    final s = _vm.startup;
    final coFounders =
        s.team.any((m) => m.coFounder) ||
        s.memberRoles.values.contains('coFounder');
    final earlierRound = _rounds.rounds.any((r) => !r.isOpen);
    ValuationCalculatorScreen.openForStartup(
      context,
      startup: s,
      round: _rounds.openRound,
      ownershipUnknown: coFounders || earlierRound,
    );
  }

  Future<void> _setPublic(bool value) async {
    final s = _vm.startup;
    // A closed startup: its owner only.
    if (s.isClosed ? !_isOwner : !_role.canManage) return;
    final result = await _vm.setPublic(value);
    if (!mounted) return;
    if (result == null) {
      if (_vm.error != null) AppToast.error(context, _vm.error!);
      return;
    }
    // A startup saved before rounds existed gets its open round now.
    _rounds.load(_vm.startup);
    _toast(
      result ? FounderToolsStrings.nowPublic : FounderToolsStrings.nowPrivate,
    );
  }

  /// This is the user's only startup (owned, joined or closed): the owner's
  /// leave confirmation says so. False when it can't tell.
  Future<bool> _isLastStartup() async {
    final session = AppSession.instance;
    if (session.user == null || !session.isFounder) return false;
    final id = _vm.startup.id;
    if (session.belongingStartupIds.any((other) => other != id)) return false;
    try {
      final repo = StartupRepository.instance;
      final all = [
        ...await repo.fetchMyStartups(),
        ...await repo.fetchMemberStartups(),
      ];
      return all.every((s) => s.id == id);
    } catch (_) {
      return false;
    }
  }

  /// After leaving: a founder with no startup left goes through the log-in
  /// steps (invitations, then "Add your startup" with a note); otherwise
  /// back to My Startups.
  Future<void> _afterLosingStartup() async {
    if (await AppRouter.openIfNoStartupLeft(context)) return;
    if (!mounted) return;
    AppNav.resetStack(context, [MainScreen(), const MyStartupsScreen()]);
  }

  /// Close startup (the owner): permanent; the startup stays in everyone's
  /// account as closed. The confirmation names who is still only invited.
  Future<void> _close() async {
    final s = _vm.startup;
    if (!_isOwner || s.isClosed) return;
    final invited = [
      for (final m in s.team)
        if (m.invited && !m.isFounder && m.name.trim().isNotEmpty)
          m.name.trim(),
    ];
    var message = FounderToolsStrings.closeMessage(s.name, s.memberIds.length);
    if (invited.isNotEmpty) {
      message =
          '$message\n\n${FounderToolsStrings.invitationsCancelled(invited)}';
    }
    final go = await showConfirmSheet(
      context,
      title: FounderToolsStrings.closeTitle(s.name),
      message: message,
      confirmLabel: FounderToolsStrings.closeStartup,
      icon: AppIcons.lock,
    );
    if (!go || !mounted) return;
    final ok = await _vm.close();
    if (!mounted) return;
    if (!ok) {
      AppToast.error(context, _vm.error ?? FounderToolsStrings.closeFailed);
      return;
    }
    AppToast.confirm(context, FounderToolsStrings.closedToast(s.name));
    AppNav.resetStack(context, [MainScreen(), const MyStartupsScreen()]);
  }

  /// Leave startup. The owner names the next owner first ([_leaveAsOwner]);
  /// a co-founder or team member just confirms. Nobody leaves a closed
  /// startup. Then [onLeave] lets the list that opened Manage drop it, and a
  /// founder with no startup left goes to "Add your startup".
  Future<void> _leave() async {
    final s = _vm.startup;
    if (s.isClosed) return;
    if (_isOwner) return _leaveAsOwner();
    final last = await _isLastStartup();
    if (!mounted) return;
    final leave = await showConfirmSheet(
      context,
      title: FounderToolsStrings.leaveTitle(s.name),
      message: _role == StartupRole.coFounder
          ? FounderToolsStrings.leaveMessageCoFounder
          : FounderToolsStrings.leaveMessageMember,
      confirmLabel: FounderToolsStrings.leaveStartup,
      cancelLabel: FounderToolsStrings.cancel,
      icon: AppIcons.logout,
      note: last ? _onlyStartupNote(s) : null,
    );
    if (!leave || !mounted) return;
    final ok = await _vm.leave();
    if (!mounted) return;
    if (!ok) {
      AppToast.error(context, _vm.error ?? FounderToolsStrings.leaveFailed);
      return;
    }
    widget.onLeave?.call();
    AppToast.confirm(context, FounderToolsStrings.leftToast(s.name));
    if (await AppRouter.openIfNoStartupLeft(context)) return;
    if (mounted) AppNav.back(context);
  }

  /// The owner leaves: she picks the next owner among the people who joined,
  /// or invites someone new by e-mail (she stays in control until it is
  /// accepted). Alone on the team, inviting is the only way.
  Future<void> _leaveAsOwner() async {
    final s = _vm.startup;
    final choices = _vm.nextOwnerChoices;
    if (choices.isEmpty) return _inviteNewOwner(alone: true);
    final pick = await showNextOwnerSheet(
      context,
      startup: s,
      uids: [for (final c in choices) c.$1],
    );
    if (pick == null || !mounted) return;
    if (pick.invite) return _inviteNewOwner(alone: false);
    final (uid, person, _) = choices.firstWhere((c) => c.$1 == pick.uid);
    final last = await _isLastStartup();
    if (!mounted) return;
    final go = await showConfirmSheet(
      context,
      title: FounderToolsStrings.makeOwnerTitle(person, s.name),
      message: FounderToolsStrings.makeOwnerMessage(person, s.name),
      confirmLabel: FounderToolsStrings.makeOwnerConfirm(person),
      cancelLabel: FounderToolsStrings.cancel,
      icon: AppIcons.logout,
      note: last ? _onlyStartupNote(s) : null,
    );
    if (!go || !mounted) return;
    final ok = await _vm.transferTo(uid);
    if (!mounted) return;
    if (!ok) {
      AppToast.error(context, _vm.error ?? FounderToolsStrings.handoverFailed);
      return;
    }
    widget.onLeave?.call();
    AppToast.confirm(
      context,
      FounderToolsStrings.newOwnerToast(person, s.name),
    );
    await _afterLosingStartup();
  }

  /// The gold note under a leave confirmation when this is my only startup:
  /// after leaving, "Add your startup" opens.
  Widget _onlyStartupNote(Startup s) => ViewOnlyBanner.notice(
    title: FounderToolsStrings.onlyStartupTitle(s.name),
    message: FounderToolsStrings.onlyStartupText,
  );

  /// "Invite someone new": one sheet with what happens next and the e-mail
  /// (not mine, not someone on the team, not an investor account), then the
  /// invitation. The Settings tab shows "Waiting for…" until it is answered.
  Future<void> _inviteNewOwner({required bool alone}) async {
    final s = _vm.startup;
    final myEmail = (AppSession.instance.user?.email ?? '')
        .trim()
        .toLowerCase();
    final teamEmails = {
      for (final m in s.team)
        if (!m.invited && m.email.trim().isNotEmpty)
          m.email.trim().toLowerCase(),
    };
    var newUser = false;
    final next = FounderToolsStrings.inviteOwnerMessage(s.name);
    final email = await showOwnerEmailSheet(
      context,
      message: alone
          ? '${FounderToolsStrings.nextOwnerAlone(s.name)} $next'
          : next,
      check: (email) async {
        if (!Validators.isEmail(email)) {
          return FounderToolsStrings.ownerEmailInvalid;
        }
        if (email == myEmail) return FounderToolsStrings.ownerEmailYou;
        if (teamEmails.contains(email)) {
          return FounderToolsStrings.ownerEmailOnTeam;
        }
        final account = await TeamLookup.instance.findByEmail(email);
        if (account != null && !account.isFounder) {
          return FounderToolsStrings.ownerEmailInvestor;
        }
        if (account != null && s.memberRoles.containsKey(account.uid)) {
          return FounderToolsStrings.ownerEmailOnTeam;
        }
        newUser = account == null;
        return null;
      },
    );
    if (email == null || !mounted) return;
    final ok = await _vm.inviteOwner(email, newUser: newUser);
    if (!mounted) return;
    if (!ok) {
      AppToast.error(
        context,
        _vm.error ?? FounderToolsStrings.ownerInviteFailed,
      );
      return;
    }
    // The invitation is saved; say whether the email really left.
    final sent = _vm.ownerEmailResult;
    if (sent == InviteSendResult.sent || sent == null) {
      AppToast.confirm(context, FounderToolsStrings.ownerInviteSent(email));
    } else {
      AppToast.error(context, _emailProblem(sent));
    }
  }

  /// Why the email did not leave (the invitation itself is saved).
  String _emailProblem(InviteSendResult result) => switch (result) {
    InviteSendResult.offline => FounderToolsStrings.invitesOffline,
    InviteSendResult.dailyLimit => FounderToolsStrings.invitesLimit,
    InviteSendResult.tooSoon => FounderToolsStrings.ownerEmailTooSoon,
    _ => FounderToolsStrings.ownerInviteSavedNoEmail,
  };

  /// "Resend email" on the Waiting card.
  Future<void> _resendOwnerInvite() async {
    final invite = _vm.pendingOwnerInvite;
    if (invite == null) return;
    final result = await _vm.resendOwnerInvite();
    if (!mounted) return;
    if (result == InviteSendResult.sent) {
      AppToast.confirm(
        context,
        FounderToolsStrings.ownerEmailResent(invite.emailLower),
      );
    } else if (result == InviteSendResult.failed ||
        result == InviteSendResult.notConfigured) {
      AppToast.error(context, FounderToolsStrings.ownerEmailResendFailed);
    } else {
      AppToast.error(context, _emailProblem(result));
    }
  }

  /// "Cancel invitation" on the Waiting card: asked first, like the other
  /// leave steps.
  Future<void> _cancelOwnerInvite() async {
    final invite = _vm.pendingOwnerInvite;
    if (invite == null) return;
    final go = await showConfirmSheet(
      context,
      title: FounderToolsStrings.cancelOwnerInviteTitle,
      message: FounderToolsStrings.cancelOwnerInviteMessage(
        invite.emailLower,
        _vm.startup.name,
      ),
      confirmLabel: FounderToolsStrings.cancelInvitation,
      cancelLabel: FounderToolsStrings.keepInvitation,
      icon: AppIcons.mail,
    );
    if (!go || !mounted) return;
    final ok = await _vm.cancelOwnerInvite();
    if (!mounted) return;
    if (ok) {
      AppToast.confirm(context, FounderToolsStrings.ownerInviteCancelled);
    } else {
      AppToast.error(
        context,
        _vm.error ?? FounderToolsStrings.ownerInviteCancelFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _interest, _rounds]),
      builder: (context, _) {
        final s = _vm.startup;
        // The open round's Raised: the "already raised" answer of the
        // startup, or the accepted requests total when that is higher.
        final already = s.raisedInRound;
        _rounds.openRaised = already == null
            ? null
            : math.max(
                already,
                RequestRepository.instance
                    .acceptedFor(s.id)
                    .fold<int>(0, (sum, r) => sum + r.amount),
              );
        final pane = switch (_vm.tab) {
          0 => ManageDashboardTab(
            startup: s,
            openRound: _rounds.openRound,
            activity: _activity,
            onRaising: () => _vm.selectTab(2),
            onValuation: _openValuation,
            onCalculator: _calculator,
            emptyInvestorsText: _role == StartupRole.member
                ? FounderToolsStrings.associatedEmptyMember
                : FounderToolsStrings.associatedEmpty,
          ),
          1 => ManageDetailsTab(
            startup: s,
            openIndex: _openSection,
            onToggle: _toggleSection,
            canEdit: _canEdit,
            onEdit: _editSection,
            myRole: _role,
            footer: ManageLeaveSection(
              role: _role,
              startupName: s.name,
              onLeave: _leave,
              isClosed: s.isClosed,
              pendingOwnerEmail: _vm.pendingOwnerInvite?.emailLower,
              onCancelOwnerInvite: _cancelOwnerInvite,
              onResendOwnerInvite: _resendOwnerInvite,
              ownerInviteDaysLeft: _vm.pendingOwnerInvite?.daysLeft(
                DateTime.now(),
              ),
              expiredOwnerEmail: _vm.expiredOwnerEmail,
            ),
          ),
          2 => ManageRoundsTab(
            vm: _rounds,
            canManage: _canEdit,
            requests: _requests,
            onCheck: (r) => ValuationCalculatorScreen.open(
              context,
              startup: s,
              funding: r.amount,
              equityPercent: r.equityPercent,
            ),
            onToast: _toast,
          ),
          3 => InterestTab(vm: _interest, onToast: _toast, canAct: _canEdit),
          _ => ManageSettingsTab(
            role: _role,
            startupName: s.name,
            isPublic: s.isPublic,
            onVisibilityChanged: _setPublic,
            isClosed: s.isClosed,
            onClose: _close,
          ),
        };
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              TabbedHeader(
                title: s.name,
                eyebrow: RoleTag.labelFor(s, _uid, fallback: _role),
                avatar: HeaderAvatarTile(
                  initials: s.initials,
                  imageUrl: s.logoUrl,
                  imageData: s.logoData,
                ),
                subline: Row(
                  children: [
                    LiveDot(on: s.isListed),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${s.isClosed
                            ? FounderToolsStrings.closedPill
                            : s.isPublic
                            ? FounderToolsStrings.publicPill
                            : FounderToolsStrings.privatePill} · ${s.sectorLabel} · ${s.stageLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.onGreenMeta,
                      ),
                    ),
                  ],
                ),
                // Eye (preview), share, then the logo. No settings gear.
                actions: [
                  GlassIconButton(
                    icon: AppIcons.eye,
                    semanticLabel: 'Preview profile',
                    onTap: _preview,
                  ),
                  GlassIconButton.share(onTap: _share),
                  const HeaderLogo(),
                ],
                scrollableTabs: true,
                tabs: [
                  const HeaderTab(FounderToolsStrings.tabDashboard),
                  const HeaderTab(FounderToolsStrings.tabDetails),
                  const HeaderTab(FounderToolsStrings.tabRounds),
                  HeaderTab(
                    FounderToolsStrings.tabInterest,
                    badge: _interest.newCount,
                  ),
                  const HeaderTab(FounderToolsStrings.tabSettings),
                ],
                selectedIndex: _vm.tab,
                onTabChanged: _vm.selectTab,
                onBack: () => AppNav.back(context),
              ),
              Expanded(
                child: AppRefresh(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: AppRefresh.physics,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    // A team member sees the same tabs, read only. A closed
                    // startup says so at the top of every one.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (s.isClosed)
                          ViewOnlyBanner.notice(
                            title: FounderToolsStrings.closedBannerTitle,
                            message: _isOwner && s.hasOwner
                                ? FounderToolsStrings.closedBannerOwner(
                                    _closedDate(s),
                                  )
                                : FounderToolsStrings.closedBannerTeam(
                                    _closedDate(s),
                                  ),
                            icon: AppIcons.lock,
                          ),
                        TabPaneSlide(index: _vm.tab, child: pane),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
