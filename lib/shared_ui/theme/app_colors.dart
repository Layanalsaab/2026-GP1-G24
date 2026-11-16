import 'package:flutter/material.dart';

/// Every color in the Start.sa prototype (docs/02_design_system.md §1).
/// CSS `#RRGGBBAA` values are written here as Flutter `0xAARRGGBB`.
///
/// Two palettes, light and dark. A color that changes with the theme is a
/// getter that answers for the palette in use ([isDark], set by
/// `ThemeController`); a color that is the same in both (the brand greens as
/// backgrounds, the gold, white on green, the avatar hues) stays a constant.
///
/// Green appears twice on purpose: [green] and [moss600] are BACKGROUNDS
/// (headers, bottom bar, primary buttons, toast) and keep their color in the
/// dark theme; [greenText] and [mossText] are the same greens used as TEXT,
/// icons and borders on a surface, and turn light in the dark theme.
class AppColors {
  AppColors._();

  // ------------------------------------------------------------- the mode

  static bool _dark = false;

  /// The dark palette is in use.
  static bool get isDark => _dark;

  /// Switches the palette. Whoever calls it also rebuilds the screens
  /// (`ThemeController` does).
  static void setDark(bool value) => _dark = value;

  static Color _p(int light, int dark) => Color(_dark ? dark : light);

  // ------------------------------------------------- same in both themes

  /// Header / bottom bar / primary button green (a background).
  static const green = Color(0xFF1F3F27);
  static const gold = Color(0xFFC9A24A);

  /// Button green (a background); white text sits on it.
  static const moss600 = Color(0xFF2F5D3A);

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

  static const notifDot = Color(0xFFE5484D);
  static const liveDot = Color(0xFF5FD38A);
  static const liveRing = Color(0x385FD38A);
  static const linkedInBrand = Color(0xFF0A66C2);

  /// Intro illustrations: the sage line on green.
  static const introSage = Color(0xFF8CA691);

  /// White at 12 %: glass icon buttons on green headers.
  static const glassFill = Color(0x1FFFFFFF);

  /// Hover/pressed fill of the guest "Sign up" outline pill.
  static const goldPillPressed = Color(0x14FFFFFF);

  /// White at 20 %: inactive step-progress segments.
  static const stepSegmentOff = Color(0x33FFFFFF);

  /// "Edit profile" outline pill on the profile banner: fill / border.
  static const editPillFill = Color(0x14FFFFFF);
  static const editPillBorder = Color(0x4CFFFFFF);

  /// White: text and icons on green, the switch knob. NOT a surface (use
  /// [surface] for a card).
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

  // ------------------------------------------------ changes with the theme

  /// The page background.
  static Color get cream => _p(0xFFFAF8F4, 0xFF101411);

  /// Cards, sheets, dialogs, inputs.
  static Color get surface => _p(0xFFFFFFFF, 0xFF1A201C);

  /// Main text.
  static Color get ink => _p(0xFF1C1F1D, 0xFFE8ECE9);

  /// Secondary text.
  static Color get grey => _p(0xFF5B625D, 0xFFA6AEA8);

  /// The brand green as TEXT, an icon or a border on a surface.
  static Color get greenText => _p(0xFF1F3F27, 0xFFA9D4B3);

  /// The button green as TEXT, an accent icon or a border on a surface.
  static Color get mossText => _p(0xFF2F5D3A, 0xFF86BB92);

  /// Soft amber for non-blocking notes ("Make sure your email domain is correct.").
  static Color get warning => _p(0xFF9A5B00, 0xFFE8B04A);
  static Color get moss400 => _p(0xFF5E8A68, 0xFF7FAE8B);
  static Color get moss100 => _p(0xFFE6EFE7, 0xFF223228);
  static Color get moss50 => _p(0xFFF2F7F3, 0xFF18211B);

