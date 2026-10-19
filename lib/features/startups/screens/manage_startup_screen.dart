import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/connection_request.dart';
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
import '../widgets/founder_ui.dart';
import '../widgets/manage_overview_tab.dart';
import '../widgets/manage_settings_tab.dart';
import 'my_startups_screen.dart';
import 'startup_steps_screen.dart';

/// Manage startup (docs/05 D3): tabbed green header (Overview, Requests,
/// Interest, Settings) and the pane of the selected tab.
class ManageStartupScreen extends StatefulWidget {
  const ManageStartupScreen({super.key, required this.startup});

  final Startup startup;

  /// Opens Manage for [startup] (forward transition).
  static void open(BuildContext context, Startup startup) =>
      push(context, startup);

  /// Like [open] but completes when the screen is closed.
  static Future<void> push(BuildContext context, Startup startup) =>
      AppNav.push(
        context,
        ManageStartupScreen(startup: startup),
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
  late final ActivityViewModel _activity = ActivityViewModel(
    startupId: widget.startup.id,
  );

  @override
  void dispose() {
    _vm.dispose();
    _requests.dispose();
    _interest.dispose();
    _activity.dispose();
    super.dispose();
  }

  void _toast(String message) => AppToast.show(context, message);

  Future<void> _edit() async {
    final saved = await StartupStepsScreen.pushEdit(context, _vm.startup);
    if (saved != null && mounted) _vm.replace(saved);
  }

  void _preview() =>
      StartupProfileScreen.open(context, startup: _vm.startup, preview: true);

  void _calculator() =>
      ValuationCalculatorScreen.open(context, startup: _vm.startup);

  Future<void> _setPublic(bool value) async {
    final result = await _vm.setPublic(value);
    if (!mounted) return;
    if (result == null) {
      if (_vm.error != null) _toast(_vm.error!);
      return;
    }
    _toast(
      result ? FounderToolsStrings.nowPublic : FounderToolsStrings.nowPrivate,
    );
  }

  Future<void> _delete() async {
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
      _toast(_vm.error ?? FounderToolsStrings.deleteFailed);
      return;
    }
    _toast(FounderToolsStrings.deleted(name));
    AppNav.resetStack(context, [MainScreen(), const MyStartupsScreen()]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _requests, _interest]),
      builder: (context, _) {
        final s = _vm.startup;
        final pane = switch (_vm.tab) {
          0 => ManageOverviewTab(
            startupId: s.id,
            activity: _activity,
            onEdit: _edit,
            onPreview: _preview,
            onCalculator: _calculator,
          ),
          1 => RequestsTab(
            vm: _requests,
            onCheck: (r) => ValuationCalculatorScreen.open(
              context,
              startup: s,
              funding: r.amount,
              equityPercent: r.equityPercent,
            ),
            onToast: _toast,
          ),
          2 => InterestTab(vm: _interest, onToast: _toast),
          _ => ManageSettingsTab(
            isPublic: s.isPublic,
            onVisibilityChanged: _setPublic,
            onDelete: _delete,
          ),
        };
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              TabbedHeader(
                title: s.name,
                avatar: HeaderAvatarTile(initials: s.initials),
                subline: Row(
                  children: [
                    LiveDot(on: s.isPublic),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${s.isPublic ? FounderToolsStrings.publicPill : FounderToolsStrings.privatePill} · ${s.sectorLabel} · ${s.stageLabel} · ${s.location.label}${s.foundedYear == null ? '' : ' · Founded ${s.foundedYear}'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.onGreenMeta,
                      ),
                    ),
                  ],
                ),
                tabs: [
                  const HeaderTab(FounderToolsStrings.tabOverview),
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
                  child: TabPaneSlide(index: _vm.tab, child: pane),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
