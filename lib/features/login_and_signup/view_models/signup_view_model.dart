import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../app_constants/auth_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/device_services/profile_photo_picker_service.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';
import '../../../models/startup_enums.dart';
import 'signup_flow.dart';

/// Sign-up step 1, "Create your account" (docs/05 A7, docs/06 section 1).
/// Owns the field controllers, validates exactly as the design says and
/// creates the account (docs/08 section 1).
class SignupViewModel extends ChangeNotifier with SafeNotifier {
  SignupViewModel({
    required this.role,
    SignupFlow? flow,
    AuthRepository? authRepository,
    ProfilePhotoPickerService? photoPicker,
  }) : flow = flow ?? SignupFlow(role: role),
       _auth = authRepository ?? AuthRepository.instance,
       _picker = photoPicker ?? ProfilePhotoPickerService.instance {
    for (final c in _controllers) {
      c.addListener(_changed);
    }
    passwordFocus.addListener(_passwordFocusChanged);
    this.flow
      ..role = role
      ..form = this;
  }

  /// All 25 sector chips, "Other" last.
  static final List<String> sectorOptions = [
    for (final s in Sector.values) s.label,
  ];

  static const otherLabel = 'Other';

  final AccountRole role;
  final SignupFlow flow;
  final AuthRepository _auth;
  final ProfilePhotoPickerService _picker;

  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final linkedin = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final value = TextEditingController();
  final gain = TextEditingController();
  final bio = TextEditingController();
  final sectorsOther = TextEditingController();

  late final List<TextEditingController> _controllers = [
    name,
    email,
    phone,
    linkedin,
    password,
    confirm,
    value,
    gain,
    bio,
    sectorsOther,
  ];

  /// Focus of the password field: its rule checklist stays hidden until the
  /// user has tapped into the field once.
  final passwordFocus = FocusNode();
  bool passwordTouched = false;

  bool get showPasswordRules => passwordTouched || attempted;

  void _passwordFocusChanged() {
    if (passwordFocus.hasFocus && !passwordTouched) {
      passwordTouched = true;
      notifyListeners();
    }
  }

  String? city;
  final Set<String> sectors = {};
  File? photo;

  /// True after the first tap on Continue: every error then shows.
  bool attempted = false;
  bool isLoading = false;

  /// An error that is not about one field (network, unknown).
  String? formError;

  String? _serverEmailError;
  String _emailAtServerError = '';

  bool get isFounder => role == AccountRole.founder;

