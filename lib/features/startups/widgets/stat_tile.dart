import 'package:flutter/material.dart';

import 'founder_ui.dart';

/// A big-number tile: a label, a value and a sub-line. Dark = the open
/// "Raising" tile (green gradient, white text); otherwise white with a 1 px
/// border. Padding 18 / 16, radius 20. Used by the Manage Dashboard and the
/// startup page (Raising, Valuation, Capital).
///
/// [onTap] null makes it a plain read-only tile.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    this.dark = false,
    this.onTap,
  });

  final bool dark;
  final String label;
  final String value;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = dark ? const Color(0xFFCFE0D3) : AppColors.grey;
    final valueColor = dark ? AppColors.onDark : AppColors.ink;
    final subColor = dark ? const Color(0xFFE3CF9B) : AppColors.grey;
    final tile = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2F5D3A), Color(0xFF1F3F27)],
              )
            : null,
        color: dark ? null : AppColors.surface,
        border: dark ? null : Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.sans(size: 14, color: labelColor)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppText.sans(
                size: 26,
                height: 32,
                weight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(sub, style: AppText.sans(size: 14, color: subColor)),
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      label: '$label, $value, $sub',
      excludeSemantics: true,
      child: onTap == null ? tile : Pressable(onTap: onTap, child: tile),
    );
  }
}
