import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// A scrollable form page: [header] (an `AuthHeader`, `StepHeader`,
/// `RoleHeader`...) followed by [children] (normally an `AuthCard` or
/// `OverlapList`, plus an optional `FooterLink`), all in one scroll view on
/// the cream background, with an optional pinned [footer] (see [FormFooter])
/// that stays above the keyboard. The header's own overlap makes the card
/// climb into the green block.
class FormPageScaffold extends StatelessWidget {
  const FormPageScaffold({
    super.key,
    required this.header,
    required this.children,
    this.footer,
    this.controller,
  });

  final Widget header;

  /// Scrollable content under the header.
  final List<Widget> children;

  /// Pinned bar under the scroll area (usually a [FormFooter]).
  final Widget? footer;

  /// Optional scroll controller (scroll to the first error).
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, ...children],
              ),
            ),
          ),
          ?footer,
        ],
      ),
    );
  }
}

/// The pinned footer of a form page (padding 12 24 24): the primary button
/// ([primary], an `AppButton`) and optionally a [link] text row under it
/// (14 px gap), e.g. `FooterLink(prefix: 'Already have an account?', ...)`.
class FormFooter extends StatelessWidget {
  const FormFooter({super.key, required this.primary, this.link});

  final Widget primary;
  final Widget? link;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            primary,
            if (link != null) ...[const SizedBox(height: 14), link!],
          ],
        ),
      ),
    );
  }
}

/// Centered 14 px grey sentence with a tappable link at its end:
/// "Already have an account? **Log in**". Footer links are 700 green
/// (default); the choose-role one is 600 moss ([FooterLink.moss]).
class FooterLink extends StatelessWidget {
  const FooterLink({
    super.key,
    required this.prefix,
    required this.linkLabel,
    required this.onTap,
    this.linkColor = AppColors.green,
    this.linkWeight = FontWeight.w700,
    this.padding = EdgeInsets.zero,
  });

  /// 14/600 moss600 link (choose-role "Log in").
  const FooterLink.moss({
    super.key,
    required this.prefix,
    required this.linkLabel,
    required this.onTap,
    this.padding = EdgeInsets.zero,
  }) : linkColor = AppColors.moss600,
       linkWeight = FontWeight.w600;

  final String prefix;
  final String linkLabel;
  final VoidCallback? onTap;
  final Color linkColor;
  final FontWeight linkWeight;

  /// Around the text: `EdgeInsets.fromLTRB(24, 18, 24, 28)` below a
  /// login-style card; zero inside a [FormFooter].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final base = AppText.sans(size: 13, color: AppColors.grey);
    return Padding(
      padding: padding,
      child: FittedBox(
        // One line that never grows wider than the button above it.
        fit: BoxFit.scaleDown,
        child: Text.rich(
          textAlign: TextAlign.center,
          TextSpan(
            style: base,
            children: [
              TextSpan(text: '$prefix '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Semantics(
                  button: true,
                  label: linkLabel,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: Text(
                      linkLabel,
                      style: base.copyWith(
                        color: linkColor,
                        fontWeight: linkWeight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
