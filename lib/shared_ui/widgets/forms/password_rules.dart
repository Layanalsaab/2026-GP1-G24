import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// One password rule and whether password meets it.
class PasswordRule {
  const PasswordRule(this.label, this.met);

  final String label;
  final bool met;
}

List<PasswordRule> evaluatePasswordRules(String password) => [
  PasswordRule('At least 8 characters', password.length >= 8),
  PasswordRule('One uppercase letter', RegExp('[A-Z]').hasMatch(password)),
  PasswordRule('One lowercase letter', RegExp('[a-z]').hasMatch(password)),
  PasswordRule('One number', RegExp('[0-9]').hasMatch(password)),
  PasswordRule(
    'One special character (! @ # \$)',
    // A space is not a special character.
    RegExp(r'[^A-Za-z0-9\s]').hasMatch(password),
  ),
];

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
    final color = rule.met ? AppColors.mossText : AppColors.error;
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
