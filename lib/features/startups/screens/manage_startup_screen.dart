import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../helpers/share_link.dart';
import '../../../models/list_entries.dart';
import '../../../helpers/app_session.dart';
import '../../../models/connection_request.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../../models/startup.dart';
import '../../../navigation/main_screen.dart';
import '../../connection_requests/screens/interest_tab.dart';
import '../../connection_requests/screens/requests_tab.dart';
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
  void dispose() {
    _vm.dispose();
    _rounds.dispose();
    _requests.dispose();
    _interest.dispose();
    _activity.dispose();
    super.dispose();
  }

  void _toast(String message) => AppToast.show(context, message);

  /// Share icon: copies the startup's link.
  void _share() => ShareLink.copy(context, ShareLink.startup(_vm.startup.id));

  /// The open section of the Details tab (0-based, like the form's steps).
  int? _openSection;

  /// The user's role here: the one passed in, else read from the startup.
  late final StartupRole _role =
      widget.role ??
      StartupRole.of(widget.startup, AppSession.instance.user?.uid) ??
      StartupRole.founder;

  bool get _canEdit => _role.canManage;

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

  void _calculator() =>
      ValuationCalculatorScreen.open(context, startup: _vm.startup);

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

  Future<void> _delete() async {
    // Only the founder can delete (checked again here, not just hidden).
    if (_role != StartupRole.founder) return;
    final name = _vm.startup.name;
    final confirmed = await showConfirmSheet(
      context,
      title: FounderToolsStrings.deleteTitle(name),
      message: FounderToolsStrings.deleteMessage,
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
    AppNav.resetStack(context, [MainScreen(), const MyStartupsScreen()]);
  }

  /// Leave startup (co-founder and team member): confirms, removes the user
  /// from the team (interface only: [ManageStartupScreen.onLeave]) and goes
  /// back to My Startups.
  Future<void> _leave() async {
    if (_role == StartupRole.founder) return;
    final name = _vm.startup.name;
    final leave = await showDiscardDialog(
      context,
      title: FounderToolsStrings.leaveTitle(name),
      message: _role == StartupRole.coFounder
          ? FounderToolsStrings.leaveMessageCoFounder
          : FounderToolsStrings.leaveMessageMember,
      discardLabel: FounderToolsStrings.leaveStartup,
      keepLabel: 'Cancel',
    );
    if (!leave || !mounted) return;
    widget.onLeave?.call();
    AppToast.confirm(context, FounderToolsStrings.leftToast(name));
    AppNav.back(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _requests, _interest, _rounds]),
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
          2 => ManageRoundsTab(vm: _rounds, canManage: _canEdit),
          3 => RequestsTab(
            vm: _requests,
            onCheck: (r) => ValuationCalculatorScreen.open(
              context,
              startup: s,
              funding: r.amount,
              equityPercent: r.equityPercent,
            ),
            onToast: _toast,
            canAct: _canEdit,
          ),
          4 => InterestTab(vm: _interest, onToast: _toast, canAct: _canEdit),
          _ => ManageSettingsTab(
            role: _role,
            isPublic: s.isPublic,
            onVisibilityChanged: _setPublic,
            onDelete: _delete,
            onLeave: _leave,
          ),
        };
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              TabbedHeader(
                title: s.name,
                eyebrow: RoleTag.labelOf(_role),
                avatar: HeaderAvatarTile(initials: s.initials),
                subline: Row(
                  children: [
                    LiveDot(on: s.isPublic),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${s.isPublic ? FounderToolsStrings.publicPill : FounderToolsStrings.privatePill} · ${s.sectorLabel} · ${s.stageLabel}',
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
                    FounderToolsStrings.tabRequests,
                    badge: _requests.count(RequestStatus.pending),
                  ),
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
                      if (_role == StartupRole.member) const ViewOnlyBanner(),
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
