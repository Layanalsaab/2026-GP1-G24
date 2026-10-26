import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';

/// "Didn’t get the email? Resend in 0:59": on the Verify step (inside the
/// white card, under the password field) and in the Log in pop-up: a 1 px
/// line (Verify only), then the centered row (14 px, padding 14 top, 18
/// bottom). While the cooldown runs it is muted and not tappable; at 0:00
/// it fades into a dark green semibold "Resend email".
class ResendRow extends StatelessWidget {
  const ResendRow({
    super.key,
    required this.seconds,
    required this.error,
    required this.busy,
    required this.onResend,
    this.divider = true,
  });

  final int seconds;
  final String? error;
  final bool busy;
  final VoidCallback onResend;

  /// The 1 px line above the row (the Verify card). The Log in pop-up has
  /// none.
  final bool divider;

  static String _clock(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final waiting = seconds > 0;
    final base = AppText.sans(size: 14, height: 20, color: AppColors.hint);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (divider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFEFECE6)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: Motion.dur(
                  context,
                  const Duration(milliseconds: 200),
                ),
                child: waiting
                    ? Semantics(
                        key: const ValueKey('waiting'),
                        label:
                            '${AuthStrings.verifyDidntGet} Resend in ${_clock(seconds)}',
                        excludeSemantics: true,
                        child: Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            style: base,
                            children: [
                              TextSpan(
                                text:
                                    '${AuthStrings.verifyDidntGet} Resend in ',
                              ),
                              TextSpan(
                                text: _clock(seconds),
                                style: AppText.sans(
                                  size: 14,
                                  height: 20,
                                  weight: FontWeight.w600,
                                  color: AppColors.grey,
                                  tabular: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Semantics(
                        key: const ValueKey('ready'),
                        button: true,
                        label: AuthStrings.resendEmail,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: busy ? null : onResend,
                          child: Text.rich(
                            textAlign: TextAlign.center,
                            TextSpan(
                              style: AppText.sans(
                                size: 14,
                                height: 20,
                                color: AppColors.grey,
                              ),
                              children: [
                                TextSpan(
                                  text: '${AuthStrings.verifyDidntGet} ',
                                ),
                                TextSpan(
                                  text: AuthStrings.resendEmail,
                                  style: AppText.sans(
                                    size: 14,
                                    height: 20,
                                    weight: FontWeight.w600,
                                    color: AppColors.moss600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon.filled(
                        AppIcons.error,
                        size: 14,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Flexible(child: Text(error!, style: AppText.error)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
