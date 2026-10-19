import 'package:flutter/material.dart';

/// Spacing, radii, sizes and shadows (docs/02_design_system.md §3).
/// All values are logical pixels at the 412 x 892 design frame.
class AppSpace {
  AppSpace._();

  /// Screen side padding.
  static const double page = 16;

  /// Gap between stacked form fields.
  static const double field = 20;

  /// Gap between home cards and sections.
  static const double list = 16;
}

class AppRadius {
  AppRadius._();

  static const double input = 12;
  static const double button = 14;
  static const double buttonSmall = 12;
  static const double card = 18;
  static const double homeCard = 20;
  static const double authCard = 22;
  static const double sheet = 24;
  static const double dialog = 24;
  static const double headerAuth = 28;
  static const double headerHome = 30;
  static const double pill = 999;
}

class AppSize {
  AppSize._();

  static const double buttonHeight = 48;
  static const double buttonSmallHeight = 40;
  static const double ctaButtonHeight = 52;
  static const double inputMinHeight = 50;
  static const double iconButton = 44;
  static const double glassIconButton = 40;
  static const double headerLogoAuth = 42;
  static const double headerLogoHome = 36;
  static const double avatarHome = 58;
  static const double avatarTrending = 50;
  static const double avatarSmall = 44;
  static const double avatarDropdown = 36;
}

/// Box shadows. Flutter's `blurRadius` equals the CSS blur radius.
class AppShadow {
  AppShadow._();

  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0A1F3F27), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0D1F3F27), offset: Offset(0, 2), blurRadius: 8),
  ];

  /// Home card / list box / profile section.
  static const homeCard = <BoxShadow>[
    BoxShadow(
      color: Color(0x991F3F27),
      offset: Offset(0, 12),
      blurRadius: 26,
      spreadRadius: -22,
    ),
    BoxShadow(color: Color(0x0D1F3F27), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const authCard = <BoxShadow>[
    BoxShadow(
      color: Color(0x731F3F27),
      offset: Offset(0, 20),
      blurRadius: 40,
      spreadRadius: -24,
    ),
    BoxShadow(color: Color(0x0D1F3F27), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Choose-role cards, My Startups cards.
  static const listCard = <BoxShadow>[
    BoxShadow(
      color: Color(0x8C1F3F27),
      offset: Offset(0, 16),
      blurRadius: 32,
      spreadRadius: -22,
    ),
    BoxShadow(color: Color(0x0D1F3F27), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Primary button (the inset highlight is drawn by the button itself).
  static const primaryButton = <BoxShadow>[
    BoxShadow(
      color: Color(0x801F3F27),
      offset: Offset(0, 6),
      blurRadius: 14,
      spreadRadius: -6,
    ),
  ];

  static const dangerButton = <BoxShadow>[
    BoxShadow(
      color: Color(0x80B3261E),
      offset: Offset(0, 6),
      blurRadius: 14,
      spreadRadius: -6,
    ),
  ];

  static const searchBar = <BoxShadow>[
    BoxShadow(
      color: Color(0x8C0F2314),
      offset: Offset(0, 10),
      blurRadius: 24,
      spreadRadius: -14,
    ),
    BoxShadow(color: Color(0x140F2314), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const toast = <BoxShadow>[
    BoxShadow(
      color: Color(0x801F3F27),
      offset: Offset(0, 12),
      blurRadius: 28,
      spreadRadius: -8,
    ),
  ];

  static const sheet = <BoxShadow>[
    BoxShadow(
      color: Color(0x401F3F27),
      offset: Offset(0, -12),
      blurRadius: 32,
      spreadRadius: -12,
    ),
  ];

  static const drawer = <BoxShadow>[
    BoxShadow(
      color: Color(0x66000000),
      offset: Offset(12, 0),
      blurRadius: 30,
      spreadRadius: -12,
    ),
  ];

  static const dialog = <BoxShadow>[
    BoxShadow(
      color: Color(0x591F3F27),
      offset: Offset(0, 24),
      blurRadius: 48,
      spreadRadius: -12,
    ),
  ];

  /// Segmented switch thumb.
  static const segThumb = <BoxShadow>[
    BoxShadow(
      color: Color(0x4D1F3F27),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: -3,
    ),
    BoxShadow(color: Color(0x0F1F3F27), blurRadius: 0, spreadRadius: 0.5),
  ];

  /// Range control selected button.
  static const rangeThumb = <BoxShadow>[
    BoxShadow(
      color: Color(0x2E000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: -2,
    ),
  ];

  /// Dropdown menus.
  static const dropdown = <BoxShadow>[
    BoxShadow(
      color: Color(0x590F1912),
      offset: Offset(0, 14),
      blurRadius: 30,
      spreadRadius: -10,
    ),
    BoxShadow(color: Color(0x0F0F1912), blurRadius: 0, spreadRadius: 1),
  ];

  static const bottomNav = <BoxShadow>[
    BoxShadow(
      color: Color(0x66000000),
      offset: Offset(0, -8),
      blurRadius: 20,
      spreadRadius: -12,
    ),
  ];
}
