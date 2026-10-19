import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/startup_draft_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../models/startup.dart';
import '../../../navigation/app_router.dart';
import '../../../navigation/main_screen.dart';
import '../../login_and_signup/screens/verify_email_screen.dart';
import '../view_models/startup_steps_view_model.dart';
import '../widgets/founder_ui.dart';
import '../widgets/leave_form_sheet.dart';
import '../widgets/startup_step_body.dart';
import 'my_startups_screen.dart';

/// Which flow the 4-step startup form is in.
enum StartupStepsMode {
  /// Founder sign-up: "STEP 3 OF 6" .. "STEP 6 OF 6"; Create goes Home.
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
  }) : assert(mode != StartupStepsMode.edit || startup != null);

  final StartupStepsMode mode;

  /// A saved draft to continue ([StartupStepsMode.add] only).
  final Map<String, Object?>? draft;

  /// The startup being edited ([StartupStepsMode.edit] only).
  final Startup? startup;

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

  @override
  State<StartupStepsScreen> createState() => _StartupStepsScreenState();
}

class _StartupStepsScreenState extends State<StartupStepsScreen> {
  late final StartupStepsViewModel _vm = StartupStepsViewModel(
    initial: widget.startup,
  );
  late final bool _fromDraft = widget.draft != null;
  final ScrollController _scroll = ScrollController();

  bool get _onboarding => widget.mode == StartupStepsMode.onboarding;
  bool get _edit => widget.mode == StartupStepsMode.edit;

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
    if (_vm.previous()) {
      _scrollTop();
    } else if (_onboarding) {
      // Step 3 of 6: Back returns to the Verify step (the stack was reset).
      VerifyEmailScreen.openFromOnboarding(context);
    } else {
      _leave();
    }
  }

  /// Leaving the first step: nothing changed -> just go back; otherwise ask
  /// whether to keep editing, discard, or (new startups) save a draft.
  Future<void> _leave() async {
    if (!_vm.isDirty) {
      AppNav.back(context);
      return;
    }
    FocusScope.of(context).unfocus();
    final choice = await showLeaveFormSheet(context, canSaveDraft: !_edit);
    if (!mounted) return;
    switch (choice) {
      case LeaveChoice.keepEditing:
        return;
      case LeaveChoice.discard:
        // Discarding a form opened from a draft deletes that draft.
        final uid = _uid;
        if (_fromDraft && uid != null) {
          await StartupDraftRepository.instance.clear(uid);
        }
        _exit();
      case LeaveChoice.saveDraft:
        final uid = _uid;
        if (uid != null) {
          await StartupDraftRepository.instance.save(uid, _vm.toDraft());
        }
        _exit();
        AppToast.showGlobal(FounderToolsStrings.draftSaved);
    }
  }

  /// Leaves the form. A plain pop, not `maybePop`: this screen's PopScope
  /// blocks the back gesture while there are unsaved changes, and the founder
  /// has just decided what happens to them.
  void _exit() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String _title(int step) => _onboarding && step == 0
      ? FounderToolsStrings.onboardingFirstTitle
      : FounderToolsStrings.stepTitles[step];

  String get _buttonLabel {
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
        AppToast.show(context, FounderToolsStrings.fillRequired);
      case StepAdvance.memberOpen:
        AppToast.show(context, FounderToolsStrings.saveMemberFirst);
      case StepAdvance.readyToSave:
        await _save();
    }
  }

  Future<void> _save() async {
    final saved = await _vm.save();
    if (!mounted) return;
    if (saved == null) {
      AppToast.show(context, _vm.saveError ?? FounderToolsStrings.saveFailed);
      return;
    }
    switch (widget.mode) {
      case StartupStepsMode.onboarding:
        await _vm.completeOnboarding(saved);
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
        AppToast.show(context, FounderToolsStrings.changesSaved);
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
        final offset = _onboarding ? 2 : 0;
        final total = _onboarding ? 6 : 4;
        return PopScope(
          // The first step can only be left through the unsaved-changes check.
          canPop: step == 0 && (_onboarding || !_vm.isDirty),
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
