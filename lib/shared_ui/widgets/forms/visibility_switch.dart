import 'package:flutter/material.dart';

import '../../motion/motion.dart';
import '../../theme/app_text.dart';

/// The Private / Public switch at the right end of the Email and Phone label
/// rows (sign-up and Edit profile, founder and investor). One tap flips it
/// (no sheet, menu or toast) and it never focuses the text field.
///
/// The word "Private" / "Public" (12.5 px, semibold, grey `#5B625D`), then an
/// 8 px gap and the switch: 40 x 24, fully rounded, 3 px padding, an 18 x 18
/// white knob with a soft shadow that slides 16 px. Off = grey `#D6D3CC`
/// (Private, the default), on = moss `#2F5D3A` (Public).
///
/// It is 26 px high, like the old pill; pass it as `AppField.labelTrailing`,
/// which lets it hang over the 20 px label line so the label row never gets
/// taller.
class VisibilitySwitch extends StatelessWidget {
  const VisibilitySwitch({
    super.key,
    required this.isPublic,
    required this.onChanged,
    required this.fieldName,
  });

  final bool isPublic;
  final ValueChanged<bool> onChanged;

  /// "email" or "phone", for the screen-reader label.
  final String fieldName;

  static const _off = Color(0xFFD6D3CC);
  static const _on = Color(0xFF2F5D3A);
  static const _word = Color(0xFF5B625D);

  @override
  Widget build(BuildContext context) {
    final duration = Motion.dur(context, const Duration(milliseconds: 160));
    return Semantics(
      button: true,
      toggled: isPublic,
      label: isPublic
          ? 'Your $fieldName is public. Tap to make it private.'
          : 'Your $fieldName is private. Tap to make it public.',
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.chip,
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(!isPublic),
        child: SizedBox(
          height: 26,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                isPublic ? 'Public' : 'Private',
                style: AppText.sans(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: _word,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                key: const ValueKey('visibility-track'),
                duration: duration,
                curve: Curves.ease,
                width: 40,
                height: 24,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isPublic ? _on : _off,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedAlign(
                  duration: duration,
                  curve: Curves.ease,
                  alignment: isPublic
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    key: const ValueKey('visibility-knob'),
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
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
