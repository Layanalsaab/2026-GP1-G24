import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../helpers/app_session.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/form_page.dart';
import '../../../shared_ui/widgets/headers/auth_headers.dart';
import '../../../shared_ui/widgets/headers/overlap_layout.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../view_models/investor_onboarding_view_model.dart';
import '../view_models/signup_flow.dart';
import '../widgets/investor_fields.dart';
import '../widgets/auth_navigation.dart';

/// /// Investor step 4 of 4, "Investment Interests". Finish saves every answer,
/// clears the pending-onboarding state and opens the Hub.
class InvestorInterestsScreen extends StatelessWidget {
  const InvestorInterestsScreen({super.key, required this.viewModel});

  final InvestorOnboardingViewModel viewModel;

  Future<void> _finish(BuildContext context) async {
    final updated = await viewModel.finish();
    if (!context.mounted) return;
    if (updated != null) {
      AppSession.instance.updateUser(updated);
      SignupFlow.current = null;
      AppRouter.openHome(context);
    } else if (!viewModel.step4Complete) {
      AppToast.error(context, AuthStrings.fillRequiredFields);
    } else if (viewModel.formError != null) {
      AppToast.error(context, viewModel.formError!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        return FormPageScaffold(
          header: StepHeader(
            step: 4,
            total: 4,
            title: AuthStrings.interestsTitle,
            onBack: () => authBack(context),
          ),
          footer: FormFooter(
            primary: AppButton(
              label: AuthStrings.finish,
              variant: vm.step4Complete
                  ? AppButtonVariant.primary
                  : AppButtonVariant.off,
              loading: vm.isSaving,
              onPressed: () => _finish(context),
            ),
          ),
          children: [
            AuthCard(
              child: FormFieldColumn(
                children: [...InvestorFields.interests(context, vm)],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
