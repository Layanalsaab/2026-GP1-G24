import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/app_strings.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/signup_view_model.dart';
import 'login_screen.dart';

/// Figma: "V2 · 04 · Create Account"
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.role});

  final AccountRole role;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _viewModel = SignupViewModel();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _bio = TextEditingController();
  final _otherSector = TextEditingController();

  String? _city;
  final _sectors = <String>[];
  bool _otherSelected = false;

  @override
  void dispose() {
    _viewModel.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _bio.dispose();
    _otherSector.dispose();
    super.dispose();
  }

  /// The chosen sectors, including the typed "Other" one.
  List<String> get _allSectors {
    final other = _otherSector.text.trim();
    return [
      ..._sectors,
      if (_otherSelected && other.isNotEmpty) other,
    ];
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final result = await _viewModel.submit(
      fullName: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
      confirmPassword: _confirm.text,
      city: _city,
      sectors: _allSectors,
      role: widget.role,
    );
    if (result == null || !mounted) return;

    // Go to Log in with the new account filled in; it opens the "Verify your
    // email" pop-up. The history is cleared down to the Start screen so Back
    // can't return to the form.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          initialEmail: _email.text.trim(),
          initialPassword: _password.text,
          verifyEmail: true,
          verificationEmailSent: result.verificationEmailSent,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  /// A server or submit error is only shown when every live rule is met;
  /// otherwise the checklist already explains what is wrong.
  String? _errorFor(String? error, List<FieldRule> rules) =>
      rules.every((r) => r.met) ? error : null;

  Future<void> _pickCity() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x730F1A12),
      builder: (_) => _CitySheet(selected: _city),
    );
    if (picked == null) return;
    setState(() => _city = picked);
    _viewModel.clearError(SignupField.city);
  }

  void _toggleSector(String sector) {
    setState(() {
      _sectors.contains(sector) ? _sectors.remove(sector) : _sectors.add(sector);
    });
    _viewModel.clearError(SignupField.sectors);
  }

  void _toggleOther() {
    setState(() {
      _otherSelected = !_otherSelected;
      if (!_otherSelected) _otherSector.clear();
    });
    _viewModel.clearError(SignupField.sectors);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _viewModel,
        _name,
        _email,
        _phone,
        _password,
        _confirm,
        _otherSector,
      ]),
      builder: (context, _) {
        final loading = _viewModel.isLoading;
        final attempted = _viewModel.attempted;

        final nameRules = Validators.fullNameRules(_name.text);
        final emailRules = Validators.emailRules(_email.text);
        final phoneRules = Validators.phoneRules(_phone.text);
        final passwordRules = Validators.passwordRules(_password.text);
        final confirmRules =
            Validators.confirmPasswordRules(_password.text, _confirm.text);

        return FormPageScaffold(
          contentTopPadding: 12,
          bottomTopPadding: 16,
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_viewModel.formError != null) ...[
                FormMessage.error(_viewModel.formError!),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                label: AppStrings.signupButton,
                isLoading: loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: loading
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: Text.rich(
                      TextSpan(
                        text: '${AppStrings.signupHaveAccount} ',
                        style: AppText.sans(
                          size: 14,
                          color: AppColors.grey,
                          height: 20,
                        ),
                        children: [
                          TextSpan(
                            text: AppStrings.loginButton,
                            style: AppText.sans(
                              size: 14,
                              color: AppColors.moss600,
                              weight: FontWeight.w600,
                              height: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.signupTitle,
                style: AppText.sans(
                  size: 22,
                  color: AppColors.ink,
                  weight: FontWeight.w600,
                  height: 28,
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.fullNameLabel,
                hint: AppStrings.fullNameHint,
                controller: _name,
                rules: nameRules,
                showRules: attempted,
                errorText: _errorFor(_viewModel.fullNameError, nameRules),
                maxLength: Validators.maxFullNameLength,
                enabled: !loading,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _viewModel.clearError(SignupField.fullName),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.emailLabel,
                hint: AppStrings.emailHint,
                controller: _email,
                rules: emailRules,
                showRules: attempted,
                errorText: _errorFor(_viewModel.emailError, emailRules),
                maxLength: Validators.maxEmailLength,
                enabled: !loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                onChanged: (_) => _viewModel.clearError(SignupField.email),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.phoneLabel,
                hint: AppStrings.phoneHint,
                controller: _phone,
                rules: phoneRules,
                showRules: attempted,
                errorText: _errorFor(_viewModel.phoneError, phoneRules),
                maxLength: Validators.phoneLength,
                enabled: !loading,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefix: const _PhonePrefix(),
                onChanged: (_) => _viewModel.clearError(SignupField.phone),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.passwordLabel,
                hint: AppStrings.passwordHint,
                controller: _password,
                rules: passwordRules,
                showRules: attempted,
                errorText: _errorFor(_viewModel.passwordError, passwordRules),
                maxLength: Validators.maxPasswordLength,
                enabled: !loading,
                obscureText: true,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _viewModel.clearError(SignupField.password),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.confirmPasswordLabel,
                hint: AppStrings.confirmPasswordHint,
                controller: _confirm,
                rules: confirmRules,
                showRules: attempted,
                errorText:
                    _errorFor(_viewModel.confirmPasswordError, confirmRules),
                enabled: !loading,
                obscureText: true,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(Validators.maxPasswordLength),
                ],
                onChanged: (_) =>
                    _viewModel.clearError(SignupField.confirmPassword),
              ),
              const SizedBox(height: 20),
              _CityField(
                city: _city,
                error: _viewModel.cityError,
                enabled: !loading,
                onTap: _pickCity,
              ),
              const SizedBox(height: 20),
              _SectorsField(
                selected: _sectors,
                otherSelected: _otherSelected,
                otherController: _otherSector,
                count: _allSectors.length,
                error: _viewModel.sectorsError,
                enabled: !loading,
                onToggle: _toggleSector,
                onToggleOther: _toggleOther,
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.bioLabel,
                hint: AppStrings.bioHint,
                controller: _bio,
                optional: true,
                maxLines: 4,
                maxLength: Validators.maxBioLength,
                enabled: !loading,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "+966 |" before the phone digits.
class _PhonePrefix extends StatelessWidget {
  const _PhonePrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.phoneCountryCode,
            style: AppText.sans(
              size: 16,
              color: AppColors.ink,
              weight: FontWeight.w500,
              height: 24,
            ),
          ),
          const SizedBox(width: 6),
          Container(width: 1, height: 24, color: AppColors.border),
        ],
      ),
    );
  }
}

/// Figma "City dropdown": a tall bottom sheet with a search field and the
/// full list of cities. Pops with the chosen city.
class _CitySheet extends StatefulWidget {
  const _CitySheet({required this.selected});

  final String? selected;

  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final query = _search.text.trim().toLowerCase();
    final cities = [
      for (final city in AppStrings.allCities)
        if (city.toLowerCase().contains(query)) city,
    ];
    // Tall like the design, but never taller than the space above the keyboard.
    final height = (media.size.height * 0.88)
        .clamp(0.0, media.size.height - media.viewInsets.bottom - 48);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.citySheetTitle,
                    style: AppText.sans(
                      size: 20,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                cursorColor: AppColors.moss600,
                style: AppText.sans(size: 15, color: AppColors.ink),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.cream,
                  hintText: AppStrings.citySearchHint,
                  hintStyle: AppText.sans(size: 15, color: AppColors.grey),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.ink,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 44),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.moss600,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: cities.isEmpty
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          AppStrings.cityNoResults,
                          style: AppText.sans(size: 15, color: AppColors.grey),
                        ),
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: math.max(24, media.padding.bottom),
                        ),
                        itemCount: cities.length,
                        itemBuilder: (context, i) => _CityRow(
                          city: cities[i],
                          selected: cities[i] == widget.selected,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({required this.city, required this.selected});

  final String city;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: city,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).pop(city),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.moss100 : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  city,
                  style: AppText.sans(
                    size: 15,
                    color: selected ? AppColors.moss600 : AppColors.ink,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, size: 18, color: AppColors.moss600),
            ],
          ),
        ),
      ),
    );
  }
}

