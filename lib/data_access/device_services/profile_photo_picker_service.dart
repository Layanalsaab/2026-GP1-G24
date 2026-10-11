import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_constants/account_strings.dart';
import '../../shared_ui/theme/app_theme.dart';

enum ProfilePhotoFailure { tooLarge, failed }

class ProfilePhotoException implements Exception {
  const ProfilePhotoException(this.failure);

  final ProfilePhotoFailure failure;
}

/// Picks a profile photo from the gallery, crops it to a square and
/// compresses it. The only code (with the logo picker) that talks to
/// image_picker / image_cropper. Tests replace [instance] with a fake.
class ProfilePhotoPickerService {
  const ProfilePhotoPickerService();

  static ProfilePhotoPickerService instance = const ProfilePhotoPickerService();

  /// Largest photo file we upload. storage.rules enforces the same limit.
  static const maxBytes = 2 * 1024 * 1024;

  static const _outputSize = 512;
  static const _jpegQuality = 80;

  /// Returns the cropped JPEG, or null when the user cancels. Throws
  /// [ProfilePhotoException] when the image can't be used.
  Future<File?> pickSquarePhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (picked == null) return null;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: _outputSize,
        maxHeight: _outputSize,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: _jpegQuality,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: AccountStrings.cropPhotoTitle,
            toolbarColor: AppColors.moss600,
            toolbarWidgetColor: AppColors.onDark,
            activeControlsWidgetColor: AppColors.moss600,
            backgroundColor: AppColors.ink,
            lockAspectRatio: true,
            initAspectRatio: CropAspectRatioPreset.square,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: AccountStrings.cropPhotoTitle,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      if (cropped == null) return null;

      final file = File(cropped.path);
      if (await file.length() >= maxBytes) {
        throw const ProfilePhotoException(ProfilePhotoFailure.tooLarge);
      }
      return file;
    } on ProfilePhotoException {
      rethrow;
    } catch (e) {
      debugPrint('Profile photo pick failed: $e');
      throw const ProfilePhotoException(ProfilePhotoFailure.failed);
    }
  }
}
