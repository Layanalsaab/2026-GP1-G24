import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

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

  /// Pinned bar under the scroll area (usually a FormFooter).
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

/// Centered grey sentence with a tappable link at its end: "Already have an account?
class FooterLink extends StatefulWidget {
  const FooterLink({
    super.key,
    required this.prefix,
    required this.linkLabel,
    required this.onTap,
    this.linkColor,
    this.linkWeight = FontWeight.w700,
    this.padding = EdgeInsets.zero,
  }) : _moss = false;

  /// 600 moss600 link (choose-role "Log in").
  const FooterLink.moss({
    super.key,
    required this.prefix,
    required this.linkLabel,
    required this.onTap,
    this.padding = EdgeInsets.zero,
  }) : linkColor = null,
       _moss = true,
       linkWeight = FontWeight.w600;

  final String prefix;
  final String linkLabel;
  final VoidCallback? onTap;

  final Color? linkColor;
  final bool _moss;
  final FontWeight linkWeight;

  final EdgeInsetsGeometry padding;

  @override
  State<FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<FooterLink> {
  late final TapGestureRecognizer _tap = TapGestureRecognizer()
    ..onTap = () => widget.onTap?.call();

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppText.sans(size: 13, color: AppColors.grey);
    return Padding(
      padding: widget.padding,
      child: Semantics(
        button: true,
        label: '${widget.prefix} ${widget.linkLabel}',
        excludeSemantics: true,
        onTap: widget.onTap,
        child: FittedBox(
          // One line that never grows wider than the button above it.
          fit: BoxFit.scaleDown,
          child: Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: base,
              children: [
                TextSpan(text: '${widget.prefix} '),
                TextSpan(
                  text: widget.linkLabel,
                  recognizer: _tap,
                  style: TextStyle(
                    color:
                        widget.linkColor ??
                        (widget._moss
                            ? AppColors.mossText
                            : AppColors.greenText),
                    fontWeight: widget.linkWeight,
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
