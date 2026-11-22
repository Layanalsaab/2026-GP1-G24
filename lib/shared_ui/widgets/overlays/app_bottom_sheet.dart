import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import '../buttons/app_button.dart';
import 'app_overlay_route.dart';

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String barrierLabel = 'Close',
  bool dismissible = true,
}) {
  return showAppOverlay<T>(
    context,
    builder: (ctx) =>
        Align(alignment: Alignment.bottomCenter, child: builder(ctx)),
    dim: AppColors.scrim,
    dimDuration: const Duration(milliseconds: 260),
    duration: Motion.slow,
    entry: AppOverlayEntry.slideUp,
    label: barrierLabel,
    dismissible: dismissible,
  );
}

class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
    super.key,
    required this.child,
    this.title,
    this.tall = false,
    this.onClose,
    this.color,
  });

  final Widget child;
  final String? title;
  final bool tall;

  /// Defaults to popping the sheet.
  final VoidCallback? onClose;

  /// The sheet fill: cream on light, the surface color on dark (null).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final h = mq.size.height;
    final keyboard = mq.viewInsets.bottom;
    final avail = h - keyboard;
    final double? fixed = tall ? math.max(200.0, avail - 64) : null;
    final maxH = tall
        ? fixed!
        : math.min(h * 0.84, math.max(200.0, avail - 24));
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxH,
          minHeight: tall ? maxH : 0,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color:
                color ??
                (AppColors.isDark ? AppColors.surface : AppColors.cream),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
            boxShadow: AppShadow.sheet,
          ),
          child: Column(
            mainAxisSize: tall ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.fromLTRB(0, 10, 0, 4),
                  decoration: BoxDecoration(
                    color: AppColors.sheetHandle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            title!,
                            style: AppText.sans(
                              size: 20,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      _SheetCloseButton(
                        onTap:
                            onClose ?? () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              Flexible(fit: tall ? FlexFit.tight : FlexFit.loose, child: child),
              SizedBox(
                height: mq.viewPadding.bottom > 0 && keyboard == 0
                    ? mq.viewPadding.bottom
                    : 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        scale: 0.92,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AppIcon.filled(
              AppIcons.close,
              size: 24,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.icon = AppIcons.trash,
    this.note,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final String icon;
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            Pop(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.errorFill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon.filled(icon, size: 28, color: AppColors.error),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 21, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
            ),
            if (note != null) ...[const SizedBox(height: 16), note!],
            SizedBox(height: note != null ? 10 : 22),
            AppButton(
              label: confirmLabel,
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            SheetCancelButton(
              label: cancelLabel,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class SheetCancelButton extends StatelessWidget {
  const SheetCancelButton({
    super.key,
    required this.onTap,
    this.label = 'Cancel',
  });

  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: AppText.sans(size: 16, weight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// Opens a ConfirmSheet; completes with true only when confirmed.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  String icon = AppIcons.trash,
  Widget? note,
}) async {
  final r = await showAppBottomSheet<bool>(
    context,
    builder: (_) => ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      note: note,
    ),
  );
  return r ?? false;
}
