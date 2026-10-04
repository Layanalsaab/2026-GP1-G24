import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../models/app_user.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/common_widgets/selection_chip.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/founder_onboarding_view_model.dart';

/// Figma: "V2 · 06 · Onboarding — Founder". Shown once, right after a founder's
/// first log in; their answers are saved to their profile.
class FounderOnboardingScreen extends StatefulWidget {
  const FounderOnboardingScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<FounderOnboardingScreen> createState() =>
      _FounderOnboardingScreenState();
}

class _FounderOnboardingScreenState extends State<FounderOnboardingScreen> {
  late final FounderOnboardingViewModel _viewModel =
      FounderOnboardingViewModel(userId: widget.user.uid);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final saved = await _viewModel.submit();
    if (!saved || !mounted) return;
    // Pass the chosen city along so the Account tab shows it straight away.
    AppRouter.openHome(
      context,
      widget.user.copyWith(onboardingCompleted: true, city: _viewModel.city),
    );
  }

  Widget _group(
    List<String> options,
    String? selected,
    ValueChanged<String> onSelect,
  ) =>
      SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              SelectionChip(
                label: option,
                selected: option == selected,
                onTap: () => onSelect(option),
              ),
          ],
        ),
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: AppText.sans(
          size: 16,
          color: AppColors.ink,
          weight: FontWeight.w600,
          height: 24,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return FormPageScaffold(
          progressSteps: 3,
          contentTopPadding: 8,
          // This is the first screen after log in, so "back" means log out.
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
              Text(
                AppStrings.onboardingSectorTitle,
                style: AppText.serif(size: 22, color: AppColors.ink, height: 28),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.onboardingSectorHint,
                style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
              ),
              const SizedBox(height: 20),
              _group(AppStrings.sectors, _viewModel.sector, _viewModel.selectSector),
              const SizedBox(height: 20),
              _sectionTitle(AppStrings.onboardingStageTitle),
              const SizedBox(height: 20),
              _group(AppStrings.stages, _viewModel.stage, _viewModel.selectStage),
              const SizedBox(height: 20),
              _sectionTitle(AppStrings.onboardingCityTitle),
              const SizedBox(height: 20),
              _group(AppStrings.cities, _viewModel.city, _viewModel.selectCity),
            ],
          ),
        );
      },
    );
  }
}
