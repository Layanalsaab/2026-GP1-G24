import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Figma "Button / Primary": 48px, moss fill, one per screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color = AppColors.moss600,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Fill color. Moss by default; [AppColors.error] for destructive actions
  /// such as deleting an account.
  final Color color;

  /// Shows a spinner and ignores taps, so a request can't be started twice.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x401F4026),
            offset: Offset(0, 3),
            blurRadius: 5,
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : onPressed,
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: AppText.sans(
                        size: 16,
                        color: Colors.white,
                        weight: FontWeight.w600,
                        height: 20,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma "Button / Secondary": 48px, white fill, moss outline.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Ink(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.moss600, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: AppText.sans(
                size: 16,
                color: AppColors.moss600,
                weight: FontWeight.w600,
                height: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
