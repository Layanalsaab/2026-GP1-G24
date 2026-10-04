import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'selection_chip.dart';
import 'svg_asset.dart';

/// A square white button with the filter icon (Figma "Filter").
/// Design only: it does nothing when tapped.
class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    this.size = 36,
    this.radius = 10,
    this.iconSize = 18,
  });

  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Center(child: svgIcon('filter.svg', size: iconSize)),
    );
  }
}

/// A one-line row of sector or category chips that scrolls sideways, with an
/// optional filter button in front. One chip is selected at a time.
class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.showFilterButton = false,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 2),
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool showFilterButton;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          if (showFilterButton) ...[
            const FilterButton(),
            const SizedBox(width: AppSpacing.sm),
          ],
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            SelectionChip(
              label: labels[i],
              selected: i == selected,
              onTap: () => onSelect(i),
            ),
          ],
        ],
      ),
    );
  }
}

/// A search box that only looks like one (Figma "Program search" and the Hub
/// search row). It is not editable yet, so tapping it does nothing.
class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.hint,
    this.height = 48,
    this.iconSize = 22,
    this.fontSize = 16,
  });

  final String hint;
  final double height;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        children: [
          svgIcon('search.svg', size: iconSize),
          SizedBox(width: iconSize > 18 ? 10 : 8),
          Expanded(
            child: Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(
                size: fontSize,
                color: AppColors.grey,
                height: fontSize + 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