  void _changed() {
    if (_serverEmailError != null && email.text.trim() != _emailAtServerError) {
      _serverEmailError = null;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------- errors

  /// Live: shown as soon as something is typed that is not yet a first and
  /// last name; after a submit also when empty.
  String? get nameError =>
      Validators.fullNameLive(name.text) ??
      (attempted ? Validators.fullName(name.text) : null);

  /// Live once something is typed; after a submit also when empty.
  String? get emailError {
    if (_serverEmailError != null) return _serverEmailError;
    final v = email.text.trim();
    if (v.isEmpty) return attempted ? ValidationStrings.emailLive : null;
    return Validators.isEmail(v) ? null : ValidationStrings.emailLive;
  }

  String? get phoneError =>
      Validators.phoneLive(phone.text) ??
      (attempted ? Validators.phone(phone.text) : null);

  String? get linkedinError => Validators.linkedinLive(linkedin.text);

  /// "Passwords don’t match", live once the confirmation has text.
  String? get confirmError {
    if (confirm.text.isEmpty && !attempted) return null;
    return confirm.text == password.text
        ? null
        : ValidationStrings.confirmMismatch;
  }

  String? get cityError => attempted ? Validators.city(city) : null;

  String? get sectorsError =>
      attempted && isFounder ? Validators.sectors(sectors) : null;

  String? get sectorsOtherError =>
      attempted &&
          isFounder &&
          sectors.contains(otherLabel) &&
          !Validators.isOtherText(sectorsOther.text)
      ? ValidationStrings.otherChips(AuthStrings.nounSector)
      : null;

  /// "What value can you bring to startups?" (investors): required.
  String? get valueError => attempted && !isFounder
      ? Validators.requiredText(value.text, ValidationStrings.bringRequired)
      : null;

  String? get gainError => attempted && !isFounder
      ? Validators.requiredText(gain.text, ValidationStrings.gainRequired)
      : null;

  bool get isValid {
    final founderOk =
        sectors.isNotEmpty &&
        (!sectors.contains(otherLabel) ||
            Validators.isOtherText(sectorsOther.text));
    return Validators.isFullName(name.text) &&
        Validators.isEmail(email.text) &&
        Validators.isPhone(phone.text) &&
        Validators.isLinkedin(linkedin.text) &&
        Validators.isPassword(password.text) &&
        Validators.confirmMatches(password.text, confirm.text) &&
        (city ?? '').trim().isNotEmpty &&
        (isFounder
            ? founderOk
            : gain.text.trim().isNotEmpty && value.text.trim().isNotEmpty);
  }

  bool get nameValid => Validators.isFullName(name.text);
  bool get emailValid => Validators.isEmail(email.text);
  bool get phoneValid => Validators.isPhone(phone.text);
  bool get linkedinValid =>
      linkedin.text.trim().isNotEmpty && Validators.isLinkedin(linkedin.text);
  bool get passwordValid => Validators.isPassword(password.text);
  bool get confirmValid =>
      Validators.confirmMatches(password.text, confirm.text);

  // ------------------------------------------------------------ editing

  void setCity(String value) {
    city = value;
    notifyListeners();
  }

  void toggleSector(String label) {
    if (!sectors.remove(label)) sectors.add(label);
    notifyListeners();
  }

  /// Taps on the photo picker: removes the photo when there is one, else
  /// picks and crops a square photo. Returns the toast to show, or null.
  Future<String?> togglePhoto() async {
    if (photo != null) {
      photo = null;
      notifyListeners();
      return AuthStrings.photoRemoved;
    }
    try {
      final file = await _picker.pickSquarePhoto();
      if (file == null) return null;
      photo = file;
      notifyListeners();
      return AuthStrings.photoAdded;
    } on ProfilePhotoException catch (e) {
      return e.failure == ProfilePhotoFailure.tooLarge
          ? AccountStrings.photoTooLarge
          : AccountStrings.photoFailed;
    } catch (_) {
      return AccountStrings.photoFailed;
    }
  }

  // ------------------------------------------------------------- submit

  /// Validates, then creates the account. Returns true when the user may
  /// move on to the Verify step. When false, [isValid] / [formError] tell
  /// the screen which toast to show.
  Future<bool> submit() async {
    if (isLoading) return false;
    attempted = true;
    formError = null;
    if (!isValid) {
      notifyListeners();
      return false;
    }

    final mail = email.text.trim();
    final pw = password.text;
    isLoading = true;
    notifyListeners();
    try {
      if (flow.accountCreated) {
        final same =
            flow.email.toLowerCase() == mail.toLowerCase() &&
            flow.password == pw &&
            flow.createdRole == role;
        // Back to step 1 and Continue again: never create a second account.
        if (same) return true;
        // Changed email / password / role: remove the unverified account.
        try {
          await _auth.discardUnverifiedAccount(flow.email, flow.password);
        } on AuthException catch (e) {
          // The old account may already be verified or gone: carry on and
          // create the new one. Only a network problem stops here.
          if (e.failure == AuthFailure.network) rethrow;
        }
        flow.accountCreated = false;
      }
      final other = sectors.contains(otherLabel)
          ? sectorsOther.text.trim()
          : null;
      Future<SignupResult> create() => _auth.signUp(
        fullName: name.text.trim(),
        email: mail,
        password: pw,
        role: role,
        phone: Validators.phoneDigits(phone.text),
        city: city,
        bio: bio.text.trim(),
        sectorsOfInterest: isFounder ? sectors.toList() : const [],
        sectorsOther: other,
        linkedin: linkedin.text.trim(),
        gain: isFounder ? null : gain.text.trim(),
        valueOffered: isFounder ? null : value.text.trim(),
        photo: photo,
      );
      // An earlier attempt that was never verified (the app was closed or
      // refreshed) left an unverified account behind. With the same password
      // it is removed and the sign-up starts fresh, so the user is not locked
      // out of their own email. A verified account is never touched.
      SignupResult result;
      try {
        result = await create();
      } on AuthException catch (e) {
        if (e.failure != AuthFailure.emailInUse) rethrow;
        try {
          await _auth.discardUnverifiedAccount(mail, pw);
        } on AuthException catch (d) {
          if (d.failure == AuthFailure.network) rethrow;
          throw e; // verified, or another password: really "in use".
        }
        result = await create();
      }
      flow
        ..email = mail
        ..password = pw
        ..emailSent = result.verificationEmailSent
        ..createdRole = role
        ..accountCreated = true;
      return true;
    } on AuthException catch (e) {
      _showFailure(e.failure, mail);
    } catch (_) {
      formError = AppStrings.genericError;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  void _showFailure(AuthFailure failure, String mail) {
    switch (failure) {
      case AuthFailure.emailInUse:
        _serverEmailError = AppStrings.emailInUse;
        _emailAtServerError = mail;
      case AuthFailure.invalidEmail:
        _serverEmailError = ValidationStrings.emailInvalid;
        _emailAtServerError = mail;
      case AuthFailure.weakPassword:
        formError = AppStrings.weakPassword;
      case AuthFailure.profileSaveFailed:
        formError = AppStrings.profileSaveFailed;
      case AuthFailure.network:
        formError = AppStrings.networkError;
      case AuthFailure.tooManyRequests:
        formError = AppStrings.tooManyRequests;
      default:
        formError = AppStrings.genericError;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(_changed);
      c.dispose();
    }
    passwordFocus
      ..removeListener(_passwordFocusChanged)
      ..dispose();
    if (flow.form == this) flow.form = null;
    super.dispose();
  }
}
