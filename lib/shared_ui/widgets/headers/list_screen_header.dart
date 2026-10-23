import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import 'arch_background.dart';
import 'auth_headers.dart';
import 'header_buttons.dart';

/// The banner of the Bookmarks and My Startups screens (one layout, so the
/// two are exactly the same height):
///
/// * row 1: back arrow on the left, [topTrailing] (My Startups: the "+ Add"
///   pill) on the right;
/// * row 2: the big [title] on the left, the 42 px Start.sa logo on the right,
///   centered on the title line. No count line under the title;
/// * row 3: [pills] (the filter and sort pills), left-aligned under the
///   title. The row keeps its 28 px even when [pills] is null, so the height
///   never changes.
///
/// The list below starts at the same y on both screens (see [height]).
class ListScreenHeader extends StatelessWidget {
  const ListScreenHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.topTrailing,
    this.pills,
  });

  final String title;
  final VoidCallback onBack;

  /// Right end of the back-arrow row; null leaves it empty.
  final Widget? topTrailing;

  /// The filter + sort pills; null hides them (empty list).
  final Widget? pills;

  /// Content height without the status bar: 6 + 44 + 4 + 42 + 12 + 28 + 18.
  static const double height = 154;

  @override
  Widget build(BuildContext context) {
    return ArchHeaderShell(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderTopRow(
            onBack: onBack,
            trailing: topTrailing ?? const SizedBox(width: 44, height: 44),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              height: 42,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: HeaderTitle(title, style: AppText.authTitle),
                    ),
                  ),
                  const HeaderLogo(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 0, 0),
            child: SizedBox(
              height: 28,
              child: Align(
                alignment: Alignment.centerLeft,
                // Never wider than the banner, even on a narrow phone or
                // with large text: the pills shrink a little instead.
                child: pills == null
                    ? null
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: pills,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
