import 'dart:io';

import 'package:flutter/material.dart';

import '../../app_constants/account_strings.dart';
import '../../data_access/device_services/profile_photo_picker_service.dart';
import '../theme/app_theme.dart';
import 'form_message.dart';

/// What the user chose in the photo options sheet.
enum PhotoChoice { choose, remove }

/// The result of picking a photo: the cropped file, or the reason it failed.
/// Both are null when the user cancelled.
typedef PhotoPickResult = ({File? file, String? error});

/// Opens the gallery and the square cropper. Never throws: a photo that can't
/// be used comes back as an error message.
Future<PhotoPickResult> pickProfilePhoto() async {
  try {
    final file = await ProfilePhotoPickerService.instance.pickSquarePhoto();
    return (file: file, error: null);
  } on ProfilePhotoException catch (e) {
    return (
      file: null,
      error: e.failure == ProfilePhotoFailure.tooLarge
          ? AccountStrings.photoTooLarge
          : AccountStrings.photoFailed,
    );
  } catch (_) {
    return (file: null, error: AccountStrings.photoFailed);
  }
}

/// Bottom sheet with "Change photo" and "Remove photo". Resolves to null when
/// dismissed.
Future<PhotoChoice?> showPhotoOptionsSheet(
  BuildContext context, {
  bool canRemove = true,
}) {
  return showModalBottomSheet<PhotoChoice>(
    context: context,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SheetRow(
              icon: Icons.photo_library_outlined,
              label: AccountStrings.changePhoto,
              color: AppColors.ink,
              onTap: () => Navigator.of(sheetContext).pop(PhotoChoice.choose),
            ),
            if (canRemove)
              _SheetRow(
                icon: Icons.delete_outline_rounded,
                label: AccountStrings.removePhoto,
                color: AppColors.error,
                onTap: () => Navigator.of(sheetContext).pop(PhotoChoice.remove),
              ),
          ],
        ),
      ),
    ),
  );
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppText.sans(
                size: 16,
                color: color,
                weight: FontWeight.w600,
                height: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma "Add profile photo (optional)" on Create Account: a round picture
/// placeholder with a camera badge and the label under it. Tapping opens the
/// gallery (or, when a photo is chosen, the change / remove sheet).
class ProfilePhotoField extends StatefulWidget {
  const ProfilePhotoField({
    super.key,
    required this.photo,
    required this.onChanged,
    this.enabled = true,
  });

  final File? photo;
  final ValueChanged<File?> onChanged;
  final bool enabled;

  @override
  State<ProfilePhotoField> createState() => _ProfilePhotoFieldState();
}

class _ProfilePhotoFieldState extends State<ProfilePhotoField> {
  String? _error;
  bool _busy = false;

  Future<void> _tap() async {
    if (!widget.enabled || _busy) return;
    if (widget.photo != null) {
      final choice = await showPhotoOptionsSheet(context);
      if (choice == null || !mounted) return;
      if (choice == PhotoChoice.remove) {
        setState(() => _error = null);
        widget.onChanged(null);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await pickProfilePhoto();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.error;
    });
    if (result.file != null) widget.onChanged(result.file);
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    const placeholder = Icon(
      Icons.person_outline_rounded,
      size: 40,
      color: AppColors.moss600,
    );
    return Column(
      children: [
        Semantics(
          button: true,
          label: photo == null
              ? '${AccountStrings.addPhoto} ${AccountStrings.optional}'
              : AccountStrings.changePhoto,
          excludeSemantics: true,
          onTap: _tap,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(top: 4, left: 4),
                        decoration: const BoxDecoration(
                          color: AppColors.moss100,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: photo == null
                              ? placeholder
                              : Image.file(
                                  photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => placeholder,
                                ),
                        ),
                      ),
                      if (_busy)
                        const Positioned.fill(
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.moss600,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.moss600,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cream,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    text: AccountStrings.addPhoto,
                    style: AppText.sans(
                      size: 14,
                      color: AppColors.moss600,
                      weight: FontWeight.w600,
                      height: 20,
                    ),
                    children: [
                      TextSpan(
                        text: ' ${AccountStrings.optional}',
                        style: AppText.sans(
                          size: 13,
                          color: AppColors.grey,
                          height: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          FormMessage.error(_error!),
        ],
      ],
    );
  }
}
