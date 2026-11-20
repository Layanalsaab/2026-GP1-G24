import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// One removable chip of the ResultsRow.
class ResultChip {
  const ResultChip({
    required this.label,
    required this.onRemove,
    this.quoted = false,
  });

  /// The search text chip: white with a border and curly quotes (“riyadh”).
  const ResultChip.query(String text, {required this.onRemove})
    : label = '“$text”',
      quoted = true;

  /// Visible text (already quoted for ResultChip.query).
  final String label;

  /// True for the white search-text chip.
  final bool quoted;
  final VoidCallback onRemove;
}

class ResultsRow extends StatelessWidget {
  const ResultsRow({
    super.key,
    required this.title,
    this.onClearAll,
    this.chips = const [],
  });

  /// "3 results", "1 result" or "Results".
  final String title;

  final VoidCallback? onClearAll;
  final List<ResultChip> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title,
                  style: AppText.sans(size: 15.5, weight: FontWeight.w700),
                ),
              ),
              if (onClearAll != null)
                Semantics(
                  button: true,
                  label: 'Clear all filters',
                  excludeSemantics: true,
                  onTap: onClearAll,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClearAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'Clear all',
                        style: AppText.sans(
                          size: 13,
                          color: AppColors.mossText,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in chips)
                ChipIn(
                  key: ValueKey(c.label),
                  child: _RemovableChip(chip: c),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.chip});

  final ResultChip chip;

  @override
  Widget build(BuildContext context) {
    final fg = chip.quoted ? AppColors.greenText : AppColors.white;
    return Semantics(
      button: true,
      label: 'Remove filter ${chip.label}',
      excludeSemantics: true,
      onTap: chip.onRemove,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: chip.onRemove,
        child: Container(
          height: 30,
          padding: const EdgeInsets.only(left: 12, right: 7),
          decoration: BoxDecoration(
            color: chip.quoted ? AppColors.surface : AppColors.green,
            borderRadius: BorderRadius.circular(999),
            border: chip.quoted
                ? Border.all(color: AppColors.chipBorderSoft)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chip.label,
                style: AppText.sans(
                  size: 12.5,
                  color: fg,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Opacity(
                opacity: 0.8,
                child: AppIcon.outline(
                  AppIcons.closeStroke,
                  size: 14,
                  stroke: 2.4,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
