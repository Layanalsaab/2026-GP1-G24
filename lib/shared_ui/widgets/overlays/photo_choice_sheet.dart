import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../lists/press_surface.dart';
import 'app_bottom_sheet.dart';

enum PhotoChoice { change, remove }

/// Asks whether to change or remove a photo or logo that is already set.
Future<PhotoChoice?> showPhotoChoiceSheet(
  BuildContext context, {
  required String changeLabel,
  required String removeLabel,
}) => showAppBottomSheet<PhotoChoice>(
  context,
  builder: (sheet) => AppSheetScaffold(
    title: changeLabel,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Option(
            label: changeLabel,
            onTap: () => Navigator.of(sheet).pop(PhotoChoice.change),
          ),
          _Option(
            label: removeLabel,
            destructive: true,
            onTap: () => Navigator.of(sheet).pop(PhotoChoice.remove),
          ),
        ],
      ),
    ),
  ),
);

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => PressSurface(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        label,
        style: AppText.sans(
          size: 16,
          color: destructive ? AppColors.error : AppColors.ink,
        ),
      ),
    ),
  );
}
