import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// An inline message with an icon, so state is never shown by color alone
/// (Figma "Text field": error adds icon + message).
class FormMessage extends StatelessWidget {
  const FormMessage.error(this.text, {super.key}) : isError = true;

  const FormMessage.success(this.text, {super.key}) : isError = false;

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.moss600;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppText.sans(size: 13, color: color, height: 18),
          ),
        ),
      ],
    );
  }
}
