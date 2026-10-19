import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../models/app_user.dart';
import '../../../models/investor_criteria.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/chips/chip_group.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/form_page.dart';
import '../../../shared_ui/widgets/forms/money_field.dart';
import '../../../shared_ui/widgets/headers/auth_headers.dart';
import '../../../shared_ui/widgets/headers/overlap_layout.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../view_models/investor_onboarding_view_model.dart';
import 'investor_interests_screen.dart';
import 'verify_email_screen.dart';

/// Investor step 3 of 4, "Your investments" (docs/05 A10). Next is grey until
/// the required answers are given; tapping it early shows the errors and the
/// toast "Please fill in the required fields". Back goes to the Verify step.
class InvestorInvestmentsScreen extends StatefulWidget {
  const InvestorInvestmentsScreen({super.key, required this.user});

  /// The investor who just verified their email.
  final AppUser user;

  /// Replaces the stack with step 3 (forward transition) after the Verify step.
  static void open(BuildContext context, AppUser user) => AppNav.reset(
    context,
    InvestorInvestmentsScreen(user: user),
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
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _back() => VerifyEmailScreen.openFromOnboarding(context);

  void _next() {
    if (!_vm.tryStep3()) {
      AppToast.show(context, ValidationStrings.fillRequired);
      return;
    }
    AppNav.push(
      context,
      InvestorInterestsScreen(viewModel: _vm),
      greenHeader: true,
    );
  }

  List<String> _one(String? value) => value == null ? const [] : [value];

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
                  children: [
                    ChipGroupField(
                      label: AuthStrings.dealsQuestion,
                      required: true,
                      options: InvestorCriteria.dealsOptions,
                      selected: _one(vm.deals),
                      onTap: vm.pickDeals,
                      error: vm.dealsError,
                    ),
                    ChipGroupField(
                      label: AuthStrings.ledQuestion,
                      required: true,
                      info: AuthStrings.ledTip,
                      options: const ['Yes', 'No'],
                      selected: _one(
                        vm.hasLedRound == null
                            ? null
                            : (vm.hasLedRound! ? 'Yes' : 'No'),
                      ),
                      onTap: vm.pickLed,
                      error: vm.ledError,
                    ),
                    if (vm.hasLedRound == true)
                      ChipGroupField(
                        label: AuthStrings.roundsLedQuestion,
                        options: InvestorCriteria.roundsLedOptions,
                        selected: _one(vm.roundsLed),
                        onTap: vm.pickRoundsLed,
                      ),
                    ChipGroupField(
                      label: AuthStrings.coInvestQuestion,
                      required: true,
                      options: InvestorCriteria.coInvestOptions,
                      selected: _one(vm.coInvest),
                      onTap: vm.pickCoInvest,
                      error: vm.coInvestError,
                    ),
                    ChipGroupField(
                      label: AuthStrings.ticketQuestion,
                      required: true,
                      options: InvestorCriteria.ticketOptions,
                      selected: _one(vm.ticketBand),
                      onTap: vm.pickTicket,
                      error: vm.ticketError,
                      otherController: vm.ticketOther,
                      otherHint: AuthStrings.ticketOtherHint,
                      otherError: vm.ticketOtherError,
                    ),
                    AppField(
                      label: AuthStrings.roundSizesQuestion,
                      hint: AuthStrings.amountsInSar,
                      error: vm.rangeError,
                      child: TrioField(
                        entries: [
                          TrioEntry(
                            label: AuthStrings.minimum,
                            controller: vm.roundMin,
                            hasError: vm.rangeBad,
                          ),
                          TrioEntry(
                            label: AuthStrings.maximum,
                            controller: vm.roundMax,
                            hasError: vm.rangeBad,
                          ),
                        ],
                      ),
                    ),
                  ],
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
