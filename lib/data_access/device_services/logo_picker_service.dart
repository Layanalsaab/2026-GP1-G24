import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_constants/startup_strings.dart';
import '../../shared_ui/theme/app_colors.dart';
import 'image_fit.dart';

enum LogoPickFailure { tooLarge, failed }

class LogoPickException implements Exception {
  const LogoPickException(this.failure);

  final LogoPickFailure failure;
}

/// Picks a startup logo from the gallery, crops it to a square, and compresses it.
class LogoPickerService {
  static const _outputSize = 256;
  static const _jpegQuality = 70;

  final _picker = ImagePicker();
  final _cropper = ImageCropper();

  /// Returns the cropped, compressed JPEG, or null when the user cancels.
  Future<File?> pickSquareLogo() async {
    try {
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
        ],
      );
      if (cropped == null) return null;

      final file = File(cropped.path);
      try {
        await ImageFit.bytesUnder(file);
      } on ImageTooLarge {
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
