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
    this.page = false,
    this.fullWidthLast = false,
  });

  /// The startup page's bigger boxes: cream #FAF8F4, label 13 grey, value 17
  /// bold. (Manage keeps its own smaller boxes.)
  final bool page;

  /// The last box spans the whole width (Key numbers: Runway).
  final bool fullWidthLast;

  /// Labels whose value is shown in moss green (the Website).
  final Set<String> accent;

  /// (label, value) pairs. An empty value shows [emptyText] in grey.
  final List<(String, String)> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final pairs = fullWidthLast && items.length.isOdd
        ? items.length - 1
        : items.length;
    for (var i = 0; i < pairs; i += 2) {
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
                  page,
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
                        page,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    if (fullWidthLast && items.length.isOdd) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(
        _Box(
          items.last.$1,
          items.last.$2,
          emptyText,
          accent.contains(items.last.$1),
          page,
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
  const _Box(this.label, this.value, this.emptyText, this.accent, this.page);

  final bool page;
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
        color: page ? const Color(0xFFFAF8F4) : const Color(0xFFF7F4EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.sans(size: page ? 13 : 12.5, color: AppColors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            empty ? emptyText : value.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(
              size: page ? 17 : 15,
              height: 20,
              weight: page ? FontWeight.w700 : FontWeight.w600,
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
