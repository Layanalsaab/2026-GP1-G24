import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/investor_strings.dart';
import '../../../models/app_user.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/investor_onboarding_view_model.dart';
import 'investment_criteria_fields.dart';

/// Figma: "V2 · 07 · Onboarding — Investor" (PBI 21). Shown once, right after
/// an investor's first log in, laid out like the founder onboarding. Their
/// answers are saved to their profile and used for matching.
class InvestorOnboardingScreen extends StatefulWidget {
  const InvestorOnboardingScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<InvestorOnboardingScreen> createState() =>
      _InvestorOnboardingScreenState();
}

class _InvestorOnboardingScreenState extends State<InvestorOnboardingScreen> {
  late final InvestorOnboardingViewModel _viewModel =
      InvestorOnboardingViewModel(
    userId: widget.user.uid,
    // Keep a city they already saved (only if it's one of the options).
    city: AppStrings.cities.contains(widget.user.city) ? widget.user.city : null,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final saved = await _viewModel.submit();
    if (!saved || !mounted) return;
    AppRouter.openHome(context, _viewModel.savedUser(widget.user));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return FormPageScaffold(
          progressSteps: 3,
          contentTopPadding: 8,
          // This is the first screen after log in, so "back" means log out
          // (the same as the founder onboarding).
          onBack: () => AppRouter.logOut(context),
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_viewModel.error != null) ...[
                FormMessage.error(_viewModel.error!),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                label: AppStrings.onboardingContinue,
                isLoading: _viewModel.isLoading,
                onPressed: _continue,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InvestmentCriteriaFields(
                form: _viewModel,
                sectorsHeading: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      InvestorStrings.sectorsTitle,
                      style: AppText.serif(
                        size: 22,
                        color: AppColors.ink,
                        height: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      InvestorStrings.onboardingHint,
                      style: AppText.sans(
                        size: 14,
                        color: AppColors.grey,
                        height: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const CriteriaSectionTitle(
                title: AppStrings.onboardingCityTitle,
                hint: InvestorStrings.chooseOne,
              ),
              const SizedBox(height: 16),
              ChoiceChips(
                options: AppStrings.cities,
                isSelected: (city) => city == _viewModel.city,
                onTap: _viewModel.selectCity,
              ),
            ],
          ),
        );
      },
    );
  }
}
