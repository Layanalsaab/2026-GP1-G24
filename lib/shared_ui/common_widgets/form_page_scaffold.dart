import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'svg_asset.dart';

/// Page frame shared by the form-style screens (choose role, create account,
/// log in, forgot password, onboarding): green top bar with a back button,
/// optional gold progress steps, scrollable content, and a pinned bottom area.
class FormPageScaffold extends StatelessWidget {
  const FormPageScaffold({
    super.key,
    required this.child,
    this.bottom,
    this.progressSteps,
    this.contentTopPadding = 16,
    this.bottomTopPadding = 12,
    this.onBack,
  });

  final Widget child;

  /// Pinned below the scrolling content (usually the primary button).
  final Widget? bottom;

  /// Number of gold progress bars under the top bar; null hides the strip.
  final int? progressSteps;

  final double contentTopPadding;
  final double bottomTopPadding;

  /// What the back arrow does. Defaults to going back one screen.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            // Top bar (extends under the status bar).
            Container(
              color: AppColors.green,
              padding: EdgeInsets.only(top: media.padding.top),
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _BackButton(
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ),
            ),
            if (progressSteps != null)
              // Figma: bars are 100 wide with 8 gaps, starting at x = 24. On
              // narrower screens they shrink so they never overflow.
              Container(
                width: double.infinity,
                color: AppColors.green,
                padding: const EdgeInsets.only(bottom: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final steps = progressSteps!;
                    final barWidth = math.min(
                      100.0,
                      (constraints.maxWidth - 24 - 20 - 8 * (steps - 1)) / steps,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Row(
                        children: [
                          for (var i = 0; i < steps; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Container(
                              width: barWidth,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, contentTopPadding, 24, 16),
                child: child,
              ),
            ),
            if (bottom != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  bottomTopPadding,
                  24,
                  math.max(32, media.padding.bottom),
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(child: svgIcon('back.svg', size: 22)),
      ),
    );
  }
}
