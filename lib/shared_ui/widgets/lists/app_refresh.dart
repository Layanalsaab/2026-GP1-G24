import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppRefresh extends StatelessWidget {
  const AppRefresh({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  /// Always scrollable, so a short page can still be pulled.
  static const ScrollPhysics physics = AlwaysScrollableScrollPhysics();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.mossText,
      backgroundColor: AppColors.surface,
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
