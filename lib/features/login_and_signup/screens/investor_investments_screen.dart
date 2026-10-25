import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/form_page.dart';
import '../../../shared_ui/widgets/headers/auth_headers.dart';
import '../../../shared_ui/widgets/headers/overlap_layout.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../view_models/investor_onboarding_view_model.dart';
import '../widgets/investor_fields.dart';
import 'investor_interests_screen.dart';
import 'verify_email_screen.dart';

/// Investor step 3 of 4, "Investment background" (docs/05 A10). Next is grey until
/// the required answers are given; tapping it early shows the errors and the
/// toast "Please fill in the required fields". Back goes to the Verify step.
class InvestorInvestmentsScreen extends StatefulWidget {
  const InvestorInvestmentsScreen({
    super.key,
    required this.user,
    this.resume = false,
  });

  /// True when the investor logs in again without having finished: if their
  /// saved step-3 answers are complete they go straight on to step 4.
  final bool resume;

  /// The investor who just verified their email.
  final AppUser user;

  /// Replaces the stack with step 3 (forward transition) after the Verify step.
  static void open(BuildContext context, AppUser user, {bool resume = false}) =>
      AppNav.reset(
        context,
        InvestorInvestmentsScreen(user: user, resume: resume),
        kind: RouteKind.forward,
        greenHeader: true,
      );

  @override
  State<InvestorInvestmentsScreen> createState() =>
      _InvestorInvestmentsScreenState();
}

class _InvestorInvestmentsScreenState extends State<InvestorInvestmentsScreen> {
  late final InvestorOnboardingViewModel _vm = InvestorOnboardingViewModel(
    user: widget.user,
    initial: widget.user.investorCriteria,
    keepDraft: true,
  );

  @override
  void initState() {
    super.initState();
    _vm.restoreDraft().then((_) {
      if (!mounted || !widget.resume || !_vm.step3Complete) return;
      AppNav.push(
        context,
        InvestorInterestsScreen(viewModel: _vm),
        greenHeader: true,
      );
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _back() => VerifyEmailScreen.openFromOnboarding(context);

  void _next() {
    if (!_vm.tryStep3()) {
      AppToast.error(context, AuthStrings.fillRequiredFields);
      return;
    }
    AppNav.push(
      context,
      InvestorInterestsScreen(viewModel: _vm),
      greenHeader: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final vm = _vm;
          return FormPageScaffold(
            header: StepHeader(
              step: 3,
              total: 4,
              title: AuthStrings.investmentsTitle,
              onBack: _back,
            ),
            footer: FormFooter(
              primary: AppButton(
                label: AuthStrings.next,
                variant: vm.step3Complete
                    ? AppButtonVariant.primary
                    : AppButtonVariant.off,
                onPressed: _next,
              ),
            ),
            children: [
              AuthCard(
                child: FormFieldColumn(
                  children: [...InvestorFields.background(context, vm)],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
