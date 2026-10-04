import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shows a rounded confirmation dialog. Resolves to true only when the
/// founder taps [confirmLabel]; Cancel, Back and tapping outside give false.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  IconData icon = Icons.help_outline_rounded,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (_) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      destructive: destructive,
    ),
  );
  return result ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.error : AppColors.moss600;
    final accentFill = destructive ? AppColors.errorFill : AppColors.moss100;
    return Dialog(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSizes.touchTarget,
              height: AppSizes.touchTarget,
              decoration: BoxDecoration(
                color: accentFill,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: AppSizes.icon),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppText.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppText.bodyMuted),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: cancelLabel,
                    foreground: AppColors.ink,
                    background: AppColors.surface,
                    border: AppColors.border,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _DialogButton(
                    label: confirmLabel,
                    foreground: AppColors.onDark,
                    background: accent,
                    border: accent,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
    required this.onTap,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(AppRadius.md);
    return Material(
      color: background,
      borderRadius: shape,
      child: InkWell(
        borderRadius: shape,
        onTap: onTap,
        child: Ink(
          height: AppSizes.buttonHeight,
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.button.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
