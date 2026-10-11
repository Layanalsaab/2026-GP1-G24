import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_constants/app_strings.dart';
import '../theme/app_theme.dart';
import 'form_message.dart';

/// Form pieces shared by Create Account and Edit profile: the "+966" prefix,
/// the city picker and the sector chips.

/// Opens the city list and returns the chosen city (null when dismissed).
Future<String?> showCityPicker(BuildContext context, {String? selected}) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x730F1A12),
    builder: (_) => CitySheet(selected: selected),
  );
}

/// "+966 |" before the phone digits.
class PhonePrefix extends StatelessWidget {
  const PhonePrefix({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.phoneCountryCode,
            style: AppText.sans(
              size: 16,
              color: AppColors.ink,
              weight: FontWeight.w500,
              height: 24,
            ),
          ),
          const SizedBox(width: 6),
          Container(width: 1, height: 24, color: AppColors.border),
        ],
      ),
    );
  }
}

/// Figma "City dropdown": a tall bottom sheet with a search field and the
/// full list of cities. Pops with the chosen city.
class CitySheet extends StatefulWidget {
  const CitySheet({super.key, required this.selected});

  final String? selected;

  @override
  State<CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<CitySheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final query = _search.text.trim().toLowerCase();
    final cities = [
      for (final city in AppStrings.allCities)
        if (city.toLowerCase().contains(query)) city,
    ];
    // Tall like the design, but never taller than the space above the keyboard.
    final height = (media.size.height * 0.88).clamp(
      0.0,
      media.size.height - media.viewInsets.bottom - 48,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.citySheetTitle,
                    style: AppText.sans(
                      size: 20,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                cursorColor: AppColors.moss600,
                style: AppText.sans(size: 15, color: AppColors.ink),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.cream,
                  hintText: AppStrings.citySearchHint,
                  hintStyle: AppText.sans(size: 15, color: AppColors.grey),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.ink,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 44),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.moss600,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: cities.isEmpty
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          AppStrings.cityNoResults,
                          style: AppText.sans(size: 15, color: AppColors.grey),
                        ),
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: math.max(24, media.padding.bottom),
                        ),
                        itemCount: cities.length,
                        itemBuilder: (context, i) => _CityRow(
                          city: cities[i],
                          selected: cities[i] == widget.selected,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({required this.city, required this.selected});

  final String city;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: city,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).pop(city),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.moss100 : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  city,
                  style: AppText.sans(
                    size: 15,
                    color: selected ? AppColors.moss600 : AppColors.ink,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, size: 18, color: AppColors.moss600),
            ],
          ),
        ),
      ),
    );
  }
}

/// Looks like a text field; tapping it opens the city list.
class CityField extends StatelessWidget {
  const CityField({
    super.key,
    this.label = AppStrings.cityLabel,
    required this.city,
    required this.error,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String? city;
  final String? error;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final chosen = city != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.sans(
            size: 14,
            color: hasError ? AppColors.error : AppColors.ink,
            weight: FontWeight.w500,
            height: 20,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: '$label ${city ?? AppStrings.cityHint}',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onTap : null,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: hasError
                      ? AppColors.error
                      : chosen
                      ? AppColors.moss600
                      : AppColors.borderStrong,
                  width: hasError ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      city ?? AppStrings.cityHint,
                      style: AppText.sans(
                        size: 16,
                        color: chosen ? AppColors.ink : AppColors.grey,
                        height: 24,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 22,
                    color: AppColors.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[const SizedBox(height: 6), FormMessage.error(error!)],
      ],
    );
  }
}

/// Multi-select sector chips, with an "Other" chip you can type into.
class SectorsField extends StatelessWidget {
  const SectorsField({
    super.key,
    this.label = AppStrings.sectorsLabel,
    this.hint = AppStrings.sectorsHint,
    this.softChips = false,
    required this.selected,
    required this.otherSelected,
    required this.otherController,
    required this.count,
    required this.error,
    required this.enabled,
    required this.onToggle,
    required this.onToggleOther,
  });

  /// The question above the chips, and the grey line under it (null hides).
  final String label;
  final String? hint;

  /// Unselected chips use the soft green fill of the Edit profile design.
  final bool softChips;
  final List<String> selected;
  final bool otherSelected;
  final TextEditingController otherController;
  final int count;
  final String? error;
  final bool enabled;
  final ValueChanged<String> onToggle;
  final VoidCallback onToggleOther;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.sans(
            size: 14,
            color: hasError ? AppColors.error : AppColors.ink,
            weight: FontWeight.w500,
            height: 20,
          ),
        ),
        const SizedBox(height: 4),
        if (hint != null) ...[
          Text(
            hint!,
            style: AppText.sans(size: 12, color: AppColors.grey, height: 16),
          ),
          const SizedBox(height: 4),
        ],
        Wrap(
          spacing: 8,
          children: [
            for (final sector in AppStrings.sectors)
              SectorChip(
                label: sector,
                selected: selected.contains(sector),
                soft: softChips,
                onTap: enabled ? () => onToggle(sector) : null,
              ),
            if (otherSelected)
              OtherChip(
                controller: otherController,
                onClear: enabled ? onToggleOther : null,
              )
            else
              SectorChip(
                label: AppStrings.otherSector,
                selected: false,
                soft: softChips,
                onTap: enabled ? onToggleOther : null,
              ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          FormMessage.error(error!),
        ] else if (count > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.check, size: 16, color: AppColors.moss600),
              const SizedBox(width: 6),
              Text(
                AppStrings.sectorsSelected(count),
                style: AppText.sans(
                  size: 12,
                  color: AppColors.moss600,
                  height: 16,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class SectorChip extends StatelessWidget {
  const SectorChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.soft = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Soft green fill and no outline when not selected (Edit profile).
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // The padding keeps the tap target at least 44 high; the visible chip
        // stays the size in the design.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.moss600
                  : soft
                  ? AppColors.moss100
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.moss600
                    : soft
                    ? AppColors.moss100
                    : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check, size: 12, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppText.sans(
                    size: 13,
                    color: selected ? Colors.white : AppColors.ink,
                    weight: FontWeight.w500,
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

/// The selected "Other:" chip: a small text field plus a clear button.
class OtherChip extends StatelessWidget {
  const OtherChip({
    super.key,
    required this.controller,
    required this.onClear,
    this.hint = AppStrings.otherSectorHint,
    this.maxLength = 30,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback? onClear;

  /// Grey text shown until the user types.
  final String hint;
  final int maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.moss600, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 12, color: AppColors.moss600),
            const SizedBox(width: 4),
            Text(
              '${AppStrings.otherSector}:',
              style: AppText.sans(
                size: 13,
                color: AppColors.moss600,
                weight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 112,
              child: TextField(
                controller: controller,
                autofocus: true,
                maxLength: maxLength,
                inputFormatters: inputFormatters,
                onChanged: onChanged,
                cursorColor: AppColors.moss600,
                textInputAction: TextInputAction.done,
                style: AppText.sans(size: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: AppText.sans(size: 13, color: AppColors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 14, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
