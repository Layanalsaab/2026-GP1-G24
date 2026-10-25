import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';
import '../../../models/startup_enums.dart';

/// Logic of Edit profile (docs/05 C5, docs/06 section 7): holds the form
/// values, validates them with the shared rules and saves them.
///
/// The email is shown but cannot be changed here (changing the login email
/// needs re-authentication and a new verification email), so it is not part
/// of the form values.
class EditAccountViewModel extends ChangeNotifier with SafeNotifier {
  EditAccountViewModel({
    required this.user,
    UserRepository? userRepository,
    StartupRepository? startupRepository,
  }) : _users = userRepository ?? UserRepository.instance,
       _startups = startupRepository ?? StartupRepository.instance,
       emailPublic = user.emailPublic,
       phonePublic = user.phonePublic,
       fullName = user.fullName,
       bio = user.bio,
       phone = Validators.phoneDigits(user.phone),
       linkedin = user.linkedin ?? '',
       valueOffered = user.valueOffered,
       gain = user.gain,
       city = user.city {
    final chips = <String>[];
    var typed = (user.sectorsOther ?? '').trim();
    var other = false;
    for (final s in user.sectorsOfInterest) {
      if (s == otherLabel) {
        other = true;
      } else if (sectorOptions.contains(s)) {
        chips.add(s);
      } else if (s.trim().isNotEmpty) {
        // Older profiles stored the typed sector in the list itself.
        other = true;
        if (typed.isEmpty) typed = s.trim();
      }
    }
    sectors = chips;
    otherSelected = other;
    otherSector = typed;
  }

  /// The 25 sector chips (the last one is "Other").
  static final List<String> sectorOptions = [
    for (final s in Sector.values) s.label,
  ];
  static const otherLabel = 'Other';

  /// The profile as it was when the screen opened.
  final AppUser user;
  final UserRepository _users;
  final StartupRepository _startups;

  /// Who sees the email / phone (the Private / Public pills).
  bool emailPublic;
  bool phonePublic;

  String fullName;
  String bio;

  /// 9 digits, no spaces.
  String phone;
  String linkedin;
  String valueOffered;
  String gain;
  String? city;

  /// The selected sector chips (without "Other").
  late List<String> sectors;
  late bool otherSelected;
  late String otherSector;

  bool isLoading = false;

  /// A photo picked on this screen, uploaded on Save.
  File? newPhoto;

  /// True when the user chose to remove the saved photo; applied on Save.
  bool removePhoto = false;

  bool get hasPhoto =>
      newPhoto != null || (!removePhoto && (user.photoUrl ?? '').isNotEmpty);

  /// True after the first Save attempt: errors then update as the user types.
  bool attempted = false;

  /// Shown when saving fails for a reason that is not about one field.
  String? formError;

  List<String> get _chosen => [...sectors, if (otherSelected) otherLabel];

  // ---- Field errors (shown once a Save was attempted) ----
  String? get fullNameError =>
      Validators.fullNameLive(fullName) ??
      (attempted ? Validators.fullName(fullName) : null);
  String? get phoneError =>
      phone.isNotEmpty || attempted ? Validators.phoneEdit(phone) : null;
  String? get cityError => attempted ? Validators.city(city) : null;
  String? get sectorsError => attempted ? Validators.sectors(_chosen) : null;
  String? get otherError =>
      attempted && otherSelected && otherSector.trim().isEmpty
      ? ValidationStrings.otherSelect('sector')
      : null;

  /// A founder's bio is required (the investor's stays optional).
  String? get bioError => attempted && user.isFounder
      ? Validators.requiredText(bio, ValidationStrings.bioRequired)
      : null;
  String? get linkedinError => Validators.linkedinLive(linkedin);
  String? get valueError => attempted && user.isInvestor
      ? Validators.requiredText(valueOffered, ValidationStrings.bringRequired)
      : null;
  String? get gainError => attempted && user.isInvestor
      ? Validators.requiredText(gain, ValidationStrings.gainRequired)
      : null;

  bool get isValid =>
      Validators.fullName(fullName) == null &&
      Validators.phoneEdit(phone) == null &&
      Validators.city(city) == null &&
      Validators.sectors(_chosen) == null &&
      !(otherSelected && otherSector.trim().isEmpty) &&
      Validators.linkedin(linkedin) == null &&
      (!user.isFounder || bio.trim().isNotEmpty) &&
      (!user.isInvestor ||
          (valueOffered.trim().isNotEmpty && gain.trim().isNotEmpty));

