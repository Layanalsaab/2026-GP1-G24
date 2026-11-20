import 'package:flutter/material.dart';

import 'founder_ui.dart';
import 'hover_lift_card.dart';

class ManageCard extends StatelessWidget {
  const ManageCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final VoidCallback? onTap;

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (onTap != null) {
      return HoverLiftCard(
        onTap: onTap,
        padding: padding,
        baseShadow: AppShadow.card,
        border: Border.all(color: AppColors.cardBorder),
        child: child,
      );
    }
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

/// The title of a Dashboard card ("Activity", "Associated Investors"): 19 px on a 26 px line, bold.
class ManageCardTitle extends StatelessWidget {
  const ManageCardTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: AppText.sans(size: 19, height: 26, weight: FontWeight.w700),
    ),
  );
}

class ManageTabHeader extends StatelessWidget {
  const ManageTabHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(
          title,
          style: AppText.sans(size: 19, height: 26, weight: FontWeight.w700),
        ),
      ),
      if (subtitle != null)
        Text(subtitle!, style: AppText.sans(size: 13, color: AppColors.hint)),
    ],
  );
}

/// A grey 14/20 line used inside a ManageCard for empty states.
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
