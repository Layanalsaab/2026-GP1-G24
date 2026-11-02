import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/invitation_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/share_link.dart';
import '../../../models/list_entries.dart';
import '../../../helpers/app_session.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
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
import '../widgets/founder_leave_dialog.dart';
import '../widgets/founder_ui.dart';
import '../widgets/manage_dashboard_tab.dart';
import '../widgets/manage_details_tab.dart';
import '../widgets/manage_rounds_tab.dart';
import '../widgets/role_tag.dart';
import '../widgets/view_only_banner.dart';
import '../widgets/manage_settings_tab.dart';
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

  /// Share icon: opens the share sheet for the startup.
  void _share() => ShareLink.share(
    context,
    ShareLink.startup(_vm.startup.id),
    title: _vm.startup.name,
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
    if (!_role.canManage) return;
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

  /// This is the user's only startup (owned, joined or closed): the delete
  /// and leave confirmations say so. False when it can't tell.
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

  /// [message] plus the last-startup warning when it applies.
  String _withLastWarning(String message, bool last) =>
      last ? '$message\n\n${FounderToolsStrings.lastStartupWarning}' : message;

  /// After deleting or leaving: a founder with no startup left goes through
  /// the log-in steps (invitations, then "Add your startup" with a note);
  /// otherwise back to My Startups.
  Future<void> _afterLosingStartup() async {
    if (await AppRouter.openIfNoStartupLeft(context)) return;
    if (!mounted) return;
    AppNav.resetStack(context, [MainScreen(), const MyStartupsScreen()]);
  }

  Future<void> _delete() async {
    // Only the owner can delete (checked again here, not just hidden), and
    // only when nobody else is on the startup.
    if (!_isOwner || _vm.startup.ownerOption != OwnerOption.delete) return;
    final name = _vm.startup.name;
    // Invited people haven't joined: their invitations are cancelled.
    final invited = [
      for (final m in _vm.startup.team)
        if (m.invited && !m.isFounder && m.name.trim().isNotEmpty)
          m.name.trim(),
    ];
    var message = FounderToolsStrings.deleteMessage;
    if (invited.isNotEmpty) {
      message =
          '$message\n\n${FounderToolsStrings.deleteCancelsInvites(invited)}';
    }
    final last = await _isLastStartup();
    if (!mounted) return;
    final confirmed = await showConfirmSheet(
      context,
      title: FounderToolsStrings.deleteTitle(name),
      message: _withLastWarning(message, last),
      confirmLabel: FounderToolsStrings.deleteStartup,
    );
    if (!confirmed || !mounted) return;
    final ok = await _vm.delete();
    if (!mounted) return;
    if (!ok) {
      AppToast.error(context, _vm.error ?? FounderToolsStrings.deleteFailed);
      return;
    }
    AppToast.confirm(context, FounderToolsStrings.deleted(name));
    await _afterLosingStartup();
  }

  /// Transfer ownership (the owner, with a co-founder on the startup): pick
  /// the co-founder, confirm, and the startup is theirs. The user stays a
  /// co-founder, so Manage reopens from My Startups with their new role.
  Future<void> _transfer() async {
    if (!_isOwner) return;
    final choices = _vm.newOwnerChoices;
    if (choices.isEmpty) return;
    var pick = choices.first;
    if (choices.length > 1) {
      final r = await showPickerSheet(
        context,
        title: FounderToolsStrings.newOwnerTitle,
        options: [for (final c in choices) c.$2],
      );
      if (r == null || !mounted) return;
      pick = choices.firstWhere((c) => c.$2 == r.value, orElse: () => pick);
    }
    final (uid, person) = pick;
    final go = await showDiscardDialog(
      context,
      title: FounderToolsStrings.transferTitle(person),
      message: FounderToolsStrings.transferMessage(person, _vm.startup.name),
      discardLabel: FounderToolsStrings.transferOwnership,
      keepLabel: FounderToolsStrings.cancel,
      danger: false,
    );
    if (!go || !mounted) return;
    final ok = await _vm.transferTo(uid);
    if (!mounted) return;
    if (!ok) {
      AppToast.error(context, _vm.error ?? FounderToolsStrings.transferFailed);
      return;
    }
    AppToast.confirm(context, FounderToolsStrings.transferredToast(person));
    AppNav.resetStack(context, [MainScreen(), const MyStartupsScreen()]);
  }

  /// Close startup (the owner, with only members on it).
  Future<void> _close() async {
    if (!_isOwner || _vm.startup.ownerOption != OwnerOption.close) return;
    final name = _vm.startup.name;
    final go = await showConfirmSheet(
      context,
      title: FounderToolsStrings.closeTitle(name),
      message: FounderToolsStrings.closeMessage(name),
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
    AppToast.confirm(context, FounderToolsStrings.closedToast(name));
    AppNav.resetStack(context, [MainScreen(), const MyStartupsScreen()]);
  }

  /// Reopen startup (the owner of a closed startup): it comes back Private.
  Future<void> _reopen() async {
    if (!_isOwner || !_vm.startup.isClosed) return;
    final name = _vm.startup.name;
    final go = await showDiscardDialog(
      context,
      title: FounderToolsStrings.reopenTitle(name),
      message: FounderToolsStrings.reopenMessage,
      discardLabel: FounderToolsStrings.reopenStartup,
      keepLabel: FounderToolsStrings.cancel,
      danger: false,
    );
    if (!go || !mounted) return;
    final ok = await _vm.reopen();
    if (!mounted) return;
    if (!ok) {
      AppToast.error(context, _vm.error ?? FounderToolsStrings.reopenFailed);
      return;
    }
    AppToast.confirm(context, FounderToolsStrings.reopenedToast(name));
    AppNav.resetStack(context, [MainScreen(), const MyStartupsScreen()]);
  }

  /// Leave startup (co-founder and team member; the owner only once the
  /// startup is closed). The person who created the startup chooses whether
  /// her name stays on its team as "Founder (former)". Then [onLeave] lets
  /// the list that opened Manage drop it, and a founder with no startup left
  /// goes to "Add your startup".
  Future<void> _leave() async {
    final s = _vm.startup;
    if (_isOwner && !s.isClosed) return;
    final name = s.name;
    final last = await _isLastStartup();
    if (!mounted) return;
    final message = _withLastWarning(
      _isOwner
          ? FounderToolsStrings.leaveMessageOwnerClosed
          : _role == StartupRole.coFounder
          ? FounderToolsStrings.leaveMessageCoFounder
          : FounderToolsStrings.leaveMessageMember,
      last,
    );
    bool keepName;
    if (_uid != null && _uid == s.originalFounderId) {
      final keep = await showFounderLeaveDialog(
        context,
        title: FounderToolsStrings.leaveTitle(name),
        message: message,
      );
      if (keep == null || !mounted) return;
      keepName = keep;
    } else {
      final leave = await showDiscardDialog(
        context,
        title: FounderToolsStrings.leaveTitle(name),
        message: message,
        discardLabel: FounderToolsStrings.leaveStartup,
        keepLabel: 'Cancel',
      );
      if (!leave || !mounted) return;
      keepName = false;
    }
    final ok = await _vm.leave(keepFounderName: keepName);
    if (!mounted) return;
    if (!ok) {
      AppToast.error(context, _vm.error ?? FounderToolsStrings.leaveFailed);
      return;
    }
    widget.onLeave?.call();
    AppToast.confirm(context, FounderToolsStrings.leftToast(name));
    if (await AppRouter.openIfNoStartupLeft(context)) return;
    if (mounted) AppNav.back(context);
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
            isPublic: s.isPublic,
            onVisibilityChanged: _setPublic,
            onDelete: _delete,
            onLeave: _leave,
            ownerOption: s.ownerOption,
            isClosed: s.isClosed,
            onTransfer: _transfer,
            onClose: _close,
            onReopen: _reopen,
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
                        '${s.isClosed ? FounderToolsStrings.closedPill : s.isPublic ? FounderToolsStrings.publicPill : FounderToolsStrings.privatePill} · ${s.sectorLabel} · ${s.stageLabel}',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  // A team member sees the same tabs, read only, with the
                  // "View only" notice at the top of every one.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (s.isClosed)
                        ViewOnlyBanner.notice(
                          title: FounderToolsStrings.closedBannerTitle,
                          message: _isOwner && s.hasOwner
                              ? FounderToolsStrings.closedBannerOwner
                              : FounderToolsStrings.closedBannerOthers,
                          icon: AppIcons.lock,
                        )
                      else if (_role == StartupRole.member)
                        const ViewOnlyBanner(),
                      TabPaneSlide(index: _vm.tab, child: pane),
                    ],
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