  void setFullName(String v) => _set(() => fullName = v);
  void setBio(String v) => _set(() => bio = v);
  void setPhone(String v) => _set(() => phone = Validators.phoneDigits(v));
  void setLinkedin(String v) => _set(() => linkedin = v);
  void setValueOffered(String v) => _set(() => valueOffered = v);
  void setGain(String v) => _set(() => gain = v);
  void setOtherSector(String v) => _set(() => otherSector = v);
  void setCity(String v) => _set(() => city = v);
  void setEmailPublic(bool v) => _set(() => emailPublic = v);
  void setPhonePublic(bool v) => _set(() => phonePublic = v);

  /// Chips: toggles [label]; "Other" opens / closes the write-in.
  void toggleSector(String label) => _set(() {
    if (label == otherLabel) {
      otherSelected = !otherSelected;
    } else if (!sectors.remove(label)) {
      sectors.add(label);
    }
  });

  bool isSectorSelected(String label) =>
      label == otherLabel ? otherSelected : sectors.contains(label);

  void pickPhoto(File file) => _set(() {
    newPhoto = file;
    removePhoto = false;
  });

  void clearPhoto() => _set(() {
    newPhoto = null;
    removePhoto = true;
  });

  void _set(VoidCallback change) {
    if (isLoading) return;
    change();
    formError = null;
    notifyListeners();
  }

  /// Validates and saves. Returns the updated user, or null when the form is
  /// invalid (errors are then shown; see [attempted]) or saving failed
  /// ([formError]).
  Future<AppUser?> submit() async {
    if (isLoading) return null;
    attempted = true;
    formError = null;
    if (!isValid) {
      notifyListeners();
      return null;
    }
    isLoading = true;
    notifyListeners();
    final name = fullName.trim();
    final about = bio.trim();
    final chosen = _chosen;
    final typed = otherSelected ? otherSector.trim() : null;
    final link = linkedin.trim();
    final bring = valueOffered.trim();
    final hope = gain.trim();
    try {
      await _users.updateProfile(
        uid: user.uid,
        fullName: name,
        bio: about,
        phone: phone,
        sectorsOfInterest: chosen,
        city: city,
        sectorsOther: typed,
        linkedin: link,
        gain: user.isInvestor ? hope : null,
        valueOffered: user.isInvestor ? bring : null,
        emailPublic: user.isFounder ? emailPublic : null,
        phonePublic: user.isFounder ? phonePublic : null,
      );
      if (user.isFounder && name != user.fullName.trim()) {
        // My name carries over to every team card of mine.
        try {
          await _startups.syncMemberName(
            uid: user.uid,
            oldName: user.fullName,
            newName: name,
          );
        } catch (_) {
          // The profile is saved; the cards catch up on the next change.
        }
      }
      var photoUrl = user.photoUrl;
      var photoRemoved = false;
      final picked = newPhoto;
      if (picked != null) {
        try {
          photoUrl = await _users.uploadProfilePhoto(user.uid, picked);
        } catch (_) {
          formError = AccountStrings.photoSaveFailed;
          return null;
        }
      } else if (removePhoto && photoUrl != null) {
        try {
          await _users.removeProfilePhoto(user.uid, photoUrl);
          photoUrl = null;
          photoRemoved = true;
        } catch (_) {
          formError = AccountStrings.photoSaveFailed;
          return null;
        }
      }
      return user.copyWith(
        fullName: name,
        bio: about,
        phone: phone,
        sectorsOfInterest: chosen,
        sectorsOther: typed,
        city: city,
        linkedin: link,
        gain: user.isInvestor ? hope : null,
        valueOffered: user.isInvestor ? bring : null,
        photoUrl: photoUrl,
        clearPhoto: photoRemoved,
        emailPublic: user.isFounder ? emailPublic : null,
        phonePublic: user.isFounder ? phonePublic : null,
      );
    } on AuthException catch (e) {
      formError = e.failure == AuthFailure.network
          ? AppStrings.networkError
          : AccountStrings.saveFailed;
    } catch (_) {
      formError = AccountStrings.saveFailed;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }
}
