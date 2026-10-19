import 'package:flutter/material.dart';

/// Every color in the Start.sa prototype (docs/02_design_system.md §1).
/// CSS `#RRGGBBAA` values are written here as Flutter `0xAARRGGBB`.
class AppColors {
  AppColors._();

  // Core tokens.
  static const cream = Color(0xFFFAF8F4);
  static const green = Color(0xFF1F3F27);
  static const gold = Color(0xFFC9A24A);
  static const ink = Color(0xFF1C1F1D);
  static const grey = Color(0xFF5B625D);
  static const moss600 = Color(0xFF2F5D3A);
  static const moss400 = Color(0xFF5E8A68);
  static const moss100 = Color(0xFFE6EFE7);
  static const moss50 = Color(0xFFF2F7F3);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E1DA);
  static const borderStrong = Color(0xFF8C918D);
  static const mutedFill = Color(0xFFF1EFEA);
  static const dividerSoft = Color(0xFFEDEAE3);
  static const gold100 = Color(0xFFF7EDD5);
  static const gold700 = Color(0xFF8A6A1F);
  static const tagGoldFill = Color(0xFFF6EEDB);
  static const tagGoldText = Color(0xFF7A5A12);
  static const error = Color(0xFFB3261E);
  static const errorFill = Color(0xFFFBEAE9);
  static const scrim = Color(0x661C1F1D);

  // Literal colors used by specific components.
  /// Light gold: selected nav icon, selected Explore tab icon, step label.
  static const goldLight = Color(0xFFE3CF9B);

  /// Guest "Sign up" and My Startups "Add" pill text.
  static const goldPillText = Color(0xFFF3E6C4);

  /// Guest "Sign up" and My Startups "Add" pill border (rgba(227,207,155,.75)).
  static const goldPillBorder = Color(0xBFE3CF9B);

  /// Muted text on green (sublines, drawer role line, calculator labels).
  static const onGreenMuted = Color(0xFFCFE0D3);

  /// Pitch text on green.
  static const onGreenPitch = Color(0xFFE4EEE6);

  /// Unselected header tab text on green.
  static const onGreenTab = Color(0xFFA9C0AE);

  /// Card tag chip fill, match % pill, filter button active fill, "New" badge.
  static const mossChip = Color(0xFFEEF4EF);

  static const metaText = Color(0xFF6B726C);
  static const bodyLine = Color(0xFF4A544D);
  static const paragraph = Color(0xFF3E4A41);
  static const placeholder = Color(0xFF4F5751);
  static const hint = Color(0xFF8C918D);
  static const chevron = Color(0xFF9AA19B);
  static const segTrack = Color(0xFFE9E6DF);
  static const rangeFill = Color(0xFFEBE8E1);
  static const profileBg = Color(0xFFF6F4EF);
  static const rowSeparator = Color(0xFFF0EDE6);
  static const notifDot = Color(0xFFE5484D);
  static const logOut = Color(0xFFB23B3B);
  static const bookmarkOn = Color(0xFFA87A25);
  static const offFill = Color(0xFFD9D6CF);
  static const offText = Color(0xFF7D837E);
  static const switchOff = Color(0xFFD6D3CC);
  static const sheetHandle = Color(0xFFD6D3CC);
  static const liveDot = Color(0xFF5FD38A);
  static const liveRing = Color(0x385FD38A);
  static const liveOff = Color(0xFFA9B0AA);
  static const liveOffRing = Color(0x38A9B0AA);
  static const deltaFill = Color(0xFFE3F3E8);
  static const deltaText = Color(0xFF1F7A42);
  static const linkedIn = Color(0xFF0A66C2);
  static const cardBorder = Color(0xFFEBE7DF);

  /// "Other existing owners" segment of the calculator ownership bar.
  static const ownershipOthers = Color(0xFF9DC0A4);
  static const chipBorderSoft = Color(0xFFCFD6D0);
  static const filterOptBorder = Color(0xFFE0DDD5);
  static const filterPanelBorder = Color(0xFFEBE8E1);
  static const searchDivider = Color(0xFFE6E3DC);
  static const sheetGrab = Color(0xFFD6D2C9);
  static const previewBar = gold100;

  /// Intro illustrations: pale grey bars/lines, sage bar, sage line on green.
  static const introGrey = Color(0xFFE3E1DB);
  static const introSageBar = Color(0xFFC5CCC5);
  static const introSage = Color(0xFF8CA691);

  /// White at 12 %: glass icon buttons on green headers.
  static const glassFill = Color(0x1FFFFFFF);

  /// Hover/pressed fill of the guest "Sign up" outline pill.
  static const goldPillPressed = Color(0x14FFFFFF);

  /// White at 20 %: inactive step-progress segments.
  static const stepSegmentOff = Color(0x33FFFFFF);

  /// Focus ring of inputs (`#2F5D3A26`).
  static const focusRing = Color(0x262F5D3A);

  /// Error ring of inputs (`#B3261E1F`).
  static const errorRing = Color(0x1FB3261E);

  /// "Edit profile" outline pill on the profile banner: fill / border.
  static const editPillFill = Color(0x14FFFFFF);
  static const editPillBorder = Color(0x4CFFFFFF);
  static const white = Color(0xFFFFFFFF);
  static const onDark = white;

  /// Avatar hue palette (`HUES` in the prototype). The hue for a name is
  /// `hues[sum of the name's UTF-16 code units % 5]`.
  static const hues = <Color>[
    Color(0xFF2F5D3A),
    Color(0xFF2B6A6E),
    Color(0xFF3F5F8A),
    Color(0xFFA87A25),
    Color(0xFF6A4F7A),
  ];

  /// 10 % of [hue] mixed with white: avatar fill.
  static Color avatarFill(Color hue) => Color.lerp(white, hue, 0.10)!;

  /// 35 % of [hue] mixed with white: avatar inner ring.
  static Color avatarRing(Color hue) => Color.lerp(white, hue, 0.35)!;

  /// The hue for [name] (prototype rule).
  static Color hueFor(String name) {
    var sum = 0;
    for (final unit in name.codeUnits) {
      sum += unit;
    }
    return hues[sum % hues.length];
  }
}