  /// The tinted border of a moss box.
  static Color get mossBorder => _p(0xFFCFE0D3, 0xFF34493A);
  static Color get border => _p(0xFFE4E1DA, 0xFF2E3831);
  static Color get borderStrong => _p(0xFF8C918D, 0xFF7B847D);
  static Color get mutedFill => _p(0xFFF1EFEA, 0xFF232A25);
  static Color get dividerSoft => _p(0xFFEDEAE3, 0xFF28312B);
  static Color get gold100 => _p(0xFFF7EDD5, 0xFF3A3219);
  static Color get gold700 => _p(0xFF8A6A1F, 0xFFD9B968);
  static Color get tagGoldFill => _p(0xFFF6EEDB, 0xFF3A3219);
  static Color get tagGoldText => _p(0xFF7A5A12, 0xFFECD08A);
  static Color get error => _p(0xFFB3261E, 0xFFF2A8A3);
  static Color get errorFill => _p(0xFFFBEAE9, 0xFF3F2220);
  static Color get scrim => _p(0x661C1F1D, 0xB3000000);

  /// Card tag chip fill, match % pill, filter button active fill, "New" badge.
  static Color get mossChip => _p(0xFFEEF4EF, 0xFF1E2A22);

  static Color get metaText => _p(0xFF6B726C, 0xFF98A199);
  static Color get bodyLine => _p(0xFF4A544D, 0xFFB7BFB9);
  static Color get paragraph => _p(0xFF3E4A41, 0xFFC5CCC6);
  static Color get placeholder => _p(0xFF4F5751, 0xFF8E978F);

  /// Hint text. A touch lighter than the strong border in the dark theme, so
  /// it stays readable (4.5:1) on a surface.
  static Color get hint => _p(0xFF8C918D, 0xFF8A938C);
  static Color get chevron => _p(0xFF9AA19B, 0xFF7B847D);
  static Color get segTrack => _p(0xFFE9E6DF, 0xFF2A332D);
  static Color get rangeFill => _p(0xFFEBE8E1, 0xFF2A332D);
  static Color get profileBg => _p(0xFFF6F4EF, 0xFF141915);
  static Color get rowSeparator => _p(0xFFF0EDE6, 0xFF252D27);
  static Color get logOut => _p(0xFFB23B3B, 0xFFF2A8A3);
  static Color get bookmarkOn => _p(0xFFA87A25, 0xFFD8B864);
  static Color get offFill => _p(0xFFD9D6CF, 0xFF2B332D);
  static Color get offText => _p(0xFF7D837E, 0xFF9AA39B);
  static Color get switchOff => _p(0xFFD6D3CC, 0xFF3A443D);
  static Color get sheetHandle => _p(0xFFD6D3CC, 0xFF3A443D);
  static Color get liveOff => _p(0xFFA9B0AA, 0xFF6B746D);
  static Color get liveOffRing => _p(0x38A9B0AA, 0x386B746D);
  static Color get deltaFill => _p(0xFFE3F3E8, 0xFF1F3A28);
  static Color get deltaText => _p(0xFF1F7A42, 0xFF86D39B);
  static Color get linkedIn => _p(0xFF0A66C2, 0xFF7DB4F0);
  static Color get cardBorder => _p(0xFFEBE7DF, 0xFF2A332D);

  /// "Other existing owners" segment of the calculator ownership bar.
  static Color get ownershipOthers => _p(0xFF9DC0A4, 0xFF5E8A68);
  static Color get chipBorderSoft => _p(0xFFCFD6D0, 0xFF3A443D);
  static Color get filterOptBorder => _p(0xFFE0DDD5, 0xFF34403A);
  static Color get filterPanelBorder => _p(0xFFEBE8E1, 0xFF2A332D);
  static Color get searchDivider => _p(0xFFE6E3DC, 0xFF2A332D);
  static Color get sheetGrab => _p(0xFFD6D2C9, 0xFF3A443D);
  static Color get previewBar => gold100;

  /// The gold notice box ("This startup is closed", "You no longer have a
  /// startup"): fill, border, title, message and icon. One look for every
  /// notice, in the app's gold (no blue).
  static Color get noticeFill => gold100;
  static Color get noticeBorder => _p(0xFFEBDDB5, 0xFF5A4C22);
  static Color get noticeTitle => _p(0xFF6A4E10, 0xFFECD08A);
  static Color get noticeText => tagGoldText;
  static Color get noticeIcon => gold700;

  /// Intro illustrations: pale grey bars/lines and the sage bar.
  static Color get introGrey => _p(0xFFE3E1DB, 0xFF2E3831);
  static Color get introSageBar => _p(0xFFC5CCC5, 0xFF4A5A4E);

