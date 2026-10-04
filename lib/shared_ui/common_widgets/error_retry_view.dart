import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'primary_button.dart';

/// Full-area error with an explanation and a Retry button.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppSizes.emptyStateIcon,
            height: AppSizes.emptyStateIcon,
            decoration: const BoxDecoration(
              color: AppColors.errorFill,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppSizes.iconLg, color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: AppText.sectionTitle, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppText.bodyMuted, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            label: retryLabel,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
