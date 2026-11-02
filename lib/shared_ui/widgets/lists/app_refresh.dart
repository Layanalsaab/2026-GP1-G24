import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Pull down to refresh: wraps a scroll view so dragging it down at the top
/// runs [onRefresh] and shows a spinner until it completes.
///
/// The scroll view inside must use [AppRefresh.physics] so the drag works
/// even when the content is shorter than the screen.
class AppRefresh extends StatelessWidget {
  const AppRefresh({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  /// Always scrollable, so a short page can still be pulled.
  static const ScrollPhysics physics = AlwaysScrollableScrollPhysics();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.green,
      backgroundColor: AppColors.white,
      onRefresh: () async {
        try {
          await onRefresh();
        } catch (_) {
          // A failed refresh keeps what is on screen.
        }
      },
      child: child,
    );
  }
}