  /// Focus ring of inputs (`#2F5D3A26`).
  static Color get focusRing => _p(0x262F5D3A, 0x4086BB92);

  /// Error ring of inputs (`#B3261E1F`).
  static Color get errorRing => _p(0x1FB3261E, 0x40F2A8A3);

  /// The toast: dark on a light page, light on a dark one.
  static Color get toastFill => _p(0xFF1F3F27, 0xFFE8ECE9);
  static Color get toastText => _p(0xFFFFFFFF, 0xFF101411);

  /// A warm box inside a card (Manage boxes), hover fills.
  static Color get boxFill => _p(0xFFF7F4EC, 0xFF232A25);

  /// Row and card hover / press tints (light values are the prototype's).
  static Color get pressFill => _p(0xFFF7F5F0, 0xFF202823);
  static Color get hoverFill => _p(0xFFF3F1EC, 0xFF232A25);
  static Color get menuHover => _p(0xFFEFECE5, 0xFF232A25);
  static Color get softDivider => _p(0xFFEFECE6, 0xFF28312B);
  static Color get invitedFill => _p(0xFFEDEEEB, 0xFF232A25);
  static Color get dotOff => _p(0xFFC3C0B9, 0xFF5A645D);
  static Color get hoverRing => _p(0xFFCFDCD2, 0xFF3A5545);

  /// Pale grey icons and dots (runway, chevrons in lists).
  static Color get dimIcon => _p(0xFFA3A7A2, 0xFF6B746D);

  /// A border when the pointer is over a card or a choice.
  static Color get borderHover => _p(0xFFD9D4C9, 0xFF3A443D);
  static Color get hoverBorderGreen => _p(0xFFB9C8BD, 0xFF4A5F50);
  static Color get dashGrey => _p(0xFFB9BDB8, 0xFF4A544D);

  /// Status colors: text lightens and fills darken in the dark theme.
  static Color get tagBlueFill => _p(0xFFE7EEF8, 0xFF1D2A3D);
  static Color get tagBlueText => _p(0xFF2B4F80, 0xFF9EC0F0);
  static Color get statusGreen => _p(0xFF2F8A4A, 0xFF6BD08C);

  /// The pale gold of an active filter pill.
  static Color get goldFillSoft => _p(0xFFF3E6C4, 0xFF3A3219);

  /// The pale mint track of a chart.
  static Color get chartTrack => _p(0xFFD5E6D9, 0xFF2F4636);

  /// Text and icon on the gold "preview" bar (green on light).
  static Color get previewBarText => _p(0xFF1F3F27, 0xFFECD08A);

  /// The soft shadow under a card (nothing to see on a dark page).
  static Color get shadowTint => _p(0xFF1F3F27, 0xFF000000);

  // ----------------------------------------------------------------- avatar

  /// Avatar tiles: light in the light theme, a dark moss gradient in the dark
  /// one.
  static Color get tileMossTop => _p(0xFFEEF4EF, 0xFF24382A);
  static Color get tileMossBottom => _p(0xFFDFEAE1, 0xFF1C2D22);
  static Color get tileGoldTop => _p(0xFFFAF3E3, 0xFF3D3519);
  static Color get tileGoldBottom => _p(0xFFF2E6C9, 0xFF2F2913);

  /// 10 % of [hue] mixed with white (a dark surface in the dark theme):
  /// avatar fill.
  static Color avatarFill(Color hue) => _dark
      ? Color.lerp(const Color(0xFF1C2D22), hue, 0.22)!
      : Color.lerp(white, hue, 0.10)!;

  /// 35 % of [hue] mixed with white: avatar inner ring.
  static Color avatarRing(Color hue) => _dark
      ? Color.lerp(const Color(0xFF1C2D22), hue, 0.55)!
      : Color.lerp(white, hue, 0.35)!;

  /// The color of the initials in an avatar: the hue itself on light, a
  /// brighter mix on dark.
  static Color avatarInk(Color hue) =>
      _dark ? Color.lerp(hue, white, 0.62)! : hue;

  /// The hue for [name] (prototype rule).
  static Color hueFor(String name) {
    var sum = 0;
    for (final unit in name.codeUnits) {
      sum += unit;
    }
    return hues[sum % hues.length];
  }
}
