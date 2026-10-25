import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/startup_draft_repository.dart';
import '../../../helpers/app_session.dart';
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
import 'my_startups_screen.dart';

/// Which flow the 4-step startup form is in.
enum StartupStepsMode {
  /// Founder sign-up: "STEP 3 OF 7" .. "STEP 7 OF 7" (the total follows the
  /// list of steps); Create goes Home.
  onboarding,

  /// My Startups -> Add: "STEP N OF 4"; Create goes back to My Startups.
  add,

  /// Manage -> Edit startup: "EDIT STARTUP · STEP N OF 4"; Save goes back.
  edit,
}

/// The Add / Edit startup form and the founder onboarding steps (docs/05 D2,
/// A9). One screen with four internal steps; the footer button is grey until
/// the step is complete and, when tapped early, shows the errors plus the
/// toast "Please fill in the required fields".
class StartupStepsScreen extends StatefulWidget {
  const StartupStepsScreen({
    super.key,
    required this.mode,
    this.startup,
    this.draft,
    this.onlySection,
  }) : assert(mode != StartupStepsMode.edit || startup != null);

  final StartupStepsMode mode;

  /// A saved draft to continue ([StartupStepsMode.add] only).
  final Map<String, Object?>? draft;

  /// The startup being edited ([StartupStepsMode.edit] only).
  final Startup? startup;

  /// Edit just this Details section (0-based: Overview, Startup Description,
  /// Target Market, Finance and Growth, Startup Ask, Startup Team) of a saved
  /// startup: no progress bar, a "Save" button, Back asks before discarding.
  final int? onlySection;

  /// Founder onboarding: replaces the whole stack (forward transition).
  static void openOnboarding(BuildContext context) {
    AppNav.reset(
      context,
      const StartupStepsScreen(mode: StartupStepsMode.onboarding),
      kind: RouteKind.forward,
      greenHeader: true,
    );
  }

  /// My Startups -> Add.
  static void openAdd(BuildContext context, {Map<String, Object?>? draft}) {
    AppNav.push(
      context,
      StartupStepsScreen(mode: StartupStepsMode.add, draft: draft),
      greenHeader: true,
    );
  }

  /// Manage -> Edit startup.
  static void openEdit(BuildContext context, Startup startup) {
    pushEdit(context, startup);
  }

  /// Like [openEdit] but completes with the saved startup (null when the
  /// founder backed out), so Manage can refresh itself.
  static Future<Startup?> pushEdit(BuildContext context, Startup startup) =>
      AppNav.push<Startup>(
        context,
        StartupStepsScreen(mode: StartupStepsMode.edit, startup: startup),
        greenHeader: true,
      );

  /// Manage -> Details -> Edit pill: opens ONE section ([section], 0-based)
  /// of [startup], pre-filled. Completes with the saved startup, or null when
  /// the user backed out.
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
  late final bool _fromDraft = widget.draft != null;
  final ScrollController _scroll = ScrollController();

  bool get _onboarding => widget.mode == StartupStepsMode.onboarding;
  bool get _edit => widget.mode == StartupStepsMode.edit;
  bool get _section => widget.onlySection != null;

  /// The first startup was forced after a log in (no sign-up in progress):
  /// the account and the e-mail are already done, so the steps are numbered
  /// 1 to 6 and leaving the flow means signing out.
  bool get _fromLogin => _onboarding && SignupFlow.current == null;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    if (d != null) _vm.loadDraft(d);
  }

  String? get _uid => AppSession.instance.user?.uid;

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
      // Step 3 of 8: Back returns to the Verify step (the stack was reset).
      VerifyEmailScreen.openFromOnboarding(context);
    } else {
      _leave();
    }
  }

  /// Back on the first step of the startup forced after a log in. If
  /// anything was entered, asks first (Discard / Keep editing). Either way
  /// the unfinished startup is dropped and the user is signed out and sent to
  /// Log in: the ACCOUNT stays, and the next log in starts from an empty form.
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

  /// Leaving the first step: nothing entered or changed -> just go back;
  /// otherwise a centered dialog asks (Discard / Keep editing).
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
    // Discarding a form opened from a draft deletes that draft.
    final uid = _uid;
    if (_fromDraft && uid != null) {
      await StartupDraftRepository.instance.clear(uid);
    }
    _exit();
  }

  /// Leaves the form. A plain pop, not `maybePop`: this screen's PopScope
  /// blocks the back gesture while there are unsaved changes, and the founder
  /// has just decided what happens to them.
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
        await _save();
    }
  }

  Future<void> _save() async {
    final saved = await _vm.save();
    if (!mounted) return;
    if (saved == null) {
      AppToast.error(context, _vm.saveError ?? FounderToolsStrings.saveFailed);
      return;
    }
    switch (widget.mode) {
      case StartupStepsMode.onboarding:
        await _vm.completeOnboarding(saved);
        SignupFlow.current = null;
        if (!mounted) return;
        AppRouter.openHome(context);
      case StartupStepsMode.add:
        final uid = _uid;
        if (_fromDraft && uid != null) {
          await StartupDraftRepository.instance.clear(uid);
        }
        if (!mounted) return;
        AppToast.show(context, FounderToolsStrings.added(saved.name));
        AppNav.resetStack(context, [MainScreen(), const MyStartupsScreen()]);
      case StartupStepsMode.edit:
        // "Changes saved" pop-up (a confirmation that is wanted on purpose).
        AppToast.confirm(context, FounderToolsStrings.changesSaved);
        // A plain pop: maybePop would hit this screen's own back guard (it
        // blocks leaving while there are unsaved changes) and step back to
        // the previous step instead of leaving.
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
          // The first step can only be left through the unsaved-changes check.
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
