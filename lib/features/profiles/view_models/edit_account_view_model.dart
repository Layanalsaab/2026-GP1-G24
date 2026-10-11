import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';

/// Logic for the Edit profile screen (PBIs 10 and 12): validates the form
/// (same rules as Create Account) and saves the name, bio, city, sectors of
/// interest and phone. The email can't be changed here: changing the login
/// email needs re-authentication and a verification email.
class EditAccountViewModel extends ChangeNotifier with SafeNotifier {
  EditAccountViewModel({required this.user, UserRepository? userRepository})
    : _users = userRepository ?? UserRepository.instance,
      city = user.city,
      sectors = List.of(user.sectorsOfInterest);

  /// The profile as it was when the screen opened.
  final AppUser user;
  final UserRepository _users;

  /// The selected city chip. Starts as the saved city (may be null).
  String? city;

  /// The chosen sectors (the fixed chips plus "Other" or a typed sector).
  final List<String> sectors;

  bool isLoading = false;

  /// A photo picked on this screen, uploaded on Save.
  File? newPhoto;

  /// True when the user chose to remove the saved photo; applied on Save.
  bool removePhoto = false;

  /// Whether the avatar shows a photo (saved, or picked but not saved yet).
  bool get hasPhoto =>
      newPhoto != null || (!removePhoto && (user.photoUrl ?? '').isNotEmpty);

  void pickPhoto(File file) {
    if (isLoading) return;
    newPhoto = file;
    removePhoto = false;
    formError = null;
    notifyListeners();
  }

  void clearPhoto() {
    if (isLoading) return;
    newPhoto = null;
    removePhoto = true;
    formError = null;
    notifyListeners();
  }

  /// True after the first Save attempt, so untouched fields show their
  /// checklists too.
  bool attempted = false;
  String? fullNameError;
  String? phoneError;
  String? cityError;
  String? sectorsError;

  /// Shown above the Save button when saving fails.
  String? formError;

  void selectCity(String value) {
    if (isLoading) return;
    city = value;
    cityError = null;
    formError = null;
    notifyListeners();
  }

  /// Whether the chip with [label] shows as selected. "Other" is selected
  /// when it, or any typed sector that isn't one of the fixed chips, is saved.
  bool isSectorSelected(String label) {
    if (label == AppStrings.otherSector) {
      return sectors.any(
        (s) => s == AppStrings.otherSector || !AppStrings.sectors.contains(s),
      );
    }
    return sectors.contains(label);
  }

  void toggleSector(String label) {
    if (isLoading) return;
    if (label == AppStrings.otherSector) {
      if (isSectorSelected(label)) {
        sectors.removeWhere((s) => !AppStrings.sectors.contains(s));
      } else {
        sectors.add(AppStrings.otherSector);
      }
    } else {
      sectors.contains(label) ? sectors.remove(label) : sectors.add(label);
    }
    sectorsError = null;
    formError = null;
    notifyListeners();
  }

  /// Clears one field's error as soon as the user edits it.
  void clearFieldError() {
    if (fullNameError == null && phoneError == null && formError == null) {
      return;
    }
    fullNameError = null;
    phoneError = null;
    formError = null;
    notifyListeners();
  }

  /// Saves the changes. Returns the updated user, or null when the form is
  /// invalid or saving failed (see the `*Error` fields / [formError]).
  /// [phone] is the 9 digits without +966.
  Future<AppUser?> submit({
    required String fullName,
    required String bio,
    required String phone,
  }) async {
    if (isLoading) return null;

    final name = fullName.trim();
    final about = bio.trim();
    final number = phone.trim();
    attempted = true;
    fullNameError = Validators.fullName(name);
    phoneError = Validators.phone(number);
    cityError = Validators.city(city);
    sectorsError = Validators.sectors(sectors);
    formError = null;
    if (fullNameError != null ||
        phoneError != null ||
        cityError != null ||
        sectorsError != null) {
      notifyListeners();
      return null;
    }

    isLoading = true;
    notifyListeners();
    try {
      await _users.updateProfile(
        uid: user.uid,
        fullName: name,
        bio: about,
        phone: number,
        sectorsOfInterest: List.of(sectors),
        city: city,
      );
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
        phone: number,
        sectorsOfInterest: List.of(sectors),
        city: city,
        photoUrl: photoUrl,
        clearPhoto: photoRemoved,
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
