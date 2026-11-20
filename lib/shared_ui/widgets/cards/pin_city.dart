import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// A city on a card line: the small location pin, a 4 px gap, then the city.
class PinCity extends StatelessWidget {
  const PinCity(this.city, {super.key, this.style});

  final String? city;

  /// The city text style; 13 px AppColors.metaText by default.
  final TextStyle? style;

  static const double pinSize = 14;
  static const double gap = 4;

  /// The pin and the city inside a line of text (for a Text.rich).
  static InlineSpan span(
    String city, {
    required TextStyle style,
    Color? pinColor,
  }) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon.filled(
          AppIcons.pin,
          size: pinSize,
          color: pinColor ?? style.color,
        ),
        const SizedBox(width: gap),
        Text(city, style: style),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = (city ?? '').trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppIcon.filled(AppIcons.pin, size: pinSize, color: AppColors.hint),
        const SizedBox(width: gap),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style ?? AppText.sans(size: 13, color: AppColors.metaText),
          ),
        ),
      ],
    );
  }
}
