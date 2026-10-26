import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/auth_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../helpers/emoji_filter.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/app_text_field.dart';
import '../../../shared_ui/widgets/forms/form_page.dart';
import '../../../shared_ui/widgets/forms/password_rules.dart';
import '../../../shared_ui/widgets/forms/photo_pickers.dart';
import '../../../shared_ui/widgets/forms/select_field.dart';
import '../../../shared_ui/widgets/forms/visibility_pill.dart';
import '../../../shared_ui/widgets/headers/auth_headers.dart';
import '../../../shared_ui/widgets/headers/overlap_layout.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../../../shared_ui/widgets/overlays/multi_picker_sheet.dart';
import '../../../shared_ui/widgets/overlays/picker_sheet.dart';
import '../../startups/widgets/invitation_dialogs.dart';
import '../view_models/signup_flow.dart';
import '../view_models/signup_view_model.dart';
import '../widgets/auth_navigation.dart';
import '../widgets/phone_formatter.dart';
import 'verify_email_screen.dart';

/// Sign-up step 1, "Create your account" (docs/05 A7), for [role]. Founders
/// also pick their sectors; investors say what they hope to gain.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.role, this.flow, this.email});

  /// An e-mail to start with (the one an invitation was sent to).
  final String? email;

  final AccountRole role;

  /// The sign-up in progress (kept so a second visit never creates a second
  /// account). Null starts or continues [SignupFlow.current].
  final SignupFlow? flow;

  /// Pushes the step-1 form for [role] (Choose role -> Continue).
  static void open(BuildContext context, AccountRole role, {String? email}) {
    final flow = SignupFlow.current ?? SignupFlow(role: role);
    // A sign-up that starts from an invitation has two steps only.
    if (email != null) flow.fromInvite = true;
    SignupFlow.current = flow;
    AppNav.push(
      context,
      SignupScreen(role: role, flow: flow, email: email),
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
    final start = widget.email;
    if (start != null && _vm.email.text.trim().isEmpty) _vm.email.text = start;
  }

  @override
  void dispose() {
    if (_ownsVm) _vm.dispose();
    super.dispose();
  }

  /// Picks (or changes) the photo. Only an error shows a toast.
  Future<void> _pickPhoto() async {
    final message = await _vm.pickPhoto();
    if (!mounted || message == null) return;
    AppToast.error(context, message);
  }

  Future<void> _pickSectors() async {
    FocusScope.of(context).unfocus();
    await showMultiPickerSheet(
      context,
      title: AuthStrings.sectorsSheetTitle,
      options: SignupViewModel.sectorOptions,
      selected: _vm.sectors,
      onToggle: _vm.toggleSector,
      searchHint: AuthStrings.sectorsSearch,
      noResultsText: AuthStrings.sectorsNone,
      otherLabel: SignupViewModel.otherLabel,
      otherNoun: AuthStrings.nounSector,
      otherHint: AuthStrings.sectorOtherHint,
      otherText: _vm.sectorsOther.text,
      onOtherChanged: (v) => _vm.sectorsOther.text = v,
      onUndoOther: () => _vm.toggleSector(SignupViewModel.otherLabel),
    );
  }

  /// Back arrow / system back. Anyone who typed or picked anything is asked
  /// first; Discard clears the form.
  Future<void> _back() async {
    if (_vm.hasInput) {
      final discard = await showDiscardDialog(
        context,
        title: AuthStrings.discardSignupTitle,
        message: AuthStrings.discardSignupMessage,
        discardLabel: AuthStrings.discard,
      );
      if (!mounted || !discard) return;
      _vm.reset();
      // A plain pop: this screen's back guard would otherwise still see the
      // form as filled (it only rebuilds on the next frame) and ask again.
      authLeave(context);
      return;
    }
    authBack(context);
  }

  /// The picked sectors in list order, "Other" shown as what was typed.
  String _sectorsText() {
    final other = _vm.sectorsOther.text.trim();
    return [
      for (final o in SignupViewModel.sectorOptions)
        if (_vm.sectors.contains(o))
          if (o != SignupViewModel.otherLabel)
            o
          else if (other.isNotEmpty)
            other,
    ].join(', ');
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

  /// An investor whose e-mail was invited to a team is asked first: the role
  /// can't be changed after sign-up.
  Future<bool> _confirmInvestor() async {
    final names = await _vm.invitedTeams();
    if (!mounted) return false;
    if (names.isEmpty) return true;
    final join = await showInvitedInvestorDialog(context, names);
    if (!mounted || join == null) return false;
    if (join) {
      // Back to the form as a founder: the invitation adds them to the team.
      final flow = SignupFlow(role: AccountRole.founder);
      SignupFlow.current = flow;
      Navigator.of(context).pushReplacement(
        AppRoute<void>(
          builder: (_) => SignupScreen(role: AccountRole.founder, flow: flow),
          greenHeader: true,
        ),
      );
      return false;
    }
    _vm.confirmInvestorEmail();
    return true;
  }

  Future<void> _submit() async {
    if (!await _confirmInvestor()) return;
    final ok = await _vm.submit();
    if (!mounted) return;
    if (ok) {
      VerifyEmailScreen.open(context, _vm.flow);
      return;
    }
    final error = _vm.formError;
    // A mistake in a field (or a failure such as no internet): the pop-up
    // says so and the user cannot continue.
    AppToast.error(context, error ?? ValidationStrings.fixFields);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final vm = _vm;
        final founder = vm.isFounder;
        return PopScope(
          // Anything typed or picked is asked about before leaving (also for
          // the system back button).
          canPop: !vm.hasInput,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: FormPageScaffold(
            header: StepHeader(
              step: 1,
              total: vm.flow.totalSteps,
              title: AuthStrings.createAccountTitle,
              onBack: _back,
            ),
            footer: FormFooter(
              primary: AppButton(
                label: AuthStrings.continueLabel,
                onPressed: _submit,
                loading: vm.isLoading,
              ),
              // The sign-up has no "Already have an account?" line.
            ),
            children: [
              AuthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfilePhotoRow(
                      onTap: _pickPhoto,
                      image: vm.photo == null ? null : FileImage(vm.photo!),
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
                          inputFormatters: founder
                              ? null
                              : const [NoEmojiFormatter()],
                          autofillHints: const [AutofillHints.name],
                        ),
                        // The bio sits right under the full name for both roles
                        // and is required (the investor's has no emoji).
                        LabeledTextField(
                          label: AuthStrings.bio,
                          required: true,
                          controller: vm.bio,
                          placeholder: AuthStrings.bioPlaceholder,
                          maxLength: vm.bioMax,
                          multiline: true,
                          inputFormatters: founder
                              ? null
                              : const [NoEmojiFormatter()],
                          error: vm.bioError,
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
                          labelTrailing: VisibilityPill(
                            isPublic: vm.emailPublic,
                            onChanged: vm.setEmailPublic,
                            fieldName: 'email',
                          ),
                          autofillHints: const [AutofillHints.email],
                        ),
                        AppField(
                          label: AuthStrings.phone,
                          required: true,
                          labelTrailing: VisibilityPill(
                            isPublic: vm.phonePublic,
                            onChanged: vm.setPhonePublic,
                            fieldName: 'phone',
                          ),
                          error: vm.phoneError,
                          child: AppTextField(
                            controller: vm.phone,
                            hint: AuthStrings.phonePlaceholder,
                            semanticLabel: AuthStrings.phone,
                            prefix: AuthStrings.phonePrefix,
                            counterMax: Validators.phoneLength,
                            counterOf: (t) => Validators.phoneDigits(t).length,
                            warnLow: false,
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
                          inputFormatters: founder
                              ? null
                              : const [NoEmojiFormatter()],
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
                          // A space is never part of a password.
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          ],
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
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          ],
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
                          AppField(
                            label: AuthStrings.sectorsQuestion,
                            required: true,
                            error: vm.sectorsError ?? vm.sectorsOtherError,
                            child: SelectField(
                              placeholder: AuthStrings.sectorsPlaceholder,
                              value: _sectorsText(),
                              semanticLabel: AuthStrings.sectorsQuestion,
                              hasError:
                                  vm.sectorsError != null ||
                                  vm.sectorsOtherError != null,
                              onTap: _pickSectors,
                            ),
                          )
                        else ...[
                          LabeledTextField(
                            label: AuthStrings.valueQuestion,
                            required: true,
                            controller: vm.value,
                            placeholder: AuthStrings.valuePlaceholder,
                            maxLength: Validators.maxValueText,
                            multiline: true,
                            info: AuthStrings.valueTip,
                            inputFormatters: const [NoEmojiFormatter()],
                            error: vm.valueError,
                          ),
                          LabeledTextField(
                            label: AuthStrings.gainQuestion,
                            required: true,
                            controller: vm.gain,
                            placeholder: AuthStrings.gainPlaceholder,
                            maxLength: Validators.maxValueText,
                            multiline: true,
                            info: AuthStrings.gainTip,
                            inputFormatters: const [NoEmojiFormatter()],
                            error: vm.gainError,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
