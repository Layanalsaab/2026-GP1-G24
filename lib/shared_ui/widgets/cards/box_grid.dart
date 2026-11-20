import 'package:flutter/material.dart';

import '../../../helpers/open_link.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// A 2-column grid of small cream boxes (label over value).
class BoxGrid extends StatelessWidget {
  const BoxGrid({
    super.key,
    required this.items,
    this.emptyText = 'Not added yet',
    this.accent = const {},
    this.page = false,
    this.fullWidthLast = false,
    this.wrap = const {},
    this.links = const {},
  });

  final bool page;

  /// The last box spans the whole width (Key numbers: Runway).
  final bool fullWidthLast;

  /// Labels whose value is shown in moss green (the Website).
  final Set<String> accent;

  final Set<String> links;

  final Set<String> wrap;

  /// (label, value) pairs.
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
                  wrap.contains(items[i].$1),
                  links.contains(items[i].$1),
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
                        wrap.contains(items[i + 1].$1),
                        links.contains(items[i + 1].$1),
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
          wrap.contains(items.last.$1),
          links.contains(items.last.$1),
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
  const _Box(
    this.label,
    this.value,
    this.emptyText,
    this.accent,
    this.page,
    this.wrap,
    this.link,
  );

  final bool link;
  final bool wrap;
  final bool page;
  final bool accent;
  final String label;
  final String value;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    final opens = link && !empty;
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: page ? AppColors.cream : AppColors.boxFill,
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
            maxLines: wrap ? null : 2,
            overflow: wrap ? TextOverflow.visible : TextOverflow.ellipsis,
            style:
                AppText.sans(
                  size: page ? 17 : 15,
                  height: 20,
                  weight: page ? FontWeight.w700 : FontWeight.w600,
                  color: empty
                      ? AppColors.hint
                      : (accent || opens ? AppColors.mossText : AppColors.ink),
                ).copyWith(
                  decoration: opens ? TextDecoration.underline : null,
                  decorationColor: AppColors.mossText,
                ),
          ),
        ],
      ),
    );
    if (!opens) return box;
    // A web address: tapping it opens the real website.
    return Semantics(
      button: true,
      link: true,
      label: '$label, ${value.trim()}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openExternalLink(value),
        child: box,
      ),
    );
  }
}
