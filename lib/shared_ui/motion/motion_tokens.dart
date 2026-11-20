import 'package:flutter/animation.dart';

/// Curves used by every animation (STARTSA_ANIMATIONS.md §0.1).
abstract final class AppCurves {
  /// Default everywhere.
  static const easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Line drawing.
  static const easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// Sheets and the side menu.
  static const drawer = Cubic(0.32, 0.72, 0, 1);

  /// Plain CSS "ease".
  static const ease = Curves.ease;
}

/// Durations used by every animation (§0.1).
abstract final class AppDur {
  static const press = Duration(milliseconds: 140);
  static const fast = Duration(milliseconds: 160);
  static const chip = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 200);
  static const card = Duration(milliseconds: 220);
  static const screen = Duration(milliseconds: 260);
  static const sheet = Duration(milliseconds: 340);

  /// Replaces every movement when the user asked for reduced motion.
  static const reducedFade = Duration(milliseconds: 200);
}

/// The pressed scale of each kind of element (§0.4).
abstract final class PressScale {
  /// Buttons, pressable cards, select fields, pickers, "Add team member".
  static const button = 0.97;

  static const icon = 0.92;

  /// Form chips, advanced-search option chips, filter pills.
  static const chip = 0.96;

  /// Home cards and rail cards.
  static const homeCard = 0.985;

  /// Share / bookmark icons on a card.
  static const cardAction = 0.90;

  /// The header avatar button and the search bar's filter button.
  static const avatar = 0.94;

  static const pill = 0.95;

  /// Menu "View profile" pill and the LinkedIn pill.
  static const smallPill = 0.96;
}