/// Looks like a text field; tapping it opens the city list.
class _CityField extends StatelessWidget {
  const _CityField({
    required this.city,
    required this.error,
    required this.enabled,
    required this.onTap,
  });

  final String? city;
  final String? error;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final chosen = city != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.cityLabel,
          style: AppText.sans(
            size: 14,
            color: hasError ? AppColors.error : AppColors.ink,
            weight: FontWeight.w500,
            height: 20,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: '${AppStrings.cityLabel} ${city ?? AppStrings.cityHint}',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onTap : null,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: hasError
                      ? AppColors.error
                      : chosen
                          ? AppColors.moss600
                          : AppColors.borderStrong,
                  width: hasError ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      city ?? AppStrings.cityHint,
                      style: AppText.sans(
                        size: 16,
                        color: chosen ? AppColors.ink : AppColors.grey,
                        height: 24,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 22,
                    color: AppColors.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          FormMessage.error(error!),
        ],
      ],
    );
  }
}

/// Multi-select sector chips, with an "Other" chip you can type into.
class _SectorsField extends StatelessWidget {
  const _SectorsField({
    required this.selected,
    required this.otherSelected,
    required this.otherController,
    required this.count,
    required this.error,
    required this.enabled,
    required this.onToggle,
    required this.onToggleOther,
  });

