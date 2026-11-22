import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/startup.dart';
import '../../../navigation/app_router.dart';
import '../../../navigation/main_screen.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../login_and_signup/screens/verify_email_screen.dart';
import '../../login_and_signup/view_models/signup_flow.dart';
import '../view_models/startup_steps_view_model.dart';
import '../widgets/founder_ui.dart';
import '../widgets/manage_details_tab.dart';
import '../widgets/startup_step_body.dart';
import '../widgets/view_only_banner.dart';
import 'my_startups_screen.dart';

/// Which flow the 4-step startup form is in.
enum StartupStepsMode {
  /// Founder sign-up: "STEP 3 OF 7" ..
  onboarding,

  /// My Startups -> Add: "STEP N OF 4"; Create goes back to My Startups.
  add,

  /// Manage -> Edit startup: "EDIT STARTUP · STEP N OF 4"; Save goes back.
  edit,
}

/// The Add / Edit startup form and the founder onboarding steps (docs/05 D2, A9).
class StartupStepsScreen extends StatefulWidget {
  const StartupStepsScreen({
    super.key,
    required this.mode,
    this.startup,
    this.onlySection,
    this.lostStartup = false,
  }) : assert(mode != StartupStepsMode.edit || startup != null);

  final bool lostStartup;

  final StartupStepsMode mode;

  /// The startup being edited (StartupStepsMode.edit only).
  final Startup? startup;

  final int? onlySection;

  /// Founder onboarding: replaces the whole stack (forward transition).
  static void openOnboarding(BuildContext context, {bool lostStartup = false}) {
    AppNav.reset(
      context,
      StartupStepsScreen(
        mode: StartupStepsMode.onboarding,
        lostStartup: lostStartup,
      ),
      kind: RouteKind.forward,
      greenHeader: true,
    );
  }

  /// My Startups -> Add.
  static void openAdd(BuildContext context) {
    AppNav.push(
      context,
      const StartupStepsScreen(mode: StartupStepsMode.add),
      greenHeader: true,
    );
  }

  static Future<Startup?> pushEditSection(
    BuildContext context,
    Startup startup,
    int section,
  ) => AppNav.push<Startup>(
    context,
    StartupStepsScreen(
      mode: StartupStepsMode.edit,
      startup: startup,
      onlySection: section,
    ),
    greenHeader: true,
  );

  @override
  State<StartupStepsScreen> createState() => _StartupStepsScreenState();
}

class _StartupStepsScreenState extends State<StartupStepsScreen> {
  late final StartupStepsViewModel _vm = StartupStepsViewModel(
    initial: widget.startup,
    onlySection: widget.onlySection,
  );
  final ScrollController _scroll = ScrollController();

  bool get _onboarding => widget.mode == StartupStepsMode.onboarding;
  bool get _edit => widget.mode == StartupStepsMode.edit;
  bool get _section => widget.onlySection != null;

  bool get _fromLogin => _onboarding && SignupFlow.current == null;

  @override
  void initState() {
    super.initState();
    if (widget.startup != null) _vm.loadInvitations();
  }

