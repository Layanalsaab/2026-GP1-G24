import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/common_widgets/profile_avatar.dart';
import '../../../shared_ui/common_widgets/selection_chip.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/edit_account_view_model.dart';

/// Figma: "V2 · 33 · Edit Account — All" (PBIs 10 and 12). The same screen for
/// founders and investors. On success it closes and returns the updated user.
class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  late final EditAccountViewModel _viewModel =
      EditAccountViewModel(user: widget.user);
  late final TextEditingController _fullName =
      TextEditingController(text: widget.user.fullName);
  late final TextEditingController _email =
      TextEditingController(text: widget.user.email);
  late final TextEditingController _bio =
      TextEditingController(text: widget.user.bio);

  @override
  void dispose() {
    _viewModel.dispose();
    _fullName.dispose();
    _email.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final updated = await _viewModel.submit(
      fullName: _fullName.text,
      bio: _bio.text,
    );
    if (updated == null || !mounted) return;
    Navigator.of(context).pop(updated);
  }

  Widget _label(String text) => Text(
        text,
        style: AppText.sans(
          size: 14,
          color: AppColors.ink,
          weight: FontWeight.w500,
          height: 20,
        ),
      );

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
            title: AccountStrings.editAccountTitle,
            bottom: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_viewModel.formError != null) ...[
                  FormMessage.error(_viewModel.formError!),
                  const SizedBox(height: 12),
                ],
                PrimaryButton(
                  label: AccountStrings.saveChanges,
                  isLoading: loading,
                  onPressed: _save,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: ProfileAvatar(name: widget.user.fullName, size: 80)),
                const SizedBox(height: 20),
                AppTextField(
                  label: AppStrings.fullNameLabel,
                  hint: AppStrings.fullNameHint,
                  controller: _fullName,
                  errorText: _viewModel.fullNameError,
                  enabled: !loading,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: AppStrings.emailLabel,
                  hint: AppStrings.emailHint,
                  controller: _email,
                  readOnly: true,
                ),
                const SizedBox(height: 20),
                _label(AccountStrings.cityLabel),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final city in AppStrings.cities)
                        SelectionChip(
                          label: city,
                          selected: city == _viewModel.city,
                          onTap: () => _viewModel.selectCity(city),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: AccountStrings.bioFieldLabel,
                  hint: AccountStrings.bioHint,
                  controller: _bio,
                  enabled: !loading,
                  maxLines: 4,
                  maxLength: AccountStrings.bioMaxLength,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
