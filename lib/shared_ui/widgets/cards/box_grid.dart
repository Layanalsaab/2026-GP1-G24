import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// A 2-column grid of small cream boxes (label over value). Boxes in the same
/// row are ALWAYS the same height: each row is
/// `IntrinsicHeight > Row(crossAxisAlignment: stretch)` with each box in an
/// `Expanded`, so when one label wraps to two lines the other box stretches to
/// match. The label stays at the top and the value right under it (never
/// vertically centred), so the values line up when neither label wraps.
///
/// Use it for every 2-column box grid (Manage Details, startup page facts and
/// funding tiles). An odd last item leaves an empty half.
class BoxGrid extends StatelessWidget {
  const BoxGrid({
    super.key,
    required this.items,
    this.emptyText = 'Not added yet',
    this.accent = const {},
  });

  /// Labels whose value is shown in moss green (the Website).
  final Set<String> accent;

  /// (label, value) pairs. An empty value shows [emptyText] in grey.
  final List<(String, String)> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 8));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Box(
                  items[i].$1,
                  items[i].$2,
                  emptyText,
                  accent.contains(items[i].$1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: i + 1 < items.length
                    ? _Box(
                        items[i + 1].$1,
                        items[i + 1].$2,
                        emptyText,
                        accent.contains(items[i + 1].$1),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _Box extends StatelessWidget {
  const _Box(this.label, this.value, this.emptyText, this.accent);

  final bool accent;
  final String label;
  final String value;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.sans(size: 12.5, color: AppColors.grey)),
          const SizedBox(height: 2),
          Text(
            empty ? emptyText : value.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(
              size: 15,
              height: 20,
              weight: FontWeight.w600,
              color: empty
                  ? AppColors.hint
                  : (accent ? AppColors.moss600 : AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
