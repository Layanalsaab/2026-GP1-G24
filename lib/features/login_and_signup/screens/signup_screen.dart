import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/auth_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/chips/chip_group.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/app_text_field.dart';
import '../../../shared_ui/widgets/forms/form_page.dart';
import '../../../shared_ui/widgets/forms/password_rules.dart';
import '../../../shared_ui/widgets/forms/photo_pickers.dart';
import '../../../shared_ui/widgets/forms/select_field.dart';
import '../../../shared_ui/widgets/headers/auth_headers.dart';
import '../../../shared_ui/widgets/headers/overlap_layout.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../../../shared_ui/widgets/overlays/picker_sheet.dart';
import '../view_models/signup_flow.dart';
import '../view_models/signup_view_model.dart';
import '../widgets/auth_navigation.dart';
import '../widgets/phone_formatter.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

/// Sign-up step 1, "Create your account" (docs/05 A7), for [role]. Founders
/// also pick their sectors; investors say what they hope to gain.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.role, this.flow});

  final AccountRole role;

  /// The sign-up in progress (kept so a second visit never creates a second
  /// account). Null starts or continues [SignupFlow.current].
  final SignupFlow? flow;

  /// Pushes the step-1 form for [role] (Choose role -> Continue).
  static void open(BuildContext context, AccountRole role) {
    final flow = SignupFlow.current ?? SignupFlow(role: role);
    SignupFlow.current = flow;
    AppNav.push(
      context,
      SignupScreen(role: role, flow: flow),
      greenHeader: true,
    );
  }

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final SignupViewModel _vm;
  bool _ownsVm = true;

  @override
  void initState() {
    super.initState();
    final flow =
        widget.flow ?? (SignupFlow.current ??= SignupFlow(role: widget.role));
    final existing = flow.form;
    if (existing != null && existing.role == widget.role) {
      _vm = existing;
      _ownsVm = false;
    } else {
      _vm = SignupViewModel(role: widget.role, flow: flow);
    }
  }

  @override
  void dispose() {
    if (_ownsVm) _vm.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final message = await _vm.togglePhoto();
    if (!mounted || message == null) return;
    AppToast.show(context, message);
  }

  Future<void> _pickCity() async {
    final result = await showPickerSheet(
      context,
      title: AuthStrings.citySheetTitle,
      options: AppStrings.allCities,
      selected: _vm.city,
      searchHint: AuthStrings.citySearch,
      noResultsText: AuthStrings.citiesNone,
      tall: true,
    );
    if (result != null) _vm.setCity(result.value);
  }

  Future<void> _submit() async {
    final ok = await _vm.submit();
    if (!mounted) return;
    if (ok) {
      VerifyEmailScreen.open(context, _vm.flow);
      return;
    }
    final error = _vm.formError;
    AppToast.show(context, error ?? ValidationStrings.fixFields);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final vm = _vm;
        final founder = vm.isFounder;
        return FormPageScaffold(
          header: StepHeader(
            step: 1,
            total: vm.flow.totalSteps,
            title: AuthStrings.createAccountTitle,
            onBack: () => authBack(context),
          ),
          footer: FormFooter(
            primary: AppButton(
              label: AuthStrings.continueLabel,
              onPressed: _submit,
              loading: vm.isLoading,
            ),
            link: FooterLink(
              prefix: AuthStrings.haveAccount,
              linkLabel: AuthStrings.logIn,
              onTap: () => LoginScreen.open(context),
            ),
          ),
          children: [
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PhotoPickerPlaceholder(
                    onTap: _pickPhoto,
                    hasPhoto: vm.photo != null,
                    initials: appInitials(vm.name.text),
                    image: vm.photo == null ? null : FileImage(vm.photo!),
                    label: AuthStrings.addPhoto,
                  ),
                  FormFieldColumn(
                    children: [
                      LabeledTextField(
                        label: AuthStrings.fullName,
                        required: true,
                        controller: vm.name,
                        placeholder: AuthStrings.fullNamePlaceholder,
                        maxLength: Validators.maxFullName,
                        valid: vm.nameValid,
                        error: vm.nameError,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                      ),
                      LabeledTextField(
                        label: AuthStrings.email,
                        required: true,
                        controller: vm.email,
                        placeholder: AuthStrings.emailPlaceholder,
                        maxLength: Validators.maxEmail,
                        keyboardType: TextInputType.emailAddress,
                        valid: vm.emailValid,
                        error: vm.emailError,
                        autofillHints: const [AutofillHints.email],
                      ),
                      AppField(
                        label: AuthStrings.phone,
                        required: true,
                        error: vm.phoneError,
                        counter:
                            '${Validators.phoneDigits(vm.phone.text).length}/${Validators.phoneLength}',
                        child: AppTextField(
                          controller: vm.phone,
                          hint: AuthStrings.phonePlaceholder,
                          semanticLabel: AuthStrings.phone,
                          prefix: AuthStrings.phonePrefix,
                          keyboardType: TextInputType.phone,
                          inputFormatters: const [PhoneInputFormatter()],
                          valid: vm.phoneValid,
                          hasError: vm.phoneError != null,
                          autofillHints: const [
                            AutofillHints.telephoneNumberNational,
                          ],
                        ),
                      ),
                      LabeledTextField(
                        label: AuthStrings.linkedin,
                        controller: vm.linkedin,
                        placeholder: AuthStrings.linkedinPlaceholder,
                        maxLength: Validators.maxLinkedin,
                        keyboardType: TextInputType.url,
                        valid: vm.linkedinValid,
                        error: vm.linkedinError,
                      ),
                      LabeledTextField(
                        label: AuthStrings.password,
                        required: true,
                        controller: vm.password,
                        placeholder: AuthStrings.passwordPlaceholder,
                        maxLength: Validators.maxPassword,
                        password: true,
                        valid: vm.passwordValid,
                        focusNode: vm.passwordFocus,
                        below: vm.showPasswordRules
                            ? PasswordRules(password: vm.password.text)
                            : null,
                        autofillHints: const [AutofillHints.newPassword],
                      ),
                      LabeledTextField(
                        label: AuthStrings.confirmPassword,
                        required: true,
                        controller: vm.confirm,
                        placeholder: AuthStrings.confirmPlaceholder,
                        password: true,
                        valid: vm.confirmValid,
                        error: vm.confirmError,
                      ),
                      AppField(
                        label: AuthStrings.city,
                        required: true,
                        error: vm.cityError,
                        child: SelectField(
                          placeholder: AuthStrings.cityPlaceholder,
                          value: vm.city,
                          semanticLabel: AuthStrings.city,
                          hasError: vm.cityError != null,
                          onTap: _pickCity,
                        ),
                      ),
                      if (founder)
                        ChipGroupField(
                          label: AuthStrings.sectorsQuestion,
                          required: true,
                          multi: true,
                          options: SignupViewModel.sectorOptions,
                          selected: vm.sectors,
                          onTap: vm.toggleSector,
                          error: vm.sectorsError,
                          otherController: vm.sectorsOther,
                          otherHint: AuthStrings.sectorOtherHint,
                          otherError: vm.sectorsOtherError,
                        )
                      else
                        LabeledTextField(
                          label: AuthStrings.gainQuestion,
                          required: true,
                          controller: vm.gain,
                          placeholder: AuthStrings.gainPlaceholder,
                          maxLength: Validators.maxValueText,
                          multiline: true,
                          info: AuthStrings.gainTip,
                          error: vm.gainError,
                        ),
                      LabeledTextField(
                        label: AuthStrings.bio,
                        controller: vm.bio,
                        placeholder: AuthStrings.bioPlaceholder,
                        maxLength: Validators.maxBio,
                        multiline: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
