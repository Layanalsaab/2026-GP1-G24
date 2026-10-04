import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A tappable list row: icon, label, optional second line, and a chevron.
/// Used on the Account and Settings screens. Put rows inside a [MenuCard].
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final String? subtitle;

  /// Null shows the row without a tap effect (e.g. read-only information).
  final VoidCallback? onTap;

  /// Red text and icon, for Log out and Delete account.
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: subtitle == null ? 52 : 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: destructive
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.moss100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: destructive ? AppColors.error : AppColors.green,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.sans(
                        size: 15,
                        color: color,
                        weight: FontWeight.w500,
                        height: 20,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppText.sans(
                          size: 13,
                          color: AppColors.grey,
                          height: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                const Icon(Icons.chevron_right, size: 22, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// White rounded card that groups [MenuRow]s, with dividers between them.
class MenuCard extends StatelessWidget {
  const MenuCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Small grey capital-letter heading above a [MenuCard] ("ACCOUNT").
class MenuSectionLabel extends StatelessWidget {
  const MenuSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: AppText.sans(
          size: 12,
          color: AppColors.grey,
          weight: FontWeight.w600,
          height: 16,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}
