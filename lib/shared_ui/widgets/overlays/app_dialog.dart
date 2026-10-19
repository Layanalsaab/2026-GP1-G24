import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import '../buttons/app_button.dart';
import 'app_overlay_route.dart';

/// Shows a centered dialog (docs/02 §8.13): scrim fades in (260 ms), the card
/// fades and scales 0.96 -> 1 over 240 ms. Tapping the scrim pops (unless
/// [dismissible] is false). [builder] normally returns an [AppDialog].
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
    curve: Motion.easeOut,
    label: barrierLabel,
    dismissible: dismissible,
  );
}

/// The dialog card (prototype `.dialog`): 20 px side margin, white, radius 24,
/// padding 28 24 16, dialog shadow. [child] is the content.
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

/// "Verify your email" dialog content (docs 11c / 08): a Pop-ing mail icon in a
/// 64 px gold circle, title 21/700, the explanation with the bold [email],
/// the spam hint, a primary "Resend verification email" button and an "OK"
/// ghost button. [needLogin] appends ", then log in"; [inSignup] appends ",
/// then come back here to continue".
class VerifyEmailDialog extends StatelessWidget {
  const VerifyEmailDialog({
    super.key,
    required this.email,
    required this.onResend,
    required this.onClose,
    this.needLogin = false,
    this.inSignup = false,
  });

  final String email;
  final VoidCallback onResend;
  final VoidCallback onClose;
  final bool needLogin;
  final bool inSignup;

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
                decoration: const BoxDecoration(
                  color: AppColors.tagGoldFill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const AppIcon.filled(
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
              'Verify your email',
              textAlign: TextAlign.center,
              style: AppText.sans(size: 21, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: base,
              children: [
                const TextSpan(text: 'We sent a verification link to '),
                TextSpan(
                  text: email,
                  style: base.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text:
                      '. Open the link to activate your account'
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
          const SizedBox(height: 20),
          AppButton(label: 'Resend verification email', onPressed: onResend),
          const SizedBox(height: 6),
          AppButton(
            label: 'OK',
            onPressed: onClose,
            variant: AppButtonVariant.ghost,
          ),
        ],
      ),
    );
  }
}
