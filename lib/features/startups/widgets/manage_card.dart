import 'package:flutter/material.dart';

import 'founder_ui.dart';

/// The white card of the Manage startup panes (prototype `.mcard`): radius 20,
/// padding 16, hairline border and the soft card shadow.
class ManageCard extends StatelessWidget {
  const ManageCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadow.card,
      ),
      child: child,
    );
  }
}

/// A grey 14/20 line used inside a [ManageCard] for empty states.
class ManageEmptyText extends StatelessWidget {
  const ManageEmptyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      text,
      style: AppText.sans(size: 14, height: 20, color: AppColors.grey),
    ),
  );
}
