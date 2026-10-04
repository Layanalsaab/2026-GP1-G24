import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Figma "Button / Primary": 48px, moss fill, one per screen.
/// A null [onPressed] (and not loading) shows the disabled style.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color = AppColors.moss600,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Fill color. Moss by default; [AppColors.error] for destructive actions
  /// such as deleting an account.
  final Color color;

  /// Shows a spinner and ignores taps, so a request can't be started twice.
  final bool isLoading;

  /// Optional line icon before the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !isLoading;
    final foreground = disabled ? AppColors.grey : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: disabled
            ? null
            : const [
                BoxShadow(
                  color: Color(0x401F4026),
                  offset: Offset(0, 3),
                  blurRadius: 5,
                ),
              ],
      ),
      child: Material(
        color: disabled ? AppColors.mutedFill : color,
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
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: foreground),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: AppText.sans(
                              size: 16,
                              color: foreground,
                              weight: FontWeight.w600,
                              height: 20,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma "Button / Secondary": 48px, white fill, moss outline.
/// Pass [color] for a differently coloured outline (e.g. a delete action).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.moss600,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLoading ? null : onPressed,
        child: Ink(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: color,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: color),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: AppText.sans(
                            size: 16,
                            color: color,
                            weight: FontWeight.w600,
                            height: 20,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
