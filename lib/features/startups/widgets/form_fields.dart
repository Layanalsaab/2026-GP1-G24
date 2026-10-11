import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../shared_ui/theme/app_theme.dart';

/// Label shown above a select field or the logo, styled like the label of
/// the shared AppTextField. [optional] adds the muted "(optional)" suffix.
/// (Text inputs use the shared AppTextField directly, with its "n/max"
/// counter, so the startup form behaves exactly like login and signup.)
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: AppText.sans(
          size: 14,
          color: AppColors.ink,
          weight: FontWeight.w500,
          height: 20,
        ),
        children: [
          if (optional)
            TextSpan(
              text: ' ${AppStrings.optionalSuffix}',
              style: AppText.sans(size: 13, color: AppColors.grey, height: 20),
            ),
        ],
      ),
    );
  }
}

/// Small grey heading between groups of fields.
class FieldGroupHeading extends StatelessWidget {
  const FieldGroupHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Text(text, style: AppText.groupLabel),
  );
}