  final List<String> selected;
  final bool otherSelected;
  final TextEditingController otherController;
  final int count;
  final String? error;
  final bool enabled;
  final ValueChanged<String> onToggle;
  final VoidCallback onToggleOther;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.sectorsLabel,
          style: AppText.sans(
            size: 14,
            color: hasError ? AppColors.error : AppColors.ink,
            weight: FontWeight.w500,
            height: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.sectorsHint,
          style: AppText.sans(size: 12, color: AppColors.grey, height: 16),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final sector in AppStrings.sectors)
              _SectorChip(
                label: sector,
                selected: selected.contains(sector),
                onTap: enabled ? () => onToggle(sector) : null,
              ),
            if (otherSelected)
              _OtherChip(
                controller: otherController,
                onClear: enabled ? onToggleOther : null,
              )
            else
              _SectorChip(
                label: AppStrings.otherSector,
                selected: false,
                onTap: enabled ? onToggleOther : null,
              ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          FormMessage.error(error!),
        ] else if (count > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.check, size: 16, color: AppColors.moss600),
              const SizedBox(width: 6),
              Text(
                AppStrings.sectorsSelected(count),
                style: AppText.sans(
                  size: 12,
                  color: AppColors.moss600,
                  height: 16,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectorChip extends StatelessWidget {
  const _SectorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // The padding keeps the tap target at least 44 high; the visible chip
        // stays the size in the design.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.moss600 : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? AppColors.moss600 : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check, size: 12, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppText.sans(
                    size: 13,
                    color: selected ? Colors.white : AppColors.ink,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The selected "Other:" chip: a small text field plus a clear button.
class _OtherChip extends StatelessWidget {
  const _OtherChip({required this.controller, required this.onClear});

  final TextEditingController controller;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.moss600, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 12, color: AppColors.moss600),
            const SizedBox(width: 4),
            Text(
              '${AppStrings.otherSector}:',
              style: AppText.sans(
                size: 13,
                color: AppColors.moss600,
                weight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 112,
              child: TextField(
                controller: controller,
                autofocus: true,
                maxLength: 30,
                cursorColor: AppColors.moss600,
                textInputAction: TextInputAction.done,
                style: AppText.sans(size: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  hintText: AppStrings.otherSectorHint,
                  hintStyle: AppText.sans(size: 13, color: AppColors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 14, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
