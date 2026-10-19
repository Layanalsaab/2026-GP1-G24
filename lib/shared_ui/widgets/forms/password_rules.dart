import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// One password rule and whether [password] meets it.
class PasswordRule {
  const PasswordRule(this.label, this.met);

  final String label;
  final bool met;
}

/// The five sign-up password rules evaluated live: at least 8 characters,
/// one uppercase letter, one lowercase letter, one number, one special
/// character (any
/// character that is not a letter or digit).
List<PasswordRule> evaluatePasswordRules(String password) => [
  PasswordRule('At least 8 characters', password.length >= 8),
  PasswordRule('One uppercase letter', RegExp('[A-Z]').hasMatch(password)),
  PasswordRule('One lowercase letter', RegExp('[a-z]').hasMatch(password)),
  PasswordRule('One number', RegExp('[0-9]').hasMatch(password)),
  PasswordRule(
    'One special character (! @ # \$)',
    RegExp('[^A-Za-z0-9]').hasMatch(password),
  ),
];

/// True when every rule is met.
bool passwordRulesMet(String password) =>
    evaluatePasswordRules(password).every((r) => r.met);

/// The password rule checklist under the sign-up password field: four rows
/// (12/16, 16 px icon, 6 px apart), unmet = red with an x, met = moss600 with a
/// check; the color animates over 200 ms. Pass the current [password].
class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = evaluatePasswordRules(password);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final r in rules) _RuleRow(rule: r)],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule});

  final PasswordRule rule;

  @override
  Widget build(BuildContext context) {
    final color = rule.met ? AppColors.moss600 : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        label: '${rule.label}, ${rule.met ? 'met' : 'not met'}',
        excludeSemantics: true,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: Motion.dur(context, const Duration(milliseconds: 200)),
          curve: Curves.ease,
          builder: (context, c, _) => Row(
            children: [
              AppIcon.filled(
                rule.met ? AppIcons.check : AppIcons.close,
                size: 16,
                color: c ?? color,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  rule.label,
                  style: AppText.sans(size: 12, color: c ?? color, height: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
