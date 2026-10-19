import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/startup.dart';
import '../../../navigation/app_router.dart';
import '../../../navigation/main_screen.dart';
import '../../login_and_signup/screens/verify_email_screen.dart';
import '../view_models/startup_steps_view_model.dart';
import '../widgets/founder_ui.dart';
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
  const StartupStepsScreen({super.key, required this.mode, this.startup})
    : assert(mode != StartupStepsMode.edit || startup != null);

  final StartupStepsMode mode;

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
  static void openAdd(BuildContext context) {
    AppNav.push(
      context,
      const StartupStepsScreen(mode: StartupStepsMode.add),
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
  final ScrollController _scroll = ScrollController();

  bool get _onboarding => widget.mode == StartupStepsMode.onboarding;
  bool get _edit => widget.mode == StartupStepsMode.edit;

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
      AppNav.back(context);
    }
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
        AppToast.show(context, FounderToolsStrings.added(saved.name));
        AppNav.resetStack(context, [MainScreen(), const MyStartupsScreen()]);
      case StartupStepsMode.edit:
        AppToast.show(context, FounderToolsStrings.changesSaved);
        AppNav.back(context, saved);
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
          canPop: step == 0,
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
