import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import '../buttons/app_button.dart';
import 'app_overlay_route.dart';

Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
  String barrierLabel = 'Close',
}) {
  return showAppOverlay<T>(
    context,
    builder: (ctx) => Center(child: builder(ctx)),
    dim: AppColors.scrim,
    dimDuration: const Duration(milliseconds: 260),
    duration: const Duration(milliseconds: 260),
    entry: AppOverlayEntry.fadeScale,
    curve: const Interval(0, 240 / 260, curve: Motion.easeOut),
    label: barrierLabel,
    dismissible: dismissible,
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.dialog),
            boxShadow: AppShadow.dialog,
          ),
          child: Semantics(
            explicitChildNodes: true,
            scopesRoute: true,
            namesRoute: true,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }
}

class VerifyEmailDialog extends StatelessWidget {
  const VerifyEmailDialog({
    super.key,
    required this.email,
    required this.onClose,
    this.needLogin = false,
    this.inSignup = false,
    this.notVerifiedYet = false,
    this.below,
  });

  final String email;
  final VoidCallback onClose;

  final Widget? below;
  final bool needLogin;
  final bool inSignup;

  final bool notVerifiedYet;

  @override
  Widget build(BuildContext context) {
    final base = AppText.sans(size: 15, color: AppColors.grey, height: 22);
    return AppDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Pop(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.tagGoldFill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon.filled(
                  AppIcons.mail,
                  size: 28,
                  color: AppColors.gold700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              notVerifiedYet ? 'Email not verified yet' : 'Verify your email',
              textAlign: TextAlign.center,
              style: AppText.sans(size: 21, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: base,
              children: [
                TextSpan(
                  text: notVerifiedYet
                      ? 'Your email hasn’t been verified yet. We sent a verification link to '
                      : 'We sent a verification link to ',
                ),
                TextSpan(
                  text: email,
                  style: base.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: notVerifiedYet
                      ? '. Open the link in that email first, then ${needLogin ? 'log in' : 'tap Continue'} again.'
                      : '. Open the link to activate your account'
                            '${needLogin ? ', then log in' : ''}'
                            '${inSignup ? ', then come back here to continue' : ''}.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Can’t find it? Check your spam or junk folder.',
            textAlign: TextAlign.center,
            style: AppText.sans(size: 13, color: AppColors.hint),
          ),
          ?below,
          const SizedBox(height: 20),
          AppButton(label: 'OK', onPressed: onClose),
        ],
      ),
    );
  }
}

Future<bool> showSaveConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
}) => showDiscardDialog(
  context,
  title: title,
  message: message,
  discardLabel: confirmLabel,
  keepLabel: cancelLabel,
  danger: false,
);

Future<bool> showDiscardDialog(
  BuildContext context, {
  required String title,
  required String message,
  String discardLabel = 'Discard',
  String keepLabel = 'Keep editing',
  bool danger = true,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final result = await showAppDialog<bool>(
    context,
    builder: (ctx) => AppDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            label: discardLabel,
            variant: danger
                ? AppButtonVariant.danger
                : AppButtonVariant.primary,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: 4),
          AppButton(
            label: keepLabel,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
