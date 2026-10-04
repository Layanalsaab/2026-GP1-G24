import 'package:flutter/material.dart';

import '../../../app_constants/investor_strings.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/edit_criteria_view_model.dart';
import 'investment_criteria_fields.dart';

/// Edit Investment Criteria (PBI 22), opened from the criteria card on the
/// investor's Account tab. Returns the updated user when saved.
class EditCriteriaScreen extends StatefulWidget {
  const EditCriteriaScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<EditCriteriaScreen> createState() => _EditCriteriaScreenState();
}

class _EditCriteriaScreenState extends State<EditCriteriaScreen> {
  late final EditCriteriaViewModel _viewModel =
      EditCriteriaViewModel(user: widget.user);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = await _viewModel.submit();
    if (updated == null || !mounted) return;
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final loading = _viewModel.isLoading;
        // While saving, Back is blocked so the result is not lost.
        return PopScope(
          canPop: !loading,
          child: FormPageScaffold(
            title: InvestorStrings.editCriteriaTitle,
            bottom: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_viewModel.error != null) ...[
                  FormMessage.error(_viewModel.error!),
                  const SizedBox(height: 12),
                ],
                PrimaryButton(
                  label: InvestorStrings.saveCriteria,
                  isLoading: loading,
                  onPressed: _save,
                ),
              ],
            ),
            child: InvestmentCriteriaFields(
              form: _viewModel,
              sectorsHeading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    InvestorStrings.editCriteriaIntro,
                    style: AppText.sans(
                      size: 14,
                      color: AppColors.grey,
                      height: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CriteriaSectionTitle(
                    title: InvestorStrings.sectorsTitle,
                    hint: InvestorStrings.chooseOneOrMore,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
