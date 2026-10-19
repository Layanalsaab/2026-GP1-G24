import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import '../buttons/app_button.dart';
import 'app_overlay_route.dart';

/// Shows a picker-style bottom sheet (docs/02 §8.12): the scrim `#1C1F1D66`
/// fades in over 260 ms and the sheet slides up over 340 ms with
/// [Motion.drawer]. [builder] should return an [AppSheetScaffold] (or a widget
/// built on it). Tapping the scrim or Android back pops with a null result.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String barrierLabel = 'Close',
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
  );
}

/// The frame of every bottom sheet: cream, top radius 24, sheet shadow, handle
/// (40 x 4, `#D6D3CC`, margin 10 auto 4), optional title row (20/700, padding
/// 8 12 8 20, close button) and [child].
///
/// * Max height is 84 % of the screen; [tall] pins the top at 64 px instead
///   (city list, "Other" write-in). Both shrink for the keyboard.
/// * [title] null hides the title row (info sheet, delete sheet).
/// * [child] is placed in a flexible area: give it a scrollable for long
///   content.
class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
    super.key,
    required this.child,
    this.title,
    this.tall = false,
    this.onClose,
    this.color = AppColors.cream,
  });

  final Widget child;
  final String? title;
  final bool tall;

  /// Defaults to popping the sheet.
  final VoidCallback? onClose;
  final Color color;

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
            color: color,
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
        child: const SizedBox(
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

/// "Got it" info sheet (calculator "i" buttons): title 18/700, text 15/22
/// `#3E4A41` and a primary "Got it" button. Show with [showInfoSheet].
class InfoSheet extends StatelessWidget {
  const InfoSheet({
    super.key,
    required this.title,
    required this.text,
    this.buttonLabel = 'Got it',
  });

  final String title;
  final String text;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: AppText.sans(size: 18, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: AppText.sans(
                size: 15,
                color: AppColors.paragraph,
                height: 22,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: buttonLabel,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens an [InfoSheet].
Future<void> showInfoSheet(
  BuildContext context, {
  required String title,
  required String text,
}) => showAppBottomSheet<void>(
  context,
  builder: (_) => InfoSheet(title: title, text: text),
);

/// Delete / confirm sheet content (prototype `sheet.isDelete`): a 60 px red
/// circle with a [icon] (default trash, Pop), title 21/700, message 15/22 grey,
/// a danger button ([confirmLabel]) and a white "Cancel" button. Pops with
/// `true` on confirm and `false` on cancel; see [showConfirmSheet].
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.icon = AppIcons.trash,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final String icon;

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
                decoration: const BoxDecoration(
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
            const SizedBox(height: 22),
            AppButton(
              label: confirmLabel,
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            Pressable(
              onTap: () => Navigator.of(context).pop(false),
              child: Semantics(
                button: true,
                label: cancelLabel,
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
                    cancelLabel,
                    style: AppText.sans(size: 16, weight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a [ConfirmSheet]; completes with true only when confirmed.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  String icon = AppIcons.trash,
}) async {
  final r = await showAppBottomSheet<bool>(
    context,
    builder: (_) => ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
    ),
  );
  return r ?? false;
}
