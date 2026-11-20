import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import 'arch_background.dart';
import 'auth_headers.dart';
import 'header_buttons.dart';

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
