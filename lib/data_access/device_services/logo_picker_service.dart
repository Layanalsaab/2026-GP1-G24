import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_constants/startup_strings.dart';
import '../../shared_ui/theme/app_theme.dart';

enum LogoPickFailure { tooLarge, failed }

class LogoPickException implements Exception {
  const LogoPickException(this.failure);

  final LogoPickFailure failure;
}

/// Picks a startup logo from the gallery, crops it to a square, and
/// compresses it. The only code that talks to image_picker / image_cropper.
class LogoPickerService {
  /// Largest logo file we upload. storage.rules enforces the same limit.
  static const maxBytes = 2 * 1024 * 1024;

  /// Logos are shown at most ~100px; 512px keeps them sharp on dense screens
  /// while keeping uploads small.
  static const _outputSize = 512;
  static const _jpegQuality = 80;

  final _picker = ImagePicker();
  final _cropper = ImageCropper();

  /// Returns the cropped, compressed JPEG, or null when the user cancels.
  /// Throws [LogoPickException] when the image can't be used.
  Future<File?> pickSquareLogo() async {
    try {
      // First pass: shrink very large photos before they reach the cropper.
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (picked == null) return null;

      final cropped = await _cropper.cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: _outputSize,
        maxHeight: _outputSize,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: _jpegQuality,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: StartupStrings.cropLogoTitle,
            toolbarColor: AppColors.green,
            toolbarWidgetColor: AppColors.onDark,
            activeControlsWidgetColor: AppColors.gold,
            backgroundColor: AppColors.ink,
            lockAspectRatio: true,
            initAspectRatio: CropAspectRatioPreset.square,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: StartupStrings.cropLogoTitle,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      if (cropped == null) return null;

      final file = File(cropped.path);
      if (await file.length() > maxBytes) {
        throw const LogoPickException(LogoPickFailure.tooLarge);
      }
      return file;
    } on LogoPickException {
      rethrow;
    } catch (e) {
      debugPrint('Logo pick failed: $e');
      throw const LogoPickException(LogoPickFailure.failed);
    }
  }
}