  @override
  void dispose() {
    _vm.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _back() {
    if (_section) {
      _leave();
    } else if (_vm.previous()) {
      _scrollTop();
    } else if (_fromLogin) {
      _leaveForcedStartup();
    } else if (_onboarding) {
      VerifyEmailScreen.openFromOnboarding(context);
    } else {
      _leave();
    }
  }

  /// Back on the first step of the startup forced after a log in.
  Future<void> _leaveForcedStartup() async {
    if (_vm.isDirty) {
      final discard = await showDiscardDialog(
        context,
        title: FounderToolsStrings.discardStartupTitle,
        message: FounderToolsStrings.discardStartupMessage,
        discardLabel: FounderToolsStrings.discard,
        keepLabel: FounderToolsStrings.keepEditing,
      );
      if (!mounted || !discard) return;
    }
    await AppRouter.logOut(context, toLogin: true);
  }

  Future<void> _leave() async {
    if (!_vm.isDirty) {
      AppNav.back(context);
      return;
    }
    final discard = await showDiscardDialog(
      context,
      title: _edit
          ? FounderToolsStrings.discardEditTitle
          : FounderToolsStrings.discardStartupTitle,
      message: _edit
          ? FounderToolsStrings.discardEditMessage
          : FounderToolsStrings.discardStartupMessage,
      discardLabel: FounderToolsStrings.discard,
      keepLabel: FounderToolsStrings.keepEditing,
    );
    if (!mounted || !discard) return;
    _exit();
  }

  /// Leaves the form.
  void _exit() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String _title(int step) => _section
      ? ManageDetailsTab.titles[widget.onlySection!]
      : _onboarding && step == 0
      ? FounderToolsStrings.onboardingFirstTitle
      : FounderToolsStrings.stepTitles[step];

  String get _buttonLabel {
    if (_section) return FounderToolsStrings.save;
    if (_vm.step < StartupStepsViewModel.stepCount - 1) {
      return FounderToolsStrings.next;
    }
    return _edit ? FounderToolsStrings.saveChanges : FounderToolsStrings.create;
  }

  Future<void> _onPrimary() async {
    FocusScope.of(context).unfocus();
    switch (_vm.next()) {
      case StepAdvance.advanced:
        _scrollTop();
      case StepAdvance.incomplete:
        AppToast.error(context, FounderToolsStrings.fillRequired);
      case StepAdvance.memberOpen:
        AppToast.error(context, FounderToolsStrings.saveMemberFirst);
      case StepAdvance.readyToSave:
        if (_edit) {
          final go = await showSaveConfirmDialog(
            context,
            title: FounderToolsStrings.saveConfirmTitle,
            message: FounderToolsStrings.saveStartupMessage,
            confirmLabel: FounderToolsStrings.saveConfirmButton,
          );
          if (!go || !mounted) return;
        }
        await _save();
    }
  }

  bool _tellAboutInvitations() {
    final r = _vm.inviteSummary;
    if (r.nothing) return false;
    if (r.failed > 0) {
      // One plain message per situation, never technical text.
      AppToast.error(
        context,
        r.offline
            ? FounderToolsStrings.invitesOffline
            : r.limit
            ? FounderToolsStrings.invitesLimit
            : FounderToolsStrings.invitesFailed(r.failed),
      );
    } else if (r.sent > 0) {
      AppToast.confirm(context, FounderToolsStrings.invitationsSent(r.sent));
    }
    return true;
  }

  Future<void> _save() async {
    final saved = await _vm.save();
    if (!mounted) return;
    if (saved == null) {
      AppToast.error(context, _vm.saveError ?? FounderToolsStrings.saveFailed);
      if (_vm.lostPermission) Navigator.of(context).pop();
      return;
    }
    final told = _tellAboutInvitations();
    switch (widget.mode) {
      case StartupStepsMode.onboarding:
        await _vm.completeOnboarding(saved);
        SignupFlow.current = null;
        if (!mounted) return;
        AppRouter.openHome(context);
      case StartupStepsMode.add:
        if (!told) {
          AppToast.show(context, FounderToolsStrings.added(saved.name));
        }
        AppNav.resetStack(context, [MainScreen(), const MyStartupsScreen()]);
      case StartupStepsMode.edit:
        if (!told) AppToast.confirm(context, FounderToolsStrings.changesSaved);
        Navigator.of(context).pop(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final step = _vm.step;
        final offset = _onboarding && !_fromLogin ? 2 : 0;
        final total = offset + StartupStepsViewModel.stepCount;
        return PopScope(
          canPop: _section
              ? !_vm.isDirty
              : !_fromLogin && step == 0 && (_onboarding || !_vm.isDirty),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: FormPageScaffold(
            controller: _scroll,
            header: StepHeader(
              step: step + 1 + offset,
              total: total,
              title: _title(step),
              edit: _edit,
              label: _section ? FounderToolsStrings.editSectionLabel : null,
              showProgress: !_section,
              onBack: _back,
            ),
            footer: FormFooter(
              primary: AppButton(
                label: _buttonLabel,
                variant: _vm.currentComplete
                    ? AppButtonVariant.primary
                    : AppButtonVariant.off,
                loading: _vm.isSaving,
                onPressed: _onPrimary,
              ),
            ),
            children: [
              if (widget.lostStartup && _fromLogin && step == 0)
                const ViewOnlyBanner.notice(
                  title: FounderToolsStrings.lostStartupTitle,
                  message: FounderToolsStrings.lostStartupMessage,
                ),
              AuthCard(
                child: TabPaneSlide(
                  index: step,
                  child: StartupStepBody(
                    key: ValueKey(step),
                    vm: _vm,
                    step: step,
                    section: widget.onlySection,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
